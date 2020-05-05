require_relative "../../../test_helper"

class MyCollectionTest < Parse::Object
  property :list, :array
end

class TestCollectionProxy < Minitest::Test
  def test_default_access
    o = MyCollectionTest.new
    assert_equal o.list, []
    changes = o.changes
    changes.delete("acl")

    assert_equal changes, {}, "Make sure default proxy collection doesn't affect dirty tracking"
    refute o.list_changed?, "Make sure it didn't affect will_change methods."
    refute o.changed.include?("list")

    o.list.add "something"
    assert o.changed.include?("list"), "Verify it is now included in dirty tracking list."
    assert o.list_changed?, "Make sure it dirty tracking was forwarded on change."
  end
end
