# encoding: UTF-8
# frozen_string_literal: true

require_relative "../query.rb"
require_relative "../client.rb"


module Parse
  # This class represents the API to send push notification to devices that are
  # available in the Installation table. Push notifications are implemented
  # through the `Parse::Push` class. To send push notifications through the
  # REST API, you must enable `REST push enabled?` option in the `Push
  # Notification Settings` section of the `Settings` page in your Parse
  # application. Push notifications targeting uses the Installation Parse
  # class to determine which devices receive the notification. You can provide
  # any query constraint, similar to using `Parse::Query`, in order to target
  # the specific set of devices you want given the columns you have configured
  # in your `Installation` class. The `Parse::Push` class supports many other
  # options not listed here.
  # @example
  #
  #   push = Parse::Push.new
  #   push.send( "Hello World!") # to everyone
  #
  #   # simple channel push
  #   push = Parse::Push.new
  #   push.channels = ["addicted2salsa"]
  #   push.send "You are subscribed to Addicted2Salsa!"
  #
  #   # advanced targeting
  #   push = Parse::Push.new( {..where query constraints..} )
  #   # or use `where()`
  #   push.where :device_type.in => ['ios','android'], :location.near => some_geopoint
  #   push.alert = "Hello World!"
  #   push.sound = "soundfile.caf"
  #
  #   # additional payload data
  #   push.data = { uri: "app://deep_link_path" }
  #
  #   # Send the push
  #   push.send
  #
  #
  class Push
    include Client::Connectable

    # @!attribute [rw] query
    # Sending a push notification is done by performing a query against the Installation
    # collection with a Parse::Query. This query contains the constraints that will be
    # sent to Parse with the push payload.
    #   @return [Parse::Query] the query containing Installation constraints.

    # @!attribute [rw] alert
    #   @return [String]
    # @!attribute [rw] badge
    #   @return [Integer]
    # @!attribute [rw] sound
    #   @return [String] the name of the sound file
    # @!attribute [rw] title
    #   @return [String]
    # @!attribute [rw] data
    #   @return [Hash] specific payload data.
    # @!attribute [rw] expiration_time
    #   @return [Parse::Date]
    # @!attribute [rw] expiration_interval
    #   @return [Integer]
    # @!attribute [rw] push_time
    #   @return [Parse::Date]
    # @!attribute [rw] channels
    #   @return [Array] an array of strings for subscribed channels.
    attr_accessor :query, :alert, :badge, :sound, :title, :data,
                  :expiration_time, :expiration_interval, :push_time, :channels

    alias_method :message, :alert
    alias_method :message=, :alert=

    # Send a push notification using a push notification hash
    # @param payload [Hash] a push notification hash payload
    def self.send(payload)
      client.push payload.as_json
    end

    # Initialize a new push notification request.
    # @param constraints [Hash] a set of query constraints
    def initialize(constraints = {})
      self.where constraints
    end

    def query
      @query ||= Parse::Query.new(Parse::Model::CLASS_INSTALLATION)
    end

    # Set a hash of conditions for this push query.
    # @return [Parse::Query]
    def where=(where_clausees)
      query.where where_clauses
    end

    # Apply a set of constraints.
    # @param constraints [Hash] the set of {Parse::Query} cosntraints
    # @return [Hash] if no constraints were passed, returns a compiled query.
    # @return [Parse::Query] if constraints were passed, returns the chainable query.
    def where(constraints = nil)
      return query.compile_where unless constraints.is_a?(Hash)
      query.where constraints
      query
    end

    def channels=(list)
      @channels = Array.wrap(list)
    end

    def data=(h)
      if h.is_a?(String)
        @alert = h
      else
        @data = h.symbolize_keys
      end
    end

    # @return [Hash] a JSON encoded hash.
    def as_json(*args)
      payload.as_json
    end

    # @return [String] a JSON encoded string.
    def to_json(*args)
      as_json.to_json
    end

    # This method takes all the parameters of the instance and creates a proper
    # hash structure, required by Parse, in order to process the push notification.
    # @return [Hash] the prepared push payload to be used in the request.
    def payload
      msg = {
        data: {
          alert: alert,
          badge: badge || "Increment",
        },
      }
      msg[:data][:sound] = sound if sound.present?
      msg[:data][:title] = title if title.present?
      msg[:data].merge! @data if @data.is_a?(Hash)

      if @expiration_time.present?
        msg[:expiration_time] = @expiration_time.respond_to?(:iso8601) ? @expiration_time.iso8601(3) : @expiration_time
      end
      if @push_time.present?
        msg[:push_time] = @push_time.respond_to?(:iso8601) ? @push_time.iso8601(3) : @push_time
      end

      if @expiration_interval.is_a?(Numeric)
        msg[:expiration_interval] = @expiration_interval.to_i
      end

      if query.where.present?
        q = @query.dup
        if @channels.is_a?(Array) && @channels.empty? == false
          q.where :channels.in => @channels
        end
        msg[:where] = q.compile_where unless q.where.empty?
      elsif @channels.is_a?(Array) && @channels.empty? == false
        msg[:channels] = @channels
      end
      msg
    end

    # helper method to send a message
    # @param message [String] the message to send
    def send(message = nil)
      @alert = message if message.is_a?(String)
      @data = message if message.is_a?(Hash)
      client.push(payload.as_json)
    end
  end
end
