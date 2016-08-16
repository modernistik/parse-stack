require_relative '../../../../test_helper'

class TestNullabilityConstraint < Minitest::Test
  extend Minitest::Spec::DSL
  include ConstraintTests

  def setup
    @klass = Parse::NullabilityConstraint
    @key = :$exists
    @operand = :null
    @keys = [:null]
  end

  def build(value)
    value = Parse::Constraint.formatted_value(value)
    if value == true
      {"field" => { @key => false } }
    else
      {"field" => { Parse::NotEqualConstraint.key => nil } }
    end
  end


end
