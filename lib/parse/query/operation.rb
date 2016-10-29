# encoding: UTF-8
# frozen_string_literal: true

require 'active_support'
require 'active_support/inflector'


module Parse

  # An operation is the core part of {Parse::Constraint} when performing
  # queries. It contains an operand (the Parse field) and an operator (the Parse
  # operation). These combined with a value, provide you with a constraint.
  #
  # All operation registrations add methods to the Symbol class.
  class Operation

    # @!attribute operand
    # The field in Parse for this operation.
    # @return [Symbol]
    attr_accessor :operand

    # @!attribute operator
    # The type of Parse operation.
    # @return [Symbol]
    attr_accessor :operator

    class << self
      # @return [Hash] a hash containing all supported Parse operations mapped
      # to their {Parse::Constraint} subclass.
      attr_accessor :operators

      def operators
        @operators ||= {}
      end
    end

    # Whether this operation is defined properly.
    def valid?
      ! (@operand.nil? || @operator.nil? || handler.nil?)
    end

    # @return [Parse::Constraint] the constraint class designed to handle
    #  this operator.
    def handler
      Operation.operators[@operator] unless @operator.nil?
    end

    # Create a new operation.
    # @param field [Symbol] the name of the Parse field
    # @param op [Symbol] the operator name (ex. :eq, :lt)
    def initialize(field, op)
      self.operand = field.to_sym
      self.operand = :objectId if operand == :id
      self.operator = op.to_sym
    end

    # @!visibility private
    def inspect
      "#{operator.inspect}(#{operand.inspect})"
    end

    # Create a new constraint based on the handler that had
    # been registered with this operation.
    # @param value [Object] a value to pass to the constraint subclass.
    # @return [Parse::Constraint] a constraint with this operation and value.
    def constraint(value = nil)
      handler.new(self, value)
    end

    # Register a new symbol operator method mapped to a specific {Parse::Constraint}.
    def self.register(op, klass)
        Operation.operators[op.to_sym] = klass
        Symbol.send :define_method, op do |value = nil|
          operation = Operation.new self, op
          value.nil? ? operation : operation.constraint(value)
        end
    end

  end

end
