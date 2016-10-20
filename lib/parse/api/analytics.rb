# encoding: UTF-8
# frozen_string_literal: true

module Parse

  module API
    module Analytics
      # Sends analytics data
      def send_analytics(event_name, data = {})
        request :post, "events/#{event_name}", body: data
      end

    end
  end

end
