require_relative "../../../test_helper"

class TestPropertyTypesClass < Parse::Object; end

class TestPropertyModule < Minitest::Test
  TYPES = [:string, :relation, :integer, :float, :boolean, :date, :array, :file, :geopoint, :bytes, :object, :acl, :timezone].freeze
  # These are the base mappings of the remote field name types.
  BASE = { objectId: :string, createdAt: :date, updatedAt: :date, ACL: :acl }.freeze
  # The list of properties that are part of all objects
  BASE_KEYS = [:id, :created_at, :updated_at].freeze
  # Default hash map of local attribute name to remote column name
  BASE_FIELD_MAP = { id: :objectId, created_at: :createdAt, updated_at: :updatedAt, acl: :ACL }.freeze
  CORE_FIELD_DEFINITION = { id: :string, created_at: :date, updated_at: :date, acl: :acl, objectId: :string, createdAt: :date, updatedAt: :date, ACL: :acl }.freeze

  def setup
  end

  def test_parse_object_definition
    assert_equal TYPES, Parse::Object::TYPES
    assert_equal BASE, Parse::Object::BASE
    assert_equal BASE_KEYS, Parse::Object::BASE_KEYS
    assert_equal BASE_FIELD_MAP, Parse::Object::BASE_FIELD_MAP
    assert_empty Parse::Object.references, "Parse::Object should not have core references."
    assert_empty Parse::Object.relations, "Parse::Object should not have core relations."
    assert_equal CORE_FIELD_DEFINITION, Parse::Object.fields, "Parse::Object should have core fields defined."
  end

  def test_property_types
    assert TestPropertyTypesClass < Parse::Object
    assert_equal Parse::Object::fields, TestPropertyTypesClass.fields, "Initial subclass should be same fields as Parse::Object"
    CORE_FIELD_DEFINITION.each do |key, type|
      assert_equal type, TestPropertyTypesClass.fields[key], "Type for core property '#{key}' should be :#{type}"
    end

    TYPES - [:id]
  end

  def test_redeclarations
    warn_level = $VERBOSE
    $VERBOSE = nil
    BASE_FIELD_MAP.flatten.each do |field|
      refute Parse::Object.property(field), "Should not allow redeclaring property #{field} field"
    end
    BASE_FIELD_MAP.flatten.each do |field|
      key = "f_#{field}"
      refute Parse::Object.property(key, field: "#{field}"), "Should not allow redeclaring alias '#{field}' field. (#{key})"
    end
    $VERBOSE = warn_level
  end
end
