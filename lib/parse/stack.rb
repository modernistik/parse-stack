# encoding: UTF-8
# frozen_string_literal: true

require_relative "stack/version"
require_relative 'client'
require_relative 'query'
require_relative 'model/object'
require_relative 'webhooks'


module Parse
  class Error < StandardError; end;
  module Stack

  end

  class Hyperdrive
    # Applies a remote JSON hash containing the ENV keys and values from a remote
    # URL. Values from the JSON hash are only applied to the current ENV hash ONLY if
    # it does not already have a value. Therefore local ENV values will take precedence
    # over remote ones. By default, it uses the url in environment value in 'CONFIG_URL' or 'HYPERDRIVE_URL'.
    # @param url [String] the remote url that responds with the JSON body.
    # @return [Boolean] true if the JSON hash was found and applied successfully.
    def self.config!(url = nil)
      url ||= ENV["HYPERDRIVE_URL"] || ENV['CONFIG_URL']
      if url.present?
        begin
          remote_config = JSON.load open( url )
          remote_config.each do |key,value|
            k = key.upcase
            next unless ENV[k].nil?
            ENV[k] ||= value.to_s
          end
          return true
        rescue => e
          warn "[Parse::Stack] Error loading config: #{url} (#{e})"
        end
      end
      false
    end
  end
end

require_relative 'stack/railtie' if defined?(::Rails)
