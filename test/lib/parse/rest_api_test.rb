require_relative "../../test_helper"

class TestRESTAPI < Minitest::Test
  OPTIONS = { server_url: "https://parse.example.test/parse", app_id: "test-app", api_key: "rest-key", master_key: "master-key" }.freeze

  def setup
    @clients = Parse::Client.clients.dup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @client = Parse::Client.setup(OPTIONS) { |conn| conn.adapter :test, @stubs }
    @model_clients = [Parse::Query, Parse::User].to_h do |klass|
      previous = klass.instance_variable_get(:@client)
      klass.client = @client
      [klass, previous]
    end
  end

  def teardown
    Parse::Client.clients.replace(@clients)
    @model_clients.each { |klass, client| klass.client = client }
    @stubs.verify_stubbed_calls
  end

  def response(body = {}, headers = {}, status = 200)
    [status, { "content-type" => "application/json" }.merge(headers), JSON.generate(body)]
  end

  def test_known_query_options_do_not_become_field_filters
    query = Parse::Query.new("Song", read_preference: :secondary_preferred, includeReadPreference: "PRIMARY", subquery_read_preference: "NEAREST", exclude_keys: [:private_value], :score.gt => 1)
    compiled = query.compile
    assert_equal "SECONDARY_PREFERRED", compiled[:readPreference]
    assert_equal "PRIMARY", compiled[:includeReadPreference]
    assert_equal "NEAREST", compiled[:subqueryReadPreference]
    assert_equal "privateValue", compiled[:excludeKeys]
    assert_equal({ "score" => { "$gt" => 1 } }, JSON.parse(compiled[:where]))
  end

  def test_query_wire_options_and_custom_options_reach_server
    @stubs.get("/parse/classes/Song/") do |env|
      assert_equal "PRIMARY", env.params["readPreference"]
      assert_equal "privateValue", env.params["excludeKeys"]
      assert_equal({ "score" => 1 }, JSON.parse(env.params["hint"]))
      assert_equal "enabled", env.params["futureOption"]
      response({ "results" => [] })
    end
    query = Parse::Query.new("Song", readPreference: "PRIMARY", excludeKeys: ["privateValue"], hint: { score: 1 }, limit: 1)
    query.server_options(futureOption: "enabled")
    assert_equal [], query.results
  end

  def test_options_can_be_cleared_without_affecting_field_constraints
    query = Parse::Query.new("Song", name: "salsa", exclude_keys: [:secret], readPreference: "PRIMARY")
    query.clear(:exclude_keys)
    refute query.compile.key?(:excludeKeys)
    assert_equal "PRIMARY", query.compile[:readPreference]
    query.clear(:server_options)
    assert_equal({ where: '{"name":"salsa"}' }, query.compile)
    query.server_options(read_preference: "NEAREST").server_options(readPreference: nil)
    assert_empty query.server_options
  end

  def test_option_validation_and_copying
    query = Parse::Query.new("Song")
    assert_raises(ArgumentError) { query.server_options(where: {}) }
    assert_raises(ArgumentError) { query.server_options(readPreference: "invalid") }
    assert_raises(ArgumentError) { query.server_options([]) }
    assert_raises(ArgumentError) { query.server_options(1 => "invalid") }
    values = { futureOption: { names: ["one"] } }
    query.server_options(values)
    values[:futureOption][:names] << "two"
    copy = query.server_options
    copy[:futureOption][:names] << "three"
    assert_equal ["one"], query.server_options.dig(:futureOption, :names)
  end

  def test_unknown_conditions_remain_fields_and_reserved_names_have_operation_escape
    query = Parse::Query.new("Song", futureOption: "field", :read_preference.eq => "field-value")
    assert_equal({ "futureOption" => "field", "readPreference" => "field-value" }, JSON.parse(query.compile[:where]))
  end

  def test_login_and_signup_forward_installation_id_without_mutating_headers
    headers = { "X-Test" => "yes" }.freeze
    @stubs.get("/parse/login") do |env|
      assert_equal "installation", env.request_headers["X-Parse-Installation-Id"]
      assert_equal "yes", env.request_headers["X-Test"]
      response({ "objectId" => "one", "sessionToken" => "token" })
    end
    @stubs.post("/parse/users") do |env|
      assert_equal "installation", env.request_headers[Parse::Protocol::INSTALLATION_ID]
      response({ "objectId" => "one", "sessionToken" => "token" }, {}, 201)
    end
    assert_equal "token", Parse::User.login("user", "password", headers: headers, installation_id: "installation").session_token
    assert_equal "one", Parse::User.signup("user", "password", installation_id: "installation").id
    assert_equal({ "X-Test" => "yes" }, headers)
  end

  def test_job_status_headers_and_public_helper_result
    @stubs.post("/parse/jobs/testJob") do |env|
      assert_equal "yes", env.request_headers["X-Test"]
      response({}, { "x-parse-job-status-id" => "job-123" })
    end
    assert_equal "job-123", Parse.trigger_job("testJob", {}, headers: { "X-Test" => "yes" })
    raw = Parse.trigger_job("testJob", {}, raw: true, headers: { "X-Test" => "yes" })
    assert raw.success?
    assert_equal "job-123", raw.job_status_id
    assert_equal "job-123", raw.header("X-PARSE-JOB-STATUS-ID")
    assert_equal "job-123", raw.headers["x-parse-job-status-id"]
  end

  def test_job_legacy_result_and_error_are_preserved
    @stubs.post("/parse/jobs/legacy") { response({ "result" => "legacy-id" }) }
    @stubs.post("/parse/jobs/failure") { response({ "code" => 141, "error" => "job failed" }, {}, 400) }
    assert_equal "legacy-id", Parse.trigger_job("legacy")
    assert_nil Parse.trigger_job("failure")
  end

  def test_function_helper_forwards_session_and_custom_headers
    @stubs.post("/parse/functions/echo") do |env|
      assert_equal "token", env.request_headers[Parse::Protocol::SESSION_TOKEN]
      refute env.request_headers.key?(Parse::Protocol::MASTER_KEY)
      assert_equal "yes", env.request_headers["X-Test"]
      response({ "result" => "hello" })
    end
    assert_equal "hello", Parse.call_function("echo", {}, session_token: "token", headers: { "X-Test" => "yes" })
  end

  def test_delete_file_and_schema_helpers
    @stubs.delete("/parse/files/server-name.bin") do |env|
      assert_equal "master-key", env.request_headers[Parse::Protocol::MASTER_KEY]
      response
    end
    @stubs.delete("/parse/schemas/Song") { response }
    assert @client.delete_file("server-name.bin").success?
    assert @client.delete_schema("Song").success?
  end

  def test_impersonation_uses_post_query_and_preserves_master_key
    @stubs.post("/parse/loginAs?userId=one") do |env|
      assert_equal "master-key", env.request_headers[Parse::Protocol::MASTER_KEY]
      assert_equal "one", env.params["userId"]
      response({ "objectId" => "one", "sessionToken" => "impersonated-token" })
    end
    assert_equal "impersonated-token", Parse::User.login_as("one").session_token
  end

  def test_aggregate_pipeline_keeps_operators_and_field_names
    pipeline = [{ "$group" => { "_id" => nil, "total" => { "$sum" => "$score" } } }]
    @stubs.get("/parse/aggregate/Song") do |env|
      assert_equal pipeline, JSON.parse(env.params["pipeline"])
      response({ "results" => [{ "total" => 6 }] })
    end
    assert_equal 6, @client.aggregate_pipeline("Song", pipeline).results.first["total"]
    assert_raises(ArgumentError) { @client.aggregate_pipeline("Song", {}) }
  end

  def test_default_batch_size_and_explicit_override
    sizes = []
    @stubs.post("/parse/batch") do |env|
      requests = JSON.parse(env.body)["requests"]
      sizes << requests.length
      response(requests.map { { "success" => {} } })
    end
    requests = 21.times.map { |i| Parse::Request.new(:delete, "/parse/classes/Song/#{i}") }
    assert_equal 21, Parse::BatchOperation.new(requests).submit.length
    assert_equal [1, 20], sizes.sort
    sizes.clear
    assert_equal 21, Parse::BatchOperation.new(requests).submit(50).length
    assert_equal [21], sizes
    @client.batch_size = 10
    sizes.clear
    Parse::BatchOperation.new(requests).submit
    assert_equal [1, 10, 10], sizes.sort
    assert_raises(ArgumentError) { @client.batch_size = 0 }
    assert_raises(ArgumentError) { Parse::BatchOperation.new(requests).submit(-1) }
  end

  def test_empty_batch_does_not_require_a_client
    Parse::Client.clients[:default] = nil
    assert_empty Parse::BatchOperation.new.submit
  end

  def test_empty_success_response_and_headers
    @stubs.delete("/parse/files/empty.bin") { [204, { "X-Test" => "present" }, ""] }
    result = @client.delete_file("empty.bin")
    assert result.success?
    assert_equal 204, result.http_status
    assert_equal "present", result.header("x-test")
  end
end
