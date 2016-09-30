# encoding: UTF-8
# frozen_string_literal: true

# The User class provided by Parse with the required fields. You may
# add mixings to this class to add the app specific properties
require_relative '../object'
module Parse

  class UsernameMissingError < StandardError; end; # 200
  class PasswordMissingError < StandardError; end; # 201
  class UsernameTakenError < StandardError; end; # 202
  class EmailTakenError < StandardError; end; # 203
  class EmailMissing < StandardError; end; # 204

  class User < Parse::Object

    parse_class Parse::Model::CLASS_USER
    attr_accessor :session_token
    property :auth_data, :object
    property :email
    property :password
    property :username

    before_save do
      # You cannot specify user ACLs.
      self.clear_attribute_change!(:acl)
    end

    def anonymous?
      anonymous_id.nil?
    end

    def anonymous_id
      auth_data['anonymous']['id'] if auth_data.present? && auth_data["anonymous"].is_a?(Hash)
    end

    def link_auth_data!(service_name, **data)
      response = client.set_service_auth_data(id, service_name, data)
      apply_attributes!(response.result) if response.success?
      response
    end

    def unlink_auth_data!(service_name)
      response = client.set_service_auth_data(id, service_name, nil)
      apply_attributes!(response.result) if response.success?
      response
    end

    # So that apply_attributes! works with session_token for login
    def session_token_set_attribute!(token, track = false)
      @session_token = token.to_s
    end
    alias_method :sessionToken_set_attribute!, :session_token_set_attribute!

    def logged_in?
      self.session_token.present?
    end

    def request_password_reset
      return false if email.nil?
      Parse::User.request_password_reset(email)
    end

    def signup!(passwd = nil)
      self.password = passwd || password
      if username.blank?
        raise Parse::UsernameMissingError, "Signup requires an username."
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
      end
      raise response
    end

    def login!(passwd = nil)
      self.password = passwd || self.password
      response = client.login(username.to_s, password.to_s)
      apply_attributes! response.result
      self.session_token.present?
    end

    def logout
      return true if self.session_token.blank?
      client.logout session_token
      self.session_token = nil
      true
    rescue => e
      false
    end

    def session_token=(token)
      @session = nil
      @session_token = token
    end

    def session
      if @session.blank? && @session_token.present?
        response = client.fetch_session(@session_token)
        @session ||= Parse::Session.new(response.result)
      end
      @session
    end

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
      raise response
    end

    # method will signup or login a user given the third-party authentication data
    def self.autologin_service(service_name, auth_data, body: {})
      body = body.merge({authData: {service_name => auth_data} })
      self.create(body)
    end

    def self.signup(username, password, email = nil, body: {})
      body = body.merge({username: username, password: password })
      body[:email] = email if email.present?
      self.create(body)
    end

    def self.login(username, password)
      response = client.login(username.to_s, password.to_s)
      response.success? ? Parse::User.build(response.result) : nil
    end

    def self.request_password_reset(email)
      email = email.email if email.is_a?(Parse::User)
      return false if email.blank?
      response = client.reset_password(email)
      response.success?
    end

    def self.session(token)
      self.session! token
    rescue InvalidSessionTokenError => e
      nil
    end

    def self.session!(token)
      # support Parse::Session objects
      token = token.session_token if token.respond_to?(:session_token)
      response = client.current_user(token)
      response.success? ? Parse::User.build(response.result) : nil
    end

  end

end
