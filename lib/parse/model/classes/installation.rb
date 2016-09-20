# encoding: UTF-8
# frozen_string_literal: true
require_relative '../object'

module Parse

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

end
