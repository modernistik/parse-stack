require_relative "../../test_helper"
require "rack/lint"
require "rack/mock"

class TestWebhooks < Minitest::Test
  def setup
    @routes = Parse::Webhooks.instance_variable_get(:@routes)
    @key = Parse::Webhooks.key
    Parse::Webhooks.instance_variable_set(:@routes, nil)
    Parse::Webhooks.key = "test-webhook-key"
    @app = Rack::MockRequest.new(Rack::Lint.new(Parse::Webhooks))
  end

  def teardown
    Parse::Webhooks.instance_variable_set(:@routes, @routes)
    Parse::Webhooks.key = @key
  end

  def post(payload, key: "test-webhook-key")
    @app.post("/", "CONTENT_TYPE" => "application/json", "HTTP_X_PARSE_WEBHOOK_KEY" => key, input: JSON.generate(payload))
  end

  def test_function_registration_and_rack_response
    Parse::Webhooks.route(:function, "greeting") { |payload| "Hello #{payload.params['name']}" }
    response = post({ "functionName" => "greeting", "params" => { "name" => "Ruby" } })
    assert_equal 200, response.status
    assert_equal({ "success" => "Hello Ruby" }, JSON.parse(response.body))
  end

  def test_model_function_and_trigger_registration_with_blocks
    Parse::User.webhook_function(:greeting) { "hello" }
    Parse::User.webhook(:function, :other_greeting) { "hi" }
    Parse::User.webhook(:before_save) do |payload|
      user = payload.parse_object
      user.username = "updated"
      user
    end
    assert_equal "hello", JSON.parse(post({ "functionName" => "greeting" }).body)["success"]
    assert_equal "hi", JSON.parse(post({ "functionName" => "other_greeting" }).body)["success"]
    response = post({ "triggerName" => "beforeSave", "object" => { "className" => "_User", "objectId" => "one", "username" => "original" } })
    assert_equal "updated", JSON.parse(response.body).dig("success", "username")
  end

  def test_invalid_key_and_invalid_json_return_parse_errors
    assert JSON.parse(post({}, key: "wrong").body).key?("error")
    response = @app.post("/", "CONTENT_TYPE" => "application/json", "HTTP_X_PARSE_WEBHOOK_KEY" => "test-webhook-key", input: "not json")
    assert JSON.parse(response.body).key?("error")
  end

  def test_request_body_need_not_be_rewindable
    Parse::Webhooks.route(:function, "greeting") { "hello" }
    body = StringIO.new('{"functionName":"greeting"}')
    stream = Object.new
    stream.define_singleton_method(:read) { |*args| body.read(*args) }
    env = Rack::MockRequest.env_for("/", method: "POST", "CONTENT_TYPE" => "application/json", "HTTP_X_PARSE_WEBHOOK_KEY" => "test-webhook-key")
    env["rack.input"] = stream
    status, _headers, response_body = Parse::Webhooks.call(env)
    assert_equal 200, status
    assert_equal({ "success" => "hello" }, JSON.parse(response_body.join))
  end
end
