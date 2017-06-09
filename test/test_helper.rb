require 'minitest/autorun'
require 'minitest/pride'
require 'byebug'
require_relative '../lib/parse/stack.rb'


module ConstraintTests

  TEST_VALUES = [
    "v", [1,"test", :other, true],
    nil, Parse::User.pointer(12345), true, false
  ]

  def build(value)
    {"field" => { @key.to_s  => Parse::Constraint.formatted_value(value) } }
  end

  def test_operator
    assert_equal @operand, @klass.operand
    # Some constraint classes are macros and do not have operator keys.
    # The reason for putting them in this block is because in MT6 (mini-test),
    # assert_equal will fail if we are comparing nil.
    if @key.nil? # for Parse::Constraint, Parse::Constraint::ObjectIdConstraint
      assert_nil @klass.key
    else
      assert_equal @key, @klass.key
    end


    @keys.each do |o|
      assert_respond_to(:field, o)
      op = :field.send(o)
      assert_instance_of(Parse::Operation, op)
      assert_instance_of( @klass, op.constraint)
      if @key.nil?
        assert_nil op.constraint.key
      else
        assert_equal @key, op.constraint.key
      end
      value = {"operand"=>"field", "operator"=> o.to_s }
      assert_equal value, op.as_json
    end

  end

  def test_scalar_values
    return if @skip_scalar_values_test.present?
    TEST_VALUES.each do |value|
      constraint = @klass.new(:field, value)
      expected = build(value).as_json
      assert_equal expected, constraint.build.as_json
    end

  end

end

module MiniTest
  module Assertions
    def refute_raises *exp
      msg = "#{exp.pop}.\n" if String === exp.last

      begin
        yield
      rescue MiniTest::Skip => e
        return e if exp.include? MiniTest::Skip
        raise e
      rescue Exception => e
        exp = exp.first if exp.size == 1
        flunk "unexpected exception raised: #{e}"
      end

    end
  end
  module Expectations
    infect_an_assertion :refute_raises, :wont_raise
  end
end
