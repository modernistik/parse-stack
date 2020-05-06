require_relative "../../../../test_helper"

class TestConstraintEquality < Minitest::Test
  extend Minitest::Spec::DSL

  def setup
    @query = Parse::Query.new("Basic")
  end

  def test_formatted_value
    value = "value"
    constraint = Parse::Constraint.new(:field, value)
    assert_equal value, constraint.formatted_value

    # Time tests
    value = Time.now
    expected_value = { __type: "Date", iso: value.utc.iso8601(3) }
    constraint = Parse::Constraint.new(:field, value)
    assert_equal expected_value, constraint.formatted_value

    # DateTime tests
    value = DateTime.now
    expected_value = { __type: "Date", iso: value.utc.iso8601(3) }
    constraint = Parse::Constraint.new(:field, value)
    assert_equal expected_value, constraint.formatted_value

    # Parse::Date tests
    value = Parse::Date.now
    expected_value = { __type: "Date", iso: value.utc.iso8601(3) }
    constraint = Parse::Constraint.new(:field, value)
    assert_equal expected_value, constraint.formatted_value

    # Regex Test
    value = /test/i
    expected_value = value.to_s
    constraint = Parse::Constraint.new(:field, value)
    assert_instance_of(Regexp, value)
    assert_equal expected_value, constraint.formatted_value

    # Pointer Test
    value = Parse::User.new(id: "123456", username: "test")
    expected_value = value.pointer
    constraint = Parse::Constraint.new(:field, value)
    assert_instance_of Parse::Pointer, constraint.formatted_value
    assert_equal expected_value, constraint.formatted_value
    expected_value = { "field" => { :__type => "Pointer", :className => "_User", :objectId => "123456" } }.as_json
    assert_equal expected_value, constraint.build.as_json

    # Parse::Query Test
    value = Parse::Query.new("Song", :name => "Song Name", :field => "value")
    constraint = Parse::Constraint.new(:field, value)
    expected_value = { :where => { "name" => "Song Name", "field" => "value" }, :className => "Song" }
    assert_equal expected_value, constraint.formatted_value
  end

  def test_build
    constraint = Parse::Constraint.new(:field, 1)
    assert_nil constraint.key
    expected = { :field => 1 }
    assert_equal expected, constraint.build

    # if we set a key when calling the base version of build
    # then we get a different format.
    Parse::Constraint.key = :$test
    constraint = Parse::Constraint.new(:field, 1)
    assert_equal :eq, constraint.operator
    constraint.operator = :test
    assert_equal :test, constraint.operator
    assert_equal :$test, constraint.key
    expected = { :field => { :$test => 1 } }
    assert_equal expected, constraint.build
    Parse::Constraint.key = nil
  end
end
