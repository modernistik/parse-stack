# encoding: UTF-8
# frozen_string_literal: true

require 'active_support'
require 'active_support/json'

module Parse
  #This class represents a Parse request.
  class Request
    # @!attribute [rw] method
    #   @return [String] the HTTP method used for this request.

    # @!attribute [rw] path
    #   @return [String] the uri path.

    # @!attribute [rw] body
    #   @return [Hash] the body of this request.

    # TODO: Document opts and cache options.

    # @!attribute [rw] opts
    #   @return [Hash] a set of options for this request.
    # @!attribute [rw] cache
    #   @return [Boolean]
    attr_accessor :method, :path, :body, :headers, :opts, :cache
    # @!visibility private
    attr_accessor :tag

    # Creates a new request
    # @param method [String] the HTTP method
    # @param uri [String] the API path of the request (without the host)
    # @param body [Hash] the body (or parameters) of this request.
    # @param headers [Hash] additional headers to send in this request.
    # @param opts [Hash] additional optional parameters.
    def initialize(method, uri, body: nil, headers: nil, opts: {})
      @tag = 0
      method = method.downcase.to_sym
      unless method == :get || method == :put || method == :post || method == :delete
        raise ArgumentError, "Invalid method #{method} for request : '#{uri}'"
      end
      self.method = method
      self.path = uri
      self.body = body
      self.headers = headers || {}
      self.opts = opts || {}
    end

    # The parameters of this request if the HTTP method is GET.
    # @return [Hash]
    def query
      body if @method == :get
    end

    # @return [Hash] JSON encoded hash
    def as_json
      signature.as_json
    end

    # @return [Boolean]
    def ==(r)
      return false unless r.is_a?(Request)
      @method == r.method && @path == r.uri && @body == r.body && @headers == r.headers
    end

    # Signature provies a way for us to compare different requests objects.
    # Two requests objects are the same if they have the same signature.
    # @return [Hash] A hash representing this request.
    def signature
      {method: @method.upcase, path: @path, body: @body}
    end

    # @!visibility private
    def inspect
        "#<#{self.class} @method=#{@method} @path='#{@path}'>"
    end
    
    # @return [String]
    def to_s
      "#{@method.to_s.upcase} #{@path}"
    end

  end

end
