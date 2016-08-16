require_relative '../../../../test_helper'

class TestContainsAllConstraint < Minitest::Test
  extend Minitest::Spec::DSL
  include ConstraintTests

  def setup
    @klass = Parse::ContainsAllConstraint
    @key = :$all
    @operand = :all
    @keys = [:all, :contains_all]
  end

  def build(value)
    {"field" =>  { @key.to_s  => [Parse::Constraint.formatted_value(value)].flatten.compact } }
  end
  
end
