require 'active_model'
require 'active_support/inflector'
require 'active_model_serializers'
require 'time'

=begin
This module provides support for handling all the different types of column data types
supported in Parse and mapping them between their remote names with their local ruby named attributes.
By default, the convention used for naming parameters is that the remote column should be in lower-first-camelcase, (ex. myField, eventAddress), except for
a few special columns like "id" and "acl".
Properties are defined when creating subclasses of Parse::Object and using the `property` class method.

By defining properties, dynamic methods are created in order to allow getters and setters to be used. We will go into detail below.

Each class will have a different copy of attribute mapping and field mappings.
=end

module Parse

  module Properties
    # This is an exception that is thrown if there is an issue when creating a specific property for a class.
    class DefinitionError < Exception; end;

    # These are the base types supported by Parse.
    TYPES = [:id, :string, :relation, :integer, :float, :boolean, :date, :array, :file, :geopoint, :bytes, :object, :acl].freeze
    # These are the base mappings of the remote field name types.
    BASE = {objectId: :string, createdAt: :date, updatedAt: :date, ACL: :acl}.freeze
    # The list of properties that are part of all objects
    BASE_KEYS = [:id, :created_at, :updated_at].freeze
    # Default hash map of local attribute name to remote column name
    BASE_FIELD_MAP = {id: :objectId, created_at: :createdAt, updated_at: :updatedAt, acl: :ACL}.freeze

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      # The fields method returns a mapping of all local attribute names and their data type.
      # if type is passed, we return only the fields that matched that data type
      def fields(type = nil)
        @fields ||= {id: :string, created_at: :date, updated_at: :date, acl: :acl}
        if type.present?
          type = type.to_sym
          return @fields.select { |k,v| v == type }
        end
        @fields
      end

      # This returns the mapping of local to remote attribute names.
      def field_map
        @field_map ||= BASE_FIELD_MAP.dup
      end

      # Keeps track of all the attributes supported by this class.
      def attributes=(hash)
        @attributes = BASE.merge(hash)
      end

      def attributes
        @attributes ||= BASE.dup
      end

      # property :songs, :array
      # property :my_date, :date, field: "myRemoteCOLUMNName"
      # property :my_int, :integer, required: true, default: ->{ rand(10) }

      # field: (literal column name in Parse)
      # required: (data_type)
      # default: (value or Proc)
      # alias: Whether to create the remote field alias getter/setters for this attribute
      # This is the class level property method to be used when declaring properties. This helps builds specific methods, formatters
      # and conversion handlers for property storing and saving data for a particular parse class.
      # The first parameter is the name of the local attribute you want to declare with its corresponding data type.
      # Declaring a `property :my_date, :date`, would declare the attribute my_date with a corresponding remote column called
      # "myDate" (lower-first-camelcase) with a Parse data type of Date.
      # You can override the implicit naming behavior by passing the option :field to override.

      # symbolize: Makes sure the saved and return value locally is in symbol format. useful
      # for enum type fields that are string columns in Parse. Ex. a booking_status for a field
      # could be either "submitted" or "completed" in Parse, however with symbolize, these would
      # be available as :submitted or :completed.
      def property(key, data_type = :string, opts = {})

        key = key.to_sym

        if data_type.is_a?(Hash)
          opts.merge!(data_type)
          data_type = :string
        end
        # set defaults
        opts = { required: false,
                 alias: true,
                 symbolize: false,
                 field: key.to_s.camelize(:lower)
               }.merge( opts )
        #By default, the remote field name is a lower-first-camelcase version of the key
        # it can be overriden by the :field parameter
        parse_field = opts[:field].to_sym
        if self.fields[key].present? && BASE_FIELD_MAP[key].nil?
          raise DefinitionError, "Property #{self}##{key} already defined with data type #{data_type}"
        end
        # We keep the list of fields that are on the remote Parse store
        if self.fields[parse_field].present?
          raise DefinitionError, "Alias property #{self}##{parse_field} conflicts with previously defined property."
        end
        #dirty tracking. It is declared to use with ActiveModel DirtyTracking
        define_attribute_methods key

        # this hash keeps list of attributes (based on remote fields) and their data types
        self.attributes.merge!( parse_field => data_type )
        # this maps all the possible attribute fields and their data types. We use both local
        # keys and remote keys because when we receive a remote object that has the remote field name
        # we need to know what the data type conversion should be.
        self.fields.merge!( key => data_type, parse_field => data_type )
        # This creates a mapping between the local field and the remote field name.
        self.field_map.merge!( key => parse_field )
        #puts "Current Self: #{self} - #{key} = #{self.attributes}"
        # if the field is marked as required, then add validations
        if opts[:required]
          # if integer or float, validate that it's a number
          if data_type == :integer || data_type == :float
            validates_numericality_of key
          end
          # validate that it is not empty
          validates_presence_of key
        end

        # get the default value if provided (or Proc)
        default_value = opts[:default]
        symbolize_value = opts[:symbolize]
        #only support symbolization of string data types
        if symbolize_value && data_type != :string
          raise 'Symbolization is only supported on :string data types.'
        end

        # Here is the where the 'magic' begins. For each property defined, we will
        # generate special setters and getters that will take advantage of ActiveModel
        # helpers.

        # We define a getter with the key
        define_method(key) do

          # we will get the value using the internal value of the instance variable
          # using the instance_variable_get
          ivar = :"@#{key}"
          value = instance_variable_get ivar

          # If the value is nil and this current Parse::Object instance is a pointer?
          # then someone is calling the getter for this, which means they probably want
          # its value - so let's go turn this pointer into a full object record
          if value.nil? && pointer?
            # call autofetch to fetch the entire record
            # and then get the ivar again cause it might have been updated.
            autofetch!(key)
            value = instance_variable_get ivar
          end

          # if value is nil (even after fetching), then lets see if the developer
          # set a default value for this attribute.
          if value.nil? && default_value.present?
            # If the default object provided is a Proc, then run the proc, otherwise
            # we'll assume it's just a plain literal value
             value = default_value.is_a?(Proc) ? default_value.call : default_value
            # lets set the variable with the updated value
             instance_variable_set ivar, value
             send "#{key}_will_change!"
          end

          # if the value is a String (like an iso8601 date) and the data type of
          # this object is :date, then let's be nice and create a parse date for it.
          if value.is_a?(String) && data_type == :date
            value = Parse::Date.parse value
            instance_variable_set ivar, value
            send "#{key}_will_change!"
          end
          # finally return the value
          symbolize_value && value.respond_to?(:to_sym) ? value.to_sym : value
        end

        # The second method to be defined is a setter method. This is done by
        # defining :key with a '=' sign. However, to support setting the attribute
        # with and without dirty tracking, we really will just proxy it to another method

        define_method("#{key}=") do |val|
          #we proxy the method passing the value and true. Passing true to the
          # method tells it to make sure dirty tracking is enabled.
          self.send "#{key}_set_attribute!", val, true
        end

        # This is the real setter method. Takes two arguments, the value to set
        # and whether to mark it as dirty tracked.
        define_method("#{key}_set_attribute!") do |val, track = true|
          # Each value has a data type, based on that we can treat the incoming
          # value as input, and format it to the correct storage format. This method is
          # defined in this file (instance method)
          val = format_value(key, val, data_type)
          # if dirty trackin is enabled, call the ActiveModel required method of _will_change!
          # this will grab the current value and keep a copy of it - but we only do this if
          # the new value being set is different from the current value stored.
          if track == true
            send :"#{key}_will_change!" unless val == instance_variable_get( :"@#{key}" )
          end
          if symbolize_value && data_type == :string
            val = nil if val.blank?
            val = val.to_sym if val.respond_to?(:to_sym)
          end
          # now set the instance value
          instance_variable_set :"@#{key}", val
        end

        # The core methods above support all attributes with the base local :key parameter
        # however, for ease of use and to handle that the incoming fields from parse have different
        # names, we will alias all those methods defined above with the defined parse_field.
        # if both the local name matches the calculated/provided remote column name, don't create
        # an alias method since it is the same thing. Ex. attribute 'username' would probably have the
        # remote column name also called 'username'.
        return if parse_field == key

        # we will now create the aliases, however if the method is already defined
        # we warn the user unless the field is :objectId since we are in charge of that one.
        # this is because it is possible they want to override. You can turn off this
        # behavior by passing false to :alias

        if self.method_defined?(parse_field) == false && opts[:alias]
          alias_method parse_field, key
          alias_method "#{parse_field}=", "#{key}="
          alias_method "#{parse_field}_set_attribute!", "#{key}_set_attribute!"
        elsif parse_field.to_sym != :objectId
          warn "Alias property method #{self}##{parse_field} already defined."
        end

      end # property

    end #ClassMethods

    # returns the class level stored field map
    def field_map
      self.class.field_map
    end

    # returns the list of fields
    def fields(type = nil)
      self.class.fields(type)
    end

    def attributes
      {__type: :string, :className => :string}.merge!(self.class.attributes)
    end

    # support for setting a hash of attributes on the object with a given dirty tracking value
    # if dirty_track: is set to false (default), attributes are set without dirty tracking.
    def apply_attributes!(hash, dirty_track: false)
      return unless hash.is_a?(Hash)

      @id ||= hash["id"] || hash["objectId"]
      hash.each do |key, value|
        method = "#{key}_set_attribute!"
        send(method, value, dirty_track) if respond_to?( method )
      end
    end

    # applies a hash of attributes overriding any current value the object has for those
    # attributes
    def attributes=(hash)
      return unless hash.is_a?(Hash)
      # - [:id, :objectId]
      # only overwrite @id if it hasn't been set.
      apply_attributes!(hash, dirty_track: true)
    end

    # returns a hash of attributes (and their new values) that had been changed.
    # This will not include any of the base attributes (ex. id, created_at, etc)
    # If true is passed as an argument, then all attributes will be included.
    # This method is useful for generating an update hash for the Parse PUT API
    # TODO: Replace this algorithm with reduce()
    def attribute_updates(include_all = false)
      h = {}
      changed.each do |key|
        key = key.to_sym
        next if include_all == false && Parse::Properties::BASE_KEYS.include?(key)
        next unless fields[key].present?
        remote_field = self.field_map[key] || key
        h[remote_field] = send key
        h[remote_field] = {__op: :Delete} if h[remote_field].nil?
        # in the case that the field is a Parse object, generate a pointer
        h[remote_field] = h[remote_field].pointer if h[remote_field].respond_to?(:pointer)
      end
      h
    end

    # determines if any of the attributes have changed.
    def attribute_changes?
      changed.any? do |key|
        fields[key.to_sym].present?
      end
    end

    def format_operation(key, val, data_type)
      return val unless val.is_a?(Hash) && val["__op"].present?
      op = val["__op"]
      #handles delete case otherwise 'null' shows up in column
      if "Delete" == op
        val = nil
      elsif "Add" == op && data_type == :array
        val = (instance_variable_get(:"@#{key}") || []).to_a + (val["objects"] || [])
      elsif "Remove" == op && data_type == :array
        val = (instance_variable_get(:"@#{key}") || []).to_a - (val["objects"] || [])
      elsif "AddUnique" == op && data_type == :array
        objects = (val["objects"] || []).uniq
        original_items = (instance_variable_get(:"@#{key}") || []).to_a
        objects.reject! { |r| original_items.include?(r) }
        val = original_items + objects
      elsif "Increment" == op && data_type == :integer || data_type == :integer
        # for operations that increment by a certain amount, they come as a hash
        val = (instance_variable_get(:"@#{key}") || 0) + (val["amount"] || 0).to_i
      end
      val
    end

    # this method takes an input value and transforms it to the proper local format
    # depending on the data type that was set for a particular property key.
    def format_value(key, val, data_type = nil)
      # if data_type wasn't passed, then get the data_type from the fields hash
      data_type ||= self.fields[key]

      val = format_operation(key, val, data_type)

      case data_type
      when :object
        val = val #should be regular hash, maybe in the future we return hashie?
      when :array
        # All "array" types use a collection proxy
        val = [val] unless val.is_a?(Array) #all objects must be in array form
        val.compact! #remove any nil
        val = Parse::CollectionProxy.new val, delegate: self, key: key
      when :geopoint
        val = Parse::GeoPoint.new(val) unless val.blank?
      when :file
        val = Parse::File.new(val) unless val.blank?
      when :bytes
        val = Parse::Bytes.new(val) unless val.blank?
      when :integer
        val = val.to_i unless val.blank?
      when :boolean
        val = val ? true : false
      when :string
        val = val.to_s unless val.blank?
      when :float
        val = val.to_f unless val.blank?
      when :acl
        # ACL types go through a special conversion
          val = ACL.typecast(val, self)
      when :date
        # if it respond to parse_date, then use that as the conversion.
        if val.respond_to?(:parse_date)
          val = val.parse_date
          # if the value is a hash, then it may be the Parse hash format for an iso date.
        elsif val.is_a?(Hash) # val.respond_to?(:iso8601)
          val = Parse::Date.parse(val["iso".freeze] || val[:iso])
        elsif val.is_a?(String)
          # if it's a string, try parsing the date
          val = Parse::Date.parse val
        end
      else
        # You can provide a specific class instead of a symbol format
        if data_type.respond_to?(:typecast)
          val = data_type.typecast(val)
        else
          warn "Property :#{key}: :#{data_type} has not valid data type"
          val = val #default
        end
      end
      val
    end

  end # Properties

end # Parse
