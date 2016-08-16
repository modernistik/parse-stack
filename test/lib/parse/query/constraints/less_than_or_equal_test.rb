require_relative '../../../../test_helper'

class TestLessThanOrEqualConstraint < Minitest::Test
  extend Minitest::Spec::DSL
  include ConstraintTests

  def setup
    @klass = Parse::LessThanOrEqualConstraint
    @key = :$lte
    @operand = :lte
    @keys = [:lte, :less_than_or_equal, :on_or_before]
  end

end
