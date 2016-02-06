
module Parse

  module API
    #object fetch methods
    module Config
      attr_accessor :config

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
