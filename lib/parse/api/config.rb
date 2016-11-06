# encoding: UTF-8
# frozen_string_literal: true

module Parse

  module API
    # Defines the Config interface for the Parse REST API
    module Config

      # @!attribute config
      #  @return [Hash] the cached config hash for the client.
      attr_accessor :config

      # @!visibility private
      CONFIG_PATH = "config"

      # @return [Hash] force fetch the application configuration hash.
      def config!
        @config = nil
        self.config
      end

      # Return the configuration hash for the configured application for this client.
      # This method caches the configuration after the first time it is fetched.
      # @return [Hash] force fetch the application configuration hash.
      def config
        if @config.nil?
          response = request :get, CONFIG_PATH
          unless response.error?
            @config = response.result["params"]
          end
        end
        @config
      end

      # Update the application configuration
      # @param params [Hash] the hash of key value pairs.
      # @return [Boolean] true if the configuration was successfully updated.
      def update_config(params)
        body = { params: params }
        response = request :put, CONFIG_PATH, body: body
        return false if response.error?
        result = response.result["result"]
        @config.merge!(params) if result && @config.present?
        result
      end

    end

  end

end
