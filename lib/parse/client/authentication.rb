require 'faraday'
require 'faraday_middleware'
require_relative 'protocol'
# All Parse requests require authentication with specific header values.
# This middleware takes all outgoing requests and adds the proper header values
# base on the client configuration.
module Parse

  module Middleware

    class Authentication < Faraday::Middleware
      include Parse::Protocol
      DISABLE_MASTER_KEY = "X-Disable-Parse-Master-Key"
      attr_accessor :application_id
      attr_accessor :api_key
      attr_accessor :master_key
      # The options hash should contain the proper keys to be added to the request.
      def initialize(app, options = {})
        super(app)
        @application_id = options[:application_id]
        @api_key = options[:api_key]
        @master_key = options[:master_key]
        @content_type = options[:content_type] || CONTENT_TYPE_FORMAT
      end

      # we dup the call for thread-safety
      def call(env)
        dup.call!(env)
      end

      def call!(env)
          # We add the main Parse protocol headers
          headers = {}
          raise "No Parse Application Id specified for authentication." unless @application_id.present?
          headers[APP_ID] = @application_id
          headers[API_KEY] = @api_key unless @api_key.blank?

          unless @master_key.blank? || env[:request_headers][DISABLE_MASTER_KEY].present?
            headers[MASTER_KEY] = @master_key
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
