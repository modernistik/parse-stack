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
  end

  def test_exp_includes
    assert_empty @query.clause(:includes)
  end

  def test_exp_skip
    assert_equal 0, @query.clause(:skip)
    @query.skip 100
    assert_equal 100, @query.clause(:skip)
  end

  def test_exp_limit
    assert_nil @query.clause(:limit)
    @query.limit 100
    assert_equal 100, @query.clause(:limit)
    @query.limit :max
    assert_equal 11_000, @query.clause(:limit)
  end

  def test_exp_options
    # cache
    # session token
    # use_master_key
  end


end
