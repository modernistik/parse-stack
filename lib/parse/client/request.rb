# encoding: UTF-8
# frozen_string_literal: true

require 'active_support'
require 'active_support/json'

module Parse
 #This class is mainly to create a potential request - mainly for the batching API.

  class Request
      attr_accessor :method, :path, :body, :headers, :opts, :cache
      attr_accessor :tag #for tracking in bulk requests
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


      def query
        body if @method == :get
      end

      def as_json
        signature.as_json
      end

      def ==(r)
        return false unless r.is_a?(Request)
        @method == r.method && @path == r.uri && @body == r.body && @headers == r.headers
      end

      # signature provies a way for us to compare different requests objects.
      # Two requests objects are the same if they have the same signature.
      # This also helps us serialize a request data into a hash.
      def signature
        {method: @method.upcase, path: @path, body: @body}
      end

      def inspect
          "#<#{self.class} @method=#{@method} @path='#{@path}'>"
      end

      def to_s
        "#{@method.to_s.upcase} #{@path}"
      end

  end

end
