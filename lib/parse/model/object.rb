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
require_relative "associations/belongs_to"
require_relative "associations/has_many"


module Parse
=begin
  This is the core class for all app specific Parse table subclasses. This class
  in herits from Parse::Pointer since an Object is a Parse::Pointer with additional fields,
  at a minimum, created_at, updated_at and ACLs.
  This class also handles all the relational types of associations in a Parse application and
  handles the main CRUD operations.

  Most Pointers and Object subclasses are treated the same. Therefore, defining a class Artist < Parse::Object
  that only has `id` set, will be treated as a pointer. Therefore a Parse::Object can be in a "pointer" state
  based on the data that it contains. Becasue of this, it is possible to take a Artist instance
  (in this example), that is in a pointer state, and fetch the rest of the data for that particular
  record without having to create a new object. Doing so would now mark it as not being a pointer anymore.
  This is important to the understanding on how relations and properties are handled.

  The implementation of this class is large and has been broken up into several modules.

  Properties:
  All columns in a Parse object are considered a type of property (ex. string, numbers, arrays, etc)
  except in two cases - Pointers and Relations. For the list of basic supported data types, please see the
  Properties module variable Parse::Properties::TYPES . When defining a property,
  dynamic methods are created that take advantage of all the ActiveModel
  plugins (dirty tracking, callbacks, json, etc).

  Associations (BelongsTo):
  This module adds support for creating an association between one object to another using a
  Parse object pointer. By defining a belongs_to relationship in a specific class, it implies
  that the remote Parse table contains a local column, which has a pointer, referring to another
  Parse table.

  Associations (HasMany):
  In Parse there are two ways to deal with one-to-many and many-to-many relationships
  One is through an array of pointers (which is recommended to be less than 100) and
  through an intermediary table called a Relation (or a Join table in other languages.)
  The way Parse::Objects treat these associations different from defining a :property of array type, is
  by making sure items in the array as of a particular class cast type.

  Querying:
  The querying module provides all the general methods to be able to find and query a specific
  Parse table.

  Fetching:
  The fetching modules supports fetching data from Parse (depending on the state of the object),
  and providing some autofetching features when traversing relational objects and properties.

  Schema:
  The schema module provides methods to modify the Parse table remotely to either add or create
  any locally define properties in ruby and have those be reflected in the Parse application.

=end

  def self.registered_classes
      Parse::Object.descendants.map { |m| m.parse_class }.uniq
  end

  # Find a corresponding class for this string or symbol
  def self.classify(className)
    Parse::Model.find_class className.to_parse_class
  end

  class Object < Pointer
    include Properties
    include Associations::BelongsTo
    include Associations::HasMany
    include Querying
    include Fetching
    include Actions
    include Schema

    def __type; Parse::Model::TYPE_OBJECT; end;
    # These define callbacks
    define_model_callbacks :save, :destroy
    #core attributes. In general these should be treated as read_only, but the
    # setters are available since we will be decoding objects from Parse. The :acl
    # type is documented in its own class file.
    attr_accessor :created_at, :updated_at, :acl

    # All Parse Objects have a class-level and instance level `parse_class` method, in which the
    # instance method is a convenience one for the class one. The default value for the parse_class is
    # the name of the ruby class name. Therefore if you have an 'Artist' ruby class, then by default we will assume
    # the remote Parse table is named 'Artist'. You may override this behavior by utilizing the `parse_class(<className>)` method
    # to set it to something different.
    class << self
      attr_accessor :disable_serialized_string_date
      attr_accessor :parse_class, :acl
      def parse_class(c = nil)
        @parse_class ||= model_name.name
        unless c.nil?
          @parse_class = c.to_s
        end
        @parse_class
      end
       #this provides basic ACLs for the specific class. Each class can change the default
       # ACLs set on their instance objects.
      def acl(acls = {}, owner: nil)
        acls = {"*" => {read: true, write: false} }.merge( acls ).symbolize_keys
        @acl ||= Parse::ACL.new(acls, owner: owner)
      end

    end

    def parse_class
      self.class.parse_class
    end
    alias_method :className, :parse_class

    def as_json(*args)
      pointer? ? pointer : super(*args)
    end

    def initialize(opts = {})
      if opts.is_a?(String) #then it's the objectId
        @id = opts.to_s
      elsif opts.is_a?(Hash)
        #if the objectId is provided we will consider the object pristine
        #and not track dirty items
        dirty_track = opts["objectId".freeze] || opts[:objectId] || opts[:id]
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

    def apply_defaults!
      self.class.defaults_list.each do |key|
        send(key) # should call set default proc/values if nil
      end
    end

    def self.pointer(id)
      return nil if id.nil?
      Parse::Pointer.new self.parse_class, id
    end

    # determines if this object has been saved to parse. If an object has
    # pending changes, then it is considered to not yet be persisted. This is true of
    # new objects as well.
    def persisted?
      changed? == false && !(@id.nil? || @created_at.nil? || @updated_at.nil? || @acl.nil?)
    end

    # force reload and replace any local fields with data from the persistent store
    def reload!
    # get the values from the persistence layer
      fetch!
      clear_changes!
    end

    # clears all dirty tracking information
    def clear_changes!
      clear_changes_information
    end

    # an object is considered new if it has no id
    def new?
      @id.blank?
    end

    # Existed returns true/false depending whether the object
    # had existed before its last save operation.
    def existed?
      if @id.blank? || @created_at.blank? || @updated_at.blank?
        return false
      end
      created_at != updated_at
    end

    # returns a hash of all the changes that have been made to the object. By default
    # changes to the Parse::Properties::BASE_KEYS are ignored unless you pass true as
    # an argument.
    def updates(include_all = false)
      h = {}
      changed.each do |key|
        next if include_all == false && Parse::Properties::BASE_KEYS.include?(key.to_sym)
        # lookup the remote Parse field name incase it is different from the local attribute name
        remote_field = self.field_map[key.to_sym] || key
        h[remote_field] = send key
        # make an exception to Parse::Objects, we should return a pointer to them instead
        h[remote_field] = h[remote_field].pointer if h[remote_field].respond_to?(:pointer)
      end
      h
    end

    # restores the previous state of the object (discards changes, but not from the persistent store)
    def rollback!
      restore_attributes
    end

    # Returns a twin copy of the object without the objectId
    def twin
      h = self.as_json
      h.delete("objectId")
      h.delete(:objectId)
      h.delete(:id)
      self.class.new h
    end

    def pretty
      JSON.pretty_generate( as_json )
    end

    def clear_attribute_change!(atts)
      clear_attribute_changes(atts)
    end

    # Method used for decoding JSON objects into their corresponding Object subclasses.
    # The first parameter is a hash containing the object data and the second parameter is the
    # name of the table / class if it is known. If it is not known, we we try and determine it
    # by checking the "className" or :className entries in the hash. If an Parse class object hash
    # is encoutered for which we don't have a corresponding Parse::Object subclass for, a Parse::Pointer
    # will be returned instead.
    def self.build(json, table = nil)
      className = table
      className ||= (json["className"] || json[:className]) if json.is_a?(Hash)
      if json.is_a?(Hash) && json["error"].present? && json["code"].present?
        warn "[Parse::Object] Detected object hash with 'error' and 'code' set. : #{json}"
      end
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
        o = Parse::Pointer.new className, (json["objectId"] || json[:objectId])
      end
      return o
    # rescue NameError => e
    #   puts "Parse::Object.build constant class error: #{e}"
    # rescue Exception => e
    #   puts "Parse::Object.build error: #{e}"
    end

    # Set default base properties of any Parse::Object
    property :id, field: :objectId
    property :created_at, :date
    property :updated_at, :date
    property :acl, :acl, field: :ACL

    # TODO: Hack since Parse createdAt and updatedAt dates have to be returned as strings
    # in UTC Zulu iso 8601 with 3 millisecond format.
    def createdAt
      return @created_at if Parse::Object.disable_serialized_string_date.present?
      @created_at.to_time.utc.iso8601(3) if @created_at.present?
    end

    def updatedAt
      return @updated_at if Parse::Object.disable_serialized_string_date.present?
      @updated_at.to_time.utc.iso8601(3) if @updated_at.present?
    end



  end

  # The User class provided by Parse with the required fields. You may
  # add mixings to this class to add the app specific properties
  class User < Parse::Object
    parse_class "_User".freeze
    property :auth_data, :object
    property :email
    property :password
    property :username

    before_save do
      # You cannot specify user ACLs.
      self.clear_attribute_change!(:acl)
    end

    def anonymous?
      auth_data.present? && auth_data["anonymous"].present?
    end
  end

  class Installation < Parse::Object
    parse_class "_Installation".freeze

    property :gcm_sender_id, :string, field: :GCMSenderId
    property :app_identifier
    property :app_name
    property :app_version
    property :badge, :integer
    property :channels, :array
    property :device_token
    property :device_token_last_modified, :integer
    property :device_type
    property :installation_id
    property :locale_identifier
    property :parse_version
    property :push_type
    property :time_zone

  end

  class Role < Parse::Object
    parse_class "_Role".freeze
    property :name

    has_many :roles, through: :relation
    has_many :users, through: :relation

    def update_acl
      acl.everyone true, false
    end

    before_save do
      update_acl
    end
  end

  class Session < Parse::Object
    parse_class "_Session".freeze
    property :created_with, :object
    property :expires_at, :date
    property :installation_id
    property :restricted, :boolean
    property :session_token

    belongs_to :user
  end

end


class Array
  # This helper method selects all objects in an array that are either inherit from
  # Parse::Pointer or are a hash. If it is a hash, a Pare::Object will be built from it
  # if it constains the proper fields. Non convertible objects will be removed
  # If the className is not contained or known, you can pass a table name as an argument
  def parse_objects(table = nil)
    f = "className".freeze
    map do |m|
      next m if m.is_a?(Parse::Pointer)
      if m.is_a?(Hash) && (m[f] || m[:className] || table)
        next Parse::Object.build m, (m[f] || m[:className] || table)
      end
      nil
    end.compact
  end

  def parse_ids
    parse_objects.map { |d| d.id }
  end

end
