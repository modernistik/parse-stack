require_relative "../../../../test_helper"

class TestFullTextSearchQueryConstraint < Minitest::Test
  extend Minitest::Spec::DSL
  include ConstraintTests

  def setup
    @klass = Parse::Constraint::FullTextSearchQueryConstraint
    @key = :$text
    @operand = :text_search
    @keys = [:text_search]
    @skip_scalar_values_test = true
  end

  def build(value)
    { "field" => { @key => { :$search => { :$term => value } } } }
  end

  def test_argument_error
    assert_raises(ArgumentError) { User.query(:name.text_search => nil).compile }
    assert_raises(ArgumentError) { User.query(:name.text_search => []).compile }
    assert_raises(ArgumentError) { User.query(:name.text_search => {}).compile }
    assert_raises(ArgumentError) { User.query(:name.text_search => { :lang => :en }).compile }

    refute_raises(ArgumentError) { User.query(:name.text_search => "text").compile }
    refute_raises(ArgumentError) { User.query(:name.text_search => :text).compile }
    refute_raises(ArgumentError) { User.query(:name.text_search => { :$term => "text" }).compile }
    refute_raises(ArgumentError) { User.query(:name.text_search => { "$term" => "text" }).compile }
    refute_raises(ArgumentError) { User.query(:name.text_search => { "term" => "text" }).compile }
    refute_raises(ArgumentError) { User.query(:name.text_search => { :term => "text" }).compile }
  end

  def test_compiled_query
    params = { "$term" => "text" }
    compiled_query = { "name" => { "$text" => { "$search" => params } } }
    # Basics
    query = User.query(:name.text_search => "text")
    assert_equal query.compile_where.as_json, compiled_query
    query = User.query(:name.text_search => :text)
    assert_equal query.compile_where.as_json, compiled_query
    query = User.query(:name.text_search => { term: "text" })
    assert_equal query.compile_where.as_json, compiled_query
    query = User.query(:name.text_search => { term: :text })
    assert_equal query.compile_where.as_json, compiled_query
    query = User.query(:name.text_search => { :$term => :text })
    assert_equal query.compile_where.as_json, compiled_query
    query = User.query(:name.text_search => { "$term" => "text" })
    assert_equal query.compile_where.as_json, compiled_query
    query = User.query(:name.text_search => { "$term" => :text })
    assert_equal query.compile_where.as_json, compiled_query
    query = User.query(:name.text_search => params)
    assert_equal query.compile_where.as_json, compiled_query

    # Advanced

    params["$caseSensitive"] = true
    compiled_query = { "name" => { "$text" => { "$search" => params } } }
    query = User.query(:name.text_search => params)
    assert_equal query.compile_where.as_json, compiled_query
    query = User.query(:name.text_search => { term: "text", case_sensitive: true })
    assert_equal query.compile_where.as_json, compiled_query
    params["$caseSensitive"] = false
    query = User.query(:name.text_search => { term: "text", caseSensitive: false })
    assert_equal query.compile_where.as_json, compiled_query
    query = User.query(:name.text_search => { term: "text", :$caseSensitive => false })
    assert_equal query.compile_where.as_json, compiled_query
    query = User.query(:name.text_search => { term: "text", "$caseSensitive" => false })
    assert_equal query.compile_where.as_json, compiled_query

    params["$language"] = ["stop", "words"]
    compiled_query = { "name" => { "$text" => { "$search" => params } } }
    query = User.query(:name.text_search => params)
    assert_equal query.compile_where.as_json, compiled_query
    query = User.query(:name.text_search => { term: "text", caseSensitive: false, language: ["stop", "words"] })
    assert_equal query.compile_where.as_json, compiled_query
  end
end
