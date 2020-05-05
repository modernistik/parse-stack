require_relative "../../../../test_helper"

class TestNullabilityConstraint < Minitest::Test
  extend Minitest::Spec::DSL
  include ConstraintTests

  def setup
    @klass = Parse::Constraint::NullabilityConstraint
    @key = :$exists
    @operand = :null
    @keys = [:null]
  end

  def build(value)
    value = Parse::Constraint.formatted_value(value)
    if value == true
      { "field" => { @key => false } }
    else
      { "field" => { Parse::Constraint::NotEqualConstraint.key => nil } }
    end
  end

  def test_scalar_values
    [true, false].each do |value|
      constraint = @klass.new(:field, value)
      expected = build(value).as_json
      assert_equal expected, constraint.build.as_json
    end

    ["true", 1, nil].each do |value|
      constraint = @klass.new(:field, value)
      assert_raises(ArgumentError) do
        expected = build(value).as_json
        constraint.build.as_json
      end
    end
  end
end
