# encoding: UTF-8
# frozen_string_literal: true

require "active_support"
require "active_support/core_ext"
require_relative "./objects"

module Parse
  module API
    # REST API methods for fetching CRUD operations on Parse objects.
    module Aggregate
      # The class prefix for fetching objects.
      # @!visibility private
      PATH_PREFIX = "aggregate/"

      # @!visibility private
      PREFIX_MAP = Parse::API::Objects::PREFIX_MAP

      # @!visibility private
      def self.included(base)
        base.extend(ClassMethods)
      end

      # Class methods to be applied to {Parse::Client}
      module ClassMethods
        # Get the aggregate API path for this class.
        # @param className [String] the name of the Parse collection.
        # @return [String] the API uri path
        def aggregate_uri_path(className)
          if className.is_a?(Parse::Pointer)
            id = className.id
            className = className.parse_class
          end
          "#{PATH_PREFIX}#{className}"
        end
      end

      # Get the API path for this class.
      # @param className [String] the name of the Parse collection.
      # @return [String] the API uri path
      def aggregate_uri_path(className)
        self.class.aggregate_uri_path(className)
      end

      # Aggregate a set of matching objects for a query.
      # @param className [String] the name of the Parse collection.
      # @param query [Hash] The set of query constraints.
      # @param opts [Hash] additional options to pass to the {Parse::Client} request.
      # @param headers [Hash] additional HTTP headers to send with the request.
      # @return [Parse::Response]
      # @see Parse::Query
      def aggregate_objects(className, query = {}, headers: {}, **opts)
        response = request :get, aggregate_uri_path(className), query: query, headers: headers, opts: opts
        response.parse_class = className if response.present?
        response
      end
    end #Aggregate
  end #API
end
