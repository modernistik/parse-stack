require_relative '../../../test_helper'

class TestUser < Minitest::Test

  def test_password_reset
    assert_equal Parse::User.request_password_reset(''), false
    assert_equal Parse::User.request_password_reset('   '), false
  end

end
