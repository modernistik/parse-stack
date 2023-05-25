# encoding: UTF-8
# frozen_string_literal: true

require "faraday"
require "moneta"
require_relative "protocol"

module Parse
  module Middleware
    # This is a caching middleware for Parse queries using Moneta. The caching
    # middleware will cache all GET requests made to the Parse REST API as long
    # as the API responds with a successful non-empty result payload.
    #
    # Whenever an object is created or updated, the corresponding entry in the cache
    # when fetching the particular record (using the specific non-Query based API)
    # will be cleared.
    class Caching < Faraday::Middleware
      include Parse::Protocol

      # List of status codes that can be cached:
      # * 200 - 'OK'
      # * 203 - 'Non-Authoritative Information'
      # * 300 - 'Multiple Choices'
      # * 301 - 'Moved Permanently'
      # * 302 - 'Found'
      # * 404 - 'Not Found' - removed
      # * 410 - 'Gone' - removed
      CACHEABLE_HTTP_CODES = [200, 203, 300, 301, 302].freeze
      # Cache control header
      CACHE_CONTROL = "Cache-Control"
      # Request env key for the content length
      CONTENT_LENGTH_KEY = "content-length"
      # Header in response that is sent if this is a cached result
      CACHE_RESPONSE_HEADER = "X-Cache-Response"
      # Header in request to set caching information for the middleware.
      CACHE_EXPIRES_DURATION = "X-Parse-Stack-Cache-Expires"

      class << self
        # @!attribute enabled
        # @return [Boolean] whether the caching middleware should be enabled.
        attr_accessor :enabled

        # @!attribute logging
        # @return [Boolean] whether the logging should be enabled.
        attr_accessor :logging

        def enabled
          @enabled = true if @enabled.nil?
          @enabled
        end

        # @return [Boolean] whether caching is enabled.
        def caching?
          @enabled
        end
      end

      # @!attribute [rw] store
      # The internal moneta cache store instance.
      # @return [Moneta::Transformer,Moneta::Expires]
      attr_accessor :store

      # @!attribute [rw] expires
      # The expiration time in seconds for this particular request.
      # @return [Integer]
      attr_accessor :expires

      # Creates a new caching middleware.
      # @param adapter [Faraday::Adapter] An instance of the Faraday adapter
      #  used for the connection. Defaults Faraday::Adapter::NetHttp.
      # @param store [Moneta] An instance of the Moneta cache store to use.
      # @param opts [Hash] additional options.
      # @option opts [Integer] :expires the default expiration for a cache entry.
      # @raise ArgumentError, if `store` is not a Moneta::Transformer or Moneta::Expires instance.
      def initialize(adapter, store, opts = {})
        super(adapter)
        @store = store
        @opts = { expires: 0 }
        @opts.merge!(opts) if opts.is_a?(Hash)
        @expires = @opts[:expires]

        unless [:key?, :[], :delete, :store].all? { |method| @store.respond_to?(method) }
          raise ArgumentError, "Caching store object must a Moneta key/value store."
        end
      end

      # Thread-safety
      # @!visibility private
      def call(env)
        dup.call!(env)
      end

      # @!visibility private
      def call!(env)
        @request_headers = env[:request_headers]

        # get default caching state
        @enabled = self.class.enabled
        # disable cache for this request if "no-cache" was passed
        if @request_headers[CACHE_CONTROL] == "no-cache"
          @enabled = false
        end

        # get the expires information from header (per-request) or instance default
        if @request_headers[CACHE_EXPIRES_DURATION].to_i > 0
          @expires = @request_headers[CACHE_EXPIRES_DURATION].to_i
        end

        # cleanup
        @request_headers.delete(CACHE_CONTROL)
        @request_headers.delete(CACHE_EXPIRES_DURATION)

        # if caching is enabled and we have a valid cache duration, use cache
        # otherwise work as a passthrough.
        return @app.call(env) unless @enabled && @store.present? && @expires > 0

        url = env.url
        method = env.method
        @cache_key = url.to_s

        if @request_headers.key?(SESSION_TOKEN)
          @session_token = @request_headers[SESSION_TOKEN]
          @cache_key = "#{@session_token}:#{@cache_key}" # prefix tokens
        elsif @request_headers.key?(MASTER_KEY)
          @cache_key = "mk:#{@cache_key}" # prefix for master key requests
        end

        begin
          if method == :get && @cache_key.present? && @store.key?(@cache_key)
            puts("[Parse::Cache] Hit >> #{url}") if self.class.logging.present?
            response = Faraday::Response.new
            begin
              cache_data = @store[@cache_key] # previous cached response
            rescue => e
              puts "[Parse::Cache] Error: #{e}"
              cache_data = nil
            end

            # check if the store was from a legacy parse-stack cache value which
            # is stored as Faraday::Env. T\he new system stores less content in a simple hash
            # for improved interoperability and access time.
            if cache_data.is_a?(Faraday::Env)
              body = cache_data.respond_to?(:body) ? cache_data.body : nil
              response_headers = cache_data.response_headers || {}
            elsif cache_data.is_a?(Hash)
              body = cache_data[:body]
              response_headers = cache_data[:headers] || {}
            end

            if cache_data.present? && body.present?
              response_headers[CACHE_RESPONSE_HEADER] = "true"
              response.finish({ status: 200, response_headers: response_headers, body: body })
              return response
            else
              @store.delete @cache_key
            end
          elsif @cache_key.present?
            #non GET requets should clear the cache for that same resource path.
            #ex. a POST to /1/classes/Artist/<objectId> should delete the cache for a GET
            # request for the same '/1/classes/Artist/<objectId>' where objectId are equivalent
            @store.delete url.to_s # regular
            @store.delete "mk:#{url.to_s}" # master key cache-key
            @store.delete @cache_key # final key
          end
        rescue ::TypeError, Errno::EINVAL, Redis::CannotConnectError, Redis::TimeoutError => e
          # if the cache store fails to connect, catch the exception but proceed
          # with the regular request, but turn off caching for this request. It is possible
          # that the cache connection resumes at a later point, so this is temporary.
          @enabled = false
          puts "[Parse::Cache] Error: #{e}"
        end

        @app.call(env).on_complete do |response_env|
          # Only cache GET requests with valid HTTP status codes whose content-length
          # is between 20 bytes and 1MB. Otherwise they could be errors, successes and empty result sets.

          if @enabled && method == :get && CACHEABLE_HTTP_CODES.include?(response_env.status) &&
             response_env.body.present? && response_env.response_headers[CONTENT_LENGTH_KEY].to_i.between?(20, 1_250_000)
            begin
              @store.store(@cache_key,
                           { headers: response_env.response_headers, body: response_env.body },
                           expires: @expires)
            rescue => e
              puts "[Parse::Cache] Store Error: #{e}"
            end
          end # if
          # do something with the response
          # response_env[:response_headers].merge!(...)
        end
      end
    end #Caching
  end #Middleware
end
