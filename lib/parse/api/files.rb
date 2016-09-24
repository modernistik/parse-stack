# encoding: UTF-8
# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext'

module Parse

  module API
    #object fetch methods
    module Files
      FILES_PATH = "files"
      # /1/classes/<className>	POST	Creating Objects
      def create_file(fileName, data = {}, content_type = nil)
        headers = {}
        headers.merge!( { Parse::Protocol::CONTENT_TYPE => content_type.to_s } ) if content_type.present?
        response = request :post, "#{FILES_PATH}/#{fileName}", body: data, headers: headers
        response.parse_class = Parse::Model::TYPE_FILE
        response
      end

    end

  end

end
