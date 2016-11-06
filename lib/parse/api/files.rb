# encoding: UTF-8
# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext'

module Parse

  module API
    # Defines the Parse Files interface for the Parse REST API
    module Files
      # @!visibility private
      FILES_PATH = "files"

      # Upload and create a Parse file.
      # @param fileName [String] the basename of the file.
      # @param data [Hash] the data related to this file.
      # @param content_type [String] the mime-type of the file.
      # @return [Parse::Response]
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
