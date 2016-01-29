require 'faraday'
require 'faraday_middleware'
require 'moneta'
require_relative 'protocol'
# This is a caching middleware for Parse queries using Moneta.
module Parse
  module Middleware
    class Caching < Faraday::Middleware
      include Parse::Protocol
      # Internal: List of status codes that can be cached:
         # * 200 - 'OK'
         # * 203 - 'Non-Authoritative Information'
         # * 300 - 'Multiple Choices'
         # * 301 - 'Moved Permanently'
         # * 302 - 'Found'
         # * 404 - 'Not Found'
         # * 410 - 'Gone'
      CACHEABLE_HTTP_CODES = [200, 203, 300, 301, 302, 404, 410].freeze

      class << self
        attr_accessor :enabled, :logging

        def enabled
           @enabled = true if @enabled.nil?
           @enabled
        end

        def caching?
          @enabled
        end

      end

      attr_accessor :store, :expires

      def initialize(app, store, opts = {})
        super(app)
        @store = store
        @opts = {expires: 0}
        @opts.merge!(opts) if opts.is_a?(Hash)
        @expires = @opts[:expires]

        unless @store.is_a?(Moneta::Transformer)
          raise "Parse::Middleware::Caching store object must a Moneta key/value store."
        end

      end

      def call(env)
        dup.call!(env)
      end

      def call!(env)

        #unless caching is enabled and we have a valid cache duration
        # then just work as a passthrough
        return @app.call(env) unless @store.present? && @expires > 0 && self.class.enabled

        cache_enabled = true

        url = env.url
        method = env.method
        begin
          if method == :get && url.present? && @store.key?(url)
            puts("[Parse::Cache] >>> #{url}") if self.class.logging.present?
            response = Faraday::Response.new
            body = @store[url].body
            if body.present?
              response.finish({status: 200, response_headers: {}, body: body })
              return response
            else
              @store.delete url
            end
          elsif url.present?
            #non GET requets should clear the cache for that same resource path.
            #ex. a POST to /1/classes/Artist/<objectId> should delete the cache for a GET
            # request for the same '/1/classes/Artist/<objectId>' where objectId are equivalent
            @store.delete url
          end
        rescue Exception => e
          # if the cache store fails to connect, catch the exception but proceed
          # with the regular request, but turn off caching for this request. It is possible
          # that the cache connection resumes at a later point, so this is temporary.
          cache_enabled = false
          warn "[Parse::Cache Error] Cache store connection failed. #{e}"
        end


        @app.call(env).on_complete do |response_env|
          # Only cache GET requests with valid HTTP status codes.
          if cache_enabled && method == :get && CACHEABLE_HTTP_CODES.include?(response_env.status) && response_env.present?
            @store.store(url, response_env, expires: @expires) # ||= response_env.body
          end
          # do something with the response
          # response_env[:response_headers].merge!(...)
        end
      end

    end #Caching

  end #Middleware

end
