# encoding: UTF-8
# frozen_string_literal: true

require "active_model"
require "active_support"
require "active_support/inflector"
require "active_support/core_ext/object"
require "active_support/core_ext"

require "rack"
require_relative "client"
require_relative "stack"
require_relative "model/object"
require_relative "webhooks/payload"
require_relative "webhooks/registration"

module Parse
  class Object

    # Register a webhook function for this subclass.
    # @example
    #  class Post < Parse::Object
    #
    #   webhook_function :helloWorld do
    #      # ... do something when this function is called ...
    #   end
    #  end
    # @param functionName [String] the literal name of the function to be registered with the server.
    # @yield (see Parse::Object.webhook)
    # @param block (see Parse::Object.webhook)
    # @return (see Parse::Object.webhook)
    def self.webhook_function(functionName, block = nil)
      if block_given?
        Parse::Webhooks.route(:function, functionName, &Proc.new)
      else
        block = functionName.to_s.underscore.to_sym if block.blank?
        block = method(block.to_sym) if block.is_a?(Symbol)
        Parse::Webhooks.route(:function, functionName, block)
      end
    end

    # Register a webhook trigger or function for this subclass.
    # @example
    #  class Post < Parse::Object
    #
    #   webhook :before_save do
    #      # ... do something ...
    #     parse_object
    #   end
    #
    #  end
    # @param type (see Parse::Webhooks.route)
    # @yield the body of the function to be evaluated in the scope of a {Parse::Webhooks::Payload} instance.
    # @param block [Symbol] the name of the method to call, if no block is passed.
    # @return (see Parse::Webhooks.route)
    def self.webhook(type, function=nil, &block)
      if type == :function
        unless function.is_a?(String) || function.is_a?(Symbol)
          raise ArgumentError, "Invalid Cloud Code function name: #{function}"
        end
        Parse::Webhooks.route(:function, function, block)
        # then block must be a symbol or a string
      else
        if block
          Parse::Webhooks.route(type, self, block)
        else
          Parse::Webhooks.route(type, self, function)
        end
      end
      #if block

    end
  end

  # A Rack-based application middlware to handle incoming Parse cloud code webhook
  # requests.
  class Webhooks
    # The error to be raised in registered trigger or function webhook blocks that
    # will trigger the Parse::Webhooks application to return the proper error response.
    class ResponseError < StandardError; end

    include Client::Connectable
    extend Parse::Webhooks::Registration
    # The name of the incoming env containing the webhook key.
    HTTP_PARSE_WEBHOOK = "HTTP_X_PARSE_WEBHOOK_KEY"
    # The name of the incoming env containing the application id key.
    HTTP_PARSE_APPLICATION_ID = "HTTP_X_PARSE_APPLICATION_ID"
    # The content type that needs to be sent back to Parse server.
    CONTENT_TYPE = "application/json"

    # The Parse Webhook Key to be used for authenticating webhook requests.
    # See {Parse::Webhooks.key} on setting this value.
    # @return [String]
    def key
      self.class.key
    end

    class << self

      # Allows support for web frameworks that support auto-reloading of source.
      # @!visibility private
      def reload!(args = {})
      end

      # @return [Boolean] whether to print additional logging information. You may also
      #  set this to `:debug` for additional verbosity.
      attr_accessor :logging

      # A hash-like structure composing of all the registered webhook
      # triggers and functions. These are `:before_save`, `:after_save`,
      # `:before_delete`, `:after_delete` or `:function`.
      # @return [OpenStruct]
      def routes
        return @routes unless @routes.nil?
        r = Parse::API::Hooks::TRIGGER_NAMES_LOCAL + [:function]
        @routes = OpenStruct.new(r.reduce({}) { |h, t| h[t] = {}; h })
      end

      # Internally registers a route for a specific webhook trigger or function.
      # @param type [Symbol] The type of cloud code webhook to register. This can be any
      #  of the supported routes. These are `:before_save`, `:after_save`,
      # `:before_delete`, `:after_delete` or `:function`.
      # @param className [String] if `type` is not `:function`, then this registers
      #  a trigger for the given className. Otherwise, className is treated to be the function
      #  name to register with Parse server.
      # @yield the block that will handle of the webhook trigger or function.
      # @return (see routes)
      def route(type, className, &block)
        type = type.to_s.underscore.to_sym #support camelcase
        if type != :function && className.respond_to?(:parse_class)
          className = className.parse_class
        end
        className = className.to_s
        if routes[type].nil? || block.respond_to?(:call) == false
          raise ArgumentError, "Invalid Webhook registration trigger #{type} #{className}"
        end

        # AfterSave/AfterDelete hooks support more than one
        if type == :after_save || type == :after_delete
          routes[type][className] ||= []
          routes[type][className].push block
        else
          routes[type][className] = block
        end
        @routes
      end

      # Run a locally registered webhook function. This bypasses calling a
      # function through Parse-Server if the method handler is registered locally.
      # @return [Object] the result of the function.
      def run_function(name, params)
        payload = Payload.new
        payload.function_name = name
        payload.params = params
        call_route(:function, name, payload)
      end

      # Calls the set of registered webhook trigger blocks or the specific function block.
      # This method is usually called when an incoming request from Parse Server is received.
      # @param type (see route)
      # @param className (see route)
      # @param payload [Parse::Webhooks::Payload] the payload object received from the server.
      # @return [Object] the result of the trigger or function.
      def call_route(type, className, payload = nil)
        type = type.to_s.underscore.to_sym #support camelcase
        className = className.parse_class if className.respond_to?(:parse_class)
        className = className.to_s

        return unless routes[type].present? && routes[type][className].present?
        registry = routes[type][className]

        if registry.is_a?(Array)
          result = registry.map { |hook| payload.instance_exec(payload, &hook) }.last
        else
          result = payload.instance_exec(payload, &registry)
        end

        if result.is_a?(Parse::Object)
          # if it is a Parse::Object, we will call the registered ActiveModel callbacks
          # and then send the proper changes payload
          if type == :before_save
            # returning false from the callback block only runs the before_* callback
            result.prepare_save!
            result = result.changes_payload
          elsif type == :before_delete
            result.run_callbacks(:destroy) { false }
            result = true
          end
        elsif type == :before_save && (result == true || result.nil?)
          # Open Source Parse server does not accept true results on before_save hooks.
          result = {}
        end

        result
      end

      # Generates a success response for Parse Server.
      # @param data [Object] the data to send back with the success.
      # @return [Hash] a success data payload
      def success(data = true)
        { success: data }.to_json
      end

      # Generates an error response for Parse Server.
      # @param data [Object] the data to send back with the error.
      # @return [Hash] a error data payload
      def error(data = false)
        { error: data }.to_json
      end

      # @!attribute key
      # Returns the configured webhook key if available. By default it will use
      # the value of ENV['PARSE_SERVER_WEBHOOK_KEY'] if not configured.
      # @return [String]
      attr_accessor :key

      def key
        @key ||= ENV["PARSE_SERVER_WEBHOOK_KEY"] || ENV["PARSE_WEBHOOK_KEY"]
      end

      # Standard Rack call method. This method processes an incoming cloud code
      # webhook request from Parse Server, validates it and executes any registered handlers for it.
      # The result of the handler for the matching webhook request is sent back to
      # Parse Server. If the handler raises a {Parse::Webhooks::ResponseError},
      # it will return the proper error response.
      # @raise Parse::Webhooks::ResponseError whenever {Parse::Object}, ActiveModel::ValidationError
      # @param env [Hash] the environment hash in a Rack request.
      # @return [Array] the value of calling `finish` on the {http://www.rubydoc.info/github/rack/rack/Rack/Response Rack::Response} object.
      def call(env)
        # Thraed safety
        dup.call!(env)
      end

      # @!visibility private
      def call!(env)
        request = Rack::Request.new env
        response = Rack::Response.new

        if self.key.present? && self.key != request.env[HTTP_PARSE_WEBHOOK]
          puts "[Parse::Webhooks] Invalid Parse-Webhook Key: #{request.env[HTTP_PARSE_WEBHOOK]}"
          response.write error("Invalid Parse Webhook Key")
          return response.finish
        end

        unless request.content_type.present? && request.content_type.include?(CONTENT_TYPE)
          response.write error("Invalid content-type format. Should be application/json.")
          return response.finish
        end

        request.body.rewind
        begin
          payload = Parse::Webhooks::Payload.new request.body.read
        rescue => e
          warn "Invalid webhook payload format: #{e}"
          response.write error("Invalid payload format. Should be valid JSON.")
          return response.finish
        end

        if self.logging.present?
          if payload.trigger?
            puts "[Webhooks::Request] --> #{payload.trigger_name} #{payload.parse_class}:#{payload.parse_id}"
          elsif payload.function?
            puts "[ParseWebhooks Request] --> Function #{payload.function_name}"
          end
          if self.logging == :debug
            puts "[Webhooks::Payload] ----------------------------"
            puts payload.as_json
            puts "----------------------------------------------------\n"
          end
        end

        begin
          result = true
          if payload.function? && payload.function_name.present?
            result = Parse::Webhooks.call_route(:function, payload.function_name, payload)
          elsif payload.trigger? && payload.parse_class.present? && payload.trigger_name.present?
            # call hooks subscribed to the specific class
            result = Parse::Webhooks.call_route(payload.trigger_name, payload.parse_class, payload)

            # call hooks subscribed to any class route
            generic_result = Parse::Webhooks.call_route(payload.trigger_name, "*", payload)
            result = generic_result if generic_result.present? && result.nil?
          else
            puts "[Webhooks] --> Could not find mapping route for #{payload.to_json}"
          end

          result = true if result.nil?
          if self.logging.present?
            puts "[Webhooks::Response] ----------------------------"
            puts success(result)
            puts "----------------------------------------------------\n"
          end
          response.write success(result)
          return response.finish
        rescue Parse::Webhooks::ResponseError, ActiveModel::ValidationError => e
          if payload.trigger?
            puts "[Webhooks::ResponseError] >> #{payload.trigger_name} #{payload.parse_class}:#{payload.parse_id}: #{e}"
          elsif payload.function?
            puts "[Webhooks::ResponseError] >> #{payload.function_name}: #{e}"
          end
          response.write error(e.to_s)
          return response.finish
        end

        #check if we can handle the type trigger/functionName
        response.write(success)
        response.finish
      end # call
    end #class << self
  end # Webhooks
end # Parse
