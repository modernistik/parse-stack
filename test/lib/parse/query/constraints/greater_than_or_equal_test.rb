require_relative "../../../../test_helper"

class TestGreaterThanOrEqualConstraint < Minitest::Test
  extend Minitest::Spec::DSL
  include ConstraintTests

  def setup
    @klass = Parse::Constraint::GreaterThanOrEqualConstraint
    @key = :$gte
    @operand = :gte
    @keys = [:gte, :greater_than_or_equal, :on_or_after]
  end
end
