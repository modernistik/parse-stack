

module Parse

  module API
    module Users
      # Note that Parse::Objects mainly use the objects.rb API since we can
      # detect class names to proper URI handlers
      USER_PATH_PREFIX = "users".freeze
      USER_LOGIN_PATH_PREFIX = "login".freeze
      USER_CLASS = "_User".freeze
      USERNAME_PARAM = "username".freeze
      PASSWORD_PARAM = "password".freeze
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
        response = request :get, "#{USER_LOGIN_PATH_PREFIX}", query: params, opts: {use_master_key: false}
        response.parse_class = USER_CLASS
        response
      end

      def signup_user(username, password, email = nil, phone = nil)
        body = {"#{USERNAME_PARAM}": username, "#{PASSWORD_PARAM}": password}
        body[:email] = email unless email.nil?
        body[:phone] = phone unless phone.nil?
        response = request :post, "#{USER_PATH_PREFIX}", body: body, opts: {use_master_key: false}
        response.parse_class = USER_CLASS
        response
      end

    end # Users

  end #API

end #Parse
