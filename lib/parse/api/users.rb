# encoding: UTF-8
# frozen_string_literal: true

require 'open-uri'

module Parse

  module API
    module Users
      # Note that Parse::Objects mainly use the objects.rb API since we can
      # detect class names to proper URI handlers
      USER_PATH_PREFIX = "users"
      USER_CLASS = "_User"
      USERNAME_PARAM = "username"
      PASSWORD_PARAM = "password"
      LOGOUT_PATH = "logout"
      LOGIN_PATH = "login"
      PASSWORD_RESET = "requestPasswordReset"

      def fetch_user(id)
        request :get, "#{USER_PATH_PREFIX}/#{id}"
      end

      def find_users(query = {})
        response = request :get, "#{USER_PATH_PREFIX}", query: query
        response.parse_class = USER_CLASS
        response
      end

      def current_user(session_token)
        headers = {Parse::Protocol::SESSION_TOKEN => session_token}
        response = request :get, "#{USER_PATH_PREFIX}/me", headers: headers
        response.parse_class = USER_CLASS
        response
      end

      def update_user(id, body = {})
        response = request :put, "#{USER_PATH_PREFIX}/#{id}", body: body
        response.parse_class = USER_CLASS
        response
      end

      def delete_user(id)
        request :delete, "#{USER_PATH_PREFIX}/#{id}"
      end

      def reset_password(email, **opts)
        body = {email: email}
        request :post, PASSWORD_RESET, body: body, opts: opts
      end

      def login(username, password, **opts)
        params = { USERNAME_PARAM => URI::encode(username), PASSWORD_PARAM => URI::encode(password) }
        headers = { Parse::Protocol::REVOCABLE_SESSION => '1'}
        # headers.merge!( { Parse::Protocol::INSTALLATION_ID => ''} )
        response = request :get, LOGIN_PATH, query: params, headers: headers, opts: opts
        response.parse_class = USER_CLASS
        response
      end

      def logout(session_token, **opts)
        opts.merge!({use_master_key: false, cache: false, session_token: session_token})
        request :post, LOGOUT_PATH, opts: opts
      end

    end # Users

  end #API

end #Parse
