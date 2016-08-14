require_relative '../../../../test_helper'

class TestConstraintEquality < Minitest::Test
  extend Minitest::Spec::DSL

  def setup
   @query = Parse::Query.new("Basic")
  end

  def test_equality_extension
    assert_respond_to(:field, :eq)
    assert_respond_to(:field, :eql)
  end

  def test_equality_operator

    op = :field.eq
    constraint = op.constraint
    assert_instance_of(Parse::Operation, op)
    assert_instance_of(Parse::Constraint, constraint)
    value = {"operand"=>"field", "operator"=>"eq"}
    assert_equal value, op.as_json

  end

  def test_equality_literal
    constraint = :field.eq("v")
    expected = {:field => "v"}
    assert_equal expected, constraint.build

  end

  def test_formatted_value

    value = "value"
    constraint = Parse::Constraint.new(:field.eq, value)
    assert_equal value, constraint.formatted_value

    # Time tests
    value = Time.now
    expected_value = { __type: "Date", iso: value.utc.iso8601(3)}
    constraint = Parse::Constraint.new(:field.eq, value)
    assert_equal expected_value, constraint.formatted_value

    # DateTime tests
    value = DateTime.now
    expected_value = { __type: "Date", iso: value.utc.iso8601(3)}
    constraint = Parse::Constraint.new(:field.eq, value)
    assert_equal expected_value, constraint.formatted_value

    # Parse::Date tests
    value = Parse::Date.now
    expected_value = { __type: "Date", iso: value.utc.iso8601(3)}
    constraint = Parse::Constraint.new(:field.eq, value)
    assert_equal expected_value, constraint.formatted_value

    # Regex Test
    value = /test/i
    expected_value = value.to_s
    constraint = Parse::Constraint.new(:field.eq, value)
    assert_instance_of(Regexp, value)
    assert_equal expected_value, constraint.formatted_value

    # Pointer Test
    value = Parse::User.new(id: "123456", username: "test")
    expected_value = value.pointer
    constraint = Parse::Constraint.new(:field.eq, value)
    assert_instance_of Parse::Pointer, constraint.formatted_value
    assert_equal expected_value, constraint.formatted_value
    expected_value = {"field"=>{:__type=>"Pointer", :className=>"_User", :objectId=>"123456"}}
    assert_equal expected_value, constraint.build.as_json

    # Parse::Query Test
    value = Parse::Query.new("Song", :name => "Song Name", :field => "value")
    constraint = Parse::Constraint.new(:field.eq, value)
    expected_value = {:where=>{"name"=>"Song Name", "field"=>"value"}, :className=>"Song"}
    assert_equal expected_value, constraint.formatted_value
    
  end


end
