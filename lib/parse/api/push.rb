
module Parse

  module API
    #object fetch methods
    module Push

      def push(payload = {})
        request :post, "/1/push".freeze, body: payload.as_json
      end

    end

  end

end
