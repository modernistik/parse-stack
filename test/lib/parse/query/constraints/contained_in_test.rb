require_relative '../../../../test_helper'

class TestContainedInConstraint < Minitest::Test
  extend Minitest::Spec::DSL
  include ConstraintTests

  def setup
    @klass = Parse::ContainedInConstraint
    @key = :$in
    @operand = :in
    @keys = [:in, :contained_in]
  end

  def build(value)
    {"field" =>  { @key.to_s  => [Parse::Constraint.formatted_value(value)].flatten.compact } }
  end

end
