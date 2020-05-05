require_relative "../../../../test_helper"

class TestNearSphereQueryConstraint < Minitest::Test
  extend Minitest::Spec::DSL
  include ConstraintTests

  def setup
    @klass = Parse::Constraint::NearSphereQueryConstraint
    @key = :$nearSphere
    @operand = :near
    @keys = [:near]
    @skip_scalar_values_test = true
  end

  def build(value)
    { "field" => { @key.to_s => value } }
  end
end
