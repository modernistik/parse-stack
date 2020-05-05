require_relative "../../../../test_helper"

class TestLessThanConstraint < Minitest::Test
  extend Minitest::Spec::DSL
  include ConstraintTests

  def setup
    @klass = Parse::Constraint::LessThanConstraint
    @key = :$lt
    @operand = :lt
    @keys = [:lt, :less_than, :before]
  end
end
