require_relative '../../../../test_helper'

class TestGreaterThanConstraint < Minitest::Test
  extend Minitest::Spec::DSL
  include ConstraintTests

  def setup
    @klass = Parse::GreaterThanConstraint
    @key = :$gt
    @operand = :gt
    @keys = [:gt, :greater_than, :after]
  end

end
