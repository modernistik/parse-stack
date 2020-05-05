# encoding: UTF-8
# frozen_string_literal: true

require "parallel"
require "active_support"
require "active_support/core_ext"

module Parse
  module API
    # Defines the Batch interface for the Parse REST API
    # @see Parse::BatchOperation
    # @see Array.destroy
    # @see Array.save
    module Batch
      # @note You cannot use batch_requests with {Parse::User} instances that need to
      #  be created.
      # @overload batch_request(requests)
      #  Perform a set of {Parse::Request} instances as a batch operation.
      #  @param requests [Array<Parse::Request>] the set of requests to batch.
      # @overload batch_request(operation)
      #  Submit a batch operation.
      #  @param operation [Parse::BatchOperation] the batch operation.
      # @return [Array<Parse::Response>] if successful, a set of responses for each operation in the batch.
      # @return [Parse::Response] if an error occurred, the error response.
      def batch_request(batch_operations)
        unless batch_operations.is_a?(Parse::BatchOperation)
          batch_operations = Parse::BatchOperation.new batch_operations
        end
        response = request(:post, "batch", body: batch_operations.as_json)
        response.success? && response.batch? ? response.batch_responses : response
      end
    end
  end
end
