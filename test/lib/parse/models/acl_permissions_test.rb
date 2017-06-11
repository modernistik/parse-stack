require_relative '../../../test_helper'

class TestACLPermissions < Minitest::Test
  READ_ONLY = {read: true}
  WRITE_ONLY = {write: true}
  READ_AND_WRITE = {read: true, write: true}
  MASTER_KEY_ONLY = {}

  def test_permissions
    no_permissions = Parse::ACL::Permission.new false, false
    assert_equal no_permissions, Parse::ACL::Permission.new
    assert_equal no_permissions, Parse::ACL::Permission.new(false,false)
    assert_equal no_permissions, Parse::ACL::Permission.new(MASTER_KEY_ONLY)
    assert no_permissions
    refute no_permissions.read
    refute no_permissions.write

    read_only = Parse::ACL::Permission.new true,false
    assert_equal read_only, Parse::ACL::Permission.new(true, false)
    assert_equal read_only, Parse::ACL::Permission.new(READ_ONLY)
    assert read_only.read
    refute read_only.write

    write_only = Parse::ACL::Permission.new false,true
    assert_equal write_only, Parse::ACL::Permission.new(false, true)
    assert_equal write_only, Parse::ACL::Permission.new(WRITE_ONLY)
    refute write_only.read
    assert write_only.write

    read_and_write = Parse::ACL::Permission.new true, true
    assert_equal read_and_write, Parse::ACL::Permission.new(true, true)
    assert_equal read_and_write, Parse::ACL::Permission.new(READ_AND_WRITE)
    assert read_and_write.read
    assert read_and_write.write

    assert_equal read_and_write.write, write_only.write
    assert_equal read_and_write.read, read_only.read
    refute_equal read_and_write.read, no_permissions.read
    refute_equal read_and_write.write, no_permissions.write

    refute_equal no_permissions, write_only
    refute_equal no_permissions, read_only
    refute_equal no_permissions, read_and_write
    refute_equal read_only, write_only
    refute_equal read_only, read_and_write
    refute_equal write_only, read_and_write
    refute_equal read_and_write, write_only
    refute_equal read_and_write, read_only
  end

end
