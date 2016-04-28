require_relative 'operation'
require 'time'
# Constraints are the heart of the Parse::Query system.
# Each constraint is made up of an Operation and a value (the right side
# of an operator). Constraints are responsible for making their specific
# Parse hash format required when sending Queries to Parse. All constraints can
# be combined by merging different constraints (since they are multiple hashes)
# and some constraints may have higher precedence than others (ex. equality is higher
# precedence than an "in" query).
# All constraints should inherit from Parse::Constraint and should
# register their specific Operation method (ex. :eq or :lte)
# For more information about the query design pattern from DataMapper
# that inspired this, see http://datamapper.org/docs/find.html
module Parse
  class Constraint

    attr_accessor :operation, :value
    # A constraint needs an operation and a value.
    # You may also pass a block to modify the operation if needed
    def initialize(operation, value)
      # if the first parameter is not an Operation, but it is a symbol
      # it most likely is just the field name, so let's assume they want
      # the default equality operation.
      if operation.is_a?(Operation) == false && operation.respond_to?(:to_sym)
          operation = Operation.new(operation.to_sym, :eq)
      end
      @operation = operation
      @value = value
      yield(self) if block_given?

    end

    # Creates a new constraint given an operation and value.
    def self.create(operation, value)
      #default to a generic equality constraint if not passed an operation
      unless operation.is_a?(Parse::Operation) && operation.valid?
        return self.new(operation, value)
      end
      operation.constraint(value)
    end

    class << self
      # The class attributes keep track of the Parse key (special Parse
      # text symbol representing this operation. Ex. local method could be called
      # .ex, where the Parse Query operation that should be sent out is "$exists")
      # in this case, key should be set to "$exists"
      attr_accessor :key
      # Precedence defines the priority of this operation when merging.
      # The higher the more priority it will receive.
      attr_accessor :precedence

      # method to set the keyword for this Constaint (subclasses)
      def contraint_keyword(k)
        @key = k
      end

      def precedence(v = nil)
        @precedence = 0 if @precedence.nil?
        @precedence = v unless v.nil?
        @precedence
      end

    end

    def precedence
      self.class.precedence
    end

    def key
      self.class.key
    end

    # All subclasses should register their operation and themselves
    # as the handler.
    def self.register(op, klass = self)
      Operation.register op, klass
    end

    def operand
      @operation.operand unless @operation.nil?
    end
    def operand=(o)
      @operation.operand = o unless @operation.nil?
    end

    def operator
      @operation.operator unless @operation.nil?
    end

    def operator=(o)
      @operation.operator = o unless @operation.nil?
    end

    def inspect
      "<#{self.class} #{operator.to_s}(#{operand.inspect}, `#{value}`)>"
    end

    def as_json(*args)
      build
    end

    # subclasses should override the build method depending on how they
    # need to construct the Parse formatted query hash
    # The default case below is for supporting equality.
    # Before the final value is set int he hash, we call formatted_value in case
    # we need to format the value for particular data types.
    def build
      return { @operation.operand => formatted_value } if @operation.operator == :eq || key.nil?
      { @operation.operand => { key => formatted_value } }
    end

    def to_s
      inspect
    end

    # This method formats the value based on some specific data types.
    def formatted_value
      d = @value
      d = { __type: "Date", iso: d.utc.iso8601(3) } if d.respond_to?(:utc)
      d = { __type: "Date", iso: d.iso8601(3) } if d.respond_to?(:iso8601)
      d = d.pointer if d.respond_to?(:pointer) #simplified query object
      d = d.to_s if d.is_a?(Regexp)
      #d = d.pointer if d.is_a?(Parse::Object) #simplified query object
      #  d = d.compile
      if d.is_a?(Parse::Query)
        compiled = d.compile(false)
        compiled["className"] = d.table
        d = compiled
      end
      d
    end

    register :eq, Constraint
    register :eql, Constraint
    precedence 100
  end
end
