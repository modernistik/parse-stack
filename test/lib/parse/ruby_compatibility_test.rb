require_relative "../../test_helper"
require "stringio"

class RubyCompatibilityRecord < Parse::Object
  property :name
  property :tags, :array
  scope :named, ->(name:) { query(name: name) }
  scope :with_tags, -> { query(:tags.exists => true) }
  has_many :related_records, ->(name:) { where(name: name) }, as: "RubyCompatibilityRecord", field: :parent
end

class TestRubyCompatibility < Minitest::Test
  def setup
    @clients = Parse::Client.clients.dup
  end

  def teardown
    Parse::Client.clients.replace(@clients)
  end

  def test_query_iteration_with_and_without_blocks
    query = RubyCompatibilityRecord.query
    records = [RubyCompatibilityRecord.new(name: "one"), RubyCompatibilityRecord.new(name: "two")]
    query.instance_variable_set(:@results, records)

    assert_instance_of Enumerator, query.each
    assert_equal ["one", "two"], query.map { |record| record.name }
    assert_equal [records.first], query.select { |record| record.name == "one" }
    visited = []
    query.each { |record| visited << record }
    assert_equal records, visited
  end

  def test_response_and_batch_iteration
    response = Parse::Response.new({ "results" => [{ "name" => "one" }] })
    assert_instance_of Enumerator, response.each
    visited = []
    assert_same response, response.each { |record| visited << record }
    assert_equal [{ "name" => "one" }], visited

    request = Parse::Request.new(:delete, "classes/Song/one")
    batch = Parse::BatchOperation.new([request])
    assert_instance_of Enumerator, batch.each
    assert_equal [request], batch.map { |item| item }
  end

  def test_collection_iteration_and_uniqueness_blocks
    record = RubyCompatibilityRecord.new(tags: ["one", "ONE", "two"])
    assert_instance_of Enumerator, record.tags.each
    assert_equal ["ONE", "ONE", "TWO"], record.tags.map(&:upcase)
    assert_equal ["two"], record.tags.select { |tag| tag == "two" }
    assert_equal ["one", "two"], record.tags.uniq(&:downcase)
    record.tags.uniq!(&:downcase)
    assert_equal ["one", "two"], record.tags.to_a
  end

  def test_named_scope_preserves_keywords_when_chained
    assert_equal({ "name" => "one" }, RubyCompatibilityRecord.named(name: "one").compile_where)
    conditions = RubyCompatibilityRecord.with_tags.named(name: "two").compile_where
    assert_equal "two", conditions["name"]
    assert_equal({ :"$exists" => true }, conditions["tags"])
  end

  def test_association_scope_preserves_keywords
    record = RubyCompatibilityRecord.new(objectId: "parent")
    conditions = record.related_records(name: "child").compile_where
    assert_equal "child", conditions["name"]
    assert_equal "parent", conditions["parent"]["objectId"]
  end

  def test_file_download_uses_uri_open_and_closes_stream
    stream = StringIO.new("image bytes")
    def stream.base_uri; URI("https://files.example.test/photo.jpg"); end
    def stream.content_type; "image/jpeg"; end
    opened = []
    downloader = lambda do |url, &block|
      opened << url
      begin
        block.call(stream)
      ensure
        stream.close
      end
    end

    URI.stub(:open, downloader) do
      file = Parse::File.new("https://files.example.test/photo.jpg")
      assert_equal "photo.jpg", file.name
      assert_equal "image bytes", file.contents
      assert_equal "image/jpeg", file.mime_type
    end
    assert_equal ["https://files.example.test/photo.jpg"], opened
    assert stream.closed?
  end

  def test_remote_config_preserves_existing_environment_values
    keys = ["PARSE_STACK_TEST_NEW", "PARSE_STACK_TEST_EXISTING"]
    previous = keys.to_h { |key| [key, ENV[key]] }
    ENV.delete(keys.first)
    ENV[keys.last] = "local"
    config = StringIO.new('{"parse_stack_test_new":42,"parse_stack_test_existing":"remote"}')
    URI.stub(:open, ->(_url, &block) { block.call(config) }) do
      assert Parse::Hyperdrive.config!("https://config.example.test/settings")
    end
    assert_equal "42", ENV[keys.first]
    assert_equal "local", ENV[keys.last]
  ensure
    previous&.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end

  def test_pointer_constraint_accepts_frozen_strings
    value = " object-id ".freeze
    query = RubyCompatibilityRecord.query(:ruby_compatibility_record.id => value)
    assert_equal "object-id", query.compile_where["rubyCompatibilityRecord"]["objectId"]
    assert_equal " object-id ", value
  end
end
