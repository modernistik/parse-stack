# encoding: UTF-8
# frozen_string_literal: true

module Parse

  module API
    #object fetch methods
    module Schema
      SCHEMAS_PATH = "schemas"
      def schema(className)
        request :get, "#{SCHEMAS_PATH}/#{className}"
      end

      def create_schema(className, schema)
        request :post, "#{SCHEMAS_PATH}/#{className}", body: schema
      end

      def update_schema(className, schema)
        request :put, "#{SCHEMAS_PATH}/#{className}", body: schema
      end

    end #Schema

  end #API

end
