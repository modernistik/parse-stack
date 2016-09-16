# encoding: UTF-8
# frozen_string_literal: true

module Parse

  module API
    #object fetch methods
    module Push

      def push(payload = {})
        request :post, "push", body: payload.as_json
      end

    end

  end

end
