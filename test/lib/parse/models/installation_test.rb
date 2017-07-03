require_relative '../../../test_helper'

class TestInstallation < Minitest::Test
  CORE_FIELDS = Parse::Object.fields.merge({
    :id=>:string,
    :created_at=>:date,
    :updated_at=>:date,
    :acl=>:acl,
    :objectId=>:string,
    :createdAt=>:date,
    :updatedAt=>:date,
    :ACL=>:acl,
    :gcm_sender_id=>:string,
    :GCMSenderId=>:string,
    :app_identifier=>:string,
    :appIdentifier=>:string,
    :app_name=>:string,
    :appName=>:string,
    :app_version=>:string,
    :appVersion=>:string,
    :badge=>:integer,
    :channels=>:array,
    :device_token=>:string,
    :deviceToken=>:string,
    :device_token_last_modified=>:integer,
    :deviceTokenLastModified=>:integer,
    :device_type=>:string,
    :deviceType=>:string,
    :installation_id=>:string,
    :installationId=>:string,
    :locale_identifier=>:string,
    :localeIdentifier=>:string,
    :parse_version=>:string,
    :parseVersion=>:string,
    :push_type=>:string,
    :pushType=>:string,
    :time_zone=>:timezone,
    :timeZone=>:timezone
 })

  def test_properties
    assert Parse::Installation < Parse::Object
    assert_equal CORE_FIELDS, Parse::Installation.fields
    assert_empty Parse::Installation.references
    assert_empty Parse::Installation.relations
    assert Parse::Installation.method_defined?(:session)
  end

end
