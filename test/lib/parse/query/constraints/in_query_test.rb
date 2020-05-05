require_relative "../../../../test_helper"

class TestInQueryConstraint < Minitest::Test
  extend Minitest::Spec::DSL
  include ConstraintTests

  def setup
    @klass = Parse::Constraint::InQueryConstraint
    @key = :$inQuery
    @operand = :matches
    @keys = [:matches, :in_query]
    @skip_scalar_values_test = true
  end

  def build(value)
    { "field" => { @key.to_s => Parse::Constraint.formatted_value(value) } }
  end
end
