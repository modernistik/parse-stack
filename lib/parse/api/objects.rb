# encoding: UTF-8
# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext'

module Parse

  module API
    #object fetch methods
    module Objects

      CLASS_PATH_PREFIX = "classes/"
      PREFIX_MAP = { installation: "installations", _installation: "installations",
        user: "users", _user: "users",
        role: "roles", _role: "roles",
        session: "sessions", _session: "sessions"
      }.freeze

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def uri_path(className, id = nil)
          if className.is_a?(Parse::Pointer)
            id = className.id
            className = className.parse_class
          end
          uri = "#{CLASS_PATH_PREFIX}#{className}"
          class_prefix = className.downcase.to_sym
          if PREFIX_MAP.has_key?(class_prefix)
            uri = "#{PREFIX_MAP[class_prefix]}/"
          end
          id.present? ? "#{uri}/#{id}" : uri
        end

      end

      def uri_path(className, id = nil)
        self.class.uri_path(className, id)
      end

      # /1/classes/<className>	POST	Creating Objects
      def create_object(className, data = {})
        response = request :post, uri_path(className) , body: data
        response.parse_class = className if response.present?
        response
      end

      # /1/classes/<className>/<objectId>	DELETE	Deleting Objects
      def delete_object(className, id)
        response = request :delete, uri_path(className, id)
        response.parse_class = className if response.present?
        response
      end

      # /1/classes/<className>/<objectId>	GET	Retrieving Objects
      def fetch_object(className, id, opts = {})
        response = request :get, uri_path(className, id), opts: opts
        response.parse_class = className if response.present?
        response
      end

      # /1/classes/<className>	GET	Queries
      def find_objects(className, query = {}, opts = {})
        response = request :get, uri_path(className), query: query, opts: opts
        response.parse_class = className if response.present?
        response
      end

      # /1/classes/<className>/<objectId>	PUT	Updating Objects
      def update_object(className, id, data = {})
        response = request :put, uri_path(className,id) , body: data
        response.parse_class = className if response.present?
        response
      end

    end #Objects
  end #API

end
