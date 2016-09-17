# encoding: UTF-8
# frozen_string_literal: true

module Parse

  module API
    module Sessions
      SESSION_PATH_PREFIX = "sessions"

      def fetch_session(session_token, **opts)
        opts.merge!({use_master_key: false, cache: false})
        headers = {Parse::Protocol::SESSION_TOKEN => session_token}
        response = request :get, "#{SESSION_PATH_PREFIX}/me", headers: headers, opts: opts
        response.parse_class = Parse::Model::CLASS_SESSION
        response
      end

    end
  end

end
