# encoding: UTF-8
# frozen_string_literal: true

module Parse

  module API
    #object fetch methods
    module Config
      attr_accessor :config

      def config!
        @config = nil
        self.config
      end

      def config
        if @config.nil?
          response = request :get, "config"
          unless response.error?
            @config = response.result["params"]
          end
        end
        @config
      end
    end

  end

end
