require_relative "../../../test_helper"

class TestAttributesClass < Parse::Object
  property :main_name
end

# Mock Rails Action Controller Parameters
class ActionControllerParametersMock
  def initialize(_attributes)
    @attributes = _attributes
  end

  def to_h
    @attributes
  end
end

class TestAttributesModule < Minitest::Test
  def setup
  end

  def test_attribution_from_hash
    test_object = TestAttributesClass.new({main_name: 'test_name'})
    assert_equal test_object.main_name, 'test_name'
    assert_equal test_object.mainName, 'test_name'
  end

  def test_attribution_from_params
    params = ActionControllerParametersMock.new({main_name: 'test_name'})
    test_object = TestAttributesClass.new(params)
    assert_equal test_object.main_name, 'test_name'
    assert_equal test_object.mainName, 'test_name'
  end
end
