require_relative '../../../test_helper'

class TestUser < Minitest::Test
  CORE_USER_FIELDS = Parse::Object.fields.merge({
        auth_data:  :object,
        authData:   :object,
        email:      :string,
        password:   :string,
        username:   :string
      })

  def test_properties
    assert Parse::User < Parse::Object
    assert_equal CORE_USER_FIELDS, Parse::User.fields
  end

  def test_password_reset
    assert_equal Parse::User.request_password_reset(''), false
    assert_equal Parse::User.request_password_reset('   '), false
  end

end
