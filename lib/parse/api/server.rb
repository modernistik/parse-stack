# encoding: UTF-8
# frozen_string_literal: true

module Parse

  module API
    # APIs related to the open source Parse Server.
    module Server

      # @!attribute server_info
      #  @return [Hash] the information about the server.
      attr_accessor :server_info

      # @!visibility private
      SERVER_INFO_PATH = 'serverInfo'
      # @!visibility private
      SERVER_HEALTH_PATH = 'health'
      # Fetch and cache information about the Parse server configuration. This
      # hash contains information specifically to the configuration of the running
      # parse server.
      # @return (see #server_info!)
      def server_info
        return @server_info if @server_info.present?
        response = request :get, SERVER_INFO_PATH
        @server_info = response.error? ? nil :
                       response.result.with_indifferent_access
      end

      # Fetches the status of the server based on the health check.
      # @return [Boolean] whether the server is 'OK'.
      def server_health
        opts = {cache: false}
        response = request :get, SERVER_HEALTH_PATH, opts: opts
        response.success?
      end

      # Force fetches the server information.
      # @return [Hash] a hash containing server configuration if available.
      def server_info!
        @server_info = nil
        server_info
      end

      # Returns the version of the Parse server the client is connected to.
      # @return [String] a version string (ex. '2.2.25') if available.
      def server_version
        server_info.present? ? @server_info[:parseServerVersion] : nil
      end

    end
  end

end
