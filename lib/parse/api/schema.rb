# encoding: UTF-8
# frozen_string_literal: true

module Parse

  module API
    # Defines the Schema interface for the Parse REST API
    module Schema
      # @!visibility private
      SCHEMAS_PATH = "schemas"

      # Get all the schemas for the application.
      # @return [Parse::Response]
      def schemas
        opts = {cache: false}
        request :get, SCHEMAS_PATH, opts: opts
      end

      # Get the schema for a collection.
      # @param className [String] the name of the remote Parse collection.
      # @return [Parse::Response]
      def schema(className)
        opts = {cache: false}
        request :get, "#{SCHEMAS_PATH}/#{className}", opts: opts
      end

      # Create a new collection with the specific schema.
      # @param className [String] the name of the remote Parse collection.
      # @param schema [Hash] the schema hash. This is a specific format specified by
      #  Parse.
      # @return [Parse::Response]
      def create_schema(className, schema)
        request :post, "#{SCHEMAS_PATH}/#{className}", body: schema
      end

      # Update the schema for a collection.
      # @param className [String] the name of the remote Parse collection.
      # @param schema [Hash] the schema hash. This is a specific format specified by
      #  Parse.
      # @return [Parse::Response]
      def update_schema(className, schema)
        request :put, "#{SCHEMAS_PATH}/#{className}", body: schema
      end

    end #Schema

  end #API

end
