require 'active_support'
require 'active_support/core_ext/object'
require_relative "model"
require 'base64'

# Support for Bytes type in Parse
module Parse

  class Bytes < Model
    attr_accessor :base64
    def parse_class; TYPE_BYTES; end;
    def parse_class; self.class.parse_class; end;
    alias_method :__type, :parse_class

    # initialize with a base64 string or a Bytes object
    def initialize(bytes = "")
      @base64 = (bytes.is_a?(Bytes) ? bytes.base64 : bytes).dup
    end

    def attributes
      {__type: :string, base64: :string }.freeze
    end

    # takes a string and base64 encodes it
    def encode(s)
      @base64 = Base64.encode64(s)
    end

    # decode the internal data
    def decoded
      Base64.decode64(@base64 || "")
    end

    def attributes=(a)
      if a.is_a?(String)
      @bytes = a
      elsif a.is_a?(Hash)
        @bytes = a["base64".freeze] || @bytes
      end
    end

    # two Bytes objects are equal if they have the same base64 signature
    def ==(u)
      return false unless u.is_a?(self.class)
      @base64 == u.base64
    end

  end

end
