require 'active_support/inflector'

# The base operation class used in generating queries.
# An Operation contains an operand (field) and the
# operator (ex. equals, greater than, etc)
# Each unique operation type needs a handler that is responsible
# for creating a Constraint with a given value.
# When creating a new operation, you need to register the operation
# method and the class that will be the handler.
module Parse
  class Operation
    attr_accessor :operand, :operator
    class << self
      attr_accessor :operators
      def operators
        @operators ||= {}
      end
    end
    # a valid Operation has a handler, operand and operator.
    def valid?
      ! (@operand.nil? || @operator.nil? || handler.nil?)
    end

    # returns the constraint class designed to handle this operator
    def handler
      Operation.operators[@operator] unless @operator.nil?
    end

    def initialize(field, op)
      self.operand = field.to_sym
      self.operand = :objectId if operand == :id
      self.operator = op.to_sym
    end

    def inspect
      "#{operator.inspect}(#{operand.inspect})"
    end

    # create a new constraint based on the handler that had
    # been registered with this operation.
    def constraint(value = nil)
      handler.new(self, value)
    end

    # have a way to register an operation type.
    # Example:
    # register :eq, MyEqualityHandlerClass
    # the above registered the equality operator which we define to be
    # a new method on the Symbol class ('eq'), which when passed a value
    # we will forward the request to the MyEqualityHandlerClass, so that
    # for a field called 'name', we can do
    #
    # :name.eq (returns operation)
    # :name.eq(value) # returns constraint provided by the handler
    #
    def self.register(op, klass)
        Operation.operators[op.to_sym] = klass
        Symbol.send :define_method, op do |value = nil|
          operation = Operation.new self, op
          value.nil? ? operation : operation.constraint(value)
        end
    end

  end

end
