require_relative "../../../test_helper"

class TestSession < Minitest::Test
  CORE_FIELDS = Parse::Object.fields.merge({
    created_with: :object,
    createdWith: :object,
    expires_at: :date,
    expiresAt: :date,
    installation_id: :string,
    installationId: :string,
    restricted: :boolean,
    session_token: :string,
    sessionToken: :string,
    user: :pointer,
  })

  def test_properties
    assert Parse::Session < Parse::Object
    assert_equal CORE_FIELDS, Parse::Session.fields
    assert_equal({ user: Parse::Model::CLASS_USER }, Parse::Session.references)
    assert_empty Parse::Session.relations
    # check association methods
    assert Parse::Session.method_defined?(:user)
    assert Parse::Session.method_defined?(:installation)
  end
end
