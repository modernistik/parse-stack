require_relative "../../test_helper"

class TestCache < Minitest::Test
  def setup
    @init_object = {
      server_url: "http://b.com/parse",
      app_id: "abc",
      api_key: "def",
    }
  end

  def test_no_cache_ok
    assert Parse.setup(@init_object)
  end

  def test_moneta_transformer_accepted
    init = @init_object.merge(cache: Moneta.new(:LRUHash))
    assert init[:cache].is_a?(Moneta::Transformer)
    assert Parse.setup(init)
  end

  def test_moneta_expire_accepted
    init = @init_object.merge(cache: Moneta.new(:LRUHash, expires: 13))
    assert init[:cache].is_a?(Moneta::Expires)
    assert Parse.setup(init)
  end

  def test_bad_cache_type_rejected
    init = @init_object.merge(cache: "hamster")
    assert_raises(ArgumentError) { Parse.setup(init) }
  end
end
