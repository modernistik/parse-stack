# encoding: UTF-8
# frozen_string_literal: true

require_relative "../pointer"
require_relative "collection_proxy"
require_relative "pointer_collection_proxy"
require_relative "relation_collection_proxy"

module Parse
  module Associations
    # The `has_one` creates a one-to-one association with another Parse class.
    # This association says that the other class in the association contains a
    # foreign pointer column which references instances of this class. If your
    # model contains a column that is a Parse pointer to another class, you should
    # use `belongs_to` for that association instead.
    #
    # Defining a `has_one` property generates a helper query method to fetch a
    # particular record from a foreign class. This is useful for setting up the
    # inverse relationship accessors of a `belongs_to`. In the case of the
    # `has_one` relationship, the `:field` option represents the name of the
    # column of the foreign class where the Parse pointer is stored. By default,
    # the lower-first camel case version of the Parse class name is used.
    #
    # In the example below, a `Band` has a local column named `manager` which has
    # a pointer to a `Parse::User` (_:user_) record. This setups up the accessor for `Band`
    # objects to access the band's manager.
    #
    # Since we know there is a column named `manager` in the `Band` class that
    # points to a single `Parse::User`, you can setup the inverse association
    # read accessor in the `Parse::User` class. Note, that to change the
    # association, you need to modify the `manager` property on the band instance
    # since it contains the `belongs_to` property.
    #
    #  # every band has a manager
    #  class Band < Parse::Object
    #    belongs_to :manager, as: :user
    #  end
    #
    #  band = Band.first id: '12345'
    #  # the user represented by this manager
    #  user = band.manger
    #
    #  # every user manages a band
    #  class Parse::User
    #    # inverse relationship to `Band.belongs_to :manager`
    #    has_one :band, field: :manager
    #  end
    #
    #  user = Parse::User.first
    #
    #  user.band # similar to performing: Band.first(:manager => user)
    #
    #
    # You may optionally use `has_one` with scopes, in order to fine tune the
    # query result. Using the example above, you can customize the query with
    # a scope that only fetches the association if the band is approved. If
    # the association cannot be fetched, `nil` is returned.
    #
    #  # adding to previous example
    #  class Band < Parse::Object
    #    property :approved, :boolean
    #    property :approved_date, :date
    #  end
    #
    #  # every user manages a band
    #  class Parse::User
    #    has_one :recently_approved, ->{ where(order: :approved_date.desc) }, field: :manager, as: :band
    #    has_one :band_by_status, ->(status) { where(approved: status) },  field: :manager, as: :band
    #  end
    #
    #  # gets the band most recently approved
    #  user.recently_approved
    #  # equivalent: Band.first(manager: user, order: :approved_date.desc)
    #
    #  # fetch the managed band that is not approved
    #  user.band_by_status(false)
    #  # equivalent: Band.first(manager: user, approved: false)
    #
    # @see Parse::Associations::BelongsTo
    # @see Parse::Associations::HasMany
    module HasOne

      # @!method self.has_one(key, scope = nil, opts = {})
      # Creates a one-to-one association with another Parse model.
      # @param [Symbol] key The singularized version of the foreign class and the name of the
      #   *foreign* column in the foreign Parse table where the pointer is stored.
      # @param [Proc] scope A proc that can customize the query by applying
      #   additional constraints when fetching the associated record. Works similarly as
      #   ActiveModel associations described in section {http://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html Customizing the Query}
      # @option opts [Symbol] :field override the name of the remote column
      #  where the pointer is stored. By default this is inferred as
      #  the columnized of the key parameter.
      # @option opts [Symbol] :as override the inferred Parse::Object subclass.
      #  By default this is inferred as the singularized camel case version of
      #  the key parameter. This option allows you to override the Parse model used
      #  to perform the query for the association, while allowing you to have a
      #  different accessor name.
      # @option opts [Boolean] scope_only Setting this option to `true`,
      #  makes the association fetch based only on the scope provided and does
      #  not use the local instance object as a foreign pointer in the query.
      #  This allows for cases where another property of the local class, is
      #  needed to match the resulting records in the association.
      # @see String#columnize
      # @see Associations::HasMany.has_many
      # @return [Parse::Object] a Parse::Object subclass when using the accessor
      #  when fetching the association.

      # @!visibility private
      def self.included(base)
        base.extend(ClassMethods)
      end

      # @!visibility private
      module ClassMethods

        # has one are not property but instance scope methods
        def has_one(key, scope = nil, **opts)
          opts.reverse_merge!({ as: key, field: parse_class.columnize, scope_only: false })
          klassName = opts[:as].to_parse_class
          foreign_field = opts[:field].to_sym
          ivar = :"@_has_one_#{key}"

          if self.method_defined?(key)
            warn "Creating has_one :#{key} association. Will overwrite existing method #{self}##{key}."
          end

          define_method(key) do |*args, &block|
            return nil if @id.nil?
            query = Parse::Query.new(klassName, limit: 1)
            query.where(foreign_field => self) unless opts[:scope_only] == true

            if scope.is_a?(Proc)
              # any method not part of Query, gets delegated to the instance object
              instance = self
              query.define_singleton_method(:method_missing) { |m, *args, &block| instance.send(m, *args, &block) }
              query.define_singleton_method(:i) { instance }

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
            # query.define_singleton_method(:method_missing) do |m, *args, &block|
            #   self.first.send(m, *args, &block)
            # end
            return query.first if block.nil?
            block.call(query.first)
          end
        end
      end
    end
  end
end
