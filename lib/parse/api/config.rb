
module Parse

  module API
    #object fetch methods
    module Config
      attr_accessor :config

      def config
        if @config.nil?
          response = request :get, "/1/config".freeze
          unless response.error?
            @config = response.result["params"]
          end
        end
        @config
      end
    end

  end

end
