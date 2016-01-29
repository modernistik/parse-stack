


module Parse


  module API
    module Hooks
      HOOKS_PREFIX = "/1/hooks/".freeze
      TRIGGER_NAMES = [:beforeSave, :afterSave, :beforeDelete, :afterDelete].freeze
      def _verify_trigger(triggerName)
        triggerName = triggerName.to_s.camelize(:lower).to_sym
        raise "Invalid trigger name #{triggerName}" unless TRIGGER_NAMES.include?(triggerName)
        triggerName
      end

      def functions
        request :get, "#{HOOKS_PREFIX}functions"
      end

      def fetch_function(functionName)
        request :get, "#{HOOKS_PREFIX}functions/#{functionName}"
      end

      def create_function(functionName, url)
        request :post, "#{HOOKS_PREFIX}functions", body: {functionName: functionName, url: url}
      end

      def update_function(functionName, url)
        # interesting trick. If you add _method => "PUT" to the JSON body,
        # and send it as a POST request and parse will accept it as a PUT.
        # They must do this because it is easier to send POST with Ajax.
        request :put, "#{HOOKS_PREFIX}functions/#{functionName}", body: { url: url }
      end

      def delete_function(functionName)
        request :put, "#{HOOKS_PREFIX}functions/#{functionName}", body: { __op: "Delete" }
      end

      def triggers
        request :get, "#{HOOKS_PREFIX}triggers"
      end

      def fetch_trigger(triggerName, className)
        triggerName = _verify_trigger(triggerName)
        request :get, "#{HOOKS_PREFIX}triggers/#{className}/#{triggerName}"
      end

      def create_trigger(triggerName, className, url)
        triggerName = _verify_trigger(triggerName)
        body = {className: className, triggerName: triggerName, url: url }
        request :post, "#{HOOKS_PREFIX}triggers", body: body
      end

      def update_trigger(triggerName, className, url)
        triggerName = _verify_trigger(triggerName)
        request :put, "#{HOOKS_PREFIX}triggers/#{className}/#{triggerName}", body: { url: url }
      end

      def delete_trigger(triggerName, className)
        triggerName = _verify_trigger(triggerName)
        request :put, "#{HOOKS_PREFIX}triggers/#{className}/#{triggerName}", body: { __op: "Delete" }
      end

    end
  end

end
