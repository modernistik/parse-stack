# encoding: UTF-8
# frozen_string_literal: true
require_relative '../object'

module Parse
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
