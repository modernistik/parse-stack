require_relative "../../../test_helper"

class Note < Parse::Object
  set_default_acl :public, read: true, write: false
  set_default_acl "123456", read: false, write: true
  set_default_acl "Admin", role: true, read: true, write: true
end

class TestACL < Minitest::Test
  NOTE_JSON_MASTER_KEY_ONLY = { :__type => "Object", :className => "Note", :objectId => "CEalzSpXRX", :createdAt => "2017-05-24T15:42:04.461Z", :updatedAt => "2017-06-10T01:13:51.581Z", :ACL => {} }
  NOTE_JSON_WRITE_ONLY = { :__type => "Object", :className => "Note", :objectId => "izByXF5L4w", :createdAt => "2017-06-06T21:16:23.463Z", :updatedAt => "2017-06-06T21:16:23.463Z", :ACL => { "*" => { "write" => true } } }
  NOTE_JSON_READ_AND_WRITE = { :__type => "Object", :className => "Note", :objectId => "izByXF5L4w", :createdAt => "2017-06-06T21:16:23.463Z", :updatedAt => "2017-06-06T21:16:23.463Z", :ACL => { "*" => { "read" => true, "write" => true } } }
  NOTE_EDGE_CASE_SHOULD_BE_AFFECTED = { :__type => "Object", :className => "Note", :objectId => "CEalzSpXRX", :createdAt => "2017-05-24T15:42:04.461Z", :updatedAt => "2017-06-10T01:13:51.581Z" }
  READ_ONLY = { read: true }
  WRITE_ONLY = { write: true }
  READ_AND_WRITE = { read: true, write: true }
  MASTER_KEY_ONLY = {}
  PUBLIC_READ_AND_WRITE = { "*" => { "read" => true, "write" => true } }
  PUBLIC_READ_ONLY = { "*" => { "read" => true } }
  PUBLIC_WRITE_ONLY = { "*" => { "write" => true } }

  def setup
    # master_key_only = Parse::ACL.new
    # public_read_only = Parse::ACL.everyone(true, false)
    # public_write_only = Parse::ACL.new({Parse::ACL::PUBLIC => {read: write}})
  end

  def test_acl
    assert Parse::ACL < Parse::DataType
    assert_equal Parse::ACL::PUBLIC, "*"
    assert_equal Parse::ACL.new(PUBLIC_READ_AND_WRITE), PUBLIC_READ_AND_WRITE
    assert_equal Parse::ACL.new(PUBLIC_READ_ONLY), PUBLIC_READ_ONLY
    assert_equal Parse::ACL.new(PUBLIC_WRITE_ONLY), PUBLIC_WRITE_ONLY
    assert_equal Parse::ACL.new(MASTER_KEY_ONLY), MASTER_KEY_ONLY
    assert_equal Parse::ACL.new, MASTER_KEY_ONLY

    assert_equal Parse::ACL.everyone.as_json, PUBLIC_READ_AND_WRITE
    assert_equal Parse::ACL.everyone(true, true).as_json, PUBLIC_READ_AND_WRITE
    assert_equal Parse::ACL.everyone(true).as_json, PUBLIC_READ_AND_WRITE
    assert_equal Parse::ACL.everyone(true, false).as_json, PUBLIC_READ_ONLY
    assert_equal Parse::ACL.everyone(false, true).as_json, PUBLIC_WRITE_ONLY
    assert_equal Parse::ACL.everyone(false, false).as_json, MASTER_KEY_ONLY
    refute_equal Parse::ACL.everyone.as_json, MASTER_KEY_ONLY

    assert_equal Parse::ACL.new(Parse::ACL.everyone(true, true)).as_json, PUBLIC_READ_AND_WRITE
    assert_equal Parse::ACL.new(Parse::ACL.everyone(true, true)).as_json, PUBLIC_READ_AND_WRITE
    assert_equal Parse::ACL.new(Parse::ACL.everyone(true, false)).as_json, PUBLIC_READ_ONLY
    assert_equal Parse::ACL.new(Parse::ACL.everyone(false, true)).as_json, PUBLIC_WRITE_ONLY
    assert_equal Parse::ACL.new(Parse::ACL.everyone(false, false)).as_json, MASTER_KEY_ONLY
    acl = Parse::ACL.new
    acl.apply :public, true, true
    assert_equal acl, Parse::ACL.everyone
    acl.apply :public, true, false
    assert_equal acl, Parse::ACL.everyone(true, false)
    acl.apply :public, false, true
    assert_equal acl, Parse::ACL.everyone(false, true)
    acl.apply :public, false, false
    assert_equal acl, Parse::ACL.everyone(false, false)

    assert acl.respond_to?(:world)
    assert_equal acl.method(:world).original_name, :everyone
  end

  def test_acl_role
    role = "Admin"
    acl = Parse::ACL.new(PUBLIC_READ_AND_WRITE)
    acl_hash = { "*" => { "read" => true, "write" => true } }
    assert_equal acl, acl_hash
    assert_equal acl, Parse::ACL.new(acl_hash)
    acl_hash["role:#{role}"] = { "read" => true }
    acl.apply_role role, true, false
    assert_equal acl, acl_hash
    assert_equal acl, Parse::ACL.new(acl_hash)

    acl_hash["role:#{role}"] = { "write" => true }
    acl.apply_role role, false, true
    assert_equal acl, acl_hash
    assert_equal acl, Parse::ACL.new(acl_hash)

    acl_hash["role:#{role}"] = { "read" => true, "write" => true }
    acl.apply_role role, true, true
    assert_equal acl, acl_hash
    assert_equal acl, Parse::ACL.new(acl_hash)

    acl_hash.delete "role:#{role}"
    acl.apply_role role, false, false
    assert_equal acl, acl_hash
    assert_equal acl, Parse::ACL.new(acl_hash)

    assert acl.respond_to?(:add_role)
    assert_equal acl.method(:add_role).original_name, :apply_role
  end

  def test_acl_id
    id = "123456"
    acl = Parse::ACL.new(PUBLIC_READ_AND_WRITE)

    acl_hash = { "*" => { "read" => true, "write" => true } }
    assert_equal acl, acl_hash
    assert_equal acl, Parse::ACL.new(acl_hash)

    acl_hash[id] = { "read" => true }
    acl.apply id, true, false
    assert_equal acl, acl_hash
    assert_equal acl, Parse::ACL.new(acl_hash)

    acl_hash[id] = { "write" => true }
    acl.apply id, false, true
    assert_equal acl, acl_hash
    assert_equal acl, Parse::ACL.new(acl_hash)

    acl_hash[id] = { "read" => true, "write" => true }
    acl.apply id, true, true
    assert_equal acl, acl_hash
    assert_equal acl, Parse::ACL.new(acl_hash)

    acl_hash.delete id
    acl.apply id, false, false
    assert_equal acl, acl_hash
    assert_equal acl, Parse::ACL.new(acl_hash)

    assert acl.respond_to?(:add)
    assert_equal acl.method(:add).original_name, :apply
  end

  def test_set_default_acl
    expected_default_acls = { "*" => { "read" => true }, "123456" => { "write" => true }, "role:Admin" => { "read" => true, "write" => true } }
    note = Note.new
    assert_equal Note.default_acls, expected_default_acls
    assert_equal note.acl, expected_default_acls
    assert_equal note.acl, Note.default_acls

    # Should cause no change.
    Note.set_default_acl "anthony", read: false, write: false

    note = Note.new
    assert_equal Note.default_acls, expected_default_acls
    assert_equal note.acl, expected_default_acls
    assert_equal note.acl, Note.default_acls

    # Should cause change.
    Note.set_default_acl "anthony", read: true, write: false
    expected_default_acls = { "*" => { "read" => true }, "anthony" => { "read" => true }, "123456" => { "write" => true }, "role:Admin" => { "read" => true, "write" => true } }
    note = Note.new
    assert_equal Note.default_acls, expected_default_acls
    assert_equal note.acl, expected_default_acls
    assert_equal note.acl, Note.default_acls

    # Override should cause change.
    Note.set_default_acl :public, read: false, write: false
    expected_default_acls = { "anthony" => { "read" => true }, "123456" => { "write" => true }, "role:Admin" => { "read" => true, "write" => true } }
    note = Note.new
    assert_equal Note.default_acls, expected_default_acls
    assert_equal note.acl, expected_default_acls
    assert_equal note.acl, Note.default_acls

    # these should not be affected by set_default_acl on the Note class as imported objects.
    note_master_key_only = Parse::Object.build NOTE_JSON_MASTER_KEY_ONLY
    note_write_only = Parse::Object.build NOTE_JSON_WRITE_ONLY
    note_read_and_write = Parse::Object.build NOTE_JSON_READ_AND_WRITE
    note_edge_case = Parse::Object.build NOTE_EDGE_CASE_SHOULD_BE_AFFECTED

    assert_equal note_master_key_only.acl, {}
    assert_equal note_write_only.acl, { "*" => { "write" => true } }
    assert_equal note_read_and_write.acl, { "*" => { "read" => true, "write" => true } }
    assert_equal note_edge_case.acl, Note.default_acls # should be affected because ACL is nil
    refute_equal note_master_key_only, Note.default_acls
    refute_equal note_write_only, Note.default_acls
    refute_equal note_read_and_write, Note.default_acls
  end
end
