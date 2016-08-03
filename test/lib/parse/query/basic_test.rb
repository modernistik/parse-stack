require_relative '../../../test_helper'

class TestQueryObject < Parse::Object
  parse_class "TestQueryObjectTableName"
end

class CommentObject < Parse::Object; end;

class TestParseQuery < Minitest::Test
  extend Minitest::Spec::DSL

  def setup
    Parse::Query.field_formatter = :columnize
    @query = Parse::Query.new("Song")
  end

  def test_columnize
    assert_equal :MyColumnField.columnize, :myColumnField
    assert_equal "MyColumnField".columnize, "myColumnField"
    assert_equal :My_column_field.columnize, :myColumnField
    assert_equal "My_column_field".columnize, "myColumnField"
    assert_equal :testField.columnize, :testField
    assert_equal "testField".columnize, "testField"
    assert_equal :test_field.columnize, :testField
    assert_equal "test_field".columnize, "testField"
  end

  def test_field_formatter
    @query.clear :where
    @query.where :fan_count => 0, :playCount => 0, :ShareCount => 0, :' test_name ' => 1
    clause = {"fanCount"=>0, "playCount"=>0, "shareCount"=>0, "testName" => 1}
    assert_equal clause, @query.compile_where
    Parse::Query.field_formatter = nil
    @query.clear :where
    @query.where :fan_count => 0, :playCount => 0, :ShareCount => 0, :' test_name ' => 1
    clause = {"fan_count"=>0, "playCount"=>0, "ShareCount"=>0, "test_name" => 1}
    assert_equal clause, @query.compile_where
    Parse::Query.field_formatter = :camelize
    @query.clear :where
    @query.where :fan_count => 0, :playCount => 0, :ShareCount => 0, :' test_name ' => 1
    clause = {"FanCount"=>0, "PlayCount"=>0, "ShareCount"=>0, "TestName" => 1}
    assert_equal clause, @query.compile_where
    Parse::Query.field_formatter = :columnize
  end

  def test_table_name
    assert_equal @query.table, "Song"
    assert_equal Parse::Query.new("MyClass").table, "MyClass"
    assert_equal TestQueryObject.query.table, TestQueryObject.parse_class
    assert_equal CommentObject.query.table, CommentObject.parse_class
  end


end
