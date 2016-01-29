
module Parse

  module API

    module Apps


      def fetch_app_keys(appid, email, password)
        headers = {}
        headers.merge!( { 'X-Parse-Email' => email, 'X-Parse-Password' => password } )
        request :get, "/1/apps/#{appid}", headers: headers
      end

      def fetch_apps(email, password)
        headers = {}
        headers.merge!( { 'X-Parse-Email' => email, 'X-Parse-Password' => password } )
        request :get, "/1/apps", headers: headers
      end

      def create_app(opts, email, password)
        headers = {}
        headers.merge!( { 'X-Parse-Email' => email, 'X-Parse-Password' => password } )
        request :post, "/1/apps", body: opts, headers: headers
      end

      def update_app(appid, opts, email, password)
        headers = {}
        headers.merge!( { 'X-Parse-Email' => email, 'X-Parse-Password' => password } )
        request :put, "/1/apps/#{appid}", body: opts, headers: headers
      end


    end
  end

end
