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

  def test_scalar_values

  [true, false].each do |value|
    constraint = @klass.new(:field, value)
    expected = build(value).as_json
    assert_equal expected, constraint.build.as_json
  end

  ["true", 1, nil].each do |value|
    constraint = @klass.new(:field, value)
    assert_raises(Parse::ConstraintError) do
      constraint.build.as_json
    end
  end

end

end
