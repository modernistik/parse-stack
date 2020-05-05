require_relative "../../../../test_helper"

class TestWithinGeoBoxQueryConstraint < Minitest::Test
  extend Minitest::Spec::DSL
  include ConstraintTests

  def setup
    @klass = Parse::Constraint::WithinGeoBoxQueryConstraint
    @key = :$within
    @operand = :within_box
    @keys = [:within_box]
    @skip_scalar_values_test = true
  end

  def build(value)
    { "field" => { @key => { :$box => value } } }
  end
end
