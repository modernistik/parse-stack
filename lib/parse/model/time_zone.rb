# encoding: UTF-8
# frozen_string_literal: true

require 'active_support'
require 'active_support/values/time_zone'
require_relative "model"

module Parse
  # This class a wrapper around ActiveSupport::TimeZone when using Parse columns that
  # store IANA time zone identifiers (ex. Installation collection). Parse does not have a
  # native time zone data type, but this class is provided to manage and perform timezone-like
  # operation on those properties which you have marked as type _:timezone_.
  #
  # When declaring a property of type :timezone, you may also define a default just like
  # any other property. In addition, the framework will automatically add a validation
  # to make sure that your property is either nil or one of the valid IANA time zone identifiers.
  #
  # Each instance of {Parse::TimeZone} has a {Parse::TimeZone#zone} attribute that provides access to
  # the underlying {http://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html ActiveSupport::TimeZone}
  # instance, which you can use to perform time zone operations.
  # @example
  #  class Event < Parse::Object
  #    # an event occurs in a time zone.
  #    property :time_zone, :timezone, default: 'America/Los_Angeles'
  #  end
  #
  #  event = Event.new
  #  event.time_zone.name # => 'America/Los_Angeles'
  #  event.time_zone.valid? # => true
  #
  #  event.time_zone.zone # => ActiveSupport::TimeZone
  #  event.time_zone.formatted_offset # => "-08:00"
  #
  #  event.time_zone = 'Europe/Paris'
  #  event.time_zone.formatted_offset # => +01:00"
  #
  #  event.time_zone = 'Galaxy/Andromeda'
  #  event.time_zone.valid? # => false
  #
  class TimeZone
    # The mapping of TimeZones
    MAPPING = ActiveSupport::TimeZone::MAPPING

    # Create methods based on the allowable public methods on ActiveSupport::TimeZone.
    # Basically sets up sending forwarding calls to the `zone` object for a Parse::TimeZone object.
    (ActiveSupport::TimeZone.public_instance_methods(false) - [:to_s, :name, :as_json]).each do |meth|
      Parse::TimeZone.class_eval do
        define_method meth do |*args|
          zone.send meth, *args
        end
      end
    end

    # Creates a new instance given the IANA identifier (ex. America/Los_Angeles)
    # @overload initialize(iana)
    #  @param iana [String] the IANA identifier (ex. America/Los_Angeles)
    #  @return [Parse::TimeZone]
    # @overload initialize(timezone)
    #  You can instantiate a new instance with either a {Parse::TimeZone} or an {http://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html ActiveSupport::TimeZone}
    #  object.
    #  @param timezone [Parse::TimeZone|ActiveSupport::TimeZone] an instance of either timezone class.
    #  @return [Parse::TimeZone]
    def initialize(iana)
      if iana.is_a?(String)
        @name = iana
        @zone = nil
      elsif iana.is_a?(::Parse::TimeZone)
        @zone = iana.zone
        @name = nil
      elsif iana.is_a?(::ActiveSupport::TimeZone)
        @zone = iana
        @name = nil
      end
    end

    # @!attribute [rw] name
    # @raise ArgumentError if value is not a string type.
    # @return [String] the IANA identifier for this time zone.
    def name
      @zone.present? ? zone.name : @name
    end

    def name=(timezone_name)
      unless timezone_name.nil? || timezone_name.is_a?(String)
        raise ArgumentError, "Parse::TimeZone#name should be an IANA time zone identifier."
      end
      @name = timezone_name
      @zone = nil
    end

    # @!attribute [rw] zone
    # Returns an instance of {http://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html ActiveSupport::TimeZone}
    # based on the IANA identifier. The setter may allow usign an IANA string identifier,
    # a {Parse::TimeZone} or an
    # {http://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html ActiveSupport::TimeZone}
    # object.
    # @see #name
    # @raise ArgumentError
    # @return [ActiveSupport::TimeZone]
    def zone
      # lazy load the TimeZone object only when the user requests it, otherwise
      # just keep the name of the string around. Makes encoding/decoding faster.
      if @zone.nil? && @name.present?
        @zone = ::ActiveSupport::TimeZone.new(@name)
        @name = nil # clear out the cache
      end
      @zone
    end

    def zone=(timezone)
      if timezone.is_a?(::ActiveSupport::TimeZone)
        @zone = timezone
        @name = nil
      elsif timezone.is_a?(Parse::TimeZone)
        @name = timezone.name
        @zone = nil
      elsif timezone_name.nil? || timezone_name.is_a?(String)
        @name = timezone
        @zone = nil
      else
        raise ArgumentError, 'Invalid value passed to Parse::TimeZone#zone.'
      end
    end

    # (see #to_s)
    def as_json(*args)
      name
    end

    # @return [String] the IANA identifier for this timezone or nil.
    def to_s
      name
    end

    # Returns true or false whether the time zone exists in the {http://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html ActiveSupport::TimeZone} mapping.
    # @return [Bool] true if it contains a valid time zone
    def valid?
      ActiveSupport::TimeZone[to_s].present?
    end

  end

end
