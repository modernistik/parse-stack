require_relative "../../../../test_helper"

class TestNotEqualConstraint < Minitest::Test
  extend Minitest::Spec::DSL
  include ConstraintTests

  def setup
    @klass = Parse::Constraint::NotEqualConstraint
    @key = :$ne
    @operand = :not
    @keys = [:not, :ne]
  end
end
