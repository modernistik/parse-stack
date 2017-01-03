# encoding: UTF-8
# frozen_string_literal: true

require_relative '../client'
require_relative "analytics"
require_relative "batch"
require_relative "config"
require_relative "files"
require_relative "cloud_functions"
require_relative "hooks"
require_relative "objects"
require_relative "push"
require_relative "schema"
require_relative "server"
require_relative "sessions"
require_relative "users"

module Parse
  # The module containing most of the REST API requests supported by Parse Server.
  # Defines all the Parse REST API endpoints.
  module API
  end
end
