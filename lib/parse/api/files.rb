
module Parse

  module API
    #object fetch methods
    module Files

      # /1/classes/<className>	POST	Creating Objects
      def create_file(fileName, data = {}, content_type = nil)
        headers = {}
        headers.merge!( { Parse::Protocol::CONTENT_TYPE => content_type.to_s } ) if content_type.present?
        response = request :post, "/1/files/#{fileName}", body: data, headers: headers
        response.parse_class = "_File".freeze
        response
      end

    end

  end

end
