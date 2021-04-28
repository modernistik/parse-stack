# encoding: UTF-8
# frozen_string_literal: true

require_relative "client"
require_relative "query/operation"
require_relative "query/constraints"
require_relative "query/ordering"
require "active_model"
require "active_model_serializers"
require "active_support"
require "active_support/inflector"
require "active_support/core_ext"

module Parse
  # The {Parse::Query} class provides the lower-level querying interface for
  # your Parse collections by utilizing the {http://docs.parseplatform.org/rest/guide/#queries
  # REST Querying interface}. This is the main engine behind making Parse queries
  # on remote collections. It takes a set of constraints and generates the
  # proper hash parameters that are passed to an API request in order to retrive
  # matching results. The querying design pattern is inspired from
  # {http://datamapper.org/ DataMapper} where symbols are overloaded with
  # specific methods with attached values.
  #
  # At the core of each item is a {Parse::Operation}. An operation is
  # made up of a field name and an operator. Therefore calling
  # something like :name.eq, defines an equality operator on the field
  # name. Using {Parse::Operation}s with values, we can build different types of
  # constraints, known as {Parse::Constraint}s.
  #
  # This component can be used on its own without defining your models as all
  # results are provided in hash form.
  #
  # *Field-Formatter*
  #
  # By convention in Ruby (see
  # {https://github.com/bbatsov/ruby-style-guide#snake-case-symbols-methods-vars Style Guide}),
  # symbols and variables are expressed in lower_snake_case form. Parse, however,
  # prefers column names in {String#columnize} format (ex. `objectId`,
  # `createdAt` and `updatedAt`). To keep in line with the style
  # guides between the languages, we do the automatic conversion of the field
  # names when compiling the query. This feature can be overridden by changing the
  # value of {Parse::Query.field_formatter}.
  #
  #  # default uses :columnize
  #  query = Parse::User.query :field_one => 1, :FieldTwo => 2, :Field_Three => 3
  #  query.compile_where # => {"fieldOne"=>1, "fieldTwo"=>2, "fieldThree"=>3}
  #
  #  # turn off
  #  Parse::Query.field_formatter = nil
  #  query = Parse::User.query :field_one => 1, :FieldTwo => 2, :Field_Three => 3
  #  query.compile_where # => {"field_one"=>1, "FieldTwo"=>2, "Field_Three"=>3}
  #
  #  # force everything camel case
  #  Parse::Query.field_formatter = :camelize
  #  query = Parse::User.query :field_one => 1, :FieldTwo => 2, :Field_Three => 3
  #  query.compile_where # => {"FieldOne"=>1, "FieldTwo"=>2, "FieldThree"=>3}
  #
  # Most of the constraints supported by Parse are available to `Parse::Query`.
  # Assuming you have a column named `field`, here are some examples. For an
  # explanation of the constraints, please see
  # {http://docs.parseplatform.org/rest/guide/#queries Parse Query Constraints documentation}.
  # You can build your own custom query constraints by creating a `Parse::Constraint`
  # subclass. For all these `where` clauses assume `q` is a `Parse::Query` object.
  class Query
    extend ::ActiveModel::Callbacks
    include Parse::Client::Connectable
    include Enumerable
    # @!group Callbacks
    #
    # @!method before_prepare
    #   A callback called before the query is compiled
    #   @yield A block to execute for the callback.
    #   @see ActiveModel::Callbacks
    # @!method after_prepare
    #   A callback called after the query is compiled
    #   @yield A block to execute for the callback.
    #   @see ActiveModel::Callbacks
    # @!endgroup
    define_model_callbacks :prepare, only: [:after, :before]
    # A query needs to be tied to a Parse table name (Parse class)
    # The client object is of type Parse::Client in order to send query requests.
    # You can modify the default client being used by all Parse::Query objects by setting
    # Parse::Query.client. You can override individual Parse::Query object clients
    # by changing their client variable to a different Parse::Client object.

    # @!attribute [rw] table
    #  @return [String] the name of the Parse collection to query against.
    # @!attribute [rw] client
    #  @return [Parse::Client] the client to use for the API Query request.
    # @!attribute [rw] key
    #  This parameter is used to support `select` queries where you have to
    #  pass a `key` parameter for matching different tables.
    #  @return [String] the foreign key to match against.
    # @!attribute [rw] cache
    #  Set whether this query should be cached and for how long. This parameter
    #  is used to cache queries when using {Parse::Middleware::Caching}. If
    #  the caching middleware is configured, all queries will be cached for the
    #  duration allowed by the cache, and therefore some queries could return
    #  cached results. To disable caching and cached results for this specific query,
    #  you may set this field to `false`. To specify the specific amount of time
    #  you want this query to be cached, set a duration (in number of seconds) that
    #  the caching middleware should cache this request.
    #  @example
    #   # find all users with name "Bob"
    #   query = Parse::Query.new("_User", :name => "Bob")
    #
    #   query.cache = true # (default) cache using default cache duration.
    #
    #   query.cache = 1.day # cache for 86400 seconds
    #
    #   query.cache = false # do not cache or use cache results
    #
    #   # You may optionally pass this into the constraint hash.
    #   query = Parse::Query.new("_User", :name => "Bob", :cache => 1.day)
    #
    #  @return [Boolean] if set to true or false on whether it should use the default caching
    #   length set when configuring {Parse::Middleware::Caching}.
    #  @return [Integer] if set to a number of seconds to cache this specific request
    #   with the {Parse::Middleware::Caching}.
    # @!attribute [rw] use_master_key
    #  True or false on whether we should send the master key in this request. If
    #  You have provided the master_key when initializing Parse, then all requests
    #  will send the master key by default. This feature is useful when you want to make
    #  a particular query be performed with public credentials, or on behalf of a user using
    #  a {session_token}. Default is set to true.
    #  @see #session_token
    #  @example
    #   # disable use of the master_key in the request.
    #   query = Parse::Query.new("_User", :name => "Bob", :master_key => false)
    #  @return [Boolean] whether we should send the master key in this request.
    # @!attribute [rw] session_token
    #  Set the session token to send with this API request. A session token is tied to
    #  a logged in {Parse::User}. When sending a session_token in the request,
    #  this performs the query on behalf of the user (with their allowed privileges).
    #  Using the short hand (inline) form, you can also pass an authenticated {Parse::User} instance
    #  or a {Parse::Session} instance.
    #  @example
    #   # perform this query as user represented by session_token
    #   query = Parse::Query.new("_User", :name => "Bob")
    #   query.session_token = "r:XyX123..."
    #
    #   # or inline
    #   query = Parse::Query.new("_User", :name => "Bob", :session => "r:XyX123...")
    #
    #   # or with a logged in user object
    #   user = Parse::User.login('user','pass') # => logged in user'
    #   user.session_token # => "r:XyZ1234...."
    #   query = Parse::Query.new("_User", :name => "Bob", :session => user)
    #  @raise ArgumentError if a non-nil value is passed that doesn't provide a session token string.
    #  @note Using a session_token automatically disables sending the master key in the request.
    #  @return [String] the session token to send with this API request.
    attr_accessor :table, :client, :key, :cache, :use_master_key, :session_token

    # We have a special class method to handle field formatting. This turns
    # the symbol keys in an operand from one key to another. For example, we can
    # have the keys like :cost_rate in a query be translated to "costRate" when we
    # build the query string before sending to Parse. This would allow you to have
    # underscore case for your ruby code, while still maintaining camelCase in Parse.
    # The default field formatter method is :columnize (which is camel case with the first letter
    # in lower case). You can specify a different method to call by setting the Parse::Query.field_formatter
    # variable with the symbol name of the method to call on the object. You can set this to nil
    # if you do not want any field formatting to be performed.

    @field_formatter = :columnize
    @allow_scope_introspection = false
    class << self

      # @!attribute allow_scope_introspection
      # The attribute will prevent automatically fetching results of a scope when
      # using the console. This is useful when you want to see the queries of scopes
      # instead of automatically returning the results.
      # @return [Boolean] true to have scopes return query objects instead of results when
      #  running in the console.

      # @!attribute field_formatter
      # The method to use when converting field names to Parse column names. Default is {String#columnize}.
      # By convention Parse uses lowercase-first camelcase syntax for field/column names, but ruby
      # uses snakecase. To support this methodology we process all field constraints through the method
      # defined by the field formatter. You may set this to nil to turn off this functionality.
      # @return [Symbol] The filter method to process column and field names. Default {String#columnize}.

      attr_accessor :field_formatter, :allow_scope_introspection

      # @param str [String] the string to format
      # @return [String] formatted string using {Parse::Query.field_formatter}.
      def format_field(str)
        res = str.to_s.strip
        if field_formatter.present? && res.respond_to?(field_formatter)
          res = res.send(field_formatter)
        end
        res
      end

      # Helper method to create a query with constraints for a specific Parse collection.
      # Also sets the default limit count to `:max`.
      # @param table [String] the name of the Parse collection to query. (ex. "_User")
      # @param constraints [Hash] a set of query constraints.
      # @return [Query] a new query for the Parse collection with the passed in constraints.
      def all(table, constraints = { limit: :max })
        self.new(table, constraints.reverse_merge({ limit: :max }))
      end

      # This methods takes a set of constraints and merges them to build a final
      # `where` constraint clause for sending to the Parse backend.
      # @param where [Array] an array of {Parse::Constraint} objects.
      # @return [Hash] a hash representing the compiled query
      def compile_where(where)
        constraint_reduce(where)
      end

      # @!visibility private
      def constraint_reduce(clauses)
        # @todo Need to add proper constraint merging
        clauses.reduce({}) do |clause, subclause|
          #puts "Merging Subclause: #{subclause.as_json}"

          clause.deep_merge!(subclause.as_json || {})
          clause
        end
      end

      # Applies special singleton methods to a query instance in order to
      # automatically fetch results when using any ruby console.
      # @!visibility private
      def apply_auto_introspection!(query)
        unless @allow_scope_introspection
          query.define_singleton_method(:to_s) { self.results.to_s }
          query.define_singleton_method(:inspect) { self.results.to_a.inspect }
        end
      end
    end

    # @!attribute [r] client
    # @return [Parse::Client] the client to use for making the API request.
    # @see Parse::Client::Connectable
    def client
      # use the set client or the default client.
      @client ||= self.class.client
    end

    # Clear a specific clause of this query. This can be one of: :where, :order,
    # :includes, :skip, :limit, :count, :keys or :results.
    # @param item [:Symbol] the clause to clear.
    # @return [self]
    def clear(item = :results)
      case item
      when :where
        # an array of Parse::Constraint subclasses
        @where = []
      when :order
        # an array of Parse::Order objects
        @order = []
      when :includes
        @includes = []
      when :skip
        @skip = 0
      when :limit
        @limit = nil
      when :count
        @count = 0
      when :keys
        @keys = []
      end
      @results = nil
      self # chaining
    end

    # Constructor method to create a query with constraints for a specific Parse collection.
    # Also sets the default limit count to `:max`.
    # @overload new(table)
    #   Create a query for this Parse collection name.
    #   @example
    #     Parse::Query.new "_User"
    #     Parse::Query.new "_Installation", :device_type => 'ios'
    #   @param table [String] the name of the Parse collection to query. (ex. "_User")
    #   @param constraints [Hash] a set of query constraints.
    # @overload new(parseSubclass)
    #   Create a query for this Parse model (or anything that responds to {Parse::Object.parse_class}).
    #   @example
    #     Parse::Query.new Parse::User
    #     # assume Post < Parse::Object
    #     Parse::Query.new Post, like_count.gt => 0
    #   @param parseSubclass [Parse::Object] the Parse model constant
    #   @param constraints [Hash] a set of query constraints.
    # @return [Query] a new query for the Parse collection with the passed in constraints.
    def initialize(table, constraints = {})
      table = table.to_s.to_parse_class if table.is_a?(Symbol)
      table = table.parse_class if table.respond_to?(:parse_class)
      raise ArgumentError, "First parameter should be the name of the Parse class (table)" unless table.is_a?(String)
      @count = 0 #non-zero/1 implies a count query request
      @where = []
      @order = []
      @keys = []
      @includes = []
      @limit = nil
      @skip = 0
      @table = table
      @cache = true
      @use_master_key = true
      conditions constraints
    end # initialize

    # Add a set of query expressions and constraints.
    # @example
    #  query.conditions({:field.gt => value})
    # @param expressions [Hash] containing key value pairs of Parse::Operations
    #   and their value.
    # @return [self]
    def conditions(expressions = {})
      expressions.each do |expression, value|
        if expression == :order
          order value
        elsif expression == :keys
          keys value
        elsif expression == :key
          keys [value]
        elsif expression == :skip
          skip value
        elsif expression == :limit
          limit value
        elsif expression == :include || expression == :includes
          includes(value)
        elsif expression == :cache
          self.cache = value
        elsif expression == :use_master_key
          self.use_master_key = value
        elsif expression == :session
          # you can pass a session token or a Parse::Session
          self.session_token = value
        else
          add_constraint(expression, value)
        end
      end # each
      self #chaining
    end

    alias_method :query, :conditions
    alias_method :append, :conditions

    def table=(t)
      @table = t.to_s.camelize
    end

    def session_token=(value)
      if value.respond_to?(:session_token) && value.session_token.is_a?(String)
        value = value.session_token
      end

      if value.nil? || (value.is_a?(String) && value.present?)
        @session_token = value
      else
        raise ArgumentError, "Invalid session token passed to query."
      end
    end

    # returns the query clause for the particular clause
    # @param clause_name [Symbol] One of supported clauses to return: :keys,
    #  :where, :order, :includes, :limit, :skip
    # @return [Object] the content of the clause for this query.
    def clause(clause_name = :where)
      return unless [:keys, :where, :order, :includes, :limit, :skip].include?(clause_name)
      instance_variable_get "@#{clause_name}".to_sym
    end

    # Restrict the fields returned by the query. This is useful for larger query
    # results set where some of the data will not be used, which reduces network
    # traffic and deserialization performance.
    # @example
    #  # results only contain :name field
    #  Song.all :keys => :name
    #
    #  # multiple keys
    #  Song.all :keys => [:name,:artist]
    # @note Use this feature with caution when working with the results, as
    #    values for the fields not specified in the query will be omitted in
    #    the resulting object.
    # @param fields [Array] the name of the fields to return.
    # @return [self]
    def keys(*fields)
      @keys ||= []
      fields.flatten.each do |field|
        if field.nil? == false && field.respond_to?(:to_s)
          @keys.push Query.format_field(field).to_sym
        end
      end
      @keys.uniq!
      @results = nil if fields.count > 0
      self # chaining
    end

    # Add a sorting order for the query.
    # @example
    #  # order updated_at ascending order
    #  Song.all :order => :updated_at
    #
    #  # first order by highest like_count, then by ascending name.
    #  # Note that ascending is the default if not specified (ex. `:name.asc`)
    #  Song.all :order => [:like_count.desc, :name]
    # @param ordering [Parse::Order] an ordering
    # @return [self]
    def order(*ordering)
      @order ||= []
      ordering.flatten.each do |order|
        order = Order.new(order) if order.respond_to?(:to_sym)
        if order.is_a?(Order)
          order.field = Query.format_field(order.field)
          @order.push order
        end
      end #value.each
      @results = nil if ordering.count > 0
      self #chaining
    end #order

    # Use with limit to paginate through results. Default is 0.
    # @example
    #  # get the next 3 songs after the first 10
    #  Song.all :limit => 3, :skip => 10
    # @param amount [Integer] The number of records to skip.
    # @return [self]
    def skip(amount)
      @skip = [0, amount.to_i].max
      @results = nil
      self #chaining
    end

    # Limit the number of objects returned by the query. The default is 100, with
    # Parse allowing a maximum of 1000. The framework also allows a value of
    # `:max`. Utilizing this will have the framework continually intelligently
    # utilize `:skip` to continue to paginate through results until no more results
    # match the query criteria. When utilizing `all()`, `:max` is the default
    # option for `:limit`.
    # @example
    #  Song.all :limit => 1 # same as Song.first
    #  Song.all :limit => 2025 # large limits supported.
    #  Song.all :limit => :max # as many records as possible.
    # @param count [Integer,Symbol] The number of records to return. You may pass :max
    #  to get as many records as possible (Parse-Server dependent).
    # @return [self]
    def limit(count)
      if count.is_a?(Numeric)
        @limit = [0, count.to_i].max
      elsif count == :max
        @limit = :max
      else
        @limit = nil
      end

      @results = nil
      self #chaining
    end

    def related_to(field, pointer)
      raise ArgumentError, "Object value must be a Parse::Pointer type" unless pointer.is_a?(Parse::Pointer)
      add_constraint field.to_sym.related_to, pointer
      self #chaining
    end

    # Set a list of Parse Pointer columns to be fetched for matching records.
    # You may chain multiple columns with the `.` operator.
    # @example
    #  # assuming an 'Artist' has a pointer column for a 'Manager'
    #  # and a Song has a pointer column for an 'Artist'.
    #
    #  # include the full artist object
    #  Song.all(:includes => [:artist])
    #
    #  # Chaining - fetches the artist and the artist's manager for matching songs
    #  Song.all :includes => ['artist.manager']
    # @param fields [Array] the list of Pointer columns to fetch.
    # @return [self]
    def includes(*fields)
      @includes ||= []
      fields.flatten.each do |field|
        if field.nil? == false && field.respond_to?(:to_s)
          @includes.push Query.format_field(field).to_sym
        end
      end
      @includes.uniq!
      @results = nil if fields.count > 0
      self # chaining
    end

    # Combine a list of {Parse::Constraint} objects
    # @param list [Array<Parse::Constraint>] an array of Parse::Constraint subclasses.
    # @return [self]
    def add_constraints(list)
      list = Array.wrap(list).select { |m| m.is_a?(Parse::Constraint) }
      @where = @where + list
      self
    end

    # Add a constraint to the query. This is mainly used internally for compiling constraints.
    # @example
    #  # add where :field equals "value"
    #  query.add_constraint(:field.eq, "value")
    #
    #  # add where :like_count is greater than 20
    #  query.add_constraint(:like_count.gt, 20)
    #
    #  # same, but ignore field formatting
    #  query.add_constraint(:like_count.gt, 20, filter: false)
    #
    # @param operator [Parse::Operator] an operator object containing the operation and operand.
    # @param value [Object] the value for the constraint.
    # @param opts [Object] A set of options. Passing :filter with false, will skip field formatting.
    # @see Query#format_field
    # @return [self]
    def add_constraint(operator, value = nil, opts = {})
      @where ||= []
      constraint = operator # assume Parse::Constraint
      unless constraint.is_a?(Parse::Constraint)
        constraint = Parse::Constraint.create(operator, value)
      end
      return unless constraint.is_a?(Parse::Constraint)
      # to support select queries where you have to pass a `key` parameter for matching
      # different tables.
      if constraint.operand == :key || constraint.operand == "key"
        @key = constraint.value
        return
      end

      unless opts[:filter] == false
        constraint.operand = Query.format_field(constraint.operand)
      end
      @where.push constraint
      @results = nil
      self #chaining
    end

    # @param raw [Boolean] whether to return the hash form of the constraints.
    # @return [Array<Parse::Constraint>] if raw is false, an array of constraints
    #  composing the :where clause for this query.
    # @return [Hash] if raw i strue, an hash representing the constraints.
    def constraints(raw = false)
      raw ? where_constraints : @where
    end

    # Formats the current set of Parse::Constraint instances in the where clause
    # as an expression hash.
    # @return [Hash] the set of constraints
    def where_constraints
      @where.reduce({}) { |memo, constraint| memo[constraint.operation] = constraint.value; memo }
    end

    # Add additional query constraints to the `where` clause. The `where` clause
    # is based on utilizing a set of constraints on the defined column names in
    # your Parse classes. The constraints are implemented as method operators on
    # field names that are tied to a value. Any symbol/string that is not one of
    # the main expression keywords described here will be considered as a type of
    # query constraint for the `where` clause in the query.
    # @example
    #  # parts of a single where constraint
    #  { :column.constraint => value }
    # @see Parse::Constraint
    # @param conditions [Hash] a set of constraints for this query.
    # @param opts [Hash] a set of options when adding the constraints. This is
    #  specific for each Parse::Constraint.
    # @return [self]
    def where(conditions = nil, opts = {})
      return @where if conditions.nil?
      if conditions.is_a?(Hash)
        conditions.each do |operator, value|
          add_constraint(operator, value, opts)
        end
      end
      self #chaining
    end

    # Combine two where clauses into an OR constraint. Equivalent to the `$or`
    # Parse query operation. This is useful if you want to find objects that
    # match several queries. We overload the `|` operator in order to have a
    # clean syntax for joining these `or` operations.
    # @example
    #  query = Player.where(:wins.gt => 150)
    #  query.or_where(:wins.lt => 5)
    #  # where wins > 150 || wins < 5
    #  results = query.results
    #
    #  # or_query = query1 | query2 | query3 ...
    #  # ex. where wins > 150 || wins < 5
    #  query = Player.where(:wins.gt => 150) | Player.where(:wins.lt => 5)
    #  results = query.results
    # @param where_clauses [Array<Parse::Constraint>] a list of Parse::Constraint objects to combine.
    # @return [Query] the combined query with an OR clause.
    def or_where(where_clauses = [])
      where_clauses = where_clauses.where if where_clauses.is_a?(Parse::Query)
      where_clauses = Parse::Query.new(@table, where_clauses).where if where_clauses.is_a?(Hash)
      return self if where_clauses.blank?
      # we can only have one compound query constraint. If we need to add another OR clause
      # let's find the one we have (if any)
      compound = @where.find { |f| f.is_a?(Parse::Constraint::CompoundQueryConstraint) }
      # create a set of clauses that are not an OR clause.
      remaining_clauses = @where.select { |f| f.is_a?(Parse::Constraint::CompoundQueryConstraint) == false }
      # if we don't have a OR clause to reuse, then create a new one with then
      # current set of constraints
      if compound.blank?
        compound = Parse::Constraint::CompoundQueryConstraint.new :or, [Parse::Query.compile_where(remaining_clauses)]
      end
      # then take the where clauses from the second query and append them.
      compound.value.push Parse::Query.compile_where(where_clauses)
      #compound = Parse::Constraint::CompoundQueryConstraint.new :or, [remaining_clauses, or_where_query.where]
      @where = [compound]
      self #chaining
    end

    # @see #or_where
    # @return [Query] the combined query with an OR clause.
    def |(other_query)
      raise ArgumentError, "Parse queries must be of the same class #{@table}." unless @table == other_query.table
      copy_query = self.clone
      copy_query.or_where other_query.where
      copy_query
    end

    # Queries can be made using distinct, allowing you find unique values for a specified field.
    # For this to be performant, please remember to index your database.
    # @example
    #   # Return a set of unique city names
    #   # for users who are greater than 21 years old
    #   Parse::Query.all(distinct: :age)
    #   query = Parse::Query.new("_User")
    #   query.where :age.gt => 21
    #   # triggers query
    #   query.distinct(:city) #=> ["San Diego", "Los Angeles", "San Juan"]
    # @note This feature requires use of the Master Key in the API.
    # @param field [Symbol|String] The name of the field used for filtering.
    # @version 1.8.0
    def distinct(field)
      if field.nil? == false && field.respond_to?(:to_s)
        # disable counting if it was enabled.
        old_count_value = @count
        @count = nil
        compile_query = compile # temporary store
        # add distinct field
        compile_query[:distinct] = Query.format_field(field).to_sym
        @count = old_count_value
        # perform aggregation
        return client.aggregate_objects(@table, compile_query.as_json, _opts).result
      else
        raise ArgumentError, "Invalid field name passed to `distinct`."
      end
    end

    # Perform a count query.
    # @example
    #  # get number of songs with a play_count > 10
    #  Song.count :play_count.gt => 10
    #
    #  # same
    #  query = Parse::Query.new("Song")
    #  query.where :play_count.gt => 10
    #  query.count
    # @return [Integer] the count result
    def count
      old_value = @count
      @count = 1
      res = client.find_objects(@table, compile.as_json, _opts).count
      @count = old_value
      res
    end

    # @yield a block yield for each object in the result
    # @return [Array]
    # @see Array#each
    def each(&block)
      return results.enum_for(:each) unless block_given? # Sparkling magic!
      results.each(&block)
    end

    # @yield a block yield for each object in the result
    # @return [Array]
    # @see Array#map
    def map(&block)
      return results.enum_for(:map) unless block_given? # Sparkling magic!
      results.map(&block)
    end

    # @yield a block yield for each object in the result
    # @return [Array]
    # @see Array#select
    def select(&block)
      return results.enum_for(:select) unless block_given? # Sparkling magic!
      results.select(&block)
    end

    # @return [Array]
    # @see Array#to_a
    def to_a
      results.to_a
    end

    # @param limit [Integer] the number of first items to return.
    # @return [Parse::Object] the first object from the result.
    def first(limit = 1)
      @results = nil if @limit != limit
      @limit = limit
      limit == 1 ? results.first : results.first(limit)
    end

    # max_results is used to iterate through as many API requests as possible using
    # :skip and :limit paramter.
    # @!visibility private
    def max_results(raw: false, on_batch: nil, discard_results: false, &block)
      compiled_query = compile
      batch_size = 1_000
      results = []
      # determine if there is a user provided hard limit
      _limit = (@limit.is_a?(Numeric) && @limit > 0) ? @limit : nil
      compiled_query[:skip] ||= 0

      loop do
        # always reset the batch size
        compiled_query[:limit] = batch_size

        # if a hard limit was set by the user, then if the remaining amount
        # is less than the batch size, set the new limit to the remaining amount.
        unless _limit.nil?
          compiled_query[:limit] = _limit if _limit < batch_size
        end

        response = fetch!(compiled_query)
        break if response.error? || response.results.empty?

        items = response.results
        items = decode(items) unless raw
        # if a block is provided, we do not keep the results after processing.
        if block_given?
          items.each(&block)
        else
          # concat results unless discard_results is true
          results += items unless discard_results
        end

        on_batch.call(items) if on_batch.present?
        # if we get less than the maximum set of results, most likely the next
        # query will return emtpy results - no need to perform it.
        break if items.count < compiled_query[:limit]

        # if we have a set limit, then subtract from the total amount the user requested
        # from the total in the current result set. Break if we've reached our limit.
        unless _limit.nil?
          _limit -= items.count
          break if _limit < 1
        end

        # add to the skip count for the next iteration
        compiled_query[:skip] += batch_size
      end
      results
    end

    # @!visibility private
    def _opts
      opts = {}
      opts[:cache] = self.cache || false
      opts[:use_master_key] = self.use_master_key
      opts[:session_token] = self.session_token
      # for now, don't cache requests where we disable master_key or provide session token
      # if opts[:use_master_key] == false || opts[:session_token].present?
      #   opts[:cache] = false
      # end
      opts
    end

    # Performs the fetch request for the query.
    # @param compiled_query [Hash] the compiled query
    # @return [Parse::Response] a response for a query request.
    def fetch!(compiled_query)
      response = client.find_objects(@table, compiled_query.as_json, **_opts)
      if response.error?
        puts "[ParseQuery] #{response.error}"
      end
      response
    end

    alias_method :execute!, :fetch!

    # Executes the query and builds the result set of Parse::Objects that matched.
    # When this method is passed a block, the block is yielded for each matching item
    # in the result, and the items are not returned. This methodology is more performant
    # as large quantifies of objects are fetched in batches and all of them do
    # not have to be kept in memory after the query finishes executing. This is the recommended
    # method of processing large result sets.
    # @example
    #  query = Parse::Query.new("_User", :created_at.before => DateTime.now)
    #  users = query.results # => Array of Parse::User objects.
    #
    #  query = Parse::Query.new("_User", limit: :max)
    #
    #  query.results do |user|
    #   # recommended; more memory efficient
    #  end
    #
    # @param raw [Boolean] whether to get the raw hash results of the query instead of
    #   a set of Parse::Object subclasses.
    # @yield a block to iterate for each object that matched the query.
    # @return [Array<Hash>] if raw is set to true, a set of Parse JSON hashes.
    # @return [Array<Parse::Object>] if raw is set to false, a list of matching Parse::Object subclasses.
    def results(raw: false, &block)
      if @results.nil?
        if block_given?
          max_results(raw: raw, &block)
        elsif @limit.is_a?(Numeric)
          response = fetch!(compile)
          return [] if response.error?
          items = raw ? response.results : decode(response.results)
          return items.each(&block) if block_given?
          @results = items
        else
          @results = max_results(raw: raw)
        end
      end
      @results
    end

    alias_method :result, :results

    # Similar to {#results} but takes an additional set of conditions to apply. This
    # method helps support the use of class and instance level scopes.
    # @param expressions (see #conditions)
    # @yield (see #results)
    # @return [Array<Hash>] if raw is set to true, a set of Parse JSON hashes.
    # @return [Array<Parse::Object>] if raw is set to false, a list of matching Parse::Object subclasses.
    # @see #results
    def all(expressions = { limit: :max }, &block)
      conditions(expressions)
      return results(&block) if block_given?
      results
    end

    # Builds objects based on the set of Parse JSON hashes in an array.
    # @param list [Array<Hash>] a list of Parse JSON hashes
    # @return [Array<Parse::Object>] an array of Parse::Object subclasses.
    def decode(list)
      list.map { |m| Parse::Object.build(m, @table) }.compact
    end

    # @return [Hash]
    def as_json(*args)
      compile.as_json
    end

    # Returns a compiled query without encoding the where clause.
    # @param includeClassName [Boolean] whether to include the class name of the collection
    #  in the resulting compiled query.
    # @return [Hash] a hash representing the prepared query request.
    def prepared(includeClassName: false)
      compile(encode: false, includeClassName: includeClassName)
    end

    # Complies the query and runs all prepare callbacks.
    # @param encode [Boolean] whether to encode the `where` clause to a JSON string.
    # @param includeClassName [Boolean] whether to include the class name of the collection.
    # @return [Hash] a hash representing the prepared query request.
    # @see #before_prepare
    # @see #after_prepare
    def compile(encode: true, includeClassName: false)
      run_callbacks :prepare do
        q = {} #query
        q[:limit] = @limit if @limit.is_a?(Numeric) && @limit > 0
        q[:skip] = @skip if @skip > 0

        q[:include] = @includes.join(",") unless @includes.empty?
        q[:keys] = @keys.join(",") unless @keys.empty?
        q[:order] = @order.join(",") unless @order.empty?
        unless @where.empty?
          q[:where] = Parse::Query.compile_where(@where)
          q[:where] = q[:where].to_json if encode
        end

        if @count && @count > 0
          # if count is requested
          q[:limit] = 0
          q[:count] = 1
        end
        if includeClassName
          q[:className] = @table
        end
        q
      end
    end

    # @return [Hash] a hash representing just the `where` clause of this query.
    def compile_where
      self.class.compile_where(@where || [])
    end

    # Retruns a formatted JSON string representing the query, useful for debugging.
    # @return [String]
    def pretty
      JSON.pretty_generate(as_json)
    end
  end # Query
end # Parse
