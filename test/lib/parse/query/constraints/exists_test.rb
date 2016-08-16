require_relative '../../../../test_helper'

class TestExistsConstraint < Minitest::Test
  extend Minitest::Spec::DSL
  include ConstraintTests

  def setup
    @klass = Parse::ExistsConstraint
    @key = :$exists
    @operand = :exists
    @keys = [:exists]
  end

  def build(value)
    value = Parse::Constraint.formatted_value(value)
    value = value.present? ? true : false
    {"field" => { @key => value } }
  end

end
