# encoding: UTF-8
# frozen_string_literal: true

module Parse

  module API
    module Sessions
      SESSION_PATH_PREFIX = "sessions"

      def fetch_session(session_token)
        headers = {Parse::Protocol::SESSION_TOKEN => session_token}
        request :get, "#{SESSION_PATH_PREFIX}/me", headers: headers
      end

    end
  end

end
