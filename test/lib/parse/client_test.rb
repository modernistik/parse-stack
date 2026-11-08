require_relative "../../test_helper"

class ClientCompatibilityRecord < Parse::Object
  property :name
end

class TestClient < Minitest::Test
  OPTIONS = { server_url: "https://parse.example.test/parse", app_id: "test-app", api_key: "rest-key", master_key: "master-key" }.freeze

  def setup
    @clients = Parse::Client.clients.dup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @client = Parse::Client.setup(OPTIONS) { |conn| conn.adapter :test, @stubs }
    @model_clients = [Parse::Query, Parse::User, Parse::Session, Parse::File, ClientCompatibilityRecord].to_h do |klass|
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

  def json_response(body, status = 200)
    json = JSON.generate(body)
    [status, { "content-type" => "application/json", "content-length" => json.bytesize.to_s }, json]
  end

  def test_setup_forwards_configuration_block
    yielded = nil
    client = Parse.setup(OPTIONS) { |conn| yielded = conn }
    assert_instance_of Parse::Client, client
    assert_instance_of Faraday::Connection, yielded
    assert_equal "test-app", client.application_id
  end

  def test_query_fetch_and_count_forward_request_options
    @stubs.get("/parse/classes/RubyCompatibilityRecord/") do |env|
      assert_equal "test-app", env.request_headers[Parse::Protocol::APP_ID]
      assert_equal "session-token", env.request_headers[Parse::Protocol::SESSION_TOKEN]
      refute env.request_headers.key?(Parse::Protocol::MASTER_KEY)
      if env.params["count"] == "1"
        json_response({ "results" => [], "count" => 2 })
      else
        json_response({ "results" => [{ "objectId" => "one", "name" => "First" }] })
      end
    end
    query = Parse::Query.new("RubyCompatibilityRecord", limit: 10, session: "session-token", use_master_key: false)
    assert_equal "First", query.results(raw: true).first["name"]
    assert_equal 2, query.count
  end

  def test_distinct_query_forwards_request_options
    @stubs.get("/parse/aggregate/Song") do |env|
      assert_equal "genre", env.params["distinct"]
      assert_equal "master-key", env.request_headers[Parse::Protocol::MASTER_KEY]
      json_response({ "results" => ["salsa", "jazz"] })
    end
    assert_equal ["salsa", "jazz"], Parse::Query.new("Song").distinct(:genre)
  end

  def test_query_streaming_and_model_all_forward_blocks
    @stubs.get("/parse/users/") do
      json_response({ "results" => [{ "objectId" => "one", "name" => "First" }] })
    end
    visited = []
    Parse::User.all { |user| visited << user.id }
    assert_equal ["one"], visited
    raw = []
    Parse::Query.new("User").results(raw: true) { |row| raw << row["objectId"] }
    assert_equal ["one"], raw
  end

  def test_object_fetch_forwards_options
    @stubs.get("/parse/users/one") do |env|
      assert_equal "session-token", env.request_headers[Parse::Protocol::SESSION_TOKEN]
      json_response({ "objectId" => "one", "username" => "updated" })
    end
    user = Parse::User.new(objectId: "one")
    assert_same user, user.fetch!(session_token: "session-token", use_master_key: false)
    assert_equal "updated", user.username
    refute user.changed?
  end

  def test_user_and_session_lookup_forward_options
    @stubs.get("/parse/users/me") do |env|
      assert_equal "token", env.request_headers[Parse::Protocol::SESSION_TOKEN]
      assert_equal "yes", env.request_headers["X-Test"]
      json_response({ "objectId" => "one", "username" => "test" })
    end
    @stubs.get("/parse/sessions/me") do |env|
      assert_equal "token", env.request_headers[Parse::Protocol::SESSION_TOKEN]
      json_response({ "objectId" => "session", "sessionToken" => "token" })
    end
    assert_equal "one", Parse::User.session!("token", headers: { "X-Test" => "yes" }).id
    assert_equal "session", Parse::Session.session("token", use_master_key: false).id
  end

  def test_user_creation_and_auth_link_preserve_options
    @stubs.post("/parse/users") do |env|
      refute env.request_headers.key?(Parse::Protocol::MASTER_KEY)
      assert_equal "new-user", JSON.parse(env.body)["username"]
      json_response({ "objectId" => "new", "createdAt" => "2026-11-07T00:00:00.000Z" }, 201)
    end
    @stubs.put("/parse/users/new") do |env|
      assert_equal "token", env.request_headers[Parse::Protocol::SESSION_TOKEN]
      assert_equal "yes", env.request_headers["X-Test"]
      assert_equal({ "id" => "external" }, JSON.parse(env.body).dig("authData", "test"))
      json_response({ "updatedAt" => "2026-11-07T00:00:00.000Z" })
    end
    assert_equal "new", Parse::User.create({ username: "new-user", password: "secret" }, use_master_key: false).id
    assert @client.set_service_auth_data("new", "test", { id: "external" }, headers: { "X-Test" => "yes" }, session_token: "token").success?
  end

  def test_signup_forwards_options
    @stubs.post("/parse/users") do |env|
      refute env.request_headers.key?(Parse::Protocol::MASTER_KEY)
      assert_equal "new-user", JSON.parse(env.body)["username"]
      json_response({ "objectId" => "new" }, 201)
    end
    assert @client.signup("new-user", "secret", use_master_key: false).success?
  end

  def test_batch_submission_yields_matching_request_and_response
    @stubs.post("/parse/batch") do |env|
      assert_equal "DELETE", JSON.parse(env.body).dig("requests", 0, "method")
      json_response([{ "success" => {} }])
    end
    request = Parse::Request.new(:delete, "classes/Song/one")
    visited = []
    responses = Parse::BatchOperation.new([request]).submit { |req, response| visited << [req, response.success?] }
    assert_equal [[request, true]], visited
    assert responses.first.success?
  end

  def test_cache_hit_and_invalidation_on_write
    cache = Moneta.new(:Memory)
    client = Parse::Client.setup(OPTIONS.merge(cache: cache)) { |conn| conn.adapter :test, @stubs }
    requests = 0
    @stubs.get("/parse/classes/Song/one") do
      requests += 1
      json_response({ "objectId" => "one", "name" => "Song" })
    end
    @stubs.put("/parse/classes/Song/one") { json_response({ "updatedAt" => "2026-11-07T00:00:00.000Z" }) }
    2.times { assert client.fetch_object("Song", "one").success? }
    assert_equal 1, requests
    assert client.update_object("Song", "one", { name: "Changed" }).success?
    assert client.fetch_object("Song", "one").success?
    assert_equal 2, requests
  end

  def test_connection_failure_is_wrapped_without_retry
    @stubs.get("/parse/classes/Song/one") { raise Faraday::ConnectionFailed, "offline" }
    error = assert_raises(Parse::Error::ConnectionError) do
      @client.fetch_object("Song", "one", retry: false)
    end
    assert_match "offline", error.message
  end

  def test_long_query_uses_post_override
    @stubs.post("/parse/classes/Song/") do |env|
      assert_nil env.url.query
      assert_equal "GET", env.request_headers[Parse::Middleware::BodyBuilder::HTTP_METHOD_OVERRIDE]
      assert_equal "GET", URI.decode_www_form(env.body).to_h["_method"]
      json_response({ "results" => [] })
    end
    assert @client.find_objects("Song", { where: { name: "a" * 2100 }.to_json }).success?
  end

  def test_send_request_preserves_body_headers_and_options
    @stubs.post("/parse/classes/Song") do |env|
      assert_equal({ "name" => "Song" }, JSON.parse(env.body))
      assert_equal "yes", env.request_headers["X-Test"]
      assert_equal "token", env.request_headers[Parse::Protocol::SESSION_TOKEN]
      refute env.request_headers.key?(Parse::Protocol::MASTER_KEY)
      json_response({ "objectId" => "one" }, 201)
    end
    request = Parse::Request.new(:post, "classes/Song", body: { name: "Song" }, headers: { "X-Test" => "yes" }, opts: { session_token: "token" })
    assert_equal "one", @client.send_request(request).result["objectId"]
  end

  def test_model_create_update_and_destroy_with_dirty_tracking
    @stubs.post("/parse/classes/ClientCompatibilityRecord/") do |env|
      assert_equal "Original", JSON.parse(env.body)["name"]
      json_response({ "objectId" => "one", "createdAt" => "2026-11-07T00:00:00.000Z" }, 201)
    end
    @stubs.put("/parse/classes/ClientCompatibilityRecord/one") do |env|
      assert_equal({ "name" => "Changed" }, JSON.parse(env.body))
      json_response({ "updatedAt" => "2026-11-07T01:00:00.000Z" })
    end
    @stubs.delete("/parse/classes/ClientCompatibilityRecord/one") { json_response({}) }
    record = ClientCompatibilityRecord.new(name: "Original")
    assert record.changed?
    assert record.save
    assert_equal "one", record.id
    refute record.changed?
    record.name = "Changed"
    assert record.name_changed?
    assert record.save
    refute record.changed?
    assert record.destroy
  end

  def test_file_upload_preserves_binary_body_and_content_type
    contents = "\x00\xFF\x80".b
    @stubs.post("/parse/files/test.bin") do |env|
      assert_equal contents, env.body
      assert_equal "application/octet-stream", env.request_headers["Content-Type"]
      json_response({ "name" => "test.bin", "url" => "https://files.example.test/test.bin" }, 201)
    end
    file = Parse::File.new("test.bin", contents, "application/octet-stream")
    assert file.save
    assert_equal "https://files.example.test/test.bin", file.url
  end
end
