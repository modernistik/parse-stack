# encoding: UTF-8
# frozen_string_literal: true
exit # don't use master branch
require_relative "stack/version"
require_relative 'client'
require_relative 'query'
require_relative 'model/object'
require_relative 'webhooks'


module Parse
  class Error < StandardError; end;
  module Stack

    # Your code goes here...
  end
end

require_relative 'stack/railtie' if defined?(::Rails)
