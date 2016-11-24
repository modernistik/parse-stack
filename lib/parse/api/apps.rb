# encoding: UTF-8
# frozen_string_literal: true

module Parse

  module API
    # @deprecated These specific APIs will no longer be available after Jan 28th, 2017.
    # Defines the Apps interface for the Parse REST API
    module Apps

      # @!visibility private
      APPS_PATH = "apps"

      # @deprecated This method will no longer be available after Jan 28th, 2017.
      # Fetch the application keys.
      # @param appid [String] the application id.
      # @param email [String] your hosted Parse account email.
      # @param password [String] your hosted Parse account password.
      # @param headers [Hash] additional HTTP headers to send with the request.
      # @note Only supported by the hosted Parse platform and not the open source Parse-Server.
      # @return [Parse::Response]
      # @deprecated
      def fetch_app_keys(appid, email, password, headers: {})
        warn "[Parse::Client#fetch_app_keys] This method will no longer be available after Jan 28th, 2017."
        headers.merge!( { Parse::Protocol::EMAIL => email, Parse::Protocol::PASSWORD => password } )
        request :get, "#{APPS_PATH}/#{appid}", headers: headers
      end

      # @deprecated This method will no longer be available after Jan 28th, 2017.
      # Fetch the applications.
      # @param email [String] your hosted Parse account email.
      # @param password [String] your hosted Parse account password.
      # @param headers [Hash] additional HTTP headers to send with the request.
      # @note Only supported by the hosted Parse platform and not the open source Parse-Server.
      # @return [Parse::Response]
      def fetch_apps(email, password, headers: {})
        warn "[Parse::Client#fetch_apps] This method will no longer be available after Jan 28th, 2017."
        headers.merge!( { Parse::Protocol::EMAIL => email, Parse::Protocol::PASSWORD => password } )
        request :get, APPS_PATH, headers: headers
      end

      # @deprecated This method will no longer be available after Jan 28th, 2017.
      # Create a new application in the hosted Parse Platform.
      # @param body [Hash] parameters for creating the app.
      # @param email [String] your hosted Parse account email.
      # @param password [String] your hosted Parse account password.
      # @param headers [Hash] additional HTTP headers to send with the request.
      # @note Only supported by the hosted Parse platform and not the open source Parse-Server.
      # @return [Parse::Response]
      def create_app(body, email, password, headers: {})
        warn "[Parse::Client#create_app] This method will no longer be available after Jan 28th, 2017."
        headers.merge!( { Parse::Protocol::EMAIL => email, Parse::Protocol::PASSWORD => password } )
        request :post, APPS_PATH, body: body, headers: headers
      end

      # @deprecated This method will no longer be available after Jan 28th, 2017.
      # Updates information about a particular app.
      # @param appid [String] the application id.
      # @param body [Hash] parameters to update the app.
      # @param email [String] your hosted Parse account email.
      # @param password [String] your hosted Parse account password.
      # @param headers [Hash] additional HTTP headers to send with the request.
      # @note Only supported by the hosted Parse platform and not the open source Parse-Server.
      # @return [Parse::Response]
      def update_app(appid, body, email, password, headers: {})
        warn "[Parse::Client#update_app] This method will no longer be available after Jan 28th, 2017."
        headers.merge!( { Parse::Protocol::EMAIL => email, Parse::Protocol::PASSWORD => password } )
        request :put, "#{APPS_PATH}/#{appid}", body: body, headers: headers
      end


    end
  end

end
