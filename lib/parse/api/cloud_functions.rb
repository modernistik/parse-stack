
module Parse

  module API
    module CloudFunctions

      def call_function(name, body = {})
        request :post, "/1/functions/#{name}", body: body
      end

      def trigger_job(name, body = {})
        request :post, "/1/jobs/#{name}", body: body
      end

    end
  end

end
