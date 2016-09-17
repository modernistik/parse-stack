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

  # This is an exception that is thrown if there is a client connectivity issue
  class ConnectionError < Exception; end;
  class TimeoutError < Exception; end;
  class ProtocolError < Exception; end;
  class ServerError < Exception; end;
  class ServiceUnavailableError < Exception; end;
  class AuthenticationError < Exception; end;
  class RequestLimitExceededError < Exception; end;
  class InvalidSessionTokenError < Exception; end;

  # helper method to get the config variables.
  def self.config(s = :default)
    Parse::Client.session(s).config
  end

  def self.config!(s = :default)
    Parse::Client.session(s).config!
  end

  def self.client(conn = :default)
    Parse::Client.session(conn)
  end

  # Main class for the client. The client class is based on a Faraday stack.
  # The Faraday stack is similar to a Rack-style application in which you can define middlewares
  # that will be called for each request going out and coming back in. We use this in order to setup
  # some helper middlewares such as encoding to JSON, handling Parse authentication and caching.
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

    attr_accessor :session, :cache
    attr_reader :application_id, :api_key, :master_key, :server_url
    # The client can support multiple sessions. The first session created, will be placed
    # under the default session tag. The :default session will be the default client to be used
    # by the other classes including Parse::Query and Parse::Objects
    @@sessions = { default: nil }

    def self.session?(v = :default)
        @@sessions[v].present?
    end
    # get a session for a given tag. This will also create a new one for the tag if not specified.
    def self.session(connection = :default)
      #warn "Please call Parse::Client.setup() to initialize your parse session" if @@sessions.empty? || @@sessions[:default].nil?
      @@sessions[connection] ||= self.new
    end

    def self.setup(opts = {})
      # If Proc.new is called from inside a method without any arguments of
      # its own, it will return a new Proc containing the block given to
      # its surrounding method.
      # http://mudge.name/2011/01/26/passing-blocks-in-ruby-without-block.html
      @@sessions[:default] = self.new(opts, &Proc.new)
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
        raise "Please call Parse.setup(application_id:, api_key:) to setup a session"
      end
      @server_url += '/' unless @server_url.ends_with?('/')
      #Configure Faraday
      opts[:faraday] ||= {}
      opts[:faraday].merge!(:url => @server_url)
      @session = Faraday.new(opts[:faraday]) do |conn|
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
            raise "Parse::Client option :cache needs to be a type of Moneta::Transformer store."
          end
          self.cache = opts[:cache]
          conn.use Parse::Middleware::Caching, self.cache, {expires: opts[:expires].to_i }
        end

        yield(conn) if block_given?

        conn.adapter opts[:adapter]

      end
      @@sessions[:default] ||= self
      self
    end

    def app_id
      @application_id
    end

    def url_prefix
      @session.url_prefix
    end

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

      if opts[:session_token].present?
        headers[Parse::Middleware::Authentication::DISABLE_MASTER_KEY] = "true"
        headers[Parse::Protocol::SESSION_TOKEN] = opts[:session_token]
      end

      #if it is a :get request, then use query params, otherwise body.
      params = (method == :get ? query : body) || {}
      # if the path does not start with the '/1/' prefix, then add it to be nice.
      # actually send the request and return the body
      response_env = @session.send(method, uri, params, headers)
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

    # shorthand for request(:delete, uri, body: {})
    def delete(uri, body = nil, headers = {})
      request :delete, uri, body: body, headers: headers
    end

    def send_request(req) #Parse::Request object
      raise "Object not of Parse::Request type." unless req.is_a?(Parse::Request)
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
            @client ||= Parse::Client.session #defaults to :default tag
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
  def self.trigger_job(name, body, session: :default, raw: false)
    response = Parse::Client.session(session).trigger_job(name, body)
    return response if raw
    response.error? ? nil : response.result["result"]
  end

  # Helper method to call cloud functions and get results
  def self.call_function(name, body, session: :default, raw: false)
    response = Parse::Client.session(session).call_function(name, body)
    return response if raw
    response.error? ? nil : response.result["result"]
  end

end
