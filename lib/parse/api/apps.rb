# encoding: UTF-8
# frozen_string_literal: true

module Parse

  module API

    module Apps

      APPS_PATH = "apps"
      def fetch_app_keys(appid, email, password, headers: {})
        headers.merge!( { Parse::Protocol::EMAIL => email, Parse::Protocol::PASSWORD => password } )
        request :get, "#{APPS_PATH}/#{appid}", headers: headers
      end

      def fetch_apps(email, password, headers: {})
        headers.merge!( { Parse::Protocol::EMAIL => email, Parse::Protocol::PASSWORD => password } )
        request :get, APPS_PATH, headers: headers
      end

      def create_app(body, email, password, headers: {})
        headers.merge!( { Parse::Protocol::EMAIL => email, Parse::Protocol::PASSWORD => password } )
        request :post, APPS_PATH, body: body, headers: headers
      end

      def update_app(appid, body, email, password, headers: {})
        headers.merge!( { Parse::Protocol::EMAIL => email, Parse::Protocol::PASSWORD => password } )
        request :put, "#{APPS_PATH}/#{appid}", body: body, headers: headers
      end


    end
  end

end
