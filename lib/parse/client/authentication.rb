# encoding: UTF-8
# frozen_string_literal: true

require "faraday"
require "active_support"
require "active_support/core_ext"

require_relative "protocol"

module Parse
  module Middleware
    # This middleware handles sending the proper authentication headers to the
    # Parse REST API endpoint.
    class Authentication < Faraday::Middleware
      include Parse::Protocol
      # @!visibility private
      DISABLE_MASTER_KEY = "X-Disable-Parse-Master-Key".freeze
      # @return [String] the application id for this Parse endpoint.
      attr_accessor :application_id
      # @return [String] the REST API Key for this Parse endpoint.
      attr_accessor :api_key
      # The Master key API Key for this Parse endpoint. This is optional. If
      # provided, it will be sent in every request.
      # @return [String]
      attr_accessor :master_key

      #
      # @param adapter [Faraday::Adapter] An instance of the Faraday adapter
      #  used for the connection. Defaults Faraday::Adapter::NetHttp.
      # @param options [Hash] the options containing Parse authentication data.
      # @option options [String] :application_id the application id.
      # @option options [String] :api_key the REST API key.
      # @option options [String] :master_key the Master Key for this application.
      #  If it is set, it will be sent on every request unless this middleware sees
      #  {DISABLE_MASTER_KEY} as an entry in the headers section.
      # @option options [String] :content_type the content type format header. Defaults to
      #  {Parse::Protocol::CONTENT_TYPE_FORMAT}.
      def initialize(adapter, options = {})
        super(adapter)
        @application_id = options[:application_id]
        @api_key = options[:api_key]
        @master_key = options[:master_key]
        @content_type = options[:content_type] || CONTENT_TYPE_FORMAT
      end

      # Thread-safety
      # @!visibility private
      def call(env)
        dup.call!(env)
      end

      # @!visibility private
      def call!(env)
        # We add the main Parse protocol headers
        headers = {}
        raise ArgumentError, "No Parse Application Id specified for authentication." unless @application_id.present?
        headers[APP_ID] = @application_id
        headers[API_KEY] = @api_key unless @api_key.blank?
        unless @master_key.blank? || env[:request_headers][DISABLE_MASTER_KEY].present?
          headers[MASTER_KEY] = @master_key
        end

        env[:request_headers].delete(DISABLE_MASTER_KEY)

        # delete the use of master key if we are using session token.
        if env[:request_headers].key?(Parse::Protocol::SESSION_TOKEN)
          headers.delete(MASTER_KEY)
        end
        # merge the headers with the current provided headers
        env[:request_headers].merge! headers
        # set the content type of the request if it was not provided already.
        env[:request_headers][CONTENT_TYPE] ||= @content_type
        # only modify header

        @app.call(env).on_complete do |response_env|
          # check for return code raise an error when authentication was a failure
          # if response_env[:status] == 401
          #   warn "Unauthorized Parse API Credentials for Application Id: #{@application_id}"
          # end

        end
      end
    end # Authenticator
  end
end
