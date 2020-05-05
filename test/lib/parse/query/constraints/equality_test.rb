require_relative "../../../../test_helper"

class TestEqualityConstraint < Minitest::Test
  extend Minitest::Spec::DSL
  include ConstraintTests

  def setup
    @klass = Parse::Constraint
    @key = nil
    @operand = :eq
    @keys = [:eq]
  end

  def build(value)
    { "field" => Parse::Constraint.formatted_value(value) }
  end
end
