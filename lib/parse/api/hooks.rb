# encoding: UTF-8
# frozen_string_literal: true

module Parse


  module API
    # Defines the Parse webhooks interface for the Parse REST API
    module Hooks
      # @!visibility private
      HOOKS_PREFIX = "hooks/"
      # The allowed set of Parse triggers.
      TRIGGER_NAMES = [:beforeSave, :afterSave, :beforeDelete, :afterDelete].freeze

      # @!visibility private
      def _verify_trigger(triggerName)
        triggerName = triggerName.to_s.camelize(:lower).to_sym
        raise ArgumentError, "Invalid trigger name #{triggerName}" unless TRIGGER_NAMES.include?(triggerName)
        triggerName
      end

      # Fetch all defined cloud code functions.
      # @return [Parse::Response]
      def functions
        request :get, "#{HOOKS_PREFIX}functions"
      end

      # Fetch information about a specific registered cloud function.
      # @param functionName [String] the name of the cloud code function.
      # @return [Parse::Response]
      def fetch_function(functionName)
        request :get, "#{HOOKS_PREFIX}functions/#{functionName}"
      end

      # Register a cloud code webhook function pointing to a endpoint url.
      # @param functionName [String] the name of the cloud code function.
      # @param url [String] the url endpoint for this cloud code function.
      # @return [Parse::Response]
      def create_function(functionName, url)
        request :post, "#{HOOKS_PREFIX}functions", body: {functionName: functionName, url: url}
      end

      # Updated the endpoint url for a registered cloud code webhook function.
      # @param functionName [String] the name of the cloud code function.
      # @param url [String] the new url endpoint for this cloud code function.
      # @return [Parse::Response]
      def update_function(functionName, url)
        # If you add _method => "PUT" to the JSON body,
        # and send it as a POST request and parse will accept it as a PUT.
        request :put, "#{HOOKS_PREFIX}functions/#{functionName}", body: { url: url }
      end

      # Remove a registered cloud code webhook function.
      # @param functionName [String] the name of the cloud code function.
      # @return [Parse::Response]
      def delete_function(functionName)
        request :put, "#{HOOKS_PREFIX}functions/#{functionName}", body: { __op: "Delete" }
      end

      # Get the set of registered triggers.
      # @return [Parse::Response]
      def triggers
        request :get, "#{HOOKS_PREFIX}triggers"
      end

      # Fetch information about a registered webhook trigger.
      # @param triggerName [String] the name of the trigger. (ex. beforeSave, afterSave)
      # @param className [String] the name of the Parse collection for the trigger.
      # @return [Parse::Response]
      # @see TRIGGER_NAMES
      def fetch_trigger(triggerName, className)
        triggerName = _verify_trigger(triggerName)
        request :get, "#{HOOKS_PREFIX}triggers/#{className}/#{triggerName}"
      end

      # Register a new cloud code webhook trigger with an endpoint url.
      # @param triggerName [String] the name of the trigger. (ex. beforeSave, afterSave)
      # @param className [String] the name of the Parse collection for the trigger.
      # @param url [String] the url endpoint for this webhook trigger.
      # @return [Parse::Response]
      # @see Parse::API::Hooks::TRIGGER_NAMES
      def create_trigger(triggerName, className, url)
        triggerName = _verify_trigger(triggerName)
        body = {className: className, triggerName: triggerName, url: url }
        request :post, "#{HOOKS_PREFIX}triggers", body: body
      end

      # Updated the registered endpoint for this cloud code webhook trigger.
      # @param triggerName [String] the name of the trigger. (ex. beforeSave, afterSave)
      # @param className [String] the name of the Parse collection for the trigger.
      # @param url [String] the new url endpoint for this webhook trigger.
      # @return [Parse::Response]
      # @see Parse::API::Hooks::TRIGGER_NAMES
      def update_trigger(triggerName, className, url)
        triggerName = _verify_trigger(triggerName)
        request :put, "#{HOOKS_PREFIX}triggers/#{className}/#{triggerName}", body: { url: url }
      end

      # Remove a registered cloud code webhook trigger.
      # @param triggerName [String] the name of the trigger. (ex. beforeSave, afterSave)
      # @param className [String] the name of the Parse collection for the trigger.
      # @return [Parse::Response]
      # @see Parse::API::Hooks::TRIGGER_NAMES
      def delete_trigger(triggerName, className)
        triggerName = _verify_trigger(triggerName)
        request :put, "#{HOOKS_PREFIX}triggers/#{className}/#{triggerName}", body: { __op: "Delete" }
      end

    end
  end

end
