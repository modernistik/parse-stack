# encoding: UTF-8
# frozen_string_literal: true

require 'active_support'
require 'active_support/json'
# This is the model that represents a response from Parse. A Response can also
# be a set of responses (from a Batch response).
module Parse


  class Response
    include Enumerable

    ERROR_INTERNAL = 1
    ERROR_SERVICE_UNAVAILALBE = 2
    ERROR_TIMEOUT = 124
    ERROR_EXCEEDED_BURST_LIMIT = 155
    ERROR_OBJECT_NOT_FOUND = 101

    ERROR = "error"
    CODE = "code"
    RESULTS = "results"
    COUNT = "count"
    # A response has a result or (a code and an error)
    attr_accessor :parse_class, :code, :error, :result, :http_status
    attr_accessor :request # capture request that created result
    # You can query Parse for counting objects, which may not actually have
    # results.
    attr_reader :count

    def initialize(res = {})
      @http_status = 0
      @count = 0
      @batch_response = false # by default, not a batch response
      @result = nil
      # If a string is used for initializing, treat it as JSON
      res = JSON.parse(res) if res.is_a?(String)
      # If it is a hash (or parsed JSON), then parse the result.
      parse_result(res) if res.is_a?(Hash)
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

    def batch?
      @batch_response
    end
    #batch response
    #
    # [
    #   {
    #     "success":{"createdAt":"2015-11-22T19:04:16.104Z","objectId":"s4tEzOVQFc"}
    #   },
    #  {
    #  "error":{"code":101,"error":"object not found for update"}
    #  }
    # ]
    # If it is a batch respnose, we'll create an array of Response objects for each
    # of the ones in the batch.
    def batch_responses

      return [@result] unless @batch_response
      # if batch response, generate array based on the response hash.
      @result.map do |r|
        next r unless r.is_a?(Hash)
        hash = r["success"] || r["error"]
        Parse::Response.new hash
      end
    end

    # This method takes the result hash and determines if it is a regular
    # parse query result, object result or a count result. The response should
    # be a hash either containing the result data or the error.

    def parse_result(h)
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

    # determines if the response is successful.
    def success?
      @code.nil? && @error.nil?
    end

    def error?
      ! success?
    end

    def object_not_found?
      @code == ERROR_OBJECT_NOT_FOUND
    end

    # returns the result data from the response. Always returns an array.
    def results
      return [] if @result.nil?
      @result.is_a?(Array) ? @result : [@result]
    end

    # returns the first thing in the array.
    def first
      @result.is_a?(Array) ? @result.first : @result
    end

    def each
      return enum_for(:each) unless block_given?
      results.each(&Proc.new)
      self
    end

    def inspect
      if error?
        "#<#{self.class} @code=#{code} @error='#{error}'>"
      else
        "#<#{self.class} @result='#{@result}'>"
      end
    end

    def to_s
      return "[E-#{@code}] #{@request} : #{@error} (#{@http_status})" if error?
      @result.to_json
    end

  end
end
