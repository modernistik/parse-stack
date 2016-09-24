# encoding: UTF-8
# frozen_string_literal: true

module Parse

  module API
    #object fetch methods
    module Push
      PUSH_PATH = "push"
      def push(payload = {})
        request :post, PUSH_PATH, body: payload.as_json
      end

    end

  end

end
