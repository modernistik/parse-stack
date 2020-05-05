require_relative "../../../test_helper"

class TestPointer < Minitest::Test
  def setup
    @id = "theObjectId"
    @theClass = "_User"
    @pointer = Parse::Pointer.new(@theClass, @id)
  end

  def test_base_fields
    pointer = @pointer
    assert_equal Parse::Model::TYPE_POINTER, "Pointer"
    assert_respond_to pointer, :__type
    assert_equal pointer.__type, Parse::Model::TYPE_POINTER
    assert_respond_to pointer, :id
    assert_respond_to pointer, :objectId
    assert_equal pointer.id, @id
    assert_equal pointer.id, pointer.objectId

    assert_respond_to pointer, :className
    assert_respond_to pointer, :parse_class
    assert_equal pointer.parse_class, @theClass
    assert_equal pointer.parse_class, pointer.className
    assert pointer.pointer?
    refute pointer.fetched?
    # Create a new pointer from this pointer. They should still be equal.
    assert pointer == pointer.pointer
    assert pointer.present?
  end

  def test_json
    assert_equal @pointer.as_json, { :__type => Parse::Model::TYPE_POINTER, className: @theClass, objectId: @id }
  end

  def test_sig
    assert_equal @pointer.sig, "#{@theClass}##{@id}"
  end

  def test_array_objectIds
    assert_equal [@pointer.id], [@pointer].objectIds
    assert_equal [@pointer.id], [@pointer, 4, "junk", nil].objectIds
    assert_equal [], [4, "junk", nil].objectIds
  end

  def test_array_valid_parse_objects
    assert_equal [@pointer], [@pointer].valid_parse_objects
    assert_equal [@pointer], [@pointer, 4, "junk", nil].valid_parse_objects
    assert_equal [], [4, "junk", nil].valid_parse_objects
  end

  def test_array_parse_pointers
    assert_equal [@pointer], [@pointer].parse_pointers
    assert_equal [@pointer, @pointer], [@pointer, { className: "_User", objectId: @id }].parse_pointers
    assert_equal [@pointer, @pointer], [@pointer, { "className" => "_User", "objectId" => @id }].parse_pointers
    assert_equal [@pointer, @pointer], [nil, 4, "junk", { className: "_User", objectId: @id }, { "className" => "_User", "objectId" => @id }].parse_pointers
  end
end
