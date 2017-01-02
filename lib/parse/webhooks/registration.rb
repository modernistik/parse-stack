# encoding: UTF-8
# frozen_string_literal: true

require 'active_support'
require 'active_support/inflector'
require 'active_support/core_ext/object'
require 'active_support/core_ext/string'
require 'active_support/core_ext'

module Parse
  # Interface to the CloudCode webhooks API.
  class Webhooks
    # Module to support registering Parse CloudCode webhooks.
    module Registration
      # The set of allowed trigger types.
      ALLOWED_HOOKS = Parse::API::Hooks::TRIGGER_NAMES + [:function]

      # removes all registered webhook functions with Parse Server.
      def remove_all_functions!

          client.functions.results.sort_by { |f| f['functionName'] }.each do |f|
            next unless f["url"].present?
            client.delete_function f['functionName']
            yield(f['functionName']) if block_given?
          end
      end

      # removes all registered webhook triggers with Parse Server.
      def remove_all_triggers!

        client.triggers.results.sort_by { |f| [f['triggerName'],f['className']] }.each do |f|
          next unless f["url"].present?
          triggerName = f["triggerName"]
          className = f[Parse::Model::KEY_CLASS_NAME]
          client.delete_trigger triggerName, className
          yield(f['triggerName'], f[Parse::Model::KEY_CLASS_NAME]) if block_given?
        end

      end

      # Registers all webhook functions registered with Parse::Stack with Parse server.
      # @param endpoint [String] a https url that points to the webhook server.
      def register_functions!(endpoint)

        unless endpoint.present? && (endpoint.starts_with?('http://') || endpoint.starts_with?('https://') )
          raise ArgumentError, "The HOOKS_URL must be http/s: '#{endpoint}''"
        end
        endpoint += '/' unless endpoint.ends_with?('/')
        functionsMap = {}
        client.functions.results.each do |f|
          next unless f["url"].present?
          functionsMap[ f['functionName'] ] = f["url"]
        end

        routes.function.keys.sort.each do |functionName|
          url = endpoint + functionName
          if functionsMap[functionName].present? #you may need to update
            next if functionsMap[functionName] == url
            client.update_function(functionName, url)
          else
            client.create_function(functionName, url)
          end
          yield(functionName) if block_given?
        end

      end

      # Registers all webhook triggers registered with Parse::Stack with Parse server.
      # @param endpoint [String] a https url that points to the webhook server.
      # @param include_wildcard [Boolean] Allow wildcard registrations
      def register_triggers!(endpoint, include_wildcard: false)

        unless endpoint.present? && (endpoint.starts_with?('http://') || endpoint.starts_with?('https://') )
          raise ArgumentError, "The HOOKS_URL must be http/s: '#{endpoint}''"
        end
        endpoint += '/' unless endpoint.ends_with?('/')
        all_triggers = Parse::API::Hooks::TRIGGER_NAMES_LOCAL

        current_triggers = {}
        all_triggers.each { |t| current_triggers[t] = {} }

        client.triggers.each do |t|
          next unless t["url"].present?
          trigger_name = t["triggerName"].underscore.to_sym
          current_triggers[trigger_name] ||= {}
          current_triggers[trigger_name][ t["className"] ] = t["url"]
        end

        all_triggers.each do |trigger|
          classNames = routes[trigger].keys.dup
          if include_wildcard && classNames.include?('*') #then create the list for all classes
            classNames.delete '*' #delete the wildcard before we expand it
            classNames = classNames + Parse.registered_classes
            classNames.uniq!
          end

          classNames.sort.each do |className|
            next if className == '*'
            url = endpoint + "#{trigger}/#{className}"
            if current_triggers[trigger][className].present? #then you may need to update
              next if current_triggers[trigger][className] == url
              client.update_trigger(trigger, className, url)
            else
              client.create_trigger(trigger, className, url)
            end
            yield(trigger.columnize,className) if block_given?
          end

        end
      end

      # Registers a webhook trigger with a given endpoint url.
      # @param trigger [Symbol] Trigger type based on Parse::API::Hooks::TRIGGER_NAMES or :function.
      # @param name [String] the name of the webhook.
      # @param url [String] the https url endpoint that will handle the request.
      # @see Parse::API::Hooks::TRIGGER_NAMES
      def register_webhook!(trigger, name, url)
        trigger = trigger.to_s.camelize(:lower).to_sym
        raise ArgumentError, "Invalid hook trigger #{trigger}" unless ALLOWED_HOOKS.include?(trigger)
        if trigger == :function
          response = client.fetch_function(name)
          # if it is either an error (which has no results) or there is a result but
          # no registered item with a URL (which implies either none registered or only cloud code registered)
          # then create it.
          if response.results.none? { |d| d.has_key?("url") }
            response = client.create_function(name, url)
          else
            # update it
            response = client.update_function(name, url)
          end
          warn "Webhook Registration warning: #{response.result["warning"]}" if response.result.has_key?("warning")
          warn "Failed to register Cloud function #{name} with #{url}" if response.error?
          return response
        else # must be trigger

          response = client.fetch_trigger(trigger, name)
          # if it is either an error (which has no results) or there is a result but
          # no registered item with a URL (which implies either none registered or only cloud code registered)
          # then create it.
          if response.results.none? { |d| d.has_key?("url") }
            # create it
            response = client.create_trigger(trigger, name, url)
          else
            # update it
            response = client.update_trigger(trigger, name, url)
          end

          warn "Webhook Registration warning: #{response.result["warning"]}" if response.result.has_key?("warning")
          warn "Webhook Registration error: #{response.error}" if response.error?
          return response
          end
      end
    end
  end
end
