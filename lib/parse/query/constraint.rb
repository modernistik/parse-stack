# encoding: UTF-8
# frozen_string_literal: true

require_relative 'operation'
require 'time'
require 'date'

module Parse
  # Constraints are the heart of the Parse::Query system.
  # Each constraint is made up of an Operation and a value (the right side
  # of an operator). Constraints are responsible for making their specific
  # Parse hash format required when sending Queries to Parse. All constraints can
  # be combined by merging different constraints (since they are multiple hashes)
  # and some constraints may have higher precedence than others (ex. equality is higher
  # precedence than an "in" query).
  #
  # All constraints should inherit from Parse::Constraint and should
  # register their specific Operation method (ex. :eq or :lte)
  # For more information about the query design pattern from DataMapper
  # that inspired this, see http://datamapper.org/docs/find.html
  class Constraint

    # @!attribute operation
    # The operation tied to this constraint.
    # @return [Parse::Operation]

    # @!attribute value
    # The value to be applied to this constraint.
    # @return [Parse::Operation]

    attr_accessor :operation, :value

    # Create a new constraint.
    # @param operation [Parse::Operation] the operation for this constraint.
    # @param value [Object] the value to attach to this constraint.
    # @yield You may also pass a block to modify the operation or value.
    def initialize(operation, value)
      # if the first parameter is not an Operation, but it is a symbol
      # it most likely is just the field name, so let's assume they want
      # the default equality operation.
      if operation.is_a?(Operation) == false && operation.respond_to?(:to_sym)
          operation = Operation.new(operation.to_sym, self.class.operand)
      end
      @operation = operation
      @value = value
      yield(self) if block_given?

    end

    class << self
      # @!attribute key
      # The class attributes keep track of the Parse key (special Parse
      # text symbol representing this operation. Ex. local method could be called
      # .ex, where the Parse Query operation that should be sent out is "$exists")
      # in this case, key should be set to "$exists"
      # @return [Symbol]
      attr_accessor :key

      # @!attribute precedence
      # Precedence defines the priority of this operation when merging.
      # The higher the more priority it will receive.
      # @return [Integer]
      attr_accessor :precedence

      # @!attribute operand
      # @return [Symbol] the operand for this constraint.
      attr_accessor :operand

      # Creates a new constraint given an operation and value.
      def create(operation, value)
        #default to a generic equality constraint if not passed an operation
        unless operation.is_a?(Parse::Operation) && operation.valid?
          return self.new(operation, value)
        end
        operation.constraint(value)
      end

      # Set the keyword for this Constaint. Subclasses should use this method.
      # @param keyword [Symbol]
      # @return (see key)
      def contraint_keyword(keyword)
        @key = keyword
      end

      # Set the default precedence for this constraint.
      # @param priority [Integer] a higher priority has higher precedence
      # @return [Integer]
      def precedence(priority = nil)
        @precedence = 0 if @precedence.nil?
        @precedence = priority unless priority.nil?
        @precedence
      end

      # Register the given operand for this Parse::Constraint subclass.
      # @note All subclasses should register their operation and themselves.
      # @param op [Symbol] the operand
      # @param klass [Parse::Constraint] a subclass of Parse::Constraint
      # @return (see Parse::Operation.register)
      def register(op, klass = self)
        self.operand ||= op
        Operation.register op, klass
      end

      # @return [Object] a formatted value based on the data type.
      def formatted_value(value)
        d = value
        d = { __type: Parse::Model::TYPE_DATE, iso: d.utc.iso8601(3) } if d.respond_to?(:utc)
        # if it responds to parse_date (most likely a time/date object), then call the conversion
        d = d.parse_date if d.respond_to?(:parse_date)
        # if it's not a Parse::Date, but still responds to iso8601, then do it manually
        if d.is_a?(Parse::Date) == false && d.respond_to?(:iso8601)
          d = { __type: Parse::Model::TYPE_DATE, iso: d.iso8601(3) }
        end
        d = d.pointer if d.respond_to?(:pointer) #simplified query object
        d = d.to_s if d.is_a?(Regexp)
        # d = d.pointer if d.is_a?(Parse::Object) #simplified query object
        #  d = d.compile
        if d.is_a?(Parse::Query)
          compiled = d.compile(encode: false, includeClassName: true)
          # compiled["className"] = d.table
          d = compiled
        end
        d
      end

    end

    # @return [Integer] the precedence of this constraint
    def precedence
      self.class.precedence
    end

    # @return [Symbol] the Parse keyword for this constraint.
    def key
      self.class.key
    end

    # @!attribute operand
    # @return [Symbol] the operand for the operation.
    def operand
      @operation.operand unless @operation.nil?
    end

    def operand=(o)
      @operation.operand = o unless @operation.nil?
    end

    # @!attribute operator
    # @return [Symbol] the operator for the operation.
    def operator
      @operation.operator unless @operation.nil?
    end

    def operator=(o)
      @operation.operator = o unless @operation.nil?
    end

    # @!visibility private
    def inspect
      "<#{self.class} #{operator.to_s}(#{operand.inspect}, `#{value}`)>"
    end

    # Calls build internally
    # @return [Hash]
    def as_json(*args)
      build
    end

    # Builds the JSON hash representation of this constraint for a Parse query.
    # This method should be overriden by subclasses. The default implementation
    # implements buildling the equality constraint.
    # @raise ArgumentError if the constraint could be be build due to a bad parameter.
    #  This will be different depending on the constraint subclass.
    # @return [Hash]
    def build
      return { @operation.operand => formatted_value } if @operation.operator == :eq || key.nil?
      { @operation.operand => { key => formatted_value } }
    end

    # @return [String] string representation of this constraint.
    def to_s
      inspect
    end

    # @return [Object] formatted value based on the specific data type.
    def formatted_value
      self.class.formatted_value(@value)
    end

    # Registers the default constraint of equality
    register :eq, Constraint
    precedence 100
  end
end
