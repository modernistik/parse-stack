require_relative '../../../../test_helper'

class TestNotEqualConstraint < Minitest::Test
  extend Minitest::Spec::DSL

  def setup
    @klass = Parse::Constraint
    @key = nil
    @operand = :eq
    @keys = [:eq]
  end

  def build(value)
    {"field" => Parse::Constraint.formatted_value(value) }
  end

  def test_operator
    assert_equal @operand, @klass.operand
    assert_equal @key, @klass.key

    @keys.each do |o|
      assert_respond_to(:field, o)
      op = :field.send(o)
      assert_instance_of(Parse::Operation, op)
      assert_instance_of( @klass, op.constraint)
      assert_equal(@key, op.constraint.key)
      value = {"operand"=>"field", "operator"=> o.to_s }
      assert_equal value, op.as_json
    end

  end

  def test_constraint

    [ "v",
      [1,"test", :other, true],
      nil,
      Parse::User.pointer(12345)
    ].each do |value|
      constraint = @klass.new(:field, value)
      expected = build(value).as_json
      assert_equal expected, constraint.build.as_json
    end


  end

end
