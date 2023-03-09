# encoding: UTF-8
# frozen_string_literal: true

require_relative "../pointer"
require_relative "collection_proxy"
require_relative "pointer_collection_proxy"
require_relative "relation_collection_proxy"

module Parse
  module Associations

    # Parse has many ways to implement one-to-many and many-to-many
    # associations: `Array`, `Parse Relation` or through a `Query`. How you decide
    # to implement your associations, will affect how `has_many` works in
    # Parse-Stack. Parse natively supports one-to-many and many-to-many
    # relationships using `Array` and `Relations`, as described in
    # {http://docs.parseplatform.org/js/guide/#relations Parse Relational Data}.
    # Both of these methods require you define a specific column type in your
    # Parse table that will be used to store information about the association.
    #
    # In addition to `Array` and `Relation`, Parse-Stack also implements the
    # standard `has_many` behavior prevalent in other frameworks through a query
    # where the associated class contains a foreign pointer to the local class,
    # usually the inverse of a `belongs_to`. This requires that the associated
    # class has a defined column that contains a pointer the refers to the
    # defining class.
    #
    # *Query-Approach*
    #
    # In this `Query` implementation, a `has_many` association for a Parse class
    # requires that another Parse class will have a foreign pointer that refers
    # to instances of this class. This is the standard way that `has_many`
    # relationships work in most databases systems. This is usually the case when
    # you have a class that has a `belongs_to` relationship to instances of the
    # local class.
    #
    # In the example below, many songs belong to a specific artist. We set this
    # association by setting {Associations::BelongsTo.belongs_to :belongs_to} relationship from `Song` to `Artist`.
    # Knowing there is a column in `Song` that points to instances of an `Artist`,
    # we can setup a `has_many` association to `Song` instances in the `Artist`
    # class. Doing so will generate a helper query method on the `Artist` instance
    # objects.
    #
    #  class Song < Parse::Object
    #    property :released, :date
    #    # this class will have a pointer column to an Artist
    #    belongs_to :artist
    #  end
    #
    #  class Artist < Parse::Object
    #    has_many :songs
    #  end
    #
    #  artist = Artist.first
    #
    #  artist.songs # => [all songs belonging to artist]
    #  # equivalent: Song.all(artist: artist)
    #
    #  # filter also by release date
    #  artist.songs(:released.after => 1.year.ago)
    #  # equivalent: Song.all(artist: artist, :released.after => 1.year.ago)
    #
    # In order to modify the associated objects (ex. `songs`), you must modify
    # their corresponding `belongs_to` field (in this case `song.artist`), to
    # another record and save it.
    #
    # Options for `has_many` using the `Query` approach are `:as` and `:field`. The
    # `:as` option behaves similarly to the {Associations::BelongsTo.belongs_to :belongs_to} counterpart. The
    # `:field` option can be used to override the derived column name located
    # in the foreign class. The default value for `:field` is the columnized
    # version of the Parse subclass `parse_class` method.
    #
    #  class Parse::User
    #    # since the foreign column name is :agent
    #    has_many :artists, field: :agent
    #  end
    #
    #  class Artist < Parse::Object
    #    belongs_to :manager, as: :user, field: :agent
    #  end
    #
    #  artist.manager # => Parse::User object
    #
    #  user.artists # => [artists where :agent column is user]
    #
    #
    # When using this approach, you may also employ the use of scopes to filter the particular data from the `has_many` association.
    #
    #  class Artist
    #    has_many :songs, ->(timeframe) { where(:created_at.after => timeframe) }
    #  end
    #
    #  artist.songs(6.months.ago)
    #  # => [artist's songs created in the last 6 months]
    #
    # You may also call property methods in your scopes related to the instance.
    # *Note:* You also have access to the instance object for the local class
    # through a special "*i*" method in the scope.
    #
    #  class Concert
    #    property :city
    #    belongs_to :artist
    #  end
    #
    #  class Artist
    #    property :hometown
    #    has_many :local_concerts, -> { where(:city => hometown) }, as: :concerts
    #  end
    #
    #  # assume
    #  artist.hometown = "San Diego"
    #
    #  # artist's concerts in their hometown of 'San Diego'
    #  artist.local_concerts
    #  # equivalent: Concert.all(artist: artist, city: artist.hometown)
    #
    # You may also omit the association completely, as rely on the scope to fetch the
    # associated records. This makes the `has_many` work as a macro query setting the :scope_only
    # option to true:
    #
    #  class Author < Parse::Object
    #    property :name
    #    has_many :posts, ->{ where :tags.in => name.downcase }, scope_only: true
    #  end
    #
    #  class Post < Parse::Object
    #    property :tags, :array
    #  end
    #
    #  author.posts # => Posts where author's name is a tag
    #  # equivalent: Post.all( :tags.in => artist.name.downcase )
    #
    # *Array-Approach*
    #
    # In the `Array` implemenatation, you can designate a column to be of `Array`
    # type that contains a list of Parse pointers. Parse-Stack supports this by
    # passing the option `through: :array` to the `has_many` method. If you use
    # this approach, it is recommended that this is used for associations where
    # the quantity is less than 100 in order to maintain query and fetch
    # performance. You would be in charge of maintaining the array with the proper
    # list of Parse pointers that are associated to the object. Parse-Stack does
    # help by wrapping the array in a {Parse::PointerCollectionProxy} which provides dirty tracking.
    #
    #  class Artist < Parse::Object
    #  end
    #
    #  class Band < Parse::Object
    #    has_many :artists, through: :array
    #  end
    #
    #  artist = Artist.first
    #
    #  # find all bands that contain this artist
    #  bands = Band.all( :artists.in => [artist.pointer] )
    #
    #  band = bands.first
    #  band.artists # => [array of Artist pointers]
    #
    #  # remove artists
    #  band.artists.remove artist
    #
    #  # add artist
    #  band.artists.add artist
    #
    #  # save changes
    #  band.save
    #
    # *ParseRelation-Approach*
    #
    # Other than the use of arrays, Parse supports native one-to-many and many-to-many
    # associations through what is referred to as a {http://docs.parseplatform.org/js/guide/#many-to-many Parse Relation}.
    # This is implemented by defining a column to be of type `Relation` which
    # refers to a foreign class. Parse-Stack supports this by passing the
    # `through: :relation` option to the `has_many` method. Designating a column
    # as a Parse relation to another class type, will create a one-way intermediate
    # "join-list" between the local class and the foreign class. One important
    # distinction of this compared to other types of data stores (ex. PostgresSQL) is that:
    #
    # *1*. The inverse relationship association is not available automatically. Therefore, having a column of `artists` in a `Band` class that relates to members of the band (as `Artist` class), does not automatically make a set of `Band` records available to `Artist` records for which they have been related. If you need to maintain both the inverse relationship between a foreign class to its associations, you will need to manually manage that by adding two Parse relation columns in each class, or by creating a separate class (ex. `ArtistBands`) that is used as a join table.
    #
    # *2*. Querying the relation is actually performed against the implicit join table, not the local one.
    #
    # *3*. Applying query constraints for a set of records within a relation is performed against the foreign table class, not the class having the relational column.
    #
    # The Parse documentation provides more details on associations, see {http://docs.parseplatform.org/ios/guide/#relations Parse Relations Guide}.
    # Parse-Stack will handle the work for (2) and (3) automatically.
    #
    # In the example below, a `Band` can have thousands of `Fans`. We setup a
    # `Relation<Fan>` column in the `Band` class that references the `Fan` class.
    # Parse-Stack provides methods to manage the relationship under the {Parse::RelationCollectionProxy}
    # class.
    #
    #  class Fan < Parse::Object
    #    # .. lots of properties ...
    #    property :location, :geopoint
    #  end
    #
    #  class Band < Parse::Object
    #    has_many :fans, through: :relation 
    #  end
    #
    #  band = Band.first
    #
    #   # the number of fans in the relation
    #  band.fans.count
    #
    #  # get the first object in relation
    #  fan = bands.fans.first # => Parse::User object
    #
    #  # use `add` or `remove` to modify relations
    #  band.fans.add user
    #  bands.fans.remove user
    #
    #  # updates the relation as well as changes to `band`
    #  band.fans.save
    #
    #  # Find 50 fans who are near San Diego, CA
    #  downtown = Parse::GeoPoint.new(32.82, -117.23)
    #  fans = band.fans.all :location.near => downtown
    #
    # You can perform atomic additions and removals of objects from `has_many`
    # relations using the methods below. Parse allows this by providing a specific atomic operation
    # request. The operation is performed directly on Parse server
    # and *NOT* on your instance object.
    #
    #  # atomically add/remove
    #  band.artists.add! objects  # { __op: :AddUnique }
    #  band.artists.remove! objects  # { __op: :AddUnique }
    #
    #  # atomically add unique Artist
    #  band.artists.add_unique! objects  # { __op: :AddUnique }
    #
    #  # atomically add/remove relations
    #  band.fans.add! users # { __op: :Add }
    #  band.fans.remove! users # { __op: :Remove }
    #
    #  # atomically perform a delete operation on this field name
    #  # this should set it as `undefined`.
    #  band.op_destroy!("category") # { __op: :Delete }
    #
    # You can also perform queries against class entities to find related objects. Assume
    # that users can like a band. The `Band` class can have a `likes` column that is
    # a Parse relation to the {Parse::User} class containing the users who have liked a
    # specific band.
    #
    #
    #   class Band < Parse::Object
    #     # likes is a Parse relation column of user objects.
    #     has_many :likes, through: :relation, as: :user
    #   end
    #
    # You can now find all {Parse::User} records who have liked a specific band. In the
    # example below, the `:likes` key refers to the `likes` column defined in the `Band`
    # collection which contains the set of user records.
    #
    #   band = Band.first # get a band
    #
    #   # find all users who have liked this band, where :likes is a column
    #   # in the Band collection - NOT in the User collection.
    #   users = Parse::User.all :likes.related_to => band
    #
    # You can also find all bands that a specific user has liked.
    #
    #   user = Parse::User.first
    #
    #   # find all bands where this user
    #   # is in the `likes` column of the Band collection
    #   bands_liked_by_user = Band.all :likes => user
    #
    module HasMany

      # @!attribute [rw] self.relations
      #  A hash mapping of all has_many associations that use the ParseRelation implementation.
      #  @return [Hash]

      # Define a one-to-many or many-to-many association between the local model and a foreign class.
      # Options for `has_many` are the same as the {Associations::BelongsTo.belongs_to} counterpart with
      # support for `:required`, `:as` and `:field`. It has additional options.
      #
      # @!method self.has_many(key, scope = nil, opts = {})
      # @param [Symbol] key The pluralized version of the foreign class. Using the :query method,
      #  this implies the name of the foreign column that a pointer to this record.
      #  Using the :array or :relation method, this implies the name of the local
      #  column that contains either an array of Parse::Pointers in the case of :array,
      #  or the Parse Relation, in the case of :relation.
      # @param [Proc] scope Only applicable using :query. A proc that can customize the query by applying
      #   additional constraints when fetching the associated records. Works similarly as
      #   ActiveModel associations described in section {http://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html Customizing the Query}
      # @option opts [Symbol] :through The type of implementation to use: :query (default), :array or :relation.
      #  If set to `:array`, it defines the column in Parse as being an array of
      #  Parse pointer objects and will be managed locally using a {Parse::PointerCollectionProxy}.
      #  If set to `:relation`, it defines a column of type Parse Relation with
      #  the foreign class and will be managed locally using a {Parse::RelationCollectionProxy}.
      #  If set to `:query`, no storage is required on the local class as the
      #  associated records will be fetched using a Parse query.
      # @option opts [Symbol] :field override the name of the remote column to use when fetching the association.
      #  When using through :query, this is the column name of the remote column
      #  of the foreign class that will be used for matching. When using :array,
      #  this is the name of the remote column of the local class that contains
      #  an array of pointers to the foreign class. When using :relation, this
      #  is the name of the remote column of the local class that contains the Parse Relation.
      # @option opts [Symbol] :as override the inferred Parse::Object subclass of the association.
      #  By default this is inferred as the singularized camel case version of
      #  the key parameter. This option allows you to override the typecast of
      #  foreign Parse model of the association, while allowing you to have a
      #  different accessor name.
      # @example
      #  has_many :fans, as: :users, through: :relation, field: "awesomeFans"
      #  has_many :songs
      #  has_many :likes, as: :users, through: :relation
      #  has_many :artists, field: "managedArtists"
      #
      # @return [Array<Parse::Object>] if through :query
      # @return [PointerCollectionProxy] if through :array
      # @return [RelationCollectionProxy] if through :relation
      # @see PointerCollectionProxy
      # @see RelationCollectionProxy

      # @!visibility private
      def self.included(base)
        base.extend(ClassMethods)
      end

      # @!visibility private
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
        def has_many_queried(key, scope = nil, **opts)
          # key will be the name of the property
          # the remote class is either key or as.
          opts[:scope_only] ||= false
          klassName = (opts[:as] || key).to_parse_class singularize: true
          foreign_field = (opts[:field] || parse_class.columnize).to_sym

          define_method(key) do |*args, &block|
            return [] if @id.nil?
            query = Parse::Query.new(klassName, limit: :max)

            query.where(foreign_field => self) unless opts[:scope_only] == true

            if scope.is_a?(Proc)
              # magic, override the singleton method_missing with accessing object level methods
              # that don't collide with Parse::Query instance. Still accessible under :i
              instance = self
              query.define_singleton_method(:method_missing) { |m, *args, &block| instance.send(m, *args, &block) }
              query.define_singleton_method(:i) { instance }
              # if the scope takes no arguments, assume arguments are additional conditions
              if scope.arity.zero?
                query.instance_exec(&scope)
                query.conditions(*args) if args.present?
              else
                query.instance_exec(*args, &scope)
              end
              instance = nil # help clean up ruby gc
            elsif args.present?
              query.conditions(*args)
            end

            query.define_singleton_method(:method_missing) do |m, *args, &chained_block|
              klass = Parse::Model.find_class klassName

              if klass.present? && klass.respond_to?(m)
                klass_scope = klass.send(m, *args) # blocks only passed to final result set
                return klass_scope unless klass_scope.is_a?(Parse::Query)
                # merge constraints
                add_constraints(klass_scope.constraints)
                # if a block was passed, execute the query, otherwise return the query
                return chained_block.present? ? results(&chained_block) : self
              end
              results.send(m, *args, &chained_block)
            end

            Parse::Query.apply_auto_introspection!(query)

            return query if block.nil?
            query.results(&block)
          end
        end

        # Define a one-to-many or many-to-many association between the local model and a foreign class.
        def has_many(key, scope = nil, **opts)
          opts[:through] ||= :query

          if opts[:through] == :query
            return has_many_queried(key, scope, **opts)
          end

          # below this is the same
          opts.reverse_merge!({
            field: key.to_s.camelize(:lower),
            required: false,
            as: key,
          })

          klassName = opts[:as].to_parse_class singularize: true
          parse_field = opts[:field].to_sym # name of the column (local or remote)
          access_type = opts[:through].to_sym

          ivar = :"@#{key}"
          will_change_method = :"#{key}_will_change!"
          set_attribute_method = :"#{key}_set_attribute!"

          # verify that the user did not duplicate properties or defined different properties with the same name
          if self.fields[key].present? && Parse::Properties::BASE_FIELD_MAP[key].nil?
            warn "Has_many property #{self}##{key} already defined with type #{klassName}"
            return false
          end
          if self.fields[parse_field].present?
            warn "Alias has_many #{self}##{parse_field} conflicts with previously defined property."
            return false
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
            self.attributes.merge!(parse_field => :array)
            # Add them to the list of fields in our class model
            self.fields.merge!(key => :array, parse_field => :array)
          end

          self.field_map.merge!(key => parse_field)
          # dirty tracking
          define_attribute_methods key

          # The first method to be defined is a getter.
          define_method(key) do
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
            send set_attribute_method, val, true
          end

          # This will set the content of the proxy.
          define_method(set_attribute_method) do |val, track = true|
            # If it is a hash, with a __type of Relation, createa a new RelationCollectionProxy, regardless
            # of what is defined because we must have gotten this from Parse.

            # if val is nil or it is the delete operation, then set to empty array.
            # this will create a new proxyKlass later on
            if val.nil? || val == Parse::Properties::DELETE_OP
              val = []
            end

            if val.is_a?(Hash) && val["__type"] == "Relation"
              relation_objects = val["objects"] || []
              val = Parse::RelationCollectionProxy.new relation_objects, delegate: self, key: key, parse_class: (val[Parse::Model::KEY_CLASS_NAME] || klassName)
            elsif val.is_a?(Hash) && val["__op"] == "AddRelation" && val["objects"].present?
              _collection = proxyKlass.new [], delegate: self, key: key, parse_class: (val[Parse::Model::KEY_CLASS_NAME] || klassName)
              _collection.loaded = true
              _collection.add val["objects"].parse_objects
              val = _collection
            elsif val.is_a?(Hash) && val["__op"] == "RemoveRelation" && val["objects"].present?
              _collection = proxyKlass.new [], delegate: self, key: key, parse_class: (val[Parse::Model::KEY_CLASS_NAME] || klassName)
              _collection.loaded = true
              _collection.remove val["objects"].parse_objects
              val = _collection
            elsif val.is_a?(Array)
              # Otherwise create a new collection based on what the user defined.
              val = proxyKlass.new val.parse_objects, delegate: self, key: key, parse_class: klassName
            end

            # send dirty tracking if set
            if track == true
              send will_change_method unless val == instance_variable_get(ivar)
            end
            # TODO: Only allow empty proxy collection class as a value or nil.
            if val.is_a?(Parse::CollectionProxy)
              instance_variable_set(ivar, val)
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
            alias_method "#{parse_field}_set_attribute!", set_attribute_method
          elsif parse_field.to_sym != :objectId
            warn "Alias has_many method #{self}##{parse_field} already defined."
          end
        end # has_many_array
      end #ClassMethods

      # A hash list of all has_many associations that use a Parse Relation.
      # @return [Hash]
      # @see Associations::HasMany.relations
      def relations
        self.class.relations
      end

      # A hash of all the relation changes that have been performed on this
      #  instance. This is only used when the association uses Parse Relations.
      # @return [Hash]
      def relation_updates
        h = {}
        changed.each do |key|
          next unless relations[key.to_sym].present? && send(key).changed?
          remote_field = self.field_map[key.to_sym] || key
          h[remote_field] = send key # we still need to send a proxy collection
        end
        h
      end

      # @return [Boolean] true if there are pending relational changes for
      def relation_changes?
        changed.any? { |key| relations[key.to_sym] }
      end
    end # HasMany
  end #Associations
end # Parse
