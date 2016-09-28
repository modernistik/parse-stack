# encoding: UTF-8
# frozen_string_literal: true

module Parse

  module API
    #object fetch methods
    module Config
      attr_accessor :config
      CONFIG_PATH = "config"
      def config!
        @config = nil
        self.config
      end

      def config
        if @config.nil?
          response = request :get, CONFIG_PATH
          unless response.error?
            @config = response.result["params"]
          end
        end
        @config
      end

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
