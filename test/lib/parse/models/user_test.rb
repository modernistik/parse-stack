require_relative "../../../test_helper"

class TestUser < Minitest::Test
  CORE_FIELDS = Parse::Object.fields.merge({
    auth_data: :object,
    authData: :object,
    email: :string,
    password: :string,
    username: :string,
  })

  def test_properties
    assert Parse::User < Parse::Object
    assert_equal CORE_FIELDS, Parse::User.fields
    assert_empty Parse::User.references
    assert_empty Parse::User.relations
  end

  def test_password_reset
    assert_equal Parse::User.request_password_reset(""), false
    assert_equal Parse::User.request_password_reset("   "), false
  end
end
