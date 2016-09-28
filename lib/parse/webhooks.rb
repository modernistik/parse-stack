# encoding: UTF-8
# frozen_string_literal: true

require 'active_model'
require 'active_support'
require 'active_support/inflector'
require 'active_support/core_ext/object'
require 'active_support/core_ext'
require 'active_model_serializers'
require 'rack'
require_relative 'client'
require_relative 'stack'
require_relative 'model/object'
require_relative 'webhooks/payload'
require_relative 'webhooks/registration'


=begin
  Some methods take a block, and this pattern frequently appears for a block:

  {|x| x.foo}
  and people would like to write that in a more concise way. In order to do that,
   a symbol, the method Symbol#to_proc, implicit class casting, and & operator
   are used in combination. If you put & in front of a Proc instance in the
   argument position, that will be interpreted as a block. If you combine
   something other than a Proc instance with &, then implicit class casting
   will try to convert that to a Proc instance using to_proc method defined on
   that object if there is any. In case of a Symbol instance, to_proc works in
   this way:

    :foo.to_proc # => ->x{x.foo}

   For example, suppose you write like this:

    bar(&:foo)
   The & operator is combined with :foo, which is not a Proc instance, so implicit class cast applies Symbol#to_proc to it, which gives ->x{x.foo}. The & now applies to this and is interpreted as a block, which gives:

   bar{|x| x.foo}
=end

module Parse

  class Object

    def validate!
      super
      self
    rescue ActiveModel::ValidationError => e
      raise WebhookErrorResponse, errors.full_messages.first
    end

    def self.webhook_function(functionName, block = nil)
      if block_given?
        Parse::Webhooks.route(:function, functionName, &Proc.new)
      else
        block = functionName.to_s.underscore.to_sym if block.blank?
        block = method(block.to_sym) if block.is_a?(Symbol)
        Parse::Webhooks.route(:function, functionName, block)
      end
    end

    def self.webhook(type, block = nil)

      if type == :function
        unless block.is_a?(String) || block.is_a?(Symbol)
          raise ArgumentError, "Invalid Cloud Code function name: #{block}"
        end
        Parse::Webhooks.route(:function, block, &Proc.new)
        # then block must be a symbol or a string
      else
        if block_given?
          Parse::Webhooks.route(type, self, &Proc.new)
        else
          Parse::Webhooks.route(type, self, block)
        end
      end
      #if block

    end

  end

  class Payload
    def error!(msg = "")
      raise WebhookErrorResponse, msg
    end
  end

  class WebhookErrorResponse < StandardError; end;
  class Webhooks

    def self.reload!(args = {})

    end

    include Client::Connectable
    extend Webhook::Registration

    HTTP_PARSE_WEBHOOK = "HTTP_X_PARSE_WEBHOOK_KEY"
    HTTP_PARSE_APPLICATION_ID = "HTTP_X_PARSE_APPLICATION_ID"
    CONTENT_TYPE = "application/json"
    attr_accessor :key
    class << self
      attr_accessor :logging

      def routes
        @routes ||= OpenStruct.new( {
          before_save: {}, after_save: {},
          before_delete: {}, after_delete: {}, function: {}
          })
      end

      def route(type, className, block = nil)
        type = type.to_s.underscore.to_sym #support camelcase
        if type != :function && className.respond_to?(:parse_class)
          className = className.parse_class
        end
        className = className.to_s
        block = Proc.new if block_given?
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
        #puts "Webhook: #{type} -> #{className}..."
      end

      def run_function(name, params)
        payload = Payload.new
        payload.function_name = name
        payload.params = params
        call_route(:function, name, payload)
      end

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
        end

        result
      end

      def success(data = true)
        { success: data }.to_json
      end

      def error(data = false)
        { error: data }.to_json
      end

      def key
        @key ||= ENV['PARSE_WEBHOOK_KEY']
      end

      def call(env)

        request = Rack::Request.new env
        response = Rack::Response.new

        if @key.present? && @key =! request.env[HTTP_PARSE_WEBHOOK]
          response.write error("Invalid Parse-Webhook Key")
          return response.finish
        end

        unless request.content_type.present? && request.content_type.include?(CONTENT_TYPE)
          response.write error("Invalid content-type format. Should be application/json.")
          return response.finish
        end

        request.body.rewind
        begin
          payload = Parse::Payload.new request.body.read
        rescue => e
          warn "Invalid webhook payload format: #{e}"
          response.write error("Invalid payload format. Should be valid JSON.")
          return response.finish
        end

        if self.logging.present?
          if payload.trigger?
            puts "[ParseWebhooks Request] --> #{payload.trigger_name} #{payload.parse_class}:#{payload.parse_id}"
          elsif payload.function?
            puts "[ParseWebhooks Request] --> Function #{payload.function_name}"
          end
          if self.logging == :debug
            puts "[ParseWebhooks Payload] ----------------------------"
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
            puts "[ParseWebhooks] --> Could not find mapping route for #{payload.to_json}"
          end

          result = true if result.nil?
          if self.logging.present?
            puts "[ParseWebhooks Response] ----------------------------"
            puts success(result)
            puts "----------------------------------------------------\n"
          end
          response.write success(result)
          return response.finish
        rescue Parse::WebhookErrorResponse, ActiveModel::ValidationError => e
          if payload.trigger?
            puts "[Webhook ResponseError] >> #{payload.trigger_name} #{payload.parse_class}:#{payload.parse_id}: #{e}"
          elsif payload.function?
            puts "[Webhook ResponseError] >> #{payload.function_name}: #{e}"
          end
          response.write error( e.to_s )
          return response.finish
        end

        #check if we can handle the type trigger/functionName
        response.write( success )
        response.finish
      end # call

    end #class << self
  end # Webhooks

end # Parse
