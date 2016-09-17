# encoding: UTF-8
# frozen_string_literal: true

# The User class provided by Parse with the required fields. You may
# add mixings to this class to add the app specific properties
require_relative 'object'
module Parse

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
      auth_data.present? && auth_data["anonymous"].present?
    end

    # So that apply_attributes! works with session_token for login
    def session_token_set_attribute!(token, track = false)
      @session_token = token.to_s
    end
    alias_method :sessionToken_set_attribute!, :session_token_set_attribute!

    def logged_in?
      self.session_token.present?
    end

    def login!(password)
      response = client.login(username.to_s, password.to_s)
      apply_attributes! response.result
      self.session_token.present?
    end

    def logout
      return true if self.session_token.blank?
      client.logout(session_token)
    rescue Exception => e
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

    def self.login(username,password)
      response = client.login(username.to_s, password.to_s)
      Parse::User.build response.result
    end

    def self.current_user(session_token)
      response = client.current_user(session_token)
      Parse::User.build response.result
    end

  end

  class Installation < Parse::Object
    parse_class Parse::Model::CLASS_INSTALLATION

    property :gcm_sender_id, :string, field: :GCMSenderId
    property :app_identifier
    property :app_name
    property :app_version
    property :badge, :integer
    property :channels, :array
    property :device_token
    property :device_token_last_modified, :integer
    property :device_type
    property :installation_id
    property :locale_identifier
    property :parse_version
    property :push_type
    property :time_zone

  end

  class Role < Parse::Object
    parse_class Parse::Model::CLASS_ROLE
    property :name

    has_many :roles, through: :relation
    has_many :users, through: :relation

    def update_acl
      acl.everyone true, false
    end

    before_save do
      update_acl
    end

  end

  class Session < Parse::Object
    parse_class Parse::Model::CLASS_SESSION
    property :created_with, :object
    property :expires_at, :date
    property :installation_id
    property :restricted, :boolean
    property :session_token

    belongs_to :user
  end

end
