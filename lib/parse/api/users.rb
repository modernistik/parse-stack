# encoding: UTF-8
# frozen_string_literal: true

require 'open-uri'

module Parse

  module API
    module Users
      # Note that Parse::Objects mainly use the objects.rb API since we can
      # detect class names to proper URI handlers
      USER_PATH_PREFIX = "users"
      LOGOUT_PATH = "logout"
      LOGIN_PATH = "login"
      REQUEST_PASSWORD_RESET = "requestPasswordReset"

      def fetch_user(id, headers: {}, **opts)
        request :get, "#{USER_PATH_PREFIX}/#{id}", headers: headers, opts: opts
      end

      def find_users(query = {}, headers: {}, **opts)
        response = request :get, USER_PATH_PREFIX, query: query, headers: headers, opts: opts
        response.parse_class = Parse::Model::CLASS_USER
        response
      end

      def current_user(session_token, headers: {}, **opts)
        headers.merge!({Parse::Protocol::SESSION_TOKEN => session_token})
        response = request :get, "#{USER_PATH_PREFIX}/me", headers: headers, opts: opts
        response.parse_class = Parse::Model::CLASS_USER
        response
      end

      def create_user(body, headers: {}, **opts)
        headers.merge!({ Parse::Protocol::REVOCABLE_SESSION => '1'})
        if opts[:session_token].present?
          headers.merge!({ Parse::Protocol::SESSION_TOKEN => opts[:session_token]})
        end
        response = request :post, USER_PATH_PREFIX, body: body, headers: headers, opts: opts
        response.parse_class = Parse::Model::CLASS_USER
        response
      end

      def update_user(id, body = {}, headers: {}, **opts)
        response = request :put, "#{USER_PATH_PREFIX}/#{id}", body: body, opts: opts
        response.parse_class = Parse::Model::CLASS_USER
        response
      end

      # deleting or unlinking is done by setting the authData of the service name to nil
      def set_service_auth_data(id, service_name, auth_data, headers: {}, **opts)
        body = { authData: { service_name => auth_data } }
        update_user(id, body, opts)
      end

      def delete_user(id, headers: {}, **opts)
        request :delete, "#{USER_PATH_PREFIX}/#{id}", headers: headers, opts: opts
      end

      def request_password_reset(email, **opts)
        body = {email: email}
        request :post, REQUEST_PASSWORD_RESET, body: body, opts: opts
      end

      def login(username, password, headers: {}, **opts)
        # Probably pass Installation-ID as header
        query = { username: username, password: password }
        headers.merge!({ Parse::Protocol::REVOCABLE_SESSION => '1'})
        # headers.merge!( { Parse::Protocol::INSTALLATION_ID => ''} )
        response = request :get, LOGIN_PATH, query: query, headers: headers, opts: opts
        response.parse_class = Parse::Model::CLASS_USER
        response
      end

      def logout(session_token, headers: {}, **opts)
        headers.merge!({ Parse::Protocol::SESSION_TOKEN => session_token})
        opts.merge!({use_master_key: false, session_token: session_token})
        request :post, LOGOUT_PATH, headers: headers, opts: opts
      end

      # {username: "", password: "", email: nil} # minimum
      def signup(username, password, email = nil, body: {}, **opts)
        body = body.merge({ username: username, password: password })
        body[:email] = email || body[:email]
        create_user(body, opts)
      end


    end # Users

  end #API

end #Parse
