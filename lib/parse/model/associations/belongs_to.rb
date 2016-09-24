# encoding: UTF-8
# frozen_string_literal: true

require_relative '../pointer'
require_relative 'collection_proxy'
require_relative 'pointer_collection_proxy'
require_relative 'relation_collection_proxy'

# BelongsTo relation is the simplies association in which the local
# table constains a column that points to a foreign table record using
# a given Parse Pointer. The key of the property is implied to be the
# name of the class/parse table that contains the foreign associated record.
# All belongs to relationship column types have the special data type of :pointer.
module Parse
  module Associations

    module BelongsTo

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        attr_accessor :references
        # We can keep references to all "belong_to" properties
        def references
          @references ||= {}
        end

        # belongs_to :featured_song, as: :song, field: :featuredSong, through: :reference
        # belongs_to :artist
        # belongs_to :manager, as: :user
        # These items are added as attributes with the special data type of :pointer
        def belongs_to(key, opts = {})
          opts = {as: key, field: key.to_s.camelize(:lower), required: false}.merge(opts)
          klassName = opts[:as].to_parse_class
          parse_field = opts[:field].to_sym

          ivar = :"@#{key}"
          will_change_method = :"#{key}_will_change!"
          set_attribute_method = :"#{key}_set_attribute!"

          if self.fields[key].present? && Parse::Properties::BASE_FIELD_MAP[key].nil?
            raise Parse::Properties::DefinitionError, "Belongs relation #{self}##{key} already defined with type #{klassName}"
          end
          if self.fields[parse_field].present?
            raise Parse::Properties::DefinitionError, "Alias belongs_to #{self}##{parse_field} conflicts with previously defined property."
          end
          # store this attribute in the attributes hash with the proper remote column name.
          # we know the type is pointer.
          self.attributes.merge!( parse_field => :pointer )
          # Add them to our list of pointer references
          self.references.merge!( parse_field => klassName )
          # Add them to the list of fields in our class model
          self.fields.merge!( key => :pointer, parse_field => :pointer )
          # Mapping between local attribute name and the remote column name
          self.field_map.merge!( key => parse_field )

          # used for dirty tracking
          define_attribute_methods key

          # validations
          validates_presence_of(key) if opts[:required]

          # We generate the getter method
          define_method(key) do

            val = instance_variable_get ivar
            # We provide autofetch functionality. If the value is nil and the
            # current Parse::Object is a pointer, then let's auto fetch it
            if val.nil? && pointer?
              autofetch!(key)
              val = instance_variable_get ivar
            end

            # if for some reason we retrieved either from store or fetching a
            # hash, lets try to buid a Pointer of that type.

            if val.is_a?(Hash) && ( val["__type"] == "Pointer" ||  val["__type"] == "Object" )
              val = Parse::Object.build val, ( val["className"] || klassName )
              instance_variable_set ivar, val
            end
            val
          end

          define_method("#{key}?") do
            self.send(key).is_a?(Parse::Pointer)
          end

          # A proxy setter method that has dirty tracking enabled.
          define_method("#{key}=") do |val|
            send set_attribute_method, val, true
          end

          # We only support pointers, either by object or by transforming a hash.
          define_method(set_attribute_method) do |val, track = true|
            if val == Parse::Properties::DELETE_OP
              val = nil
            elsif val.is_a?(Hash) && ( val["__type"] == "Pointer" ||  val["__type"] == "Object" )
              val = Parse::Object.build val, ( val["className"] || klassName )
            end

            if track == true
              send will_change_method unless val == instance_variable_get( ivar )
            end

            # Never set an object that is not a Parse::Pointer
            if val.nil? || val.is_a?(Parse::Pointer)
              instance_variable_set(ivar, val)
            else
              warn "[#{self.class}] Invalid value #{val} set for belongs_to field #{key}"
            end

          end
          # don't create method aliases if the fields are the same
          return if parse_field.to_sym == key.to_sym

          if self.method_defined?(parse_field) == false
            alias_method parse_field, key
            alias_method "#{parse_field}=", "#{key}="
            alias_method "#{parse_field}_set_attribute!", set_attribute_method
          elsif parse_field.to_sym != :objectId
            warn "Alias belongs_to method #{self}##{parse_field} already defined."
          end

        end

      end # ClassMethod

    end #BelongsTo
  end #Associations

end
