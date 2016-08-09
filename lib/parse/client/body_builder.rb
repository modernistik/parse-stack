require 'faraday'
require 'faraday_middleware'
require_relative 'response'
require_relative 'protocol'
require 'active_support'
require 'active_support/core_ext'
require 'active_model_serializers'
# This middleware takes an incoming response (after an outgoing request)
# and creates a Parse::Response object.
module Parse
  module Middleware
    class BodyBuilder < Faraday::Middleware
      class << self
        attr_accessor :logging
      end

      include Parse::Protocol
      HTTP_OVERRIDE = 'X-Http-Method-Override'.freeze

      # thread-safety
      def call(env)
        dup.call!(env)
      end

      def call!(env)
        # the maximum url size is ~2KB, so if we request a Parse API url greater than this
        # (which is most likely a very complicated query), we need to override the request method
        # to be POST instead of GET and send the query parameters in the body of the POST request.
        # The standard maximum POST request (which is a server setting), is usually set to 20MBs
        if env[:method] == :get && env[:url].to_s.length > 2_000
          env[:request_headers][HTTP_OVERRIDE] = 'GET'
          env[:request_headers][CONTENT_TYPE] = 'application/x-www-form-urlencoded'.freeze
          env[:body] = env[:url].query
          env[:url].query = nil
          #override
          env[:method] = :post
        # else if not a get, always make sure the request is JSON encoded if the content type matches
        elsif env[:request_headers][CONTENT_TYPE] == CONTENT_TYPE_FORMAT &&
           (env[:body].is_a?(Hash) || env[:body].is_a?(Array))
           env[:body] = env[:body].to_json
        end

        if self.class.logging
            puts "[Request #{env.method.upcase}] #{env[:url]}"
            puts "[Request Body] #{env[:body]}"
        end
        @app.call(env).on_complete do |response_env|
          # on a response, create a new Parse::Response and replace the :body
          # of the env
          # TODO: CHECK FOR HTTP STATUS CODES
          if self.class.logging
            puts "[[Response ]] --------------------------------------"
            puts response_env.body
            puts "[[Response]] --------------------------------------\n"
          end

          begin
            r = Parse::Response.new(response_env.body)
          rescue Exception => e
            r = Parse::Response.new
            r.code = response_env.status
            r.error = "Invalid Parse Response: #{e}"
          end

          r.code ||= response_env[:status] if r.error.present?
          response_env[:body] = r
        end
      end

    end
  end #Middleware
end
