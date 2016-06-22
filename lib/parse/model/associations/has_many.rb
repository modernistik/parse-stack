require_relative '../pointer'
require_relative 'collection_proxy'
require_relative 'pointer_collection_proxy'
require_relative 'relation_collection_proxy'

module Parse

  module Associations

    # This module provides has_many functionality to defining Parse::Object classes.
    # There are two main types of a has_many association - array and relation.
    # A has_many array relation, uses a PointerCollectionProxy to store a list of Parse::Object (or pointers)
    # that are stored in the column of the local table. This means we expect a the remote Parse table to contain
    # a column of type array which would contain a set of hash-like Pointers.
    # In the relation case, the object's Parse table has a column, but it points to a separate
    # relational table (join table) which maps both the local class and the foreign class. In this case
    # the type of the column is of "Relation" with a specific class name. This then means that it contains a set of
    # object Ids that we will treat as being part of the foreign table.
    # Ex. If a Artist defines a has_many relation to a Song class through a column called 'favoriteSongs'.
    # Then the Parse type of the favoriteSongs column, contained in the Artist table,
    # would be Relation<Song>. Any objectIds listed in that relation would then
    # be Song object Ids.
    # One thing to note is that when querying relations, the foreign table is the one that needs to be
    # queried in order to retrive the associated object to the local object. For example,
    # if an Artist has a relation to many Song objects, and we wanted to get the list of songs
    # this artist is related to, we would query the Song table passing the specific artist record
    # we are constraining to.
    module HasMany
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        attr_accessor :relations
        def relations
          @relations ||= {}
        end
        # Examples:
        # has_many :fans, as: :users, through: :relation, field: "awesomeFans"
        # has_many :songs
        # has_many :likes, as: :users, through: :relation
        # has_many :artists, field: "managedArtists"
        # The first item in the has_many is the name of the local attribute. This will create
        # several methods for accessing the relation type. By default, the remote column name
        # relating to this attribute will be the lower-first-camelcase version of this key.
        # Ex. a relation to :my_songs, would imply that the remote column name is "mySongs". This behavior
        # can be overriden by using the field: option and passing the literal field name in the Parse table.
        # This allows you to use a local attribute name while still having a different remote column name.
        # Since these types of collections are of a particular "type", we will assume that the name of the
        # key is the plural version of the name of the local camelized-named class. Ex. If the property is named :songs, then
        # we will assume there is a local class name defined as 'Song'. This can be overriden by using the as: parameter.
        # This allows you to name your local attribute differently to what the responsible class for this association.
        # Ex. You could define a has_many :favorite_songs property that points to the User class by using the 'as: :songs'. This would
        # imply that the instance object has a set of Song objects through the attribute :favorite_songs.
        # By default, all associations are stored in 'through: :array' form. If you are working with a Parse Relation, you
        # should specify the 'through: :relation' property instead. This will switch the internal storage mechanisms
        # from using a PointerCollectionProxy to a RelationCollectionProxy.

        def has_many(key, opts = {})
          opts = {through: :array,
                  field: key.to_s.camelize(:lower),
                  required: false,
                  as: key}.merge(opts)

          klassName = opts[:as].to_parse_class singularize: true
          parse_field = opts[:field].to_sym
          access_type = opts[:through].to_sym
          # verify that the user did not duplicate properties or defined different properties with the same name
          if self.fields[key].present? && Parse::Properties::BASE_FIELD_MAP[key].nil?
            raise Parse::Properties::DefinitionError, "Has_many property #{self}##{key} already defined with type #{klassName}"
          end
          if self.fields[parse_field].present?
            raise Parse::Properties::DefinitionError, "Alias has_many #{self}##{parse_field} conflicts with previously defined property."
          end
          # validations
          validates_presence_of(key) if opts[:required]

          # default proxy class.
          proxyKlass = Parse::PointerCollectionProxy

          #if this is a relation type, use this proxy instead. Relations are stored
          # in the relations hash. If a PointerCollectionProxy is used, we store those
          # as we would normal properties.
          if access_type == :relation
            proxyKlass = Parse::RelationCollectionProxy
            self.relations[key] = klassName
          else
            self.attributes.merge!( parse_field => :array )
            # Add them to the list of fields in our class model
            self.fields.merge!( key => :array, parse_field => :array )
          end

          self.field_map.merge!( key => parse_field )
          # dirty tracking
          define_attribute_methods key

          # The first method to be defined is a getter.
          define_method(key) do
            ivar = :"@#{key}"
            val = instance_variable_get(ivar)
            # if the value for this is nil and we are a pointer, then autofetch
            if val.nil? && pointer?
              autofetch!(key)
              val = instance_variable_get ivar
            end

            # if the result is not a collection proxy, then create a new one.
            unless val.is_a?(Parse::PointerCollectionProxy)
              results = []
              #results = val.parse_objects if val.respond_to?(:parse_objects)
              val = proxyKlass.new results, delegate: self, key: key
              instance_variable_set(ivar, val)
            end
            val
          end

          # proxy setter that forwards with dirty tracking
          define_method("#{key}=") do |val|
              send "#{key}_set_attribute!", val, true
          end

          # This will set the content of the proxy.
          define_method("#{key}_set_attribute!") do |val, track = true|
            # If it is a hash, with a __type of Relation, createa a new RelationCollectionProxy, regardless
            # of what is defined because we must have gotten this from Parse.

            # if val is nil or it is the delete operation, then set to empty array.
            # this will create a new proxyKlass later on
            if val.nil? || val == Parse::Properties::DELETE_OP
              val = []
            end

            if val.is_a?(Hash) && val["__type"] == "Relation"
              relation_objects = val["objects"] || []
              val = Parse::RelationCollectionProxy.new relation_objects, delegate: self, key: key, parse_class: (val["className"] || klassName)
            elsif val.is_a?(Hash) && val["__op"] == "AddRelation" && val["objects"].present?
              _collection = proxyKlass.new [], delegate: self, key: key, parse_class: (val["className"] || klassName)
              _collection.loaded = true
              _collection.add val["objects"].parse_objects
              val = _collection
            elsif val.is_a?(Hash) && val["__op"] == "RemoveRelation" && val["objects"].present?
              _collection = proxyKlass.new [], delegate: self, key: key, parse_class: (val["className"] || klassName)
              _collection.loaded = true
              _collection.remove val["objects"].parse_objects
              val = _collection
            elsif val.is_a?(Array)
              # Otherwise create a new collection based on what the user defined.
              val = proxyKlass.new val.parse_objects, delegate: self, key: key, parse_class: klassName
            end

            # send dirty tracking if set
            if track == true
              send :"#{key}_will_change!" unless val == instance_variable_get( :"@#{key}" )
            end
            # TODO: Only allow empty proxy collection class as a value or nil.
            if val.is_a?(Parse::CollectionProxy)
              instance_variable_set(:"@#{key}", val)
            else
              warn "[#{self.class}] Invalid value #{val} for :has_many field #{key}. Should be an Array or a CollectionProxy"
            end

          end

          data_type = opts[:through]
          # if the type is a relation association, add these methods to the delegate
          #   that will be used when creating the collection proxies. See Collection proxies
          #   for more information.
          if data_type == :relation
            # return a query given the foreign table class name.
            define_method("#{key}_relation_query") do
              Parse::Query.new(klassName, key.to_sym.related_to => self.pointer, limit: :max)
            end
            # fetch the contents of the relation
            define_method("#{key}_fetch!") do
              q = self.send :"#{key}_relation_query"
              q.results || []
            end

          end

          # if the remote field name and the local field name are the same
          # don't create alias methods
          return if parse_field.to_sym == key.to_sym

          if self.method_defined?(parse_field) == false
            alias_method parse_field, key
            alias_method "#{parse_field}=", "#{key}="
            alias_method "#{parse_field}_set_attribute!", "#{key}_set_attribute!"
          elsif parse_field.to_sym != :objectId
            warn "Alias has_many method #{self}##{parse_field} already defined."
          end


        end # has_many_array
      end #ClassMethods

      # provides a hash list of all relations to this class.
      def relations
        self.class.relations
      end

      # returns a has of all the relation changes that have been performed on this
      # instance.
      def relation_updates
        h = {}
        changed.each do |key|
          next unless relations[key.to_sym].present? && send(key).changed?
          remote_field = self.field_map[key.to_sym] || key
          h[remote_field] = send key
        end
        h
      end

      # true if this object has any relation changes
      def relation_changes?
        changed.any? { |key| relations[key.to_sym] }
      end

    end # HasMany
  end #Associations


end # Parse
