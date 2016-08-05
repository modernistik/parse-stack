

module Parse

  module API
    module Users
      # Note that Parse::Objects mainly use the objects.rb API since we can
      # detect class names to proper URI handlers
      USER_PATH_PREFIX = "users".freeze
      USER_LOGIN_PATH_PREFIX = "login".freeze
      USER_LOGOUT_PATH_PREFIX = "logout".freeze
      USER_CLASS = "_User".freeze
      USERNAME_PARAM = "username".freeze
      PASSWORD_PARAM = "password".freeze
      AUTHDATA_PARAM = "authData".freeze

      def fetch_user(id)
        request :get, "#{USER_PATH_PREFIX}/#{id}"
      end

      def find_users(query = {})
        response = request :get, "#{USER_PATH_PREFIX}", query: query
        response.parse_class = USER_CLASS
        response
      end

      def fetch_me(query = {})
        response = request :get, "#{USER_PATH_PREFIX}/me", query: query
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

      def login_user(username, password)
        params = {"#{USERNAME_PARAM}": username, "#{PASSWORD_PARAM}": password}
        response = request :get, "#{USER_LOGIN_PATH_PREFIX}", query: params, opts: {use_master_key: false, cache: false}
        response.parse_class = USER_CLASS
        response
      end

      def signup_user(username, password, email = nil)
        body = {"#{USERNAME_PARAM}": username, "#{PASSWORD_PARAM}": password}
        body[:email] = email if email.present?
        response = request :post, "#{USER_PATH_PREFIX}", body: body, opts: {use_master_key: false, cache: false}
        response.parse_class = USER_CLASS
        response
      end

      def logout_user(session_token)
        request :post, "#{USER_LOGOUT_PATH_PREFIX}", opts: {use_master_key: false, cache: false, session_token: session_token}
      end

      def auth_user(auth_data)
        body = {"#{AUTHDATA_PARAM}": auth_data}
        response = request :post, "#{USER_PATH_PREFIX}", body: body, opts: {use_master_key: false, cache: false}
        response.parse_class = USER_CLASS
        response
      end

      def link_user(id, auth_data)
        body = {"#{AUTHDATA_PARAM}": auth_data}
        request :put, "#{USER_PATH_PREFIX}/#{id}", body: body, opts: {use_master_key: false, cache: false}
      end

      def unlink_user(id, service_name, session_token)
        body = {"#{AUTHDATA_PARAM}": {"#{service_name}": nil}}
        request :put, "#{USER_PATH_PREFIX}/#{id}", body: body, opts: {use_master_key: false, cache: false, session_token: session_token}
      end
    end # Users

  end #API

end #Parse
