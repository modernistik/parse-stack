require_relative '../../../test_helper'

class TestRole < Minitest::Test
  CORE_FIELDS = Parse::Object.fields.merge({
    :id=>:string,
    :created_at=>:date,
    :updated_at=>:date,
    :acl=>:acl,
    :objectId=>:string,
    :createdAt=>:date,
    :updatedAt=>:date,
    :ACL=>:acl,
    :name=>:string
})

  def test_properties
    assert Parse::Role < Parse::Object
    assert_equal CORE_FIELDS, Parse::Role.fields
    assert_empty Parse::Role.references
    assert_equal({:roles=> Parse::Model::CLASS_ROLE, :users=>Parse::Model::CLASS_USER},  Parse::Role.relations)
  end

end
