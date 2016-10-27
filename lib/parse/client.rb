require 'faraday'
require 'faraday_middleware'
require 'active_support'
require 'active_model_serializers'
require 'active_support/inflector'
require 'active_support/core_ext/object'
require 'active_support/core_ext/string'
require 'active_support/core_ext/date/calculations'
require 'active_support/core_ext/date_time/calculations'
require 'active_support/core_ext/time/calculations'
require 'active_support/core_ext'
require_relative "client/request"
require_relative "client/response"
require_relative "client/body_builder"
require_relative "client/authentication"
require_relative "client/caching"
require_relative "api/all"

module Parse

  class ConnectionError < StandardError; end;
  class TimeoutError < StandardError; end;
  class ProtocolError < StandardError; end;
  class ServerError < StandardError; end;
  class ServiceUnavailableError < StandardError; end;
  class AuthenticationError < StandardError; end;
  class RequestLimitExceededError < StandardError; end;
  class InvalidSessionTokenError < StandardError; end;

  # Retrieve the App specific Parse configuration parameters. The configuration
  # for a connection is cached after the first request. Use the bang version to
  # force update from the Parse backend.
  # @see Parse.config!
  # @param conn [Symbol] the name of the client connection to use.
  # @return [Hash] the Parse config hash for the session.
  def self.config(conn = :default)
    Parse::Client.client(conn).config
  end

  # Set a parameter in the Parse configuration for an application.
  # @param field [String] the name configuration variable.
  # @param value [Object] the value configuration variable. Only Parse types are supported.
  # @param conn [Symbol] the name of the client connection to use.
  # @return [Hash] the Parse config hash for the session.
  def self.set_config(field, value, conn = :default)
    Parse::Client.client(conn).update_config({ field => value })
  end

  # Set a key value pairs in the Parse configuration for an application.
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
  # @param conn [Symbol] the name of the client connection to use.
  # @return [Parse::Client] a client object for the connection name.
  def self.client(conn = :default)
    Parse::Client.client(conn)
  end

  # This class is the core and low level API for the Parse SDK REST interface that
  # is used by the other components. It can manage multiple sessions, which means
  # you can have multiple client instances pointing to different Parse Applications
  # at the same time. It handles sending raw requests as well as providing
  # Request/Response objects for all API handlers. The connection engine is
  # Faraday, which means it is open to add any additional middleware for
  # features you'd like to implement.
  class Client
    include Parse::API::Objects
    include Parse::API::Config
    include Parse::API::Files
    include Parse::API::CloudFunctions
    include Parse::API::Users
    include Parse::API::Sessions
    include Parse::API::Hooks
    include Parse::API::Apps
    include Parse::API::Batch
    include Parse::API::Push
    include Parse::API::Schema
    RETRY_COUNT = 2
    RETRY_DELAY = 2 #seconds

    # @!attribute cache
    #  The underlying cache store for caching API requests.
    #  @return [Moneta::Transformer]
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
    attr_accessor :cache
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

      # Setup the Parse-Stack framework with the appropriate Parse app keys and middleware.
      # @yield a block for additional configuration
      # @param opts [Hash] the set of options to configure the :default Parse::Client connection.
      # @return [Parse::Client]
      # @see Parse::Client#initialize
      def setup(opts = {})
        @clients[:default] = self.new(opts, &Proc.new)
      end

    end

    # This builds a new Parse::Client stack. The options are:
    # required
    # :application_id -  Parse Application ID. If not set it will be read from the
    #                    PARSE_APP_ID environment variable
    # :api_key - the Parse REST API Key. If not set it will be
    #            read from PARSE_API_KEY environment variable
    # :master_key - the Parse Master Key (optional). If PARSE_MASTER_KEY env is set
    #               it will be used.
    # optional
    # :logger - boolean - whether to print the requests and responses.
    # :cache - Moneta::Transformer - if set, it should be a Moneta store instance
    # :expires - Integer - if set, it should be a Moneta store instance
    # :adapter - the HTTP adapter to use with Faraday, defaults to Faraday.default_adapter
    # :host - defaults to Parse::Protocol::SERVER_URL (https://api.parse.com/1/)
    def initialize(opts = {})
      @server_url     = opts[:server_url] || ENV["PARSE_SERVER_URL"] || Parse::Protocol::SERVER_URL
      @application_id = opts[:application_id] || opts[:app_id] || ENV["PARSE_APP_ID"] || ENV['PARSE_SERVER_APPLICATION_ID']
      @api_key        = opts[:api_key] || opts[:rest_api_key]  || ENV["PARSE_API_KEY"] || ENV["PARSE_REST_API_KEY"]
      @master_key     = opts[:master_key] || ENV["PARSE_MASTER_KEY"] || ENV['PARSE_SERVER_MASTER_KEY']
      opts[:adapter] ||= Faraday.default_adapter
      opts[:expires] ||= 3
      if @application_id.nil? || ( @api_key.nil? && @master_key.nil? )
        raise "Please call Parse.setup(application_id:, api_key:) to setup a client"
      end
      @server_url += '/' unless @server_url.ends_with?('/')
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
          unless opts[:cache].is_a?(Moneta::Transformer)
            raise ArgumentError, "Parse::Client option :cache needs to be a type of Moneta::Transformer store."
          end
          self.cache = opts[:cache]
          conn.use Parse::Middleware::Caching, self.cache, {expires: opts[:expires].to_i }
        end

        yield(conn) if block_given?

        conn.adapter opts[:adapter]

      end
      Parse::Client.clients[:default] ||= self
      self
    end

    # @return [String] the url prefix of the Parse Server url.
    def url_prefix
      @conn.url_prefix
    end

    # Clear the client cache
    def clear_cache!
      self.cache.clear if self.cache.present?
    end

    # This is the base method to make raw requests. The first parameter is a symbol
    # of the type of request - either :get, :put, :post, :delete. The second parameter
    # is the path api to use. For example, to make a request for objects, you would pass the "/1/classes/<ClassName>".
    # After the first two parameters, the rest are named parameters. If the request is of type :get, you can pass
    # any query string parameters in hash form with query:. If it is any other request, the body of the request should be sent
    # with the body: parameter. Note that the middleware will handle turning the hash sent into the body: parameter into JSON.
    # If you need to override or add additional headers to a specific request (ex. when uploading a Parse File), you can do so
    # with the header: paramter (also a hash).
    # This method also takes in a Parse::Request object instead of the arguments listed above.
    def request(method, uri = nil, body: nil, query: nil, headers: nil, opts: {})
      retry_count ||= RETRY_COUNT
      headers ||= {}
      # if the first argument is a Parse::Request object, then construct it
      _request = nil
      if method.is_a?(Request)
        _request     = method
        method       = _request.method
        uri        ||= _request.path
        query      ||= _request.query
        body       ||= _request.body
        headers.merge! _request.headers
      else
        _request = Parse::Request.new(method, uri, body: body, headers: headers, opts: opts)
      end

      # http method
      method = method.downcase.to_sym
      # set the User-Agent
      headers["User-Agent"] = "Parse-Stack v#{Parse::Stack::VERSION}"

      if opts[:cache] == false
        headers[Parse::Middleware::Caching::CACHE_CONTROL] = "no-cache"
      elsif opts[:cache].is_a?(Numeric)
        # specify the cache duration of this request
        headers[Parse::Middleware::Caching::CACHE_EXPIRES_DURATION] = opts[:cache].to_i
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
        puts "[Parse:AuthenticationError] #{response}"
        raise Parse::AuthenticationError, response
      when 400, 408
        if response.code == Parse::Response::ERROR_TIMEOUT || response.code == 143 #"net/http: timeout awaiting response headers"
          puts "[Parse:TimeoutError] #{response}"
          raise Parse::TimeoutError, response
        end
      when 404
        unless response.object_not_found?
          puts "[Parse:ConnectionError] #{response}"
          raise Parse::ConnectionError, response
        end
      when 405, 406
        puts "[Parse:ProtocolError] #{response}"
        raise Parse::ProtocolError, response
      when 500
        puts "[Parse:ServiceUnavailableError] #{response}"
        raise Parse::ServiceUnavailableError, response
      when 503
        puts "[Parse:ServiceUnavailableError] #{response}"
        raise Parse::ServiceUnavailableError, response
      end

      if response.error?
        if response.code <= Parse::Response::ERROR_SERVICE_UNAVAILALBE
          puts "[Parse:ServiceUnavailableError] #{response}"
          raise Parse::ServiceUnavailableError, response
        elsif response.code <= 100
          puts "[Parse:ServerError] #{response}"
          raise Parse::ServerError, response
        elsif response.code == Parse::Response::ERROR_EXCEEDED_BURST_LIMIT
          puts "[Parse:RequestLimitExceededError] #{response}"
          raise Parse::RequestLimitExceededError, response
        elsif response.code == 209 #Error 209: invalid session token
          puts "[Parse:InvalidSessionTokenError] #{response}"
          raise Parse::InvalidSessionTokenError, response
        end
      end

      response
    rescue Parse::ServiceUnavailableError => e
      if retry_count > 0
        puts "[Parse:Retry] Retries remaining #{retry_count} : #{response.request}"
        sleep RETRY_DELAY
        retry_count -= 1
        retry
      end
      raise e
    rescue Faraday::Error::ClientError, Net::OpenTimeout => e
      if retry_count > 0
        puts "[Parse:Retry] Retries remaining #{retry_count} : #{_request}"
        sleep RETRY_DELAY
        retry_count -= 1
        retry
      end
      raise Parse::ConnectionError, "#{_request} : #{e.class} - #{e.message}"
    end

    # shorthand for request(:get, uri, query: {})
    def get(uri, query = nil, headers = {})
      request :get, uri, query: query, headers: headers
    end

    # shorthand for request(:post, uri, body: {})
    def post(uri, body = nil, headers = {} )
      request :post, uri, body: body, headers: headers
    end

    # shorthand for request(:put, uri, body: {})
    def put(uri, body = nil, headers = {})
      request :put, uri, body: body, headers: headers
    end

    # shorthand for request(:delete, uri, body: {}, headers: {})
    def delete(uri, body = nil, headers = {})
      request :delete, uri, body: body, headers: headers
    end

    def send_request(req) #Parse::Request object
      raise ArgumentError, "Object not of Parse::Request type." unless req.is_a?(Parse::Request)
      request req.method, req.path, req.body, req.headers
    end

    # The connectable  module adds methods to objects so that they can get a default
    # Parse::Client object if needed. This is mainly used for Parse::Query and Parse::Object classes.
    # This is included in the Parse::Model class.
    # Any subclass can override their `client` methods to provide a different session to use
    module Connectable

      def self.included(baseClass)
        baseClass.extend ClassMethods
      end

      module ClassMethods
          attr_accessor :client
          def client
            @client ||= Parse::Client.client #defaults to :default tag
          end
      end

      def client
        self.class.client
      end

    end #Connectable
  end

  # Helper method that users should call to setup the client stack.
  # A block can be passed in order to do additional client configuration.
  def self.setup(opts = {})
    if block_given?
      Parse::Client.new(opts, &Proc.new)
    else
      Parse::Client.new(opts)
    end
  end

  # Helper method to call cloud functions and get results
  def self.trigger_job(name, body = {}, **opts)
    conn = opts[:session] || opts[:client] ||  :default
    response = Parse::Client.client(conn).trigger_job(name, body)
    return response if opts[:raw].present?
    response.error? ? nil : response.result["result"]
  end

  # Helper method to call cloud functions and get results
  def self.call_function(name, body = {}, **opts)
    conn = opts[:session] || opts[:client] ||  :default
    response = Parse::Client.client(conn).call_function(name, body)
    return response if opts[:raw].present?
    response.error? ? nil : response.result["result"]
  end

end
