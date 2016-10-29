# encoding: UTF-8
# frozen_string_literal: true

module Parse

  module API
    # Defines the Analytics interface for the Parse REST API
    module Analytics

      # Send analytics data.
      # @param event_name [String] the name of the event.
      # @param metrics [Hash] the metrics to attach to event.
      # @see https://parseplatform.github.io/docs/rest/guide/#analytics-app-open-analytics Parse Analytics
      def send_analytics(event_name, metrics = {})
        request :post, "events/#{event_name}", body: metrics
      end

    end
  end

end
