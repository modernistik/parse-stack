require "faraday"
require "faraday_middleware"
require "active_support"
require "moneta"
require "active_model_serializers"
require "active_support/inflector"
require "active_support/core_ext/object"
require "active_support/core_ext/string"
require "active_support/core_ext/date/calculations"
require "active_support/core_ext/date_time/calculations"
require "active_support/core_ext/time/calculations"
require "active_support/core_ext"
require_relative "client/request"
require_relative "client/response"
require_relative "client/batch"
require_relative "client/body_builder"
require_relative "client/authentication"
require_relative "client/caching"
require_relative "api/all"

module Parse
  class Error < StandardError
    # An error when a general connection occurs.
    class ConnectionError < Error; end

    # An error when a connection timeout occurs.
    class TimeoutError < Error; end

    # An error when there is an Parse REST API protocol error.
    class ProtocolError < Error; end

    # An error when the Parse server returned invalid code.
    class ServerError < Error; end

    # An error when a Parse server responds with HTTP 500.
    class ServiceUnavailableError < Error; end

    # An error when the authentication credentials in the request are invalid.
    class AuthenticationError < Error; end

    # An error when the burst limit has been exceeded.
    class RequestLimitExceededError < Error; end

    # An error when the session token provided in the request is invalid.
    class InvalidSessionTokenError < Error; end
  end

  # Retrieve the App specific Parse configuration parameters. The configuration
  # for a connection is cached after the first request. Use the bang version to
  # force update from the Parse backend.
  # @example
  #  val = Parse.config["myKey"]
  #  val = Parse.config["myKey"] # cached
  # @see Parse.config!
  # @param conn [Symbol] the name of the client connection to use.
  # @return [Hash] the Parse config hash for the session.
  def self.config(conn = :default)
    Parse::Client.client(conn).config
  end

  # Set a parameter in the Parse configuration for an application.
  # @example
  #  # update a config with Parse
  #  Parse.set_config "myKey", "someValue"
  # @param field [String] the name configuration variable.
  # @param value [Object] the value configuration variable. Only Parse types are supported.
  # @param conn [Symbol] the name of the client connection to use.
  # @return [Hash] the Parse config hash for the session.
  def self.set_config(field, value, conn = :default)
    Parse::Client.client(conn).update_config({ field => value })
  end

  # Set a key value pairs in the Parse configuration for an application.
  # @example
  #   # batch update several
  #   Parse.update_config({fieldEnabled: true, searchMiles: 50})
  # @param params [Hash] a set of key value pairs to set in the Parse configuration.
  # @param conn [Symbol] the name of the client connection to use.
  # @return [Hash] the Parse config hash for the session.
  def self.update_config(params, conn = :default)
    Parse::Client.client(conn).update_config(params)
  end

  # Force fetch updated Parse configuration
  # @param conn [Symbol] the name of the client connection to use.
  # @return [Hash] the Parse configuration
  def self.config!(conn = :default)
    Parse::Client.client(conn).config!
  end

  # Helper method to get the default Parse client.
  # @param conn [Symbol] the name of the client connection to use. Defaults to :default
  # @return [Parse::Client] a client object for the connection name.
  def self.client(conn = :default)
    Parse::Client.client(conn)
  end

  # The shared cache for the default client connection. This is useful if you want to
  # also utilize the same cache store for other purposes in your application.
  # This should normally be a {https://github.com/minad/moneta Moneta} unified
  # cache interface.
  # @return [Moneta::Transformer,Moneta::Expires] the cache instance
  # @see Parse::Client#cache
  def self.cache
    @shared_cache ||= Parse::Client.client(:default).cache
  end

  # This class is the core and low level API for the Parse SDK REST interface that
  # is used by the other components. It can manage multiple sessions, which means
  # you can have multiple client instances pointing to different Parse Applications
  # at the same time. It handles sending raw requests as well as providing
  # Request/Response objects for all API handlers. The connection engine is
  # Faraday, which means it is open to add any additional middleware for
  # features you'd like to implement.
  class Client
    include Parse::API::Analytics
    include Parse::API::Aggregate
    include Parse::API::Batch
    include Parse::API::CloudFunctions
    include Parse::API::Config
    include Parse::API::Files
    include Parse::API::Hooks
    include Parse::API::Objects
    include Parse::API::Push
    include Parse::API::Schema
    include Parse::API::Server
    include Parse::API::Sessions
    include Parse::API::Users
    # The user agent header key.
    USER_AGENT_HEADER = "User-Agent".freeze
    # The value for the User-Agent header.
    USER_AGENT_VERSION = "Parse-Stack v#{Parse::Stack::VERSION}".freeze
    # The default retry count
    DEFAULT_RETRIES = 2
    # The wait time in seconds between retries
    RETRY_DELAY = 1.5

    # An error when a general response error occurs when communicating with Parse server.
    class ResponseError < Parse::Error; end

    # @!attribute cache
    #  The underlying cache store for caching API requests.
    #  @see Parse.cache
    #  @return [Moneta::Transformer,Moneta::Expires]
    # @!attribute [r] application_id
    #  The Parse application identifier to be sent in every API request.
    #  @return [String]
    # @!attribute [r] api_key
    #  The Parse API key to be sent in every API request.
    #  @return [String]
    # @!attribute [r] master_key
    #  The Parse master key for this application, which when set, will be sent
    #  in every API request. (There is a way to prevent this on a per request basis.)
    #  @return [String]
    # @!attribute [r] server_url
    #  The Parse server url that will be receiving these API requests. By default
    #  this will be {Parse::Protocol::SERVER_URL}.
    #  @return [String]
    # @!attribute retry_limit
    #  The default retry count for the client when a specific request timesout or
    #  the service is unavailable. Defaults to {DEFAULT_RETRIES}.
    #  @return [String]
    attr_accessor :cache, :retry_limit
    attr_reader :application_id, :api_key, :master_key, :server_url
    alias_method :app_id, :application_id
    # The client can support multiple sessions. The first session created, will be placed
    # under the default session tag. The :default session will be the default client to be used
    # by the other classes including Parse::Query and Parse::Objects
    @clients = { default: nil }
    class << self
      # @!attribute [r] clients
      #  A hash of Parse::Client instances.
      #  @return [Hash<Parse::Client>]
      attr_reader :clients

      # @param conn [Symbol] the name of the connection.
      # @return [Boolean] true if a Parse::Client has been configured.
      def client?(conn = :default)
        @clients[conn].present?
      end

      # Returns or create a new Parse::Client connection for the given connection
      # name.
      # @param conn [Symbol] the name of the connection.
      # @return [Parse::Client]
      def client(conn = :default)
        @clients[conn] ||= self.new
      end

      # Setup the a new client with the appropriate Parse app keys, middleware and
      # options.
      # @example
      #   Parse.setup app_id: "YOUR_APP_ID",
      #               api_key: "YOUR_REST_API_KEY",
      #               master_key: "YOUR_MASTER_KEY", # optional
      #               server_url: 'https://localhost:1337/parse' #default
      # @param opts (see Parse::Client#initialize)
      # @option opts (see Parse::Client#initialize)
      # @yield the block for additional configuration with Faraday middleware.
      # @return (see Parse::Client#initialize)
      # @see Parse::Middleware::BodyBuilder
      # @see Parse::Middleware::Caching
      # @see Parse::Middleware::Authentication
      # @see Parse::Protocol
      def setup(opts = {}, &block)
        @clients[:default] = self.new(opts, &block)
      end
    end

    # Create a new client connected to the Parse Server REST API endpoint.
    # @param opts [Hash] a set of connection options to configure the client.
    # @option opts [String] :server_url The server url of your Parse Server if you
    #   are not using the hosted Parse service. By default it will use
    #   ENV["PARSE_SERVER_URL"] if available, otherwise fallback to {Parse::Protocol::SERVER_URL}.
    # @option opts [String] :app_id The Parse application id. Defaults to
    #    ENV['PARSE_SERVER_APPLICATION_ID'].
    # @option opts [String] :api_key Your Parse REST API Key. Defaults to ENV['PARSE_SERVER_REST_API_KEY'].
    # @option opts [String] :master_key The Parse application master key (optional).
    #    If this key is set, it will be sent on every request sent by the client
    #    and your models. Defaults to ENV['PARSE_SERVER_MASTER_KEY'].
    # @option opts [Boolean] :logging It provides you additional logging information
    #    of requests and responses. If set to the special symbol of *:debug*, it
    #    will provide additional payload data in the log messages. This option affects
    #    the logging performed by {Parse::Middleware::BodyBuilder}.
    # @option opts [Object] :adapter The connection adapter. By default it uses
    #    the `Faraday.default_adapter` which is Net/HTTP.
    # @option opts [Moneta::Transformer,Moneta::Expires] :cache A caching adapter of type
    #    {https://github.com/minad/moneta Moneta::Transformer} or
    #    {https://github.com/minad/moneta Moneta::Expires} that will be used
    #    by the caching middleware {Parse::Middleware::Caching}.
    #    Caching queries and object fetches can help improve the performance of
    #    your application, even if it is for a few seconds. Only successful GET
    #    object fetches and non-empty result queries will be cached by default.
    #    You may set the default expiration time with the expires option.
    #    At any point in time you may clear the cache by calling the {Parse::Client#clear_cache!}
    #    method on the client connection. See {https://github.com/minad/moneta Moneta}.
    # @option opts [Integer] :expires Sets the default cache expiration time
    #    (in seconds) for successful non-empty GET requests when using the caching
    #    middleware. The default value is 3 seconds. If :expires is set to 0,
    #    caching will be disabled. You can always clear the current state of the
    #    cache using the clear_cache! method on your Parse::Client instance.
    # @option opts [Hash] :faraday You may pass a hash of options that will be
    #    passed to the Faraday constructor.
    # @raise Parse::Error::ConnectionError if the client was not properly configured with required keys or url.
    # @raise ArgumentError if the cache instance passed to the :cache option is not of Moneta::Transformer or Moneta::Expires
    # @see Parse::Middleware::BodyBuilder
    # @see Parse::Middleware::Caching
    # @see Parse::Middleware::Authentication
    # @see Parse::Protocol
    def initialize(opts = {})
      @server_url = opts[:server_url] || ENV["PARSE_SERVER_URL"] || Parse::Protocol::SERVER_URL
      @application_id = opts[:application_id] || opts[:app_id] || ENV["PARSE_SERVER_APPLICATION_ID"] || ENV["PARSE_APP_ID"]
      @api_key = opts[:api_key] || opts[:rest_api_key] || ENV["PARSE_SERVER_REST_API_KEY"] || ENV["PARSE_API_KEY"]
      @master_key = opts[:master_key] || ENV["PARSE_SERVER_MASTER_KEY"] || ENV["PARSE_MASTER_KEY"]
      opts[:adapter] ||= Faraday.default_adapter
      opts[:expires] ||= 3
      if @server_url.nil? || @application_id.nil? || (@api_key.nil? && @master_key.nil?)
        raise Parse::Error::ConnectionError, "Please call Parse.setup(server_url:, application_id:, api_key:) to setup a client"
      end
      @server_url += "/" unless @server_url.ends_with?("/")
      #Configure Faraday
      opts[:faraday] ||= {}
      opts[:faraday].merge!(:url => @server_url)
      @conn = Faraday.new(opts[:faraday]) do |conn|
        #conn.request :json

        conn.response :logger if opts[:logging]

        # This middleware handles sending the proper authentication headers to Parse
        # on each request.

        # this is the required authentication middleware. Should be the first thing
        # so that other middlewares have access to the env that is being set by
        # this middleware. First added is first to brocess.
        conn.use Parse::Middleware::Authentication,
                 application_id: @application_id,
                 master_key: @master_key,
                 api_key: @api_key
        # This middleware turns the result from Parse into a Parse::Response object
        # and making sure request that are going out, follow the proper MIME format.
        # We place it after the Authentication middleware in case we need to use then
        # authentication information when building request and responses.
        conn.use Parse::Middleware::BodyBuilder
        if opts[:logging].present? && opts[:logging] == :debug
          Parse::Middleware::BodyBuilder.logging = true
        end

        if opts[:cache].present? && opts[:expires].to_i > 0
          # advanced: provide a REDIS url, we'll configure a Moneta Redis store.
          if opts[:cache].is_a?(String) && opts[:cache].starts_with?("redis://")
            begin
              opts[:cache] = Moneta.new(:Redis, url: opts[:cache])
            rescue LoadError
              puts "[Parse::Middleware::Caching] Did you forget to load the redis gem (Gemfile)?"
              raise
            end
          end

          unless [:key?, :[], :delete, :store].all? { |method| opts[:cache].respond_to?(method) }
            raise ArgumentError, "Parse::Client option :cache needs to be a type of Moneta store"
          end
          self.cache = opts[:cache]
          conn.use Parse::Middleware::Caching, self.cache, { expires: opts[:expires].to_i }
        end

        yield(conn) if block_given?

        conn.adapter opts[:adapter]
      end
      Parse::Client.clients[:default] ||= self
    end

    # If set, returns the current retry count for this instance. Otherwise,
    # returns {DEFAULT_RETRIES}. Set to 0 to disable retry mechanism.
    # @return [Integer] the current retry count for this client.
    def retry_limit
      return DEFAULT_RETRIES if @retry_limit.nil?
      @retry_limit
    end

    # @return [String] the url prefix of the Parse Server url.
    def url_prefix
      @conn.url_prefix
    end

    # Clear the client cache
    def clear_cache!
      self.cache.clear if self.cache.present?
    end

    # Send a REST API request to the server. This is the low-level API used for all requests
    # to the Parse server with the provided options. Every request sent to Parse through
    # the client goes through the configured set of middleware that can be modified by applying
    # different headers or specific options.
    # This method supports retrying requests a few times when a {Parse::ServiceUnavailableError}
    # is raised.
    # @param method [Symbol] The method type of the HTTP request (ex. :get, :post).
    #   - This parameter can also be a {Parse::Request} object.
    # @param uri [String] the url path. It should not be an absolute url.
    # @param body [Hash] the body of the request.
    # @param query [Hash] the set of url query parameters to use in a GET request.
    # @param headers [Hash] additional headers to apply to this request.
    # @param opts [Hash] a set of options to pass through the middleware stack.
    #  - *:cache* [Integer] the number of seconds to cache this specific request.
    #    If set to `false`, caching will be disabled completely all together, which means even if
    #    a cached response exists, it will not be used.
    #  - *:use_master_key* [Boolean] whether this request should send the master key, if
    #    it was configured with {Parse.setup}. By default, if a master key was configured,
    #    all outgoing requests will contain it in the request header. Default `true`.
    #  - *:session_token* [String] The session token to send in this request. This disables
    #    sending the master key in the request, and sends this request with the credentials provided by
    #    the session_token.
    #  - *:retry* [Integer] The number of retrties to perform if the service is unavailable.
    #    Set to false to disable the retry mechanism. When performing request retries, the
    #    client will sleep for a number of seconds ({Parse::Client::RETRY_DELAY}) between requests.
    #    The default value is {Parse::Client::DEFAULT_RETRIES}.
    # @raise Parse::Error::AuthenticationError when HTTP response status is 401 or 403
    # @raise Parse::Error::TimeoutError when HTTP response status is 400 or
    #   408, and the Parse code is 143 or {Parse::Response::ERROR_TIMEOUT}.
    # @raise Parse::Error::ConnectionError when HTTP response status is 404 is not an object not found error.
    #  - This will also be raised if after retrying a request a number of times has finally failed.
    # @raise Parse::Error::ProtocolError when HTTP response status is 405 or 406
    # @raise Parse::Error::ServiceUnavailableError when HTTP response status is 500 or 503.
    #   - This may also happen when the Parse Server response code is any
    #     number less than {Parse::Response::ERROR_SERVICE_UNAVAILABLE}.
    # @raise Parse::Error::ServerError when the Parse response code is less than 100
    # @raise Parse::Error::RequestLimitExceededError when the Parse response code is {Parse::Response::ERROR_EXCEEDED_BURST_LIMIT}.
    #   - This usually means you have exceeded the burst limit on requests, which will mean you will be throttled for the
    #     next 60 seconds.
    # @raise Parse::Error::InvalidSessionTokenError when the Parse response code is 209.
    #   - This means the session token that was sent in the request seems to be invalid.
    # @return [Parse::Response] the response for this request.
    # @see Parse::Middleware::BodyBuilder
    # @see Parse::Middleware::Caching
    # @see Parse::Middleware::Authentication
    # @see Parse::Protocol
    # @see Parse::Request
    def request(method, uri = nil, body: nil, query: nil, headers: nil, opts: {})
      _retry_count ||= self.retry_limit

      if opts[:retry] == false
        _retry_count = 0
      elsif opts[:retry].to_i > 0
        _retry_count = opts[:retry]
      end

      headers ||= {}
      # if the first argument is a Parse::Request object, then construct it
      _request = nil
      if method.is_a?(Request)
        _request = method
        method = _request.method
        uri ||= _request.path
        query ||= _request.query
        body ||= _request.body
        headers.merge! _request.headers
      else
        _request = Parse::Request.new(method, uri, body: body, headers: headers, opts: opts)
      end

      # http method
      method = method.downcase.to_sym
      # set the User-Agent
      headers[USER_AGENT_HEADER] = USER_AGENT_VERSION

      if opts[:cache] == false
        headers[Parse::Middleware::Caching::CACHE_CONTROL] = "no-cache"
      elsif opts[:cache].is_a?(Numeric)
        # specify the cache duration of this request
        headers[Parse::Middleware::Caching::CACHE_EXPIRES_DURATION] = opts[:cache].to_s
      end

      if opts[:use_master_key] == false
        headers[Parse::Middleware::Authentication::DISABLE_MASTER_KEY] = "true"
      end

      token = opts[:session_token]
      if token.present?
        token = token.session_token if token.respond_to?(:session_token)
        headers[Parse::Middleware::Authentication::DISABLE_MASTER_KEY] = "true"
        headers[Parse::Protocol::SESSION_TOKEN] = token
      end

      #if it is a :get request, then use query params, otherwise body.
      params = (method == :get ? query : body) || {}
      # if the path does not start with the '/1/' prefix, then add it to be nice.
      # actually send the request and return the body
      response_env = @conn.send(method, uri, params, headers)
      response = response_env.body
      response.request = _request

      case response.http_status
      when 401, 403
        warn "[Parse:AuthenticationError] #{response}"
        raise Parse::Error::AuthenticationError, response
      when 400, 408
        if response.code == Parse::Response::ERROR_TIMEOUT || response.code == 143 #"net/http: timeout awaiting response headers"
          warn "[Parse:TimeoutError] #{response}"
          raise Parse::Error::TimeoutError, response
        end
      when 404
        unless response.object_not_found?
          warn "[Parse:ConnectionError] #{response}"
          raise Parse::Error::ConnectionError, response
        end
      when 405, 406
        warn "[Parse:ProtocolError] #{response}"
        raise Parse::Error::ProtocolError, response
      when 429 # Request over the throttle limit
        warn "[Parse:RequestLimitExceededError] #{response}"
        raise Parse::Error::RequestLimitExceededError, response
      when 500, 503
        warn "[Parse:ServiceUnavailableError] #{response}"
        raise Parse::Error::ServiceUnavailableError, response
      end

      if response.error?
        if response.code <= Parse::Response::ERROR_SERVICE_UNAVAILABLE
          warn "[Parse:ServiceUnavailableError] #{response}"
          raise Parse::Error::ServiceUnavailableError, response
        elsif response.code <= 100
          warn "[Parse:ServerError] #{response}"
          raise Parse::Error::ServerError, response
        elsif response.code == Parse::Response::ERROR_EXCEEDED_BURST_LIMIT
          warn "[Parse:RequestLimitExceededError] #{response}"
          raise Parse::Error::RequestLimitExceededError, response
        elsif response.code == 209 # Error 209: invalid session token
          warn "[Parse:InvalidSessionTokenError] #{response}"
          raise Parse::Error::InvalidSessionTokenError, response
        end
      end

      response
    rescue Parse::Error::RequestLimitExceededError, Parse::Error::ServiceUnavailableError => e
      if _retry_count > 0
        warn "[Parse:Retry] Retries remaining #{_retry_count} : #{response.request}"
        _retry_count -= 1
        backoff_delay = RETRY_DELAY * (self.retry_limit - _retry_count)
        _retry_delay = [0, RETRY_DELAY, backoff_delay].sample
        sleep _retry_delay if _retry_delay > 0
        retry
      end
      raise
    rescue Faraday::Error::ClientError, Net::OpenTimeout => e
      if _retry_count > 0
        warn "[Parse:Retry] Retries remaining #{_retry_count} : #{_request}"
        _retry_count -= 1
        backoff_delay = RETRY_DELAY * (self.retry_limit - _retry_count)
        _retry_delay = [0, RETRY_DELAY, backoff_delay].sample
        sleep _retry_delay if _retry_delay > 0
        retry
      end
      raise Parse::Error::ConnectionError, "#{_request} : #{e.class} - #{e.message}"
    end

    # Send a GET request.
    # @param uri [String] the uri path for this request.
    # @param query [Hash] the set of url query parameters.
    # @param headers [Hash] additional headers to send in this request.
    # @return (see #request)
    def get(uri, query = nil, headers = {})
      request :get, uri, query: query, headers: headers
    end

    # Send a POST request.
    # @param uri (see #get)
    # @param body [Hash] a hash that will be JSON encoded for the body of this request.
    # @param headers (see #get)
    # @return (see #request)
    def post(uri, body = nil, headers = {})
      request :post, uri, body: body, headers: headers
    end

    # Send a PUT request.
    # @param uri (see #post)
    # @param body (see #post)
    # @param headers (see #post)
    # @return (see #request)
    def put(uri, body = nil, headers = {})
      request :put, uri, body: body, headers: headers
    end

    # Send a DELETE request.
    # @param uri (see #post)
    # @param body (see #post)
    # @param headers (see #post)
    # @return (see #request)
    def delete(uri, body = nil, headers = {})
      request :delete, uri, body: body, headers: headers
    end

    # Send a {Parse::Request} object.
    # @param req [Parse::Request] the request to send
    # @raise ArgumentError if req is not of type Parse::Request.
    # @return (see #request)
    def send_request(req) #Parse::Request object
      raise ArgumentError, "Object not of Parse::Request type." unless req.is_a?(Parse::Request)
      request req.method, req.path, req.body, req.headers
    end

    # The connectable  module adds methods to objects so that they can get a default
    # Parse::Client object if needed. This is mainly used for Parse::Query and Parse::Object classes.
    # This is included in the Parse::Model class.
    # Any subclass can override their `client` methods to provide a different session to use
    module Connectable

      # @!visibility private
      def self.included(baseClass)
        baseClass.extend ClassMethods
      end
      # Class methods to be added to any object that wants to have standard access to
      # a the default {Parse::Client} instance.
      module ClassMethods

        # @return [Parse::Client] the current client for :default.
        attr_accessor :client

        def client
          @client ||= Parse::Client.client #defaults to :default tag
        end
      end

      # @return [Parse::Client] the current client defined for the class.
      def client
        self.class.client
      end
    end #Connectable
  end

  # Helper method that users should call to setup the client stack.
  # A block can be passed in order to do additional client configuration.
  # To connect to a Parse server, you will need a minimum of an application_id,
  # an api_key and a server_url. To connect to the server endpoint, you use the
  # {Parse.setup} method below.
  #
  # @example (see Parse::Client.setup)
  # @param opts (see Parse::Client.setup)
  # @option opts (see Parse::Client.setup)
  # @yield (see Parse::Client.setup)
  # @return (see Parse::Client.setup)
  # @see Parse::Client.setup
  def self.setup(opts = {}, &block)
    if block_given?
      Parse::Client.new(opts, &block)
    else
      Parse::Client.new(opts)
    end
  end

  # Helper method to trigger cloud jobs and get results.
  # @param name [String] the name of the cloud code job to trigger.
  # @param body [Hash] the set of parameters to pass to the job.
  # @param opts (see Parse.call_function)
  # @return (see Parse.call_function)
  def self.trigger_job(name, body = {}, **opts)
    conn = opts[:session] || opts[:client] || :default
    response = Parse::Client.client(conn).trigger_job(name, body)
    return response if opts[:raw].present?
    response.error? ? nil : response.result["result"]
  end

  # Helper method to call cloud functions and get results.
  # @param name [String] the name of the cloud code function to call.
  # @param body [Hash] the set of parameters to pass to the function.
  # @param opts [Hash] additional options.
  # @return [Object] the result data of the response. nil if there was an error.
  def self.call_function(name, body = {}, **opts)
    conn = opts[:session] || opts[:client] || :default
    response = Parse::Client.client(conn).call_function(name, body)
    return response if opts[:raw].present?
    response.error? ? nil : response.result["result"]
  end
end
