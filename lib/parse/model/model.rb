# encoding: UTF-8
# frozen_string_literal: true

require 'active_model'
require 'active_support'
require 'active_support/inflector'
require 'active_support/core_ext/object'
require 'active_model_serializers'
require_relative '../client'

# This is the base model for all Parse object-type classes.

module Parse

  class Model

    include Client::Connectable # allows easy default Parse::Client access
    include ::ActiveModel::Model
    include ::ActiveModel::Serializers::JSON # support for JSON Serializers
    include ::ActiveModel::Dirty # adds dirty tracking support
    include ::ActiveModel::Conversion
    extend  ::ActiveModel::Callbacks # callback support on save, update, delete, etc.
    extend  ::ActiveModel::Naming # provides the methods for getting class names from Model classes

    # General Parse constants
    KEY_CLASS_NAME  = 'className'
    KEY_OBJECT_ID   = 'objectId'
    KEY_CREATED_AT  = 'createdAt'
    KEY_UPDATED_AT  = 'updatedAt'
    CLASS_USER      = '_User'
    CLASS_INSTALLATION = '_Installation'
    CLASS_SESSION = '_Session'
    CLASS_ROLE = '_Role'
    TYPE_FILE = 'File'
    TYPE_GEOPOINT = 'GeoPoint'
    TYPE_OBJECT = 'Object'
    TYPE_DATE = 'Date'
    TYPE_BYTES = 'Bytes'
    TYPE_POINTER = 'Pointer'
    TYPE_RELATION = 'Relation'
    TYPE_FIELD = '__type'

    # To support being able to have different ruby class names from the 'table'
    # names used in Parse, we will need to have a dynamic lookup system where
    # when a parse class name received, we go through all of our subclasses to determine
    # which Parse::Object subclass is responsible for handling this Parse table class.
    # we use @@model_cache to cache the results of the algorithm since we do this frequently
    # when encoding and decoding objects.
    @@model_cache = {}
    def self.autosave_on_create
      @@autosave_on_create ||= false
    end
    def self.autosave_on_create=(bool)
      @@autosave_on_create = bool
    end

    class << self

      def raise_on_save_failure
        @global_raise_on_save_failure ||= false
      end
      def raise_on_save_failure=(bool)
        @global_raise_on_save_failure = bool
      end

    end

    # class method to find the responsible ruby Parse::Object subclass that handles
    # the provided parse class (str).
    def self.find_class(str)
      return Parse::File if str == TYPE_FILE
      return Parse::GeoPoint if str == TYPE_GEOPOINT
      return Parse::Date if str == TYPE_DATE
      return Parse::Bytes if str == TYPE_BYTES
      # return Parse::User if str == "User"
      # return Parse::Installation if str == "Installation"

      str = str.to_s
      # Basically go through all Parse::Object subclasses and see who is has a parse_class
      # set to this string. We will cache the results for future use.
      @@model_cache[str] ||= Parse::Object.descendants.find do |f|
        f.parse_class == str || f.parse_class == "_#{str}"
      end

    end

  end

end


class String
  # short helper method to provide lower-first-camelcase
  def columnize
     return "objectId" if self == "id"
     camelize(:lower)
   end;

  #users for properties: ex. :users -> "_User" or :songs -> Song
  def to_parse_class(singularize: false)
    final_class = singularize ? self.singularize.camelize : self.camelize
    klass = Parse::Model.find_class(final_class) || Parse::Model.find_class(self)
    #handles the case that a class has a custom parse table
    final_class = klass.parse_class if klass.present?
    final_class
  end
end

class Symbol
  # for compatibility
  def columnize
    to_s.columnize.to_sym
  end

  def singularize
    to_s.singularize
  end

  def camelize
    to_s.camelize
  end

  def to_parse_class(singularize: false)
    to_s.to_parse_class(singularize: singularize)
  end
end
