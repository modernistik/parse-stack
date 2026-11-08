abort "Run this suite through rake integration" unless ENV["PARSE_STACK_INTEGRATION"] == "1"
require_relative "../test_helper"
require "securerandom"
require "uri"

class TestRESTIntegration < Minitest::Test
  def setup
    @options = {
      server_url: ENV.fetch("PARSE_STACK_INTEGRATION_URL"),
      app_id: ENV.fetch("PARSE_STACK_INTEGRATION_APP_ID"),
      master_key: ENV.fetch("PARSE_STACK_INTEGRATION_MASTER_KEY"),
      api_key: ENV.fetch("PARSE_STACK_INTEGRATION_REST_KEY"),
      faraday: { proxy: nil },
    }
    @client = Parse::Client.setup(@options)
    @client.retry_limit = 0
    Parse::Query.client = Parse::User.client = Parse::Session.client = @client
    @table = "Sdk#{SecureRandom.hex(8)}"
  end

  def create(body = {})
    response = @client.create_object(@table, body)
    assert response.success?, response.to_s
    response.result.fetch("objectId")
  end

  def test_crud_and_error_response
    id = create(name: "original", score: 1)
    response = @client.fetch_object(@table, id)
    assert_equal "original", response.result["name"]
    assert @client.update_object(@table, id, { name: "updated" }).success?
    assert_equal "updated", @client.fetch_object(@table, id).result["name"]
    assert @client.delete_object(@table, id).success?
    missing = @client.fetch_object(@table, id)
    assert_equal 404, missing.http_status
    assert_equal 101, missing.code
    assert missing.error?
  end

  def test_typed_values_and_atomic_operations
    id = create(point: Parse::GeoPoint.new(32.8, -117.6), at: Parse::Date.parse("2026-11-07T00:00:00Z"), bytes: Parse::Bytes.new("YWJj"), score: 1, tags: ["one"])
    assert @client.update_object(@table, id, { score: { __op: "Increment", amount: 2 }, tags: { __op: "AddUnique", objects: ["two", "one"] } }).success?
    result = @client.fetch_object(@table, id).result
    assert_equal 3, result["score"]
    assert_equal ["one", "two"], result["tags"]
    assert_equal "GeoPoint", result.dig("point", "__type")
    assert_equal "Date", result.dig("at", "__type")
    assert_equal "Bytes", result.dig("bytes", "__type")
  end

  def test_query_filter_count_distinct_and_projection
    3.times { |i| create(name: "name#{i}", score: i, privateValue: "hidden") }
    query = Parse::Query.new(@table, :score.gte => 1, order: :score.desc, limit: 2, read_preference: :primary, exclude_keys: [:private_value])
    rows = query.results(raw: true)
    assert_equal [2, 1], rows.map { |row| row["score"] }
    assert rows.none? { |row| row.key?("privateValue") }
    assert_equal 2, query.count
    assert_equal [0, 1, 2], Parse::Query.new(@table).distinct(:score).sort
    selected = Parse::Query.new(@table, keys: [:name], limit: 1).results(raw: true).first
    assert selected.key?("name")
    refute selected.key?("score")
    # The guide also describes JSON-array projection parameters on modern servers.
    array_projection = @client.find_objects(@table, { keys: ["name"].to_json, limit: 1 })
    assert array_projection.success?, array_projection.to_s
    assert array_projection.results.first.key?("name")
  end

  def test_pipeline_aggregation
    3.times { |i| create(score: i + 1) }
    response = @client.aggregate_pipeline(@table, [{ "$group" => { "_id" => nil, "total" => { "$sum" => "$score" } } }])
    assert response.success?, response.to_s
    assert_equal 6, response.results.first["total"]
  end

  def test_batch_chunks_and_mount_path
    requests = 21.times.map { |i| Parse::Request.new(:post, "#{URI(@options[:server_url]).path}/classes/#{@table}", body: { index: i }) }
    batch = Parse::BatchOperation.new(requests)
    responses = batch.submit
    assert_equal 21, responses.length
    assert responses.all?(&:success?)
    assert_equal 21, Parse::Query.new(@table).count
  end

  def test_user_login_installation_session_and_impersonation
    installation = SecureRandom.uuid
    username = "sdk-#{SecureRandom.hex(8)}"
    user = Parse::User.signup(username, "sdk-test-password", installation_id: installation)
    assert user.id
    assert user.session_token
    session = @client.fetch_session(user.session_token)
    assert_equal installation, session.result["installationId"]
    logged_in = Parse::User.login(username, "sdk-test-password", installation_id: installation)
    assert_equal user.id, logged_in.id
    assert_equal user.id, @client.current_user(logged_in.session_token).result["objectId"]
    impersonated = Parse::User.login_as(user.id)
    assert_equal user.id, impersonated.id
    assert impersonated.session_token
    assert @client.logout(logged_in.session_token).success?
    assert_raises(Parse::Error::InvalidSessionTokenError) { @client.current_user(logged_in.session_token) }
  end

  def test_public_credentials_respect_object_acl
    id = create(name: "private", ACL: {})
    public_client = Parse::Client.new(@options.reject { |key, _value| key == :master_key })
    response = public_client.fetch_object(@table, id)
    assert response.error?
    assert_equal 101, response.code
    assert @client.fetch_object(@table, id).success?
  end

  def test_binary_file_upload_and_deletion
    bytes = "\x00\xFF\x80".b
    response = @client.create_file("sdk.bin", bytes, "application/octet-stream")
    assert response.success?, response.to_s
    assert response.result["url"]
    assert @client.delete_file(response.result.fetch("name")).success?
  end

  def test_schema_creation_update_and_deletion
    response = @client.create_schema(@table, { className: @table, fields: { name: { type: "String" } } })
    assert response.success?, response.to_s
    assert @client.update_schema(@table, { fields: { score: { type: "Number" } } }).success?
    assert_equal "Number", @client.schema(@table).result.dig("fields", "score", "type")
    assert @client.delete_schema(@table).success?
  end

  def test_cloud_function_and_background_job_tracking
    assert_equal({ "value" => 42, "userId" => nil }, Parse.call_function("sdkEcho", { value: 42 }))
    id = Parse.trigger_job("sdkJob")
    assert id, "Job-status response header was lost"
    status = nil
    50.times do
      status = @client.fetch_object("_JobStatus", id).result["status"]
      break if status == "succeeded"
      sleep 0.05
    end
    assert_equal "succeeded", status
  end
end
