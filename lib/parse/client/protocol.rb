# encoding: UTF-8
# frozen_string_literal: true

# A module to contain all the main constants.
module Parse

  module Protocol
      HOST          = 'api.parse.com'
      SERVER_URL    = 'https://api.parse.com/1/'
      APP_ID        = 'X-Parse-Application-Id'
      API_KEY       = 'X-Parse-REST-API-Key'
      MASTER_KEY    = 'X-Parse-Master-Key'
      SESSION_TOKEN = 'X-Parse-Session-Token'
      REVOCABLE_SESSION = 'X-Parse-Revocable-Session'
      INSTALLATION_ID = 'Parse-Installation-Id'
      CONTENT_TYPE = 'Content-Type'
      CONTENT_TYPE_FORMAT = 'application/json; charset=utf-8'
  end

end
