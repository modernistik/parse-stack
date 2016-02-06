

module Parse

  module API
    module Users
      # Note that Parse::Objects mainly use the objects.rb API since we can
      # detect class names to proper URI handlers
      USER_PATH_PREFIX = "users".freeze
      USER_CLASS = "_User".freeze
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



    end # Users

  end #API

end #Parse
