require_relative '../../../test_helper'

class TestProduct < Minitest::Test
  CORE_FIELDS = Parse::Object.fields.merge({
    :id=>:string,
    :created_at=>:date,
    :updated_at=>:date,
    :acl=>:acl,
    :objectId=>:string,
    :createdAt=>:date,
    :updatedAt=>:date,
    :ACL=>:acl,
    :download=>:file,
    :download_name=>:string,
    :downloadName=>:string,
    :icon=>:file,
    :order=>:integer,
    :product_identifier=>:string,
    :productIdentifier=>:string,
    :subtitle=>:string,
    :title=>:string
 })

  def test_properties
    assert Parse::Product < Parse::Object
    assert_equal CORE_FIELDS, Parse::Product.fields
    assert_empty Parse::Product.references
    assert_empty Parse::Product.relations
  end

end
