# encoding: UTF-8
# frozen_string_literal: true

require_relative '../../query'

module Parse
  module Core
    # Defines the querying methods applied to a Parse::Object.
    module Querying

        # This feature is a small subset of the
        # {http://guides.rubyonrails.org/active_record_querying.html#scopes
        # ActiveRecord named scopes} feature. Scoping allows you to specify
        # commonly-used queries which can be referenced as class method calls and
        # are chainable with other scopes. You can use every {Parse::Query}
        # method previously covered such as `where`, `includes` and `limit`.
        #
        #  class Article < Parse::Object
        #    property :published, :boolean
        #    scope :published, -> { query(published: true) }
        #  end
        #
        # This is the same as defining your own class method for the query.
        #
        #  class Article < Parse::Object
        #    def self.published
        #      query(published: true)
        #    end
        #  end
        #
        # You can also chain scopes and pass parameters. In addition, boolean and
        # enumerated properties have automatically generated scopes for you to use.
        #
        #  class Article < Parse::Object
        #    scope :published, -> { query(published: true) }
        #
        #    property :comment_count, :integer
        #    property :category
        #    property :approved, :boolean
        #
        #    scope :published_and_commented, -> { published.where :comment_count.gt => 0 }
        #    scope :popular_topics, ->(name) { published_and_commented.where category: name }
        #  end
        #
        #  # simple scope
        #  Article.published # => where published is true
        #
        #  # chained scope
        #  Article.published_and_commented # published is true and comment_count > 0
        #
        #  # scope with parameters
        #  Article.popular_topic("music") # => popular music articles
        #  # equivalent: where(published: true, :comment_count.gt => 0, category: name)
        #
        #  # automatically generated scope
        #  Article.approved(category: "tour") # => where approved: true, category: 'tour'
        #
        # If you would like to turn off automatic scope generation for property types,
        # set the option `:scope` to false when declaring the property.
        # @param name [Symbol] the name of the scope.
        # @param body [Proc] the proc related to the scope.
        # @raise ArgumentError if body parameter does not respond to `call`
        # @return [Symbol] the name of the singleton method created.
        def scope(name, body)
          unless body.respond_to?(:call)
            raise ArgumentError, 'The scope body needs to be callable.'
          end

          name = name.to_sym
          if respond_to?(name, true)
            puts "Creating scope :#{name}. Will overwrite existing method #{self}.#{name}."
          end

          define_singleton_method(name) do |*args, &block|

            if body.arity.zero?
              res = body.call
              res.conditions(*args) if args.present?
            else
              res = body.call(*args)
            end

            _q = res || query

            if _q.is_a?(Parse::Query)
              klass = self
              _q.define_singleton_method(:method_missing) do |m, *args, &chained_block|
                if klass.respond_to?(m, true)
                  # must be a scope
                  klass_scope = klass.send(m, *args)
                  if klass_scope.is_a?(Parse::Query)
                    # merge constraints
                    add_constraints( klass_scope.constraints )
                    # if a block was passed, execute the query, otherwise return the query
                    return chained_block.present? ? results(&chained_block) : self
                  end # if
                  klass = nil # help clean up ruby gc
                  return klass_scope
                end
                klass = nil # help clean up ruby gc
                return results.send(m, *args, &chained_block)
              end
            end

            Parse::Query.apply_auto_introspection!(_q)

            return _q if block.nil?
            _q.results(&block)
          end

        end


        # Creates a new {Parse::Query} with the given constraints for this class.
        # @example
        #  # assume Post < Parse::Object
        #  query = Post.query(:updated_at.before => DateTime.now)
        # @return [Parse::Query] a new query with the given constraints for this
        #  Parse::Object subclass.
        def query(constraints = {})
          Parse::Query.new self.parse_class, constraints
        end; alias_method :where, :query

        # @param conditions (see Parse::Query#where)
        # @return (see Parse::Query#where)
        # @see Parse::Query#where
        def literal_where(conditions = {})
          query.where(conditions)
        end

        # Fetch all matching objects in this collection matching the constraints.
        # This will be the most common way when querying Parse objects for a subclass.
        # When no block is passed, all objects are returned. Using a block is more memory
        # efficient as matching objects are fetched in batches and discarded after the iteration
        # is completed.
        # @param constraints [Hash] a set of {Parse::Query} constraints.
        # @yield a block to iterate with each matching object.
        # @example
        #
        #  songs = Song.all( ... expressions ...) # => array of Parse::Objects
        #  # memory efficient for large amounts of records.
        #  Song.all( ... expressions ...) do |song|
        #      # ... do something with song..
        #  end
        #
        # @return [Array<Parse::Object>] an array of matching objects. If a block is passed,
        #  an empty array is returned.
        def all(constraints = {limit: :max})
          constraints = constraints.reverse_merge({limit: :max})
          prepared_query = query(constraints)
          return prepared_query.results(&Proc.new) if block_given?
          prepared_query.results
        end

        # Returns the first item matching the constraint.
        # @overload first(count = 1)
        #  @param count [Interger] The number of items to return.
        #  @example
        #   Object.first(2) # => an array of the first 2 objects in the collection.
        #  @return [Parse::Object] if count == 1
        #  @return [Array<Parse::Object>] if count > 1
        # @overload first(constraints = {})
        #  @param constraints [Hash] a set of {Parse::Query} constraints.
        #  @example
        #   Object.first( :name => "Anthony" )
        #  @return [Parse::Object] the first matching object.
        def first(constraints = {})
          fetch_count = 1
          if constraints.is_a?(Numeric)
            fetch_count = constraints.to_i
            constraints = {}
          end
          constraints.merge!( {limit: fetch_count} )
          res = query(constraints).results
          return res.first if fetch_count == 1
          return res.first fetch_count
        end

        # Creates a count request which is more performant when counting objects.
        # @example
        #  # number of songs with a like count greater than 20.
        #  count = Song.count( :like_count.gt => 20 )
        # @param constraints (see #all)
        # @return [Interger] the number of records matching the query.
        # @see Parse::Query#count
        def count(constraints = {})
          query(constraints).count
        end

        # Find objects matching the constraint ordered by the descending created_at date.
        # @param constraints (see #all)
        # @return [Array<Parse::Object>]
        def newest(constraints = {})
          constraints.merge!(order: :created_at.desc)
          _q = query(constraints)
          _q.define_singleton_method(:method_missing) { |m, *args, &block| self.results.send(m, *args, &block) }
          _q
        end

        # Find objects matching the constraint ordered by the ascending created_at date.
        # @param constraints (see #all)
        # @return [Array<Parse::Object>]
        def oldest(constraints = {})
          constraints.merge!(order: :created_at.asc)
          _q = query(constraints)
          _q.define_singleton_method(:method_missing) { |m, *args, &block| self.results.send(m, *args, &block) }
          _q
        end

        # Find objects for a given objectId in this collection.The result is a list
        # (or single item) of the objects that were successfully found.
        # @example
        #  Object.find "<objectId>"
        #  Object.find "<objectId>", "<objectId>"....
        #  Object.find ["<objectId>", "<objectId>"]
        # @param parse_ids [String] the objectId to find.
        # @param type [Symbol] the fetching methodology to use if more than one id was passed.
        #  - *:parallel* : Utilizes parrallel HTTP requests to fetch all objects requested.
        #  - *:batch* : This uses a batch fetch request using a contained_in clause.
        # @param compact [Boolean] whether to remove nil items from the returned array for objects
        #  that were not found.
        # @return [Parse::Object] if only one id was provided as a parameter.
        # @return [Array<Parse::Object>] if more than one id was provided as a parameter.
        def find(*parse_ids, type: :parallel, compact: true)
          # flatten the list of Object ids.
          parse_ids.flatten!
          parse_ids.compact!
          # determines if the result back to the call site is an array or a single result
          as_array = parse_ids.count > 1
          results = []

          if type == :batch
            # use a .in query with the given id as a list
            results = self.class.all(:id.in => parse_ids)
          else
            # use Parallel to make multiple threaded requests for finding these objects.
            # The benefit of using this as default is that each request goes to a specific URL
            # which is better than Query request (table scan). This in turn allows for caching of
            # individual objects.
            results = parse_ids.threaded_map do |parse_id|
              next nil unless parse_id.present?
              response = client.fetch_object(parse_class, parse_id)
              next nil if response.error?
              Parse::Object.build response.result, parse_class
            end
          end
          # removes any nil items in the array
          results.compact! if compact

          as_array ? results : results.first
        end; alias_method :get, :find

    end # Querying
  end
end
