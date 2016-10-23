# encoding: UTF-8
# frozen_string_literal: true

require_relative '../object'
module Parse
  # 200	Error code indicating that the username is missing or empty.
  class UsernameMissingError < StandardError; end;
  # 201	Error code indicating that the password is missing or empty.
  class PasswordMissingError < StandardError; end;
  # Error code 202: indicating that the username has already been taken.
  class UsernameTakenError < StandardError; end;
  # 203	Error code indicating that the email has already been taken.
  class EmailTakenError < StandardError; end;
  # 204	Error code indicating that the email is missing, but must be specified.
  class EmailMissing < StandardError; end;
  # 205	Error code indicating that a user with the specified email was not found.
  class EmailNotFound < StandardError; end;
  # 125	Error code indicating that the email address was invalid.
  class InvalidEmailAddress < StandardError; end;

  # The main class representing the _User table in Parse. A user can either be signed up or anonymous.
  # All users need to have a username and a password, with email being optional but globally unique if set.
  # You may add additional properties by redeclaring the class to match your specific schema.
  class User < Parse::Object

    parse_class Parse::Model::CLASS_USER
    # @return [String] The session token if this user is logged in.
    attr_accessor :session_token

    # The auth data for this Parse::User. Depending on how this user is authenticated or
    # logged in, the contents may be different, especially if you are using another third-party
    # authentication mechanism like Facebook/Twitter.
    # @return [Hash] Auth data hash object.
    property :auth_data, :object

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

    # All Parse users have a username and must be globally unique.
    # @return [String] The user's username.
    property :username

    before_save do
      # You cannot specify user ACLs.
      self.clear_attribute_change!(:acl)
    end

    # True if this user is anonymous.
    def anonymous?
      anonymous_id.nil?
    end

    # Returns the anonymous identifier only if this user is anonymous.
    # @see #anonymous?
    # @return [String] The anonymous identifier for this anonymous user.
    def anonymous_id
      auth_data['anonymous']['id'] if auth_data.present? && auth_data["anonymous"].is_a?(Hash)
    end

    # Adds the third-party authentication data to for a given service.
    # @param service_name [Symbol] The name of the service (ex. :facebook)
    # @param data [Hash] The body of the OAuth data. Dependent on each service.
    # @raise [ResponseError] If user was not successfully linked
    def link_auth_data!(service_name, **data)
      response = client.set_service_auth_data(id, service_name, data)
      raise Parse::ResponseError, response if response.error?
      apply_attributes!(response.result)
    end

    # Removes third-party authentication data for this user
    # @param service_name [Symbol] The name of the third-party service (ex. :facebook)
    # @raise [ResponseError] If user was not successfully unlinked
    # @return [Boolean] True/false if successful.
    def unlink_auth_data!(service_name)
      response = client.set_service_auth_data(id, service_name, nil)
      raise Parse::ResponseError, response if response.error?
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
    def request_password_reset
      return false if email.nil?
      Parse::User.request_password_reset(email)
    end

    # You may set a password for this user when you are creating them. Parse never returns a
    # @param passwd The user's password to be used for signing up.
    # @raise [Parse::UsernameMissingError] If username is missing.
    # @raise [Parse::PasswordMissingError] If password is missing.
    # @raise [Parse::UsernameTakenError] If the username has already been taken.
    # @raise [Parse::EmailTakenError] If the email has already been taken (or exists in the system).
    # @raise [Parse::InvalidEmailAddress] If the email is invalid.
    # @raise [Parse::ResponseError] An unknown error occurred.
    # @return [Boolean] True if signup it was successful. If it fails an exception is thrown.
    def signup!(passwd = nil)
      self.password = passwd || password
      if username.blank?
        raise Parse::UsernameMissingError, "Signup requires a username."
      end

      if password.blank?
        raise Parse::PasswordMissingError, "Signup requires a password."
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
        raise Parse::UsernameMissingError, response
      when Parse::Response::ERROR_PASSWORD_MISSING
        raise Parse::PasswordMissingError, response
      when Parse::Response::ERROR_USERNAME_TAKEN
        raise Parse::UsernameTakenError, response
      when Parse::Response::ERROR_EMAIL_TAKEN
        raise Parse::EmailTakenError, response
      when Parse::Response::ERROR_EMAIL_INVALID
        raise Parse::InvalidEmailAddress, response
      end
      raise Parse::ResponseError, response
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
    # @raise [UsernameMissingError] If username is missing.
    # @raise [PasswordMissingError] If password is missing.
    # @raise [UsernameTakenError] If the username has already been taken.
    # @raise [EmailTakenError] If the email has already been taken (or exists in the system).
    # @raise [InvalidEmailAddress] If the email is invalid.
    # @raise [ResponseError] An unknown error occurred.
    # @return [User] Returns a successfully created Parse::User.
    def self.create(body, **opts)
      response = client.create_user(body, opts: opts)
      if response.success?
        return Parse::User.build response.result
      end

      case response.code
      when Parse::Response::ERROR_USERNAME_MISSING
        raise Parse::UsernameMissingError, response
      when Parse::Response::ERROR_PASSWORD_MISSING
        raise Parse::PasswordMissingError, response
      when Parse::Response::ERROR_USERNAME_TAKEN
        raise Parse::UsernameTakenError, response
      when Parse::Response::ERROR_EMAIL_TAKEN
        raise Parse::EmailTakenError, response
      end
      raise  Parse::ResponseError, response
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
      body = body.merge({authData: {service_name => auth_data} })
      self.create(body)
    end

    # This method will signup a new user using the parameters below. The required fields
    # to create a user in Parse is the _username_ and _password_ fields. The _email_ field is optional.
    # Both _username_ and _email_ (if provided), must be unique. At a minimum, it is recommended you perform
    # a query using the supplied _username_ first to verify do not already have an account with that username.
    # This method will raise all the exceptions from the similar `create` method.
    # @see User.create
    def self.signup(username, password, email = nil, body: {})
      body = body.merge({username: username, password: password })
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
    rescue InvalidSessionTokenError => e
      nil
    end

    # Return a Parse::User for this active session token.
    # @raise [InvalidSessionTokenError] Invalid session token.
    # @return [User] the user matching this active token
    # @see #session
    def self.session!(token, opts = {})
      # support Parse::Session objects
      token = token.session_token if token.respond_to?(:session_token)
      response = client.current_user(token, opts)
      response.success? ? Parse::User.build(response.result) : nil
    end

  end

end
