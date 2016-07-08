require_relative "client"
require_relative "query/operation"
require_relative "query/constraints"
require_relative "query/ordering"


module Parse
  # This is the main engine behind making Parse queries on tables. It takes
  # a set of constraints and generatse the proper hash parameters that are passed
  # to a client :get request in order to retrive the results.
  # The design of querying is based on ruby DataMapper orm where we define
  # symbols with specific methos attached to values.
  # At the core of each item is a Parse::Operation. An operation is
  # made up of a field name and an operator. Therefore calling
  # something like :name.eq, defines an equality operator on the field
  # name. Using Parse::Operations with values, we can build different types of
  # constraints - as Parse::Constraint

  class Query
    include Parse::Client::Connectable
    # A query needs to be tied to a Parse table name (Parse class)
    # The client object is of type Parse::Client in order to send query requests.
    # You can modify the default client being used by all Parse::Query objects by setting
    # Parse::Query.client. You can override individual Parse::Query object clients
    # by changing their client variable to a different Parse::Client object.
    attr_accessor :table, :client, :key, :cache, :use_master_key

    # We have a special class method to handle field formatting. This turns
    # the symbol keys in an operand from one key to another. For example, we can
    # have the keys like :cost_rate in a query be translated to "costRate" when we
    # build the query string before sending to Parse. This would allow you to have
    # underscore case for your ruby code, while still maintaining camelCase in Parse.
    # The default field formatter method is :columnize (which is camel case with the first letter
    # in lower case). You can specify a different method to call by setting the Parse::Query.field_formatter
    # variable with the symbol name of the method to call on the object. You can set this to nil
    # if you do not want any field formatting to be performed.
    class << self
      #field formatter getters and setters.
      attr_accessor :field_formatter

      def field_formatter
        #default
        @field_formatter ||= :columnize
      end

      def format_field(str)
        res = str.to_s
        if field_formatter.present?
          formatter = field_formatter.to_sym
          # don't format if object d
          res = res.send(formatter) if res.respond_to?(formatter)
        end
        res.strip
      end

      # Simple way to create a query.
      def all(table, constraints = {})
        self.new(table, {limit: :max}.merge(constraints) )
      end

    end

    def client
      # use the set client or the default client.
      @client ||= self.class.client
    end

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
        @limit = 100
      when :count
        @count = 0
      when :keys
        @keys = []
      end
      @results = nil

      self
    end

    def initialize(table, constraints = {})
      raise "First parameter should be the name of the Parse class (table)" unless table.is_a?(String)
      @count = 0 #non-zero/1 implies a count query request
      @where = []
      @order = []
      @keys = []
      @includes = []
      @limit = 100
      @skip = 0
      @table = table
      @cache = true
      @use_master_key = true
      conditions constraints
      self # chaining
    end # initialize

    def conditions(expressions = {})
      expressions.each do |expression, value|
        if expression == :order
          order value
        elsif expression == :keys
          keys value
        elsif expression == :key
          @key = value
        elsif expression == :skip
          skip value
        elsif expression == :limit
          limit value
        elsif expression == :include || expression == :includes
          includes(value)
        elsif expression == :cache
          self.cache = value
        elsif expression == :use_master_key
          self.cache = value
        else
          add_constraint(expression, value)
        end
      end # each
    end

    def table=(t)
      @table = t.to_s.camelize
    end

    # returns the query parameter for the particular clause
    def clause(clause_name = :where)
      return unless [:keys, :where, :order, :includes, :limit, :skip].include?(clause_name)
      instance_variable_get "@#{clause_name}".to_sym
    end

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

    def skip(count)
      #  min <= count <= max
      @skip = [ 0, count.to_i, 10_000].sort[1]
      @results = nil
      self #chaining
    end

    def limit(count)
      if count == :max || count == :all
        @limit = 11_000
      elsif count.is_a?(Numeric)
        @limit = [ 0, count.to_i, 11_000].sort[1]
      end

      @results = nil
      self #chaining
    end

    def related_to(field, pointer)
      raise "Object value must be a Parse::Pointer type" unless pointer.is_a?(Parse::Pointer)
      add_constraint field.to_sym.related_to, pointer
      self
    end

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
    alias_method :include, :includes

    def add_constraint(operator, value, opts = {})
      @where ||= []
      constraint = Parse::Constraint.create operator, value
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
    def constraints; @where; end;

    def where(conditions = nil, opts = {})
      return @where if conditions.nil?
      if conditions.is_a?(Hash)
        conditions.each do |operator, value|
          add_constraint(operator, value, opts)
        end
      end
      self  #chaining
    end

    def or_where(where_clauses = [])
      where_clauses = where_clauses.where if where_clauses.is_a?(Parse::Query)
      where_clauses = Parse::Query.new(@table, where_clauses ).where if where_clauses.is_a?(Hash)
      return self if where_clauses.blank?
      # we can only have one compound query constraint. If we need to add another OR clause
      # let's find the one we have (if any)
      compound = @where.find { |f| f.is_a?(Parse::CompoundQueryConstraint) }
      # create a set of clauses that are not an OR clause.
      remaining_clauses = @where.select { |f| f.is_a?(Parse::CompoundQueryConstraint) == false }
      # if we don't have a OR clause to reuse, then create a new one with then
      # current set of constraints
      if compound.blank?
        compound = Parse::CompoundQueryConstraint.new :or, [ Parse::Query.compile_where(remaining_clauses) ]
      end
      # then take the where clauses from the second query and append them.
      compound.value.push Parse::Query.compile_where(where_clauses)
      #compound = Parse::CompoundQueryConstraint.new :or, [remaining_clauses, or_where_query.where]
      @where = [compound]
      self #chaining
    end

    def |(other_query)
        raise "Parse queries must be of the same class #{@table}." unless @table == other_query.table
        copy_query = self.clone
        copy_query.or_where other_query.where
        copy_query
    end

    def count
      @results = nil
      old_value = @count
      @count = 1
      res = client.find_objects(@table, compile.as_json ).count
      @count = old_value
      res
    end

    def each
       return results.enum_for(:each) unless block_given? # Sparkling magic!
       results.each(&Proc.new)
    end

    def first(limit = 1)
      @results = nil
      @limit = limit
      limit == 1 ? results.first : results.first(limit)
    end

    def max_results(raw: false)
      compiled_query = compile
      query_limit = compiled_query[:limit] ||= 1_000
      query_skip =  compiled_query[:skip] ||= 0
      compiled_query[:limit] = 1_000
      iterations = (query_limit/1000.0).ceil
      results = []

      iterations.times do |idx|
        #puts "Fetching 1000 after #{compiled_query[:skip]}"
        response = fetch!( compiled_query )
        break if response.error? || response.results.empty?
        #puts "Appending #{response.results.count} results..."
        items = response.results
        items = decode(items) unless raw

        if block_given?
          items.each(&Proc.new)
        else
          results += items
        end
        # if we get less than the maximum set of results, most likely the next
        # query will return emtpy results - no need to perform it.
        break if items.count < compiled_query[:limit]
        # add to the skip count for the next iteration
        compiled_query[:skip] += 1_000
        break if compiled_query[:skip] > 10_000
      end
      results
    end

    def fetch!(compiled_query)
      opts = {}
      opts[:cache] = false unless self.cache
      opts[:use_mster_key] = self.use_master_key
      response = client.find_objects(@table, compiled_query.as_json, opts )
      if response.error?
        puts "[ParseQuery] #{response.error}"
      end
      response
    end

    def results(raw: false)
      if @results.nil?
        if @limit <= 1_000
          response = fetch!( compile )
          return [] if response.error?
          items = raw ? response.results : decode(response.results)
          return items.each(&Proc.new) if block_given?
          @results = items
        elsif block_given?
          return max_results(raw: raw, &Proc.new)
        else
          @results = max_results(raw: raw)
        end
      end
      @results
    end
    alias_method :result, :results

    def decode(list)
      list.map { |m| Parse::Object.build(m, @table) }.compact
    end

    def as_json(*args)
      compile.as_json
    end

    def compile(encode = true)
      q = {} #query
      q[:limit] = 11_000 if @limit == :max || @limit == :all
      q[:limit] = @limit if @limit.is_a?(Numeric) && @limit > 0
      q[:skip] = @skip if @skip > 0

      q[:include] = @includes.join(',') unless @includes.empty?
      q[:keys] = @keys.join(',')  unless @keys.empty?
      q[:order] = @order.join(',') unless @order.empty?
      unless @where.empty?
        q[:where] = Parse::Query.compile_where(@where)
        q[:where] = q[:where].to_json if encode
      end

      if @count && @count > 0
        # if count is requested
        q[:limit] = 0
        q[:count] = 1
      end
      q
    end

    def compile_where
      self.class.compile_where( @where || [] )
    end

    def self.compile_where(where)
      constraint_reduce( where )
    end

    def self.constraint_reduce(clauses)
      # TODO: Need to add proper constraint merging
      clauses.reduce({}) do |clause, subclause|
        #puts "Merging Subclause: #{subclause.as_json}"

        clause.deep_merge!( subclause.as_json || {} )
        clause
      end
    end

    def print
      puts JSON.pretty_generate( as_json )
    end

  end # Query

end # Parse
