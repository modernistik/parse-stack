# encoding: UTF-8
# frozen_string_literal: true

require "active_support"
require "active_support/json"

module Parse

  # Represents a response from Parse server. A response can also
  # be a set of responses (from a Batch response).
  class Response
    include Enumerable

    # Code for an unknown error.
    ERROR_INTERNAL = 1
    # Code when the server returns a 500 or is non-responsive.
    ERROR_SERVICE_UNAVAILABLE = 2
    # Code when the request times out.
    ERROR_TIMEOUT = 124
    # Code when the requests per second limit as been exceeded.
    ERROR_EXCEEDED_BURST_LIMIT = 155
    # Code when a requested record is not found.
    ERROR_OBJECT_NOT_FOUND = 101
    # Code when the username is missing in request.
    ERROR_USERNAME_MISSING = 200
    # Code when the password is missing in request.
    ERROR_PASSWORD_MISSING = 201
    # Code when the username is already in the system.
    ERROR_USERNAME_TAKEN = 202
    # Code when the email is already in the system.
    ERROR_EMAIL_TAKEN = 203
    # Code when the email is not found
    ERROR_EMAIL_NOT_FOUND = 205
    # Code when the email is invalid
    ERROR_EMAIL_INVALID = 125

    # The field name for the error.
    ERROR = "error".freeze
    # The field name for the success.
    SUCCESS = "success".freeze
    # The field name for the error code.
    CODE = "code".freeze
    # The field name for the results of the request.
    RESULTS = "results".freeze
    # The field name for the count result in a count response.
    COUNT = "count".freeze

    # @!attribute [rw] parse_class
    #  @return [String] the Parse class for this request
    # @!attribute [rw] code
    #  @return [Integer] the error code
    # @!attribute [rw] error
    #  @return [Integer] the error message
    # @!attribute [rw] result
    #  @return [Hash] the body of the response result.
    # @!attribute [rw] http_status
    #  @return [Integer] the HTTP status code from the response.
    # @!attribute [rw] request
    #  @return [Integer] the Parse::Request that generated this response.
    #  @see Parse::Request
    attr_accessor :parse_class, :code, :error, :result, :http_status,
                  :request
    # You can query Parse for counting objects, which may not actually have
    # results.
    # @return [Integer] the count result from a count query request.
    attr_reader :count

    # Create an instance with a Parse response JSON hash.
    # @param res [Hash] the JSON hash
    def initialize(res = {})
      @http_status = 0
      @count = 0
      @batch_response = false # by default, not a batch response
      @result = nil
      # If a string is used for initializing, treat it as JSON
      # check for string to not be 'OK' since that is the health check API response
      res = JSON.parse(res) if res.is_a?(String) && res != "OK".freeze
      # If it is a hash (or parsed JSON), then parse the result.
      parse_result!(res) if res.is_a?(Hash)
      # if the result is an Array, then most likely it is a set of responses
      # from using a Batch API.
      if res.is_a?(Array)
        @batch_response = true
        @result = res || []
        @count = @result.count
      end
      #if none match, set pure result
      @result = res if @result.nil?
    end

    # true if this was a batch response.
    def batch?
      @batch_response
    end

    # If it is a batch respnose, we'll create an array of Response objects for each
    # of the ones in the batch.
    # @return [Array] an array of Response objects.
    def batch_responses
      return [@result] unless @batch_response
      # if batch response, generate array based on the response hash.
      @result.map do |r|
        next r unless r.is_a?(Hash)
        hash = r[SUCCESS] || r[ERROR]
        Parse::Response.new hash
      end
    end

    # This method takes the result hash and determines if it is a regular
    # parse query result, object result or a count result. The response should
    # be a hash either containing the result data or the error.
    def parse_result!(h)
      @result = {}
      return unless h.is_a?(Hash)
      @code = h[CODE]
      @error = h[ERROR]
      if h[RESULTS].is_a?(Array)
        @result = h[RESULTS]
        @count = h[COUNT] || @result.count
      else
        @result = h
        @count = 1
      end
    end

    alias_method :parse_results!, :parse_result!

    # true if the response is successful.
    # @see #error?
    def success?
      @code.nil? && @error.nil?
    end

    # true if the response has an error code.
    # @see #success?
    def error?
      !success?
    end

    # true if the response has an error code of 'object not found'
    # @see ERROR_OBJECT_NOT_FOUND
    def object_not_found?
      @code == ERROR_OBJECT_NOT_FOUND
    end

    # @return [Array] the result data from the response.
    def results
      return [] if @result.nil?
      @result.is_a?(Array) ? @result : [@result]
    end

    # @return [Object] the first thing in the result array.
    def first
      @result.is_a?(Array) ? @result.first : @result
    end

    # Iterate through each result item.
    # @yieldparam [Object] a result entry.
    def each(&block)
      return enum_for(:each) unless block_given?
      results.each(&block)
      self
    end

    # @!visibility private
    def inspect
      if error?
        "#<#{self.class} @code=#{code} @error='#{error}'>"
      else
        "#<#{self.class} @result='#{@result}'>"
      end
    end

    # @return [String] JSON encoded object, or an error string.
    def to_s
      return "[E-#{@code}] #{@request} : #{@error} (#{@http_status})" if error?
      @result.to_json
    end
  end
end
