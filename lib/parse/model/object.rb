# encoding: UTF-8
# frozen_string_literal: true

require 'active_model'
require 'active_support'
require 'active_support/inflector'
require 'active_support/core_ext'
require 'active_support/core_ext/object'
require 'active_support/core_ext/string'
require 'active_model_serializers'
require 'time'
require 'open-uri'

require_relative "../client"
require_relative "model"
require_relative "pointer"
require_relative "geopoint"
require_relative "file"
require_relative "bytes"
require_relative "date"
require_relative "acl"
require_relative "push"
require_relative 'core/actions'
require_relative 'core/querying'
require_relative "core/schema"
require_relative "core/properties"
require_relative "associations/has_one"
require_relative "associations/belongs_to"
require_relative "associations/has_many"


module Parse
  # @return [Array] an array of registered Parse::Object subclasses.
  def self.registered_classes
      Parse::Object.descendants.map { |m| m.parse_class }.uniq
  end

  # This is the core class for all app specific Parse table subclasses. This class
  # in herits from Parse::Pointer since an Object is a Parse::Pointer with additional fields,
  # at a minimum, created_at, updated_at and ACLs.
  # This class also handles all the relational types of associations in a Parse application and
  # handles the main CRUD operations.
  #
  # Most Pointers and Object subclasses are treated the same. Therefore, defining a class Artist < Parse::Object
  # that only has `id` set, will be treated as a pointer. Therefore a Parse::Object can be in a "pointer" state
  # based on the data that it contains. Becasue of this, it is possible to take a Artist instance
  # (in this example), that is in a pointer state, and fetch the rest of the data for that particular
  # record without having to create a new object. Doing so would now mark it as not being a pointer anymore.
  # This is important to the understanding on how relations and properties are handled.
  #
  # The implementation of this class is large and has been broken up into several modules.
  #
  # Properties:
  # All columns in a Parse object are considered a type of property (ex. string, numbers, arrays, etc)
  # except in two cases - Pointers and Relations. For the list of basic supported data types, please see the
  # Properties module variable Parse::Properties::TYPES . When defining a property,
  # dynamic methods are created that take advantage of all the ActiveModel
  # plugins (dirty tracking, callbacks, json, etc).
  #
  # Associations (BelongsTo):
  # This module adds support for creating an association between one object to another using a
  # Parse object pointer. By defining a belongs_to relationship in a specific class, it implies
  # that the remote Parse table contains a local column, which has a pointer, referring to another
  # Parse table.
  #
  # Associations (HasMany):
  # In Parse there are two ways to deal with one-to-many and many-to-many relationships
  # One is through an array of pointers (which is recommended to be less than 100) and
  # through an intermediary table called a Relation (or a Join table in other languages.)
  # The way Parse::Objects treat these associations different from defining a :property of array type, is
  # by making sure items in the array as of a particular class cast type.
  #
  # Querying:
  # The querying module provides all the general methods to be able to find and query a specific
  # Parse table.
  #
  # Fetching:
  # The fetching modules supports fetching data from Parse (depending on the state of the object),
  # and providing some autofetching features when traversing relational objects and properties.
  #
  # Schema:
  # The schema module provides methods to modify the Parse table remotely to either add or create
  # any locally define properties in ruby and have those be reflected in the Parse application.
  class Object < Pointer
    include Properties
    include Associations::HasOne
    include Associations::BelongsTo
    include Associations::HasMany
    include Querying
    include Fetching
    include Actions
    include Schema
    BASE_OBJECT_CLASS = "Parse::Object".freeze

    # @return [Model::TYPE_OBJECT]
    def __type; Parse::Model::TYPE_OBJECT; end;

    # Default ActiveModel::Callbacks
    define_model_callbacks :create, :save, :destroy, only: [:after, :before]

    attr_accessor :created_at, :updated_at, :acl

    # All Parse Objects have a class-level and instance level `parse_class` method, in which the
    # instance method is a convenience one for the class one. The default value for the parse_class is
    # the name of the ruby class name. Therefore if you have an 'Artist' ruby class, then by default we will assume
    # the remote Parse table is named 'Artist'. You may override this behavior by utilizing the `parse_class(<className>)` method
    # to set it to something different.
    class << self
      # @!attribute [rw] disable_serialized_string_date
      # Disables returning a serialized string date properties when encoding to JSON.
      # This affects created_at and updated_at fields in order to be backwards compatible with old SDKs.
      #   @return [Boolean]
      attr_accessor :disable_serialized_string_date

      attr_accessor :parse_class, :acl

      # The class method to override the implicitly assumed Parse collection name
      # in your Parse database. The default Parse collection name is the singular form
      # of the ruby Parse::Object subclass name. The Parse class value should match to
      # the corresponding remote table in your database in order to properly store records and
      # perform queries.
      ## @example
      #  class Song < Parse::Object; end;
      #  class Artist < Parse::Object
      #    parse_class "Musician" # remote collection name
      #  end
      #
      #  Parse::User.parse_class # => '_User'
      #  Song.parse_class # => 'Song'
      #  Artist.parse_class # => 'Musician'
      #
      # @param c [String] the name of the remote collection
      # @return [String]
      def parse_class(c = nil)
        @parse_class ||= model_name.name
        unless c.nil?
          @parse_class = c.to_s
        end
        @parse_class
      end

      # A method to override the default ACLs for new objects for this particular
      # subclass.
      # @param acls [Hash] a hash with key value pairs of ACLs permissions.
      # @return [ACL] the default ACLs for this class.
      def acl(acls = {}, owner: nil)
        acls = {"*" => {read: true, write: false} }.merge( acls ).symbolize_keys
        @acl ||= Parse::ACL.new(acls, owner: owner)
      end

    end

    # @return [String] the Parse class for this object.
    # @see Parse::Object.parse_class
    def parse_class
      self.class.parse_class
    end
    alias_method :className, :parse_class

    # @return [Hash] a json-hash representing this object.
    def as_json(*args)
      pointer? ? pointer : super(*args)
    end

    # The main constructor for subclasses. It can take different parameter types
    # including a String and a JSON hash. Assume a `Post` class that inherits
    # from Parse::Object:
    # @example
    #  # using an object id
    #  Post.new "1234"
    #
    #  # using a JSON hash
    #  Post.new({"className" => "Post", "objectId" => "1234"})
    #
    #  # or regular ruby
    #  Post.new field: "value"
    #
    def initialize(opts = {})
      if opts.is_a?(String) #then it's the objectId
        @id = opts.to_s
      elsif opts.is_a?(Hash)
        #if the objectId is provided we will consider the object pristine
        #and not track dirty items
        dirty_track = opts[Parse::Model::OBJECT_ID] || opts[:objectId] || opts[:id]
        apply_attributes!(opts, dirty_track: !dirty_track)
      end

      if self.acl.blank?
        self.acl = self.class.acl({}, owner: self) || Parse::ACL.new(owner: self)
      end
      clear_changes! if @id.present? #then it was an import

      # do not apply defaults on a pointer because it will stop it from being
      # a pointer and will cause its field to be autofetched (for sync)
      apply_defaults! unless pointer?
      # do not call super since it is Pointer subclass
    end

    # force apply default values for any properties defined with default values.
    # @return [Array] list of default fields
    def apply_defaults!
      self.class.defaults_list.each do |key|
        send(key) # should call set default proc/values if nil
      end
    end

    # Helper method to create a Parse::Pointer object for a given id.
    # @param id [String] The objectId
    # @return [Parse::Pointer] a pointer object corresponding to this class and id.
    def self.pointer(id)
      return nil if id.nil?
      Parse::Pointer.new self.parse_class, id
    end

    # Determines if this object has been saved to the Parse database. If an object has
    # pending changes, then it is considered to not yet be persisted.
    # @return [Boolean] true if this object has not been saved.
    def persisted?
      changed? == false && !(@id.nil? || @created_at.nil? || @updated_at.nil? || @acl.nil?)
    end

    # force reload from the database and replace any local fields with data from
    # the persistent store
    # @param opts [Hash] a set of options to send to fetch!
    # @see Fetching#fetch!
    def reload!(opts = {})
    # get the values from the persistence layer
      fetch!(opts)
      clear_changes!
    end

    # clears all dirty tracking information
    def clear_changes!
      clear_changes_information
    end

    # An object is considered new if it has no id. This is the method to use
    # in a webhook beforeSave when checking if this object is new.
    # @return [Boolean] true if the object has no id.
    def new?
      @id.blank?
    end

    # Existed returns true/false depending whether the object
    # had existed before *its last save operation*. This implies
    # that the created_at and updated_at dates are exactly the same. This
    # is a helper method in a webhook afterSave to know if this object was recently
    # saved in the beforeSave webhook.
    # @note You should not use this method inside a beforeSave webhook.
    # @return [Boolean] true if the last beforeSave webhook successfuly saved this object for the first time.
    def existed?
      if @id.blank? || @created_at.blank? || @updated_at.blank?
        return false
      end
      created_at != updated_at
    end

    # Returns a hash of all the changes that have been made to the object. By default
    # changes to the Parse::Properties::BASE_KEYS are ignored unless you pass true as
    # an argument.
    # @param include_all [Boolean] whether to include all keys in result.
    # @return [Hash] a hash containing only the change information.
    # @see Properties::BASE_KEYS
    def updates(include_all = false)
      h = {}
      changed.each do |key|
        next if include_all == false && Parse::Properties::BASE_KEYS.include?(key.to_sym)
        # lookup the remote Parse field name incase it is different from the local attribute name
        remote_field = self.field_map[key.to_sym] || key
        h[remote_field] = send key
        # make an exception to Parse::Objects, we should return a pointer to them instead
        h[remote_field] = h[remote_field].parse_pointers if h[remote_field].is_a?(Parse::PointerCollectionProxy)
        h[remote_field] = h[remote_field].pointer if h[remote_field].respond_to?(:pointer)
      end
      h
    end

    # Locally restores the previous state of the object and clears all dirty
    # tracking information.
    # @note This does not reload the object from the persistent store, for this use "reload!" instead.
    # @see #reload!
    def rollback!
      restore_attributes
    end

    # Overrides ActiveModel::Validations#validate! instance method.
    # It runs all valudations for this object. If it validation fails,
    # it raises ActiveModel::ValidationError otherwise it returns the object.
    # @raise ActiveModel::ValidationError
    # @see ActiveModel::Validations#validate!
    # @return [self] self the object if validation passes.
    def validate!
      super
      self
    end

    # This method creates a new object of the same instance type with a copy of
    # all the properties of the current instance. This is useful when you want
    # to create a duplicate record.
    # @return [Parse::Object] a twin copy of the object without the objectId
    def twin
      h = self.as_json
      h.delete(Parse::Model::OBJECT_ID)
      h.delete(:objectId)
      h.delete(:id)
      self.class.new h
    end

    # @return [String] a pretty-formatted JSON string
    # @see JSON.pretty_generate
    def pretty
      JSON.pretty_generate( as_json )
    end

    # clear all change and dirty tracking information.
    def clear_attribute_change!(atts)
      clear_attribute_changes(atts)
    end

    # Method used for decoding JSON objects into their corresponding Object subclasses.
    # The first parameter is a hash containing the object data and the second parameter is the
    # name of the table / class if it is known. If it is not known, we we try and determine it
    # by checking the "className" or :className entries in the hash.
    # @note If a Parse class object hash is encoutered for which we don't have a
    #       corresponding Parse::Object subclass for, a Parse::Pointer will be returned instead.
    #
    # @param json [Hash] a JSON hash that contains a Parse object.
    # @param table [String] the Parse class for this hash. If not passed it will be detected.
    # @return [Parse::Object] an instance of the Parse subclass
    def self.build(json, table = nil)
      className = table
      className ||= (json[Parse::Model::KEY_CLASS_NAME] || json[:className]) if json.is_a?(Hash)
      if json.is_a?(Hash) && json["error"].present? && json["code"].present?
        warn "[Parse::Object] Detected object hash with 'error' and 'code' set. : #{json}"
      end
      className = parse_class unless parse_class == BASE_OBJECT_CLASS
      return if className.nil?
      # we should do a reverse lookup on who is registered for a different class type
      # than their name with parse_class
      klass = Parse::Model.find_class className
      o = nil
      if klass.present?
        # when creating objects from Parse JSON data, don't use dirty tracking since
        # we are considering these objects as "pristine"
        o = klass.new(json)
      else
        o = Parse::Pointer.new className, (json[Parse::Model::OBJECT_ID] || json[:objectId])
      end
      return o
    # rescue NameError => e
    #   puts "Parse::Object.build constant class error: #{e}"
    # rescue Exception => e
    #   puts "Parse::Object.build error: #{e}"
    end

    # @!attribute [rw] id
    #  @return [String] the value of Parse "objectId" field.

    # @!attribute [r] created_at
    #  @return [Date] the created_at date of the record in UTC Zulu iso 8601 with 3 millisecond format.

    # @!attribute [r] updated_at
    #  @return [Date] the updated_at date of the record in UTC Zulu iso 8601 with 3 millisecond format.

    # @!attribute [rw] acl
    #  @return [ACL] the access control list (permissions) object for this record.
    property :id, field: :objectId
    property :created_at, :date
    property :updated_at, :date
    property :acl, :acl, field: :ACL

    def createdAt
      return @created_at if Parse::Object.disable_serialized_string_date.present?
      @created_at.to_time.utc.iso8601(3) if @created_at.present?
    end

    def updatedAt
      return @updated_at if Parse::Object.disable_serialized_string_date.present?
      @updated_at.to_time.utc.iso8601(3) if @updated_at.present?
    end

  end

end

class Array
  # This helper method selects or converts all objects in an array that are either inherit from
  # Parse::Pointer or are a JSON Parse hash. If it is a hash, a Pare::Object will be built from it
  # if it constains the proper fields. Non-convertible objects will be removed.
  # If the className is not contained or known, you can pass a table name as an argument
  # @return [Array] an array of Parse::Object subclasses.
  def parse_objects(table = nil)
    f = Parse::Model::KEY_CLASS_NAME
    map do |m|
      next m if m.is_a?(Parse::Pointer)
      if m.is_a?(Hash) && (m[f] || m[:className] || table)
        next Parse::Object.build m, (m[f] || m[:className] || table)
      end
      nil
    end.compact
  end

  # @return [Array] an array of objectIds for all objects that are Parse::Objects.
  def parse_ids
    parse_objects.map(&:id)
  end

end

# Load all the core classes.
require_relative 'classes/installation'
require_relative 'classes/role'
require_relative 'classes/session'
require_relative 'classes/user'
