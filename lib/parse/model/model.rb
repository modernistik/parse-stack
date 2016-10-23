# encoding: UTF-8
# frozen_string_literal: true

require 'active_model'
require 'active_support'
require 'active_support/inflector'
require 'active_support/core_ext/object'
require 'active_model_serializers'
require_relative '../client'

module Parse
  # Find a corresponding Parse::Object subclass for this string or symbol
  # @param className [String] The name of the Parse class as string (ex. "_User")
  # @return [Class] The proper subclass matching the className.
  def self.classify(className)
    Parse::Model.find_class className.to_parse_class
  end

  # The core model of all Parse-Stack classes. This class works by providing a
  # baseline for all subclass objects to support ActiveModel features such as
  # serialization, dirty tracking, callbacks, etc.
  # @see ActiveModel
  class Model

    include Client::Connectable # allows easy default Parse::Client access
    include ::ActiveModel::Model
    include ::ActiveModel::Serializers::JSON # support for JSON Serializers
    include ::ActiveModel::Dirty # adds dirty tracking support
    include ::ActiveModel::Conversion
    extend  ::ActiveModel::Callbacks # callback support on save, update, delete, etc.
    extend  ::ActiveModel::Naming # provides the methods for getting class names from Model classes

    ID = "id".freeze
    OBJECT_ID   = 'objectId'.freeze
    KEY_CLASS_NAME  = 'className'.freeze
    KEY_OBJECT_ID   = 'objectId'.freeze
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
    # @!visibility private
    @@model_cache = {}

    # If set to true, a call to first_or_create will automatically save the object.
    # @return [Boolean]
    def self.autosave_on_create
      @@autosave_on_create ||= false
    end

    def self.autosave_on_create=(bool)
      @@autosave_on_create = bool
    end

    class << self
      # By default, we return `true` or `false` for save and destroy operations.
      # If you prefer to have `Parse::Object` raise an exception instead, you
      # can tell to do so either globally or on a per-model basis. When a save
      # fails, it will raise a `Parse::SaveFailureError`.
      #
      # @example
      #   Parse::Model.raise_on_save_failure = true # globally across all models
      #   Song.raise_on_save_failure = true          # per-model
      #
      #   # or per-instance raise on failure
      #   song.save!
      #
      # When enabled, if an error is returned by Parse due to saving or
      # destroying a record, due to your `before_save` or `before_delete`
      # validation cloud code triggers, `Parse::Object` will return the a
      # `Parse::SaveFailureError` exception type. This exception has an
      # instance method of `#object` which contains the object that failed to save.
      #
      # @return [Boolean]
      attr_accessor :raise_on_save_failure

      def raise_on_save_failure
        @global_raise_on_save_failure ||= false
      end
      def raise_on_save_failure=(bool)
        @global_raise_on_save_failure = bool
      end

    end

    # Find a Parse::Model subclass matching this type or Pares collection name.
    # This helper method is useful to find the corresponding class ruby Parse::Object subclass that handles
    # the provided parse class.
    #
    # @example
    #  Parse::Model.find_class('_User') # => Parse::User
    #  Parse::Model.find_class('_Date') # => Parse::Date
    #  Parse::Model.find_class('Installation') # => Parse::Installation
    #
    #  class Artist < Parse::Object
    #    parse_class "Musician"
    #  end
    #
    #  Parse::Model.find_class("Musician") # => Artist
    #
    # @param str [String] the class name
    # @return [Parse::Object] a Parse::Object subclass or a specific Parse type.
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
  # This method returns a camel-cased version of the string with the first letter
  # of the string in lower case. This is the standard naming convention for Parse columns
  # and property fields. This has special exception to the string "id", which returns
  # "objectId". This is the default name filtering method for all defined properties and
  # query keys in Parse::Query.
  #
  # @example
  #  "my_field".columnize # => "myField"
  #  "MyDataColumn".columnize # => "myDataColumn"
  #  "id".columnize # => "objectId" (special)
  #
  # @return [String]
  # @see Parse::Query.field_formatter
  def columnize
     return Parse::Model::OBJECT_ID if self == Parse::Model::ID
     u = '_'.freeze
     (first == u ? sub(u,'') : self).camelize(:lower)
  end

  # Convert a string to a Parse class name. This method tries to find a
  # responsible Parse::Object subclass that potentially matches the given string.
  # If no match is found, it returns the camelized version of the string. This method
  # is used internally for matching association attributes to registered
  # Parse::Object subclasses. The method can also singularize the name before
  # performing conversion.
  #
  # @example
  #  "users".to_parse_class(singularize: true) # => "_User"
  #  "users".to_parse_class # => "Users"
  #  "song_data".to_parse_class # => "SongData"
  #
  # @param singularize [Boolean] whether the string should be singularized first before performing conversion.
  # @return [String] the matching Parse class for this string.
  def to_parse_class(singularize: false)
    final_class = singularize ? self.singularize.camelize : self.camelize
    klass = Parse::Model.find_class(final_class) || Parse::Model.find_class(self)
    #handles the case that a class has a custom parse table
    final_class = klass.parse_class if klass.present?
    final_class
  end
end

class Symbol
  # @return [String] a lower-first-camelcased version of the symbol
  # @see String#columnize
  def columnize
    to_s.columnize.to_sym
  end

  # @see String#singularize
  def singularize
    to_s.singularize
  end

  # @see String#camelize
  def camelize
    to_s.camelize
  end

  # @see String#to_parse_class
  def to_parse_class(singularize: false)
    to_s.to_parse_class(singularize: singularize)
  end
end
