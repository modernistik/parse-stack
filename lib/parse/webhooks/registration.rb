require 'active_support'
require 'active_support/inflector'
require 'active_support/core_ext/object'
require 'active_support/core_ext/string'

module Parse

  module Webhook

    module Registration

      ALLOWED_HOOKS = Parse::API::Hooks::TRIGGER_NAMES + [:function]


      def remove_all_functions!

          client.functions.results.each do |f|
            next unless f["url"].present?
            client.delete_function f['functionName']
            puts "[Webhook] Removed function - #{f['functionName']}"
          end
      end

      def remove_all_triggers!

        client.triggers.results.each do |f|
          next unless f["url"].present?
          triggerName = f["triggerName"]
          className = f["className"]
          client.delete_trigger triggerName, className
          puts "[Webhook] Removed #{f['triggerName']} - #{f['className']}"
        end

      end

      def register_functions!(endpoint)

        unless endpoint.starts_with?('https://')
          raise "The HOOKS_URL must be https: '#{endpoint}''"
        end
        endpoint += '/' unless endpoint.ends_with?('/')
        functionsMap = {}
        client.functions.results.each do |f|
          next unless f["url"].present?
          functionsMap[ f['functionName'] ] = f["url"]
        end

        routes.function.keys.each do |functionName|
          url = endpoint + functionName
          if functionsMap[functionName].present? #you may need to update
            next if functionsMap[functionName] == url
            client.update_function(functionName, url)
          else
            client.create_function(functionName, url)
          end
          puts "[Webhook] Registered function - #{functionName}"
        end

      end

      def register_triggers!(endpoint, include_wildcard: false)

        unless endpoint.starts_with?('https://')
          raise "The HOOKS_URL must be https: '#{endpoint}''"
        end
        endpoint += '/' unless endpoint.ends_with?('/')

        current_triggers = {
          after_save: {},
          after_delete: {},
          before_delete: {},
          before_save: {}
        }

        client.triggers.each do |t|
          next unless t["url"].present?
          trigger_name = t["triggerName".freeze].underscore.to_sym
          current_triggers[trigger_name] ||= {}
          current_triggers[trigger_name][ t["className"] ] = t["url"]
        end

        [:after_save,  :after_delete, :before_delete, :before_save].each do |trigger|
          classNames = routes[trigger].keys.dup
          if include_wildcard && classNames.include?('*') #then create the list for all classes
            classNames.delete '*' #delete the wildcard before we expand it
            classNames = classNames + Parse.registered_classes
            classNames.uniq!
          end

          classNames.each do |className|
            next if className == '*'.freeze
            url = endpoint + "#{trigger}/#{className}"
            if current_triggers[trigger][className].present? #then you may need to update
              next if current_triggers[trigger][className] == url
              client.update_trigger(trigger, className, url)
            else
              client.create_trigger(trigger, className, url)
            end
            puts "[Webhook] Registered #{trigger} - #{className}"
          end

        end
      end

      def register_webhook!(trigger, name, url)
        trigger = trigger.to_s.camelize(:lower).to_sym
        raise "Invalid hook trigger #{trigger}" unless ALLOWED_HOOKS.include?(trigger)
        if trigger == :function
          response = client.fetch_function(name)
          # if it is either an error (which has no results) or there is a result but
          # no registered item with a URL (which implies either none registered or only cloud code registered)
          # then create it.
          if response.results.none? { |d| d.has_key?("url".freeze) }
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
          if response.results.none? { |d| d.has_key?("url".freeze) }
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
