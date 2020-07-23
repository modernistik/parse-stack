# encoding: UTF-8
# frozen_string_literal: true

require "active_support"
require "active_support/core_ext"

module Parse
  module API
    # REST API methods for fetching CRUD operations on Parse objects.
    module Objects
      # The class prefix for fetching objects.
      # @!visibility private
      CLASS_PATH_PREFIX = "classes/"

      # @!visibility private
      PREFIX_MAP = { installation: "installations", _installation: "installations",
                     user: "users", _user: "users",
                     role: "roles", _role: "roles",
                     session: "sessions", _session: "sessions" }.freeze

      # @!visibility private
      def self.included(base)
        base.extend(ClassMethods)
      end

      # Class methods to be applied to {Parse::Client}
      module ClassMethods
        # Get the API path for this class.
        # @param className [String] the name of the Parse collection.
        # @param id [String] optional objectId to add at the end of the path.
        # @return [String] the API uri path
        def uri_path(className, id = nil)
          if className.is_a?(Parse::Pointer)
            id = className.id
            className = className.parse_class
          end
          uri = "#{CLASS_PATH_PREFIX}#{className}"
          class_prefix = className.downcase.to_sym
          if PREFIX_MAP.has_key?(class_prefix)
            uri = PREFIX_MAP[class_prefix]
          end
          id.present? ? "#{uri}/#{id}" : "#{uri}/"
        end
      end

      # Get the API path for this class.
      # @param className [String] the name of the Parse collection.
      # @param id [String] optional objectId to add at the end of the path.
      # @return [String] the API uri path
      def uri_path(className, id = nil)
        self.class.uri_path(className, id)
      end

      # Create an object in a collection.
      # @param className [String] the name of the Parse collection.
      # @param body [Hash] the body of the request.
      # @param opts [Hash] additional options to pass to the {Parse::Client} request.
      # @param headers [Hash] additional HTTP headers to send with the request.
      # @return [Parse::Response]
      def create_object(className, body = {}, headers: {}, **opts)
        response = request :post, uri_path(className), body: body, headers: headers, opts: opts
        response.parse_class = className if response.present?
        response
      end

      # Delete an object in a collection.
      # @param className [String] the name of the Parse collection.
      # @param id [String] The objectId of the record in the collection.
      # @param opts [Hash] additional options to pass to the {Parse::Client} request.
      # @param headers [Hash] additional HTTP headers to send with the request.
      # @return [Parse::Response]
      def delete_object(className, id, headers: {}, **opts)
        response = request :delete, uri_path(className, id), headers: headers, opts: opts
        response.parse_class = className if response.present?
        response
      end

      # Fetch a specific object from a collection.
      # @param className [String] the name of the Parse collection.
      # @param id [String] The objectId of the record in the collection.
      # @param opts [Hash] additional options to pass to the {Parse::Client} request.
      # @param headers [Hash] additional HTTP headers to send with the request.
      # @return [Parse::Response]
      def fetch_object(className, id, headers: {}, **opts)
        response = request :get, uri_path(className, id), headers: headers, opts: opts
        response.parse_class = className if response.present?
        response
      end

      # Fetch a set of matching objects for a query.
      # @param className [String] the name of the Parse collection.
      # @param query [Hash] The set of query constraints.
      # @param opts [Hash] additional options to pass to the {Parse::Client} request.
      # @param headers [Hash] additional HTTP headers to send with the request.
      # @return [Parse::Response]
      # @see Parse::Query
      def find_objects(className, query = {}, headers: {}, **opts)
        response = request :get, uri_path(className), query: query, headers: headers, opts: opts
        response.parse_class = className if response.present?
        response
      end

      # Update an object in a collection.
      # @param className [String] the name of the Parse collection.
      # @param id [String] The objectId of the record in the collection.
      # @param body [Hash] The key value pairs to update.
      # @param opts [Hash] additional options to pass to the {Parse::Client} request.
      # @param headers [Hash] additional HTTP headers to send with the request.
      # @return [Parse::Response]
      def update_object(className, id, body = {}, headers: {}, **opts)
        response = request :put, uri_path(className, id), body: body, headers: headers, opts: opts
        response.parse_class = className if response.present?
        response
      end
    end #Objects
  end #API
end
