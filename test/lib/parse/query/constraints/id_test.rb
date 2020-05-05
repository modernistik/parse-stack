require_relative "../../../../test_helper"

class Song < Parse::Object; end

class OtherSong < Parse::Object
  parse_class "MySong"
end

class TestObjectIdConstraint < Minitest::Test
  extend Minitest::Spec::DSL
  include ConstraintTests

  def setup
    @klass = Parse::Constraint::ObjectIdConstraint
    @key = nil
    @operand = :id
    @keys = [:id]
  end

  def test_scalar_values
    [10, nil, true, false].each do |value|
      constraint = @klass.new(:field, value)
      assert_raises(ArgumentError) do
        # all should fail
        constraint.build.as_json
      end
    end

    list = ["123456", :myObjectId]
    assert_equal "Song", Song.parse_class
    assert_equal "MySong", OtherSong.parse_class

    list.each do |value|
      # Test against className matching parseClass
      constraint = @klass.new(:song, value)
      expected = { "song" => Song.pointer(value) }.as_json
      constraint.build.as_json
      assert_equal expected, constraint.build.as_json

      # Test by safely supporting pointers too
      constraint = @klass.new(:song, Song.pointer(value))
      expected = { "song" => Song.pointer(value) }.as_json
      constraint.build.as_json
      assert_equal expected, constraint.build.as_json

      # Test against a valid parse class name
      constraint = @klass.new(:my_song, value)
      expected = { "my_song" => OtherSong.pointer(value) }.as_json
      assert_equal expected, constraint.build.as_json

      # Test Pointer support
      constraint = @klass.new(:my_song, OtherSong.pointer(value))
      expected = { "my_song" => OtherSong.pointer(value) }.as_json
      assert_equal expected, constraint.build.as_json

      # Test with parse_class name set to something else
      constraint = @klass.new(:other_song, value)
      expected = { "other_song" => OtherSong.pointer(value) }.as_json
      assert_equal expected, constraint.build.as_json

      # Test with pointers
      constraint = @klass.new(:other_song, OtherSong.pointer(value))
      expected = { "other_song" => OtherSong.pointer(value) }.as_json
      assert_equal expected, constraint.build.as_json
    end
  end
end
