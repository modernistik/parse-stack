require_relative "../../../test_helper"

class TestParseCoreQuery < Minitest::Test
  def test_save_all_invalid_constraints
    # test passing :updated_at as a constraint
    assert_raises(ArgumentError) { Parse::User.save_all :updated_at => 123 }
    assert_raises(ArgumentError) { Parse::User.save_all :updated_at.on_or_after => DateTime.now }
    assert_raises(ArgumentError) { Parse::User.save_all :updated_at.after => DateTime.now }
    assert_raises(ArgumentError) { Parse::User.save_all :updated_at.on_or_before => DateTime.now }
    assert_raises(ArgumentError) { Parse::User.save_all :updated_at.before => DateTime.now }
    assert_raises(ArgumentError) { Parse::User.save_all :updated_at.gt => DateTime.now }
    assert_raises(ArgumentError) { Parse::User.save_all :updated_at.gte => DateTime.now }
    assert_raises(ArgumentError) { Parse::User.save_all :updated_at.ne => DateTime.now }
    assert_raises(ArgumentError) { Parse::User.save_all :updated_at.lt => DateTime.now }
    assert_raises(ArgumentError) { Parse::User.save_all :updated_at.lte => DateTime.now }
    assert_raises(ArgumentError) { Parse::User.save_all :updated_at.eq => DateTime.now }
    # test passing :updatedAt as a constraint
    assert_raises(ArgumentError) { Parse::User.save_all :updatedAt => 123 }
    assert_raises(ArgumentError) { Parse::User.save_all :updatedAt.on_or_after => DateTime.now }
    assert_raises(ArgumentError) { Parse::User.save_all :updatedAt.after => DateTime.now }
    assert_raises(ArgumentError) { Parse::User.save_all :updatedAt.on_or_before => DateTime.now }
    assert_raises(ArgumentError) { Parse::User.save_all :updatedAt.before => DateTime.now }
    assert_raises(ArgumentError) { Parse::User.save_all :updatedAt.gt => DateTime.now }
    assert_raises(ArgumentError) { Parse::User.save_all :updatedAt.gte => DateTime.now }
    assert_raises(ArgumentError) { Parse::User.save_all :updatedAt.ne => DateTime.now }
    assert_raises(ArgumentError) { Parse::User.save_all :updatedAt.lt => DateTime.now }
    assert_raises(ArgumentError) { Parse::User.save_all :updatedAt.lte => DateTime.now }
    assert_raises(ArgumentError) { Parse::User.save_all :updatedAt.eq => DateTime.now }
  end

  def test_each_invalid_constraints
    # test passing :created_at as a constraint
    assert_raises(ArgumentError) { Parse::User.each :created_at => 123 }
    assert_raises(ArgumentError) { Parse::User.each :created_at.on_or_after => DateTime.now }
    assert_raises(ArgumentError) { Parse::User.each :created_at.after => DateTime.now }
    assert_raises(ArgumentError) { Parse::User.each :created_at.on_or_before => DateTime.now }
    assert_raises(ArgumentError) { Parse::User.each :created_at.before => DateTime.now }
    assert_raises(ArgumentError) { Parse::User.each :created_at.gt => DateTime.now }
    assert_raises(ArgumentError) { Parse::User.each :created_at.gte => DateTime.now }
    assert_raises(ArgumentError) { Parse::User.each :created_at.ne => DateTime.now }
    assert_raises(ArgumentError) { Parse::User.each :created_at.lt => DateTime.now }
    assert_raises(ArgumentError) { Parse::User.each :created_at.lte => DateTime.now }
    assert_raises(ArgumentError) { Parse::User.each :created_at.eq => DateTime.now }
    # test passing :createdAt as a constraint
    assert_raises(ArgumentError) { Parse::User.each :createdAt => 123 }
    assert_raises(ArgumentError) { Parse::User.each :createdAt.on_or_after => DateTime.now }
    assert_raises(ArgumentError) { Parse::User.each :createdAt.after => DateTime.now }
    assert_raises(ArgumentError) { Parse::User.each :createdAt.on_or_before => DateTime.now }
    assert_raises(ArgumentError) { Parse::User.each :createdAt.before => DateTime.now }
    assert_raises(ArgumentError) { Parse::User.each :createdAt.gt => DateTime.now }
    assert_raises(ArgumentError) { Parse::User.each :createdAt.gte => DateTime.now }
    assert_raises(ArgumentError) { Parse::User.each :createdAt.ne => DateTime.now }
    assert_raises(ArgumentError) { Parse::User.each :createdAt.lt => DateTime.now }
    assert_raises(ArgumentError) { Parse::User.each :createdAt.lte => DateTime.now }
    assert_raises(ArgumentError) { Parse::User.each :createdAt.eq => DateTime.now }
  end
end
