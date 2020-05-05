# encoding: UTF-8
# frozen_string_literal: true

module Parse
  module API
    # Defines the Parse Push notification service interface for the Parse REST API
    module Push
      # @!visibility private
      PUSH_PATH = "push"

      # Update the schema for a collection.
      # @param payload [Hash] the paylod for the Push notification.
      # @return [Parse::Response]
      # @see http://docs.parseplatform.org/rest/guide/#sending-pushes Sending Pushes
      def push(payload = {})
        request :post, PUSH_PATH, body: payload.as_json
      end
    end
  end
end
