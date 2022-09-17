# encoding: UTF-8
# frozen_string_literal: true

require "active_model"
require "active_support"
require "active_support/inflector"
require "active_support/core_ext"
require "active_support/core_ext/object"
require "active_support/core_ext/string"

require "time"
require "open-uri"

require_relative "../client"
require_relative "model"
require_relative "pointer"
require_relative "geopoint"
require_relative "file"
require_relative "bytes"
require_relative "date"
require_relative "time_zone"
require_relative "acl"
require_relative "push"
require_relative "core/actions"
require_relative "core/fetching"
require_relative "core/querying"
require_relative "core/schema"
require_relative "core/properties"
require_relative "core/errors"
require_relative "core/builder"
require_relative "associations/has_one"
require_relative "associations/belongs_to"
require_relative "associations/has_many"

module Parse
  # @return [Array] an array of registered Parse::Object subclasses.
  def self.registered_classes
    Parse::Object.descendants.map(&:parse_class).uniq
  end

  # @return [Array<Hash>] the list of all schemas for this application.
  def self.schemas
    client.schemas.results
  end

  # Fetch the schema for a specific collection name.
  # @param className [String] the name collection
  # @return [Hash] the schema document of this collection.
  # @see Parse::Core::ClassBuilder.build!
  def self.schema(className)
    client.schema(className).result
  end

  # Perform a non-destructive upgrade of all your Parse schemas in the backend
  # based on the property definitions of your local {Parse::Object} subclasses.
  def self.auto_upgrade!
    klassModels = Parse::Object.descendants
    klassModels.sort_by(&:parse_class).each do |klass|
      yield(klass) if block_given?
      klass.auto_upgrade!
    end
  end

  # Alias shorter names of core Parse class names.
  # Ex, alias Parse::User to User, Parse::Installation to Installation, etc.
  def self.use_shortnames!
    require_relative "shortnames"
  end

  # This is the core class for all app specific Parse table subclasses. This class
  # in herits from Parse::Pointer since an Object is a Parse::Pointer with additional fields,
  # at a minimum, created_at, updated_at and ACLs. This class also handles all
  # the relational types of associations in a Parse application and handles the main CRUD operations.
  #
  # As the parent class to all custom subclasses, this class provides the default property schema:
  #
  #   class Parse::Object
  #      # All subclasses will inherit these properties by default.
  #
  #      # the objectId column of a record.
  #      property :id, :string, field: :objectId
  #
  #      # The the last updated date for a record (Parse::Date)
  #      property :updated_at, :date
  #
  #      # The original creation date of a record (Parse::Date)
  #      property :created_at, :date
  #
  #      # The Parse::ACL field
  #      property :acl, :acl, field: :ACL
  #
  #   end
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
  #
  # All columns in a Parse object are considered a type of property (ex. string, numbers, arrays, etc)
  # except in two cases - Pointers and Relations. For a detailed discussion of properties, see
  # The {https://github.com/modernistik/parse-stack#defining-properties Defining Properties} section.
  #
  # Associations:
  #
  # Parse supports a three main types of relational associations. One type of
  # relation is the `One-to-One` association. This is implemented through a
  # specific column in Parse with a Pointer data type. This pointer column,
  # contains a local value that refers to a different record in a separate Parse
  # table. This association is implemented using the `:belongs_to` feature. The
  # second association is of `One-to-Many`. This is implemented is in Parse as a
  # Array type column that contains a list of of Parse pointer objects. It is
  # recommended by Parse that this array does not exceed 100 items for performance
  # reasons. This feature is implemented using the `:has_many` operation with the
  # plural name of the local Parse class. The last association type is a Parse
  # Relation. These can be used to implement a large `Many-to-Many` association
  # without requiring an explicit intermediary Parse table or class. This feature
  # is also implemented using the `:has_many` method but passing the option of `:relation`.
  #
  # @see Associations::BelongsTo
  # @see Associations::HasOne
  # @see Associations::HasMany
  class Object < Pointer
    include Properties
    include Associations::HasOne
    include Associations::BelongsTo
    include Associations::HasMany
    extend Core::Querying
    extend Core::Schema
    include Core::Fetching
    include Core::Actions
    # @!visibility private
    BASE_OBJECT_CLASS = "Parse::Object".freeze

    # @return [Model::TYPE_OBJECT]
    def __type; Parse::Model::TYPE_OBJECT; end

    # Default ActiveModel::Callbacks
    # @!group Callbacks
    #
    # @!method before_create
    #   A callback called before the object has been created.
    #   @yield A block to execute for the callback.
    #   @see ActiveModel::Callbacks
    # @!method after_create
    #   A callback called after the object has been created.
    #   @yield A block to execute for the callback.
    #   @see ActiveModel::Callbacks
    # @!method before_save
    #   A callback called before the object is saved.
    #   @note This is not related to a Parse beforeSave webhook trigger.
    #   @yield A block to execute for the callback.
    #   @see ActiveModel::Callbacks
    # @!method after_save
    #   A callback called after the object has been successfully saved.
    #   @note This is not related to a Parse afterSave webhook trigger.
    #   @yield A block to execute for the callback.
    #   @see ActiveModel::Callbacks
    # @!method before_destroy
    #   A callback called before the object is about to be deleted.
    #   @note This is not related to a Parse beforeDelete webhook trigger.
    #   @yield A block to execute for the callback.
    #   @see ActiveModel::Callbacks
    # @!method after_destroy
    #   A callback called after the object has been successfully deleted.
    #   @note This is not related to a Parse afterDelete webhook trigger.
    #   @yield A block to execute for the callback.
    #   @see ActiveModel::Callbacks
    # @!endgroup
    define_model_callbacks :create, :save, :destroy, only: [:after, :before]

    attr_accessor :created_at, :updated_at, :acl

    # All Parse Objects have a class-level and instance level `parse_class` method, in which the
    # instance method is a convenience one for the class one. The default value for the parse_class is
    # the name of the ruby class name. Therefore if you have an 'Artist' ruby class, then by default we will assume
    # the remote Parse table is named 'Artist'. You may override this behavior by utilizing the `parse_class(<className>)` method
    # to set it to something different.
    class << self
      attr_accessor :parse_class
      attr_reader :default_acls

      # The class method to override the implicitly assumed Parse collection name
      # in your Parse database. The default Parse collection name is the singular form
      # of the ruby Parse::Object subclass name. The Parse class value should match to
      # the corresponding remote table in your database in order to properly store records and
      # perform queries.
      # @example
      #  class Song < Parse::Object; end;
      #  class Artist < Parse::Object
      #    parse_class "Musician" # remote collection name
      #  end
      #
      #  Parse::User.parse_class # => '_User'
      #  Song.parse_class # => 'Song'
      #  Artist.parse_class # => 'Musician'
      #
      # @param remoteName [String] the name of the remote collection
      # @return [String] the name of the Parse collection for this model.
      def parse_class(remoteName = nil)
        @parse_class ||= model_name.name
        @parse_class = remoteName.to_s unless remoteName.nil?
        @parse_class
      end

      # The set of default ACLs to be applied on newly created instances of this class.
      # By default, public read and write are enabled.
      # @see Parse::ACL.everyone
      # @return [Parse::ACL] the current default ACLs for this class.
      def default_acls
        @default_acls ||= Parse::ACL.everyone # default public read/write
      end

      # A method to set default ACLs to be applied for newly created
      # instances of this class. All subclasses have public read and write enabled
      # by default.
      # @example
      #  class AdminData < Parse::Object
      #
      #    # Disable public read and write
      #    set_default_acl :public, read: false, write: false
      #
      #    # but allow members of the Admin role to read and write
      #    set_default_acl 'Admin', role: true, read: true, write: true
      #
      #  end
      #
      #  data = AdminData.new
      #  data.acl # => ACL({"role:Admin"=>{"read"=>true, "write"=>true}})
      #
      # @param id [String|:public] The name for ACL entry. This can be an objectId, a role name or :public.
      # @param read [Boolean] Whether to allow read permissions (default: false).
      # @param write [Boolean] Whether to allow write permissions (default: false).
      # @param role [Boolean] Whether the `id` argument should be applied as a role name.
      # @see Parse::ACL#apply_role
      # @see Parse::ACL#apply
      # @version 1.7.0
      def set_default_acl(id, read: false, write: false, role: false)
        unless id.present?
          raise ArgumentError, "Invalid argument applying #{self}.default_acls : must be either objectId, role or :public"
        end
        role ? default_acls.apply_role(id, read, write) : default_acls.apply(id, read, write)
      end

      # @!visibility private
      def acl(acls, owner: nil)
        raise "[#{self}.acl DEPRECATED] - Use `#{self}.default_acl` instead."
      end
    end # << self

    # @return [String] the Parse class for this object.
    # @see Parse::Object.parse_class
    def parse_class
      self.class.parse_class
    end

    alias_method :className, :parse_class

    # @return [Hash] the schema structure for this Parse collection from the server.
    # @see Parse::Core::Schema
    def schema
      self.class.schema
    end

    # @return [Hash] a json-hash representing this object.
    def as_json(opts = nil)
      return pointer if pointer?
      changed_fields = changed_attributes
      super(opts).delete_if { |k, v| v.nil? && !changed_fields.has_key?(k) }
    end

    # The main constructor for subclasses. It can take different parameter types
    # including a String and a JSON hash. Assume a `Post` class that inherits
    # from Parse::Object:
    # @note Should only be called with Parse::Object subclasses.
    # @overload new(id)
    #   Create a new object with an objectId. This method is useful for creating
    #   an unfetched object (pointer-state).
    #   @example
    #     Post.new "1234"
    #   @param id [String] The object id.
    # @overload new(hash = {})
    #   Create a new object with Parse JSON hash.
    #   @example
    #    # JSON hash from Parse
    #    Post.new({"className" => "Post", "objectId" => "1234", "title" => "My Title"})
    #
    #    post = Post.new title: "My Title"
    #    post.title # => "My Title"
    #
    #   @param hash [Hash] the hash representing the object
    # @return [Parse::Object] a the corresponding Parse::Object or subclass.
    def initialize(opts = {})
      if opts.is_a?(String) #then it's the objectId
        @id = opts.to_s
      elsif opts.respond_to?(:to_h)
        #if the objectId is provided we will consider the object pristine
        #and not track dirty items
        _attributes = opts.to_h
        dirty_track = _attributes[Parse::Model::OBJECT_ID] || _attributes[:objectId] || _attributes[:id]
        apply_attributes!(_attributes, dirty_track: !dirty_track)
      end

      # if no ACLs, then apply the class default acls
      # ACL.typecast will auto convert of Parse::ACL
      self.acl = self.class.default_acls.as_json if self.acl.nil?

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

    # Existed returns true if the object had existed before *its last save
    # operation*. This method returns false if the {Parse::Object#created_at}
    # and {Parse::Object#updated_at} dates of an object are equal, implyiny this
    # object has been newly created and saved (especially in an afterSave hook).
    #
    # This is a helper method in a webhook afterSave to know
    # if this object was recently saved in the beforeSave webhook. Checking for
    # {Parse::Object#existed?} == false in an afterSave hook, is equivalent to using
    # {Parse::Object#new?} in a beforeSave hook.
    # @note You should not use this method inside a beforeSave webhook.
    # @return [Boolean] true iff the last beforeSave successfully saved this object for the first time.
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
    # It runs all validations for this object. If validation fails,
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
      JSON.pretty_generate(as_json)
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
    # @example
    #   # assume you have defined Post subclass
    #   post = Parse::Object.build({"className" => "Post", "objectId" => '1234'})
    #   post # => #<Post:....>
    #
    #   # if you know the table name
    #   post = Parse::Object.build({"title" => "My Title"}, "Post")
    #   # or
    #   post = Post.build({"title" => "My Title"})
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

    # @!attribute id
    #  @return [String] the value of Parse "objectId" field.
    property :id, field: :objectId

    # @!attribute [r] created_at
    #  @return [Date] the created_at date of the record in UTC Zulu iso 8601 with 3 millisecond format.
    property :created_at, :date

    # @!attribute [r] updated_at
    #  @return [Date] the updated_at date of the record in UTC Zulu iso 8601 with 3 millisecond format.
    property :updated_at, :date

    # @!attribute acl
    #  @return [ACL] the access control list (permissions) object for this record.
    property :acl, :acl, field: :ACL

    # Access the value for a defined property through hash accessor. This method
    # returns nil if the key is not one of the defined properties for this Parse::Object
    # subclass.
    # @param key [String] the name of the property. This key must be in the {fields} hash.
    # @return [Object] the value for this key.
    def [](key)
      return nil unless self.class.fields[key.to_sym].present?
      send(key)
    end

    # Set the value for a specific property through a hash accessor. This method
    # does nothing if key is not one of the defined properties for this Parse::Object
    # subclass.
    # @param key (see Parse::Object#[])
    # @param value [Object] the value to set this property.
    # @return [Object] the value passed in.
    def []=(key, value)
      return unless self.class.fields[key.to_sym].present?
      send("#{key}=", value)
    end
  end
end

class Hash

  # Turns a Parse formatted JSON hash into a Parse-Stack class object, if one is found.
  # This is equivalent to calling `Parse::Object.build` on the hash object itself, but allows
  # for doing this in loops, such as `map` when using symbol to proc. However, you can also use
  # the Array extension `Array#parse_objects` for doing that more safely.
  # @return [Parse::Object] A Parse::Object subclass represented the built class.
  def parse_object
    Parse::Object.build(self)
  end
end

class Array
  # This helper method selects or converts all objects in an array that are either inherit from
  # Parse::Pointer or are a JSON Parse hash. If it is a hash, a Pare::Object will be built from it
  # if it constains the proper fields. Non-convertible objects will be removed.
  # If the className is not contained or known, you can pass a table name as an argument
  # @param className [String] the name of the Parse class if it could not be detected.
  # @return [Array<Parse::Object>] an array of Parse::Object subclasses.
  def parse_objects(className = nil)
    f = Parse::Model::KEY_CLASS_NAME
    map do |m|
      next m if m.is_a?(Parse::Pointer)
      if m.is_a?(Hash) && (m[f] || m[:className] || className)
        next Parse::Object.build m, (m[f] || m[:className] || className)
      end
      nil
    end.compact
  end

  # @return [Array<String>] an array of objectIds for all objects that are Parse::Objects.
  def parse_ids
    parse_objects.map(&:id)
  end
end

# Load all the core classes.
require_relative "classes/installation"
require_relative "classes/product"
require_relative "classes/role"
require_relative "classes/session"
require_relative "classes/user"
