require_relative '../../../test_helper'

class TestParseQueryExpressions < Minitest::Test

  def setup
    @query = Parse::Query.new("Song")
    Parse::Query.field_formatter = :columnize
  end

  def test_counting
    @query.clear :where
    @query.where :fan_count => 0
    # interal way of setting count query without executing
    @query.instance_variable_set :@count, 1
    clause = {:where=>{"fanCount"=>0}, :limit=>0, :count=>1}
    assert_equal clause, @query.prepared
    @query.limit 1_000 # should be ignored
    assert_equal clause, @query.prepared
  end

  def test_exp_order
    assert_empty @query.clause(:order)

  end

  def test_exp_keys
    assert_empty @query.clause(:keys)
    simple_query = {"keys"=>"test"}
    compound_query = {"keys"=>"test,field"}

    q = User.query(:key => "test")
    assert_equal q.compile.as_json, simple_query
    q = User.query(:key => ["test"])
    assert_equal q.compile.as_json, simple_query
    q = User.query(:key => ["test","field"])
    assert_equal q.compile.as_json, compound_query
    q = User.query(:key => :test)
    assert_equal q.compile.as_json, simple_query
    q = User.query(:key => [:test,:field])
    assert_equal q.compile.as_json, compound_query

    q = User.query(:keys => "test")
    assert_equal q.compile.as_json, simple_query
    q = User.query(:keys => ["test"])
    assert_equal q.compile.as_json, simple_query
    q = User.query(:keys => ["test","field"])
    assert_equal q.compile.as_json, compound_query
    q = User.query(:keys => :test)
    assert_equal q.compile.as_json, simple_query
    q = User.query(:keys => [:test,:field])
    assert_equal q.compile.as_json, compound_query
  end

  def test_exp_includes
    assert_empty @query.clause(:includes)
    @query.includes(:field)
    assert_equal @query.compile.as_json, {"include" => "field"}
    @query.includes(:field, :name)
    assert_equal @query.compile.as_json, {"include" => "field,name"}
    @query.where(:field.eq => "text")
    assert_equal @query.compile.as_json, {"include"=> "field,name", "where"=>"{\"field\":\"text\"}"}
  end

  def test_exp_skip
    assert_equal 0, @query.clause(:skip)
    @query.skip 100
    assert_equal 100, @query.clause(:skip)
    @query.skip 15_000 # allow skips over 10k
    assert_equal 15_000, @query.clause(:skip)
  end

  def test_exp_limit
    assert_nil @query.clause(:limit)
    @query.limit 100
    assert_equal 100, @query.clause(:limit)
    @query.limit 5000 # allow limits over 1k
    assert_equal 5000, @query.clause(:limit)
    @query.limit :max
    assert_equal :max, @query.clause(:limit)
  end

  def test_exp_session
    assert_nil @query.clause(:session)
    assert_nil @query.session_token

    user = Parse::User.new
    session = Parse::Session.new

    assert_raises(ArgumentError) { @query.session_token = 123456 }
    assert_raises(ArgumentError) { @query.session_token = user }
    assert_raises(ArgumentError) { @query.session_token = session }
    assert_raises(ArgumentError) { @query.conditions(session: 123456) }
    assert_raises(ArgumentError) { @query.conditions(session: user) }
    assert_raises(ArgumentError) { @query.conditions(session: session) }

    session.session_token = user.session_token = "r:123456"

    refute_raises(ArgumentError) { @query.session_token = nil }
    refute_raises(ArgumentError) { @query.session_token = user }
    refute_raises(ArgumentError) { @query.session_token = session }
    refute_raises(ArgumentError) { @query.conditions(session: nil) }
    refute_raises(ArgumentError) { @query.conditions(session: user) }
    refute_raises(ArgumentError) { @query.conditions(session: session) }

  end

  def test_exp_options
    # cache
    # session token
    # use_master_key
  end


end
