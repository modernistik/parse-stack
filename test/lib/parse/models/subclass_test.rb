require_relative '../../../test_helper'

class TestSubclassing < Minitest::Test

  def setup
    Parse.use_shortnames!
  end

  def test_inheritance
    assert_equal Installation.superclass, Parse::Object
    assert_equal Role.superclass, Parse::Object
    assert_equal User.superclass, Parse::Object
    assert_equal Session.superclass, Parse::Object
    assert_equal Product.superclass, Parse::Object
    assert_equal Parse::Object.superclass, Parse::Pointer
    assert_equal Parse::Pointer.superclass, Parse::Model
  end

end
