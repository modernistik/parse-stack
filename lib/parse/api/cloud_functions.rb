
module Parse

  module API
    module CloudFunctions

      def call_function(name, body = {})
        request :post, "functions/#{name}", body: body
      end

      def trigger_job(name, body = {})
        request :post, "jobs/#{name}", body: body
      end

    end
  end

end
