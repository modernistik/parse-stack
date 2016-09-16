# encoding: UTF-8
# frozen_string_literal: true

# The User class provided by Parse with the required fields. You may
# add mixings to this class to add the app specific properties
require_relative 'object'
module Parse

  class User < Parse::Object
    parse_class "_User"
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

    def self.session(token)

    end

    def login!(password)
      response = client.login(username,password)
      apply_attributes! response.result
    end

    def session=(token)
      @current_session = nil
      @session_token = token
    end

    def current_session
      if @session_token.present?
        @current_session ||= client.fetch_session(@session_token)
      end
    end

  end

  class Installation < Parse::Object
    parse_class "_Installation"

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
    parse_class "_Role"
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
    parse_class "_Session"
    property :created_with, :object
    property :expires_at, :date
    property :installation_id
    property :restricted, :boolean
    property :session_token

    belongs_to :user
  end

end
