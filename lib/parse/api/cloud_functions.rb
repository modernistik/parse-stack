# encoding: UTF-8
# frozen_string_literal: true

module Parse
  module API
    # Defines the CloudCode interface for the Parse REST API
    module CloudFunctions

      # Call a cloud function.
      # @param name [String] the name of the cloud function.
      # @param body [Hash] the parameters to forward to the function.
      # @return [Parse::Response]
      def call_function(name, body = {}, headers: {}, **opts)
        request :post, "functions/#{name}", body: body, headers: headers, opts: opts
      end

      # Trigger a job.
      # @param name [String] the name of the job to trigger.
      # @param body [Hash] the parameters to forward to the job.
      # @return [Parse::Response]
      def trigger_job(name, body = {}, headers: {}, **opts)
        request :post, "jobs/#{name}", body: body, headers: headers, opts: opts
      end
    end
  end
end
