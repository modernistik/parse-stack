require_relative '../../../../test_helper'

class TestNotContainedInConstraint < Minitest::Test
  extend Minitest::Spec::DSL
  include ConstraintTests

  def setup
    @klass = Parse::NotContainedInConstraint
    @key = :$nin
    @operand = :not_in
    @keys = [:not_in, :nin, :not_contained_in]
  end

  def build(value)
    {"field" =>  { @key.to_s  => [Parse::Constraint.formatted_value(value)].flatten.compact } }
  end

end
