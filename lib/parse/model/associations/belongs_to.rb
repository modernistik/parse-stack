# encoding: UTF-8
# frozen_string_literal: true

require_relative '../pointer'
require_relative 'collection_proxy'
require_relative 'pointer_collection_proxy'
require_relative 'relation_collection_proxy'


module Parse
  # Defines all the types of Parse object associations.
  module Associations
    # This association creates a one-to-one association with another Parse model.
    # BelongsTo relation is the simplies association in which the local
    # Parse table constains a column that has a Parse::Pointer to a foreign table record.
    #
    # This association says that this class contains a foreign pointer column
    # which references a different class. Utilizing the `belongs_to` method in
    # defining a property in a Parse::Object subclass sets up an association
    # between the local table and a foreign table. Specifying the `belongs_to`
    # in the class, tells the framework that the Parse table contains a local
    # column in its schema that has a reference to a record in a foreign table.
    # The argument to `belongs_to` should be the singularized version of the
    # foreign Parse::Object class. you should specify the foreign table as the
    # snake_case singularized version of the foreign table class.
    #
    # Note that the reverse relationship on the foreign class is not generated automatically.
    # You can use a `has_one` on the foreign model to create it.
    # @example
    #  class Author < Parse::Object
    #  	property :name
    #  end
    #
    #
    #  class Post < Parse::Object
    #  	belongs_to :author
    #  end
    #
    #  Post.references # => {:author=>"Author"}
    #
    #  post = Post.first
    #  post.author? # => true if has a pointer
    #
    #  # Follow the author pointer and get name
    #  post.author.name
    #
    #  other_author = Author.first
    #  # change author by setting new pointer
    #  post.author = other_author
    #  post.save
    #
    # @see Parse::Associations::HasOne
    # @see Parse::Associations::HasMany
    module BelongsTo

      # @!attribute [rw] self.references
      #  A hash mapping of all belongs_to associations for this model.
      #  @return [Hash]

      # @!method self.belongs_to(key, opts = {})
      # Creates a one-to-one association with another Parse model.
      # @param [Symbol] key The singularized version of the foreign class and the name of the
      #   local column in the remote Parse table where the pointer is stored.
      # @option opts [Symbol] :field override the name of the remote column
      #  where the pointer is stored. By default this is inferred as
      #  the columnized of the key parameter.
      # @option opts [Symbol] :as override the inferred Parse::Object subclass.
      #  By default this is inferred as the singularized camel case version of
      #  the key parameter. This option allows you to override the typecast of
      #  foreign Parse model of the association, while allowing you to have a
      #  different accessor name.
      # @option opts [Boolean] :required Setting to `true`, automatically creates
      #   an ActiveModel validation of `validates_presence_of` for the
      #   association. This will not prevent the save, but affects the validation
      #   check when `valid?` is called on an instance. Default is false.
      # @example
      #  # Assumes 'Artist' is foreign class.
      #  belongs_to :artist
      #
      #  # uses Parse::User as foreign class
      #  belongs_to :manager, as: :user
      #
      #  # sets attribute name to `featured_song` for foreign class Song with the remote
      #  # column name in Parse as 'theFeaturedSong'.
      #  belongs_to :featured_song, as: :song, field: :theFeaturedSong
      #
      # @see String#columnize
      # @see #key?
      # @return [Parse::Object] a Parse::Object subclass when using the accessor
      #  when fetching the association.

      # @!method key?
      # A dynamically generated method based on the value of `key` passed to the
      # belongs_to method, which returns true if this instance has a pointer for
      # this field.
      # @example
      #
      #  class Post < Parse::Object
      #  	belongs_to :author # generates 'author?'
      #  end
      #
      #  post = Post.new
      #  post.author? # => false
      #  post.author = Author.new
      #  post.author? # => true
      # @return [Boolean] true if field contains a Parse::Pointer or subclass.

      # @!visibility private
      def self.included(base)
        base.extend(ClassMethods)
      end

      # @!visibility private
      module ClassMethods
        attr_accessor :references
        # We can keep references to all "belong_to" properties
        def references
          @references ||= {}
        end

        # These items are added as attributes with the special data type of :pointer
        def belongs_to(key, opts = {})
          opts = {as: key, field: key.to_s.camelize(:lower), required: false}.merge(opts)
          klassName = opts[:as].to_parse_class
          parse_field = opts[:field].to_sym

          ivar = :"@#{key}"
          will_change_method = :"#{key}_will_change!"
          set_attribute_method = :"#{key}_set_attribute!"

          if self.fields[key].present? && Parse::Properties::BASE_FIELD_MAP[key].nil?
            warn "Belongs relation #{self}##{key} already defined with type #{klassName}"
            return false
          end
          if self.fields[parse_field].present?
            warn "Alias belongs_to #{self}##{parse_field} conflicts with previously defined property."
            return false
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
              val = Parse::Object.build val, ( val[Parse::Model::KEY_CLASS_NAME] || klassName )
              instance_variable_set ivar, val
            end
            val
          end

          if self.method_defined?("#{key}?")
            warn "Creating belongs_to helper :#{key}?. Will overwrite existing method #{self}##{key}?."
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
              val = Parse::Object.build val, ( val[Parse::Model::KEY_CLASS_NAME] || klassName )
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
