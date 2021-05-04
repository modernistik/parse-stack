# encoding: UTF-8
# frozen_string_literal: true

require_relative "../object"

module Parse
  class Error
    # 200	Error code indicating that the username is missing or empty.
    class UsernameMissingError < Error; end

    # 201	Error code indicating that the password is missing or empty.
    class PasswordMissingError < Error; end

    # Error code 202: indicating that the username has already been taken.
    class UsernameTakenError < Error; end

    # 203	Error code indicating that the email has already been taken.
    class EmailTakenError < Error; end

    # 204	Error code indicating that the email is missing, but must be specified.
    class EmailMissing < Error; end

    # 205	Error code indicating that a user with the specified email was not found.
    class EmailNotFound < Error; end

    # 125	Error code indicating that the email address was invalid.
    class InvalidEmailAddress < Error; end
  end

  # The main class representing the _User table in Parse. A user can either be signed up or anonymous.
  # All users need to have a username and a password, with email being optional but globally unique if set.
  # You may add additional properties by redeclaring the class to match your specific schema.
  #
  # The default schema for the {User} class is as follows:
  #
  #   class Parse::User < Parse::Object
  #      # See Parse::Object for inherited properties...
  #
  #      property :auth_data, :object
  #      property :username
  #      property :password
  #      property :email
  #
  #      has_many :active_sessions, as: :session
  #   end
  #
  # *Signup*
  #
  # You can signup new users in two ways. You can either use a class method
  # {Parse::User.signup} to create a new user with the minimum fields of username,
  # password and email, or create a {Parse::User} object can call the {#signup!}
  # method. If signup fails, it will raise the corresponding exception.
  #
  #  user = Parse::User.signup(username, password, email)
  #
  #  #or
  #  user = Parse::User.new username: "user", password: "s3cret"
  #  user.signup!
  #
  # *Login/Logout*
  #
  # With the {Parse::User} class, you can also perform login and logout
  # functionality. The class special accessors for {#session_token} and {#session}
  # to manage its authentication state. This will allow you to authenticate
  # users as well as perform Parse queries as a specific user using their session
  # token. To login a user, use the {Parse::User.login} method by supplying the
  # corresponding username and password, or if you already have a user record,
  # use {#login!} with the proper password.
  #
  #  user = Parse::User.login(username,password)
  #  user.session_token # session token from a Parse::Session
  #  user.session # Parse::Session tied to the token
  #
  #  # You can login user records
  #  user = Parse::User.first
  #  user.session_token # nil
  #
  #  passwd = 'p_n7!-e8' # corresponding password
  #  user.login!(passwd) # true
  #
  #  user.session_token # 'r:pnktnjyb996sj4p156gjtp4im'
  #
  #  # logout to delete the session
  #  user.logout
  #
  # If you happen to already have a valid session token, you can use it to
  # retrieve the corresponding Parse::User.
  #
  #  # finds user with session token
  #  user = Parse::User.session(session_token)
  #
  #  user.logout # deletes the corresponding session
  #
  # *OAuth-Login*
  #
  # You can signup users using third-party services like Facebook and Twitter as
  # described in {http://docs.parseplatform.org/rest/guide/#signing-up
  # Signing Up and Logging In}. To do this with Parse-Stack, you can call the
  # {Parse::User.autologin_service} method by passing the service name and the
  # corresponding authentication hash data. For a listing of supported third-party
  # authentication services, see {http://docs.parseplatform.org/parse-server/guide/#oauth-and-3rd-party-authentication OAuth}.
  #
  #  fb_auth = {}
  #  fb_auth[:id] = "123456789"
  #  fb_auth[:access_token] = "SaMpLeAAiZBLR995wxBvSGNoTrEaL"
  #  fb_auth[:expiration_date] = "2025-02-21T23:49:36.353Z"
  #
  #  # signup or login a user with this auth data.
  #  user = Parse::User.autologin_service(:facebook, fb_auth)
  #
  # You may also combine both approaches of signing up a new user with a
  # third-party service and set additional custom fields. For this, use the
  # method {Parse::User.create}.
  #
  #  # or to signup a user with additional data, but linked to Facebook
  #  data = {
  #    username: "johnsmith",
  #    name: "John",
  #    email: "user@example.com",
  #    authData: { facebook: fb_auth }
  #  }
  #  user = Parse::User.create data
  #
  # *Linking/Unlinking*
  #
  # You can link or unlink user accounts with third-party services like
  # Facebook and Twitter as described in:
  # {http://docs.parseplatform.org/rest/guide/#linking-users Linking and Unlinking Users}.
  # To do this, you must first get the corresponding authentication data for the
  # specific service, and then apply it to the user using the linking and
  # unlinking methods. Each method returns true or false if the action was
  # successful. For a listing of supported third-party authentication services,
  # see {http://docs.parseplatform.org/parse-server/guide/#oauth-and-3rd-party-authentication OAuth}.
  #
  #  user = Parse::User.first
  #
  #  fb_auth = { ... } # Facebook auth data
  #
  #  # Link this user's Facebook account with Parse
  #  user.link_auth_data! :facebook, fb_auth
  #
  #  # Unlinks this user's Facebook account from Parse
  #  user.unlink_auth_data! :facebook
  #
  # @see Parse::Object
  class User < Parse::Object
    parse_class Parse::Model::CLASS_USER
    # @return [String] The session token if this user is logged in.
    attr_accessor :session_token

    # @!attribute auth_data
    # The auth data for this Parse::User. Depending on how this user is authenticated or
    # logged in, the contents may be different, especially if you are using another third-party
    # authentication mechanism like Facebook/Twitter.
    # @return [Hash] Auth data hash object.
    property :auth_data, :object

    # @!attribute email
    # Emails are optional in Parse, but if set, they must be unique.
    # @return [String] The email field.
    property :email

    # @overload password=(value)
    # You may set a password for this user when you are creating them. Parse never returns a
    # Parse::User's password when a record is fetched. Therefore, normally this getter is nil.
    # While this API exists, it is recommended you use either the #login! or #signup! methods.
    # (see #login!)
    # @return [String] The password you set.
    property :password

    # @!attribute username
    # All Parse users have a username and must be globally unique.
    # @return [String] The user's username.
    property :username

    # @!attribute active_sessions
    # A has_many relationship to all {Parse::Session} instances for this user. This
    # will query the _Session collection for all sessions which have this user in it's `user`
    # column.
    # @version 1.7.1
    # @return [Array<Parse::Session>] A list of active Parse::Session objects.
    has_many :active_sessions, as: :session

    before_save do
      # You cannot specify user ACLs.
      self.clear_attribute_change!([:acl])
    end

    # @return [Boolean] true if this user is anonymous.
    def anonymous?
      anonymous_id.nil?
    end

    # Returns the anonymous identifier only if this user is anonymous.
    # @see #anonymous?
    # @return [String] The anonymous identifier for this anonymous user.
    def anonymous_id
      auth_data["anonymous"]["id"] if auth_data.present? && auth_data["anonymous"].is_a?(Hash)
    end

    # Adds the third-party authentication data to for a given service.
    # @param service_name [Symbol] The name of the service (ex. :facebook)
    # @param data [Hash] The body of the OAuth data. Dependent on each service.
    # @raise [Parse::Client::ResponseError] If user was not successfully linked
    def link_auth_data!(service_name, **data)
      response = client.set_service_auth_data(id, service_name, data)
      raise Parse::Client::ResponseError, response if response.error?
      apply_attributes!(response.result)
    end

    # Removes third-party authentication data for this user
    # @param service_name [Symbol] The name of the third-party service (ex. :facebook)
    # @raise [Parse::Client::ResponseError] If user was not successfully unlinked
    # @return [Boolean] True/false if successful.
    def unlink_auth_data!(service_name)
      response = client.set_service_auth_data(id, service_name, nil)
      raise Parse::Client::ResponseError, response if response.error?
      apply_attributes!(response.result)
    end

    # @!visibility private
    # So that apply_attributes! works with session_token for login
    def session_token_set_attribute!(token, track = false)
      @session_token = token.to_s
    end

    alias_method :sessionToken_set_attribute!, :session_token_set_attribute!

    # @return [Boolean] true if this user has a session token.
    def logged_in?
      self.session_token.present?
    end

    # Request a password reset for this user
    # @return [Boolean] true if it was successful requested. false otherwise.
    # @see Parse::User.request_password_reset
    def request_password_reset
      return false if email.nil?
      Parse::User.request_password_reset(email)
    end

    # You may set a password for this user when you are creating them. Parse never returns a
    # @param passwd The user's password to be used for signing up.
    # @raise [Parse::Error::UsernameMissingError] If username is missing.
    # @raise [Parse::Error::PasswordMissingError] If password is missing.
    # @raise [Parse::Error::UsernameTakenError] If the username has already been taken.
    # @raise [Parse::Error::EmailTakenError] If the email has already been taken (or exists in the system).
    # @raise [Parse::Error::InvalidEmailAddress] If the email is invalid.
    # @raise [Parse::Client::ResponseError] An unknown error occurred.
    # @return [Boolean] True if signup it was successful. If it fails an exception is thrown.
    def signup!(passwd = nil)
      self.password = passwd || password
      if username.blank?
        raise Parse::Error::UsernameMissingError, "Signup requires a username."
      end

      if password.blank?
        raise Parse::Error::PasswordMissingError, "Signup requires a password."
      end

      signup_attrs = attribute_updates
      signup_attrs.except! *Parse::Properties::BASE_FIELD_MAP.flatten

      # first signup the user, then save any additional attributes
      response = client.create_user signup_attrs

      if response.success?
        apply_attributes! response.result
        return true
      end

      case response.code
      when Parse::Response::ERROR_USERNAME_MISSING
        raise Parse::Error::UsernameMissingError, response
      when Parse::Response::ERROR_PASSWORD_MISSING
        raise Parse::Error::PasswordMissingError, response
      when Parse::Response::ERROR_USERNAME_TAKEN
        raise Parse::Error::UsernameTakenError, response
      when Parse::Response::ERROR_EMAIL_TAKEN
        raise Parse::Error::EmailTakenError, response
      when Parse::Response::ERROR_EMAIL_INVALID
        raise Parse::Error::InvalidEmailAddress, response
      end
      raise Parse::Client::ResponseError, response
    end

    # Login and get a session token for this user.
    # @param passwd [String] The password for this user.
    # @return [Boolean] True/false if we received a valid session token.
    def login!(passwd = nil)
      self.password = passwd || self.password
      response = client.login(username.to_s, password.to_s)
      apply_attributes! response.result
      self.session_token.present?
    end

    # Invalid the current session token for this logged in user.
    # @return [Boolean] True/false if successful
    def logout
      return true if self.session_token.blank?
      client.logout session_token
      self.session_token = nil
      true
    rescue => e
      false
    end

    # @!visibility private
    def session_token=(token)
      @session = nil
      @session_token = token
    end

    # @return [Session] the session corresponding to the user's session token.
    def session
      if @session.blank? && @session_token.present?
        response = client.fetch_session(@session_token)
        @session ||= Parse::Session.new(response.result)
      end
      @session
    end

    # Creates a new Parse::User given a hash that maps to the fields defined in your Parse::User collection.
    # @param body [Hash] The hash containing the Parse::User fields. The field `username` and `password` are required.
    # @option opts [Boolean] :master_key Whether the master key should be used for this request.
    # @raise [Parse::Error::UsernameMissingError] If username is missing.
    # @raise [Parse::Error::PasswordMissingError] If password is missing.
    # @raise [Parse::Error::UsernameTakenError] If the username has already been taken.
    # @raise [Parse::Error::EmailTakenError] If the email has already been taken (or exists in the system).
    # @raise [Parse::Error::InvalidEmailAddress] If the email is invalid.
    # @raise [Parse::Client::ResponseError] An unknown error occurred.
    # @return [User] Returns a successfully created Parse::User.
    def self.create(body, **opts)
      response = client.create_user(body, opts: opts)
      if response.success?
        body.delete :password # clear password before merging
        return Parse::User.build body.merge(response.result)
      end

      case response.code
      when Parse::Response::ERROR_USERNAME_MISSING
        raise Parse::Error::UsernameMissingError, response
      when Parse::Response::ERROR_PASSWORD_MISSING
        raise Parse::Error::PasswordMissingError, response
      when Parse::Response::ERROR_USERNAME_TAKEN
        raise Parse::Error::UsernameTakenError, response
      when Parse::Response::ERROR_EMAIL_TAKEN
        raise Parse::Error::EmailTakenError, response
      end
      raise Parse::Client::ResponseError, response
    end

    # Automatically and implicitly signup a user if it did not already exists and
    # authenticates them (login) using third-party authentication data. May raise exceptions
    # similar to `create` depending on what you provide the _body_ parameter.
    # @param service_name [Symbol] the name of the service key (ex. :facebook)
    # @param auth_data [Hash] the specific service data to place in the user's auth-data for this service.
    # @param body [Hash] any additional User related fields or properties when signing up this User record.
    # @return [User] a logged in user, or nil.
    # @see User.create
    def self.autologin_service(service_name, auth_data, body: {})
      body = body.merge({ authData: { service_name => auth_data } })
      self.create(body)
    end

    # This method will signup a new user using the parameters below. The required fields
    # to create a user in Parse is the _username_ and _password_ fields. The _email_ field is optional.
    # Both _username_ and _email_ (if provided), must be unique. At a minimum, it is recommended you perform
    # a query using the supplied _username_ first to verify do not already have an account with that username.
    # This method will raise all the exceptions from the similar `create` method.
    # @see User.create
    def self.signup(username, password, email = nil, body: {})
      body = body.merge({ username: username, password: password })
      body[:email] = email if email.present?
      self.create(body)
    end

    # Login and return a Parse::User with this username/password combination.
    # @param username [String] the user's username
    # @param password [String] the user's password
    # @return [User] a logged in user for the provided username. Returns nil otherwise.
    def self.login(username, password)
      response = client.login(username.to_s, password.to_s)
      response.success? ? Parse::User.build(response.result) : nil
    end

    # Request a password reset for a registered email.
    # @example
    #  user = Parse::User.first
    #
    #  # pass a user object
    #  Parse::User.request_password_reset user
    #  # or email
    #  Parse::User.request_password_reset("user@example.com")
    # @param email [String] The user's email address.
    # @return [Boolean] True/false if successful.
    def self.request_password_reset(email)
      email = email.email if email.is_a?(Parse::User)
      return false if email.blank?
      response = client.request_password_reset(email)
      response.success?
    end

    # Same as `session!` but returns nil if a user was not found or sesion token was invalid.
    # @return [User] the user matching this active token, otherwise nil.
    # @see #session!
    def self.session(token, opts = {})
      self.session! token, opts
    rescue Parse::Error::InvalidSessionTokenError => e
      nil
    end

    # Return a Parse::User for this active session token.
    # @raise [InvalidSessionTokenError] Invalid session token.
    # @return [User] the user matching this active token
    # @see #session
    def self.session!(token, opts = {})
      # support Parse::Session objects
      token = token.session_token if token.respond_to?(:session_token)
      response = client.current_user(token, **opts)
      response.success? ? Parse::User.build(response.result) : nil
    end

    # If the current session token for this instance is nil, this method finds
    # the most recent active Parse::Session token for this user and applies it to the instance.
    # The user instance will now be authenticated and logged in with the selected session token.
    # Useful if you need to call save or destroy methods on behalf of a logged in user.
    # @return [String] The session token or nil if no session was found for this user.
    def any_session!
      unless @session_token.present?
        _active_session = active_sessions(restricted: false, order: :updated_at.desc).first
        self.session_token = _active_session.session_token if _active_session.present?
      end
      @session_token
    end
  end
end
