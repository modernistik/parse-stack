require_relative '../../../../test_helper'

class TestNotInQueryConstraint < Minitest::Test
  extend Minitest::Spec::DSL
  include ConstraintTests

  def setup
    @klass = Parse::Constraint::NotInQueryConstraint
    @key = :$notInQuery
    @operand = :excludes
    @keys = [:excludes, :not_in_query]
    @skip_scalar_values_test = true
  end

end
