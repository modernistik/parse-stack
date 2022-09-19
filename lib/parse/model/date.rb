# encoding: UTF-8
# frozen_string_literal: true

require "time"
require "date"
require "active_model"
require "active_support"
require "active_support/inflector"
require "active_support/core_ext/object"
require "active_support/core_ext/date/calculations"
require "active_support/core_ext/date_time/calculations"
require "active_support/core_ext/time/calculations"

require_relative "model"

module Parse
  # This class manages dates in the special JSON format it requires for
  # properties of type _:date_.
  class Date < ::DateTime
    # The default attributes in a Parse Date hash.
    ATTRIBUTES = { __type: :string, iso: :string }.freeze
    include ::ActiveModel::Model
    include ::ActiveModel::Serializers::JSON

    # @return [Parse::Model::TYPE_DATE]
    def self.parse_class; Parse::Model::TYPE_DATE; end
    # @return [Parse::Model::TYPE_DATE]
    def parse_class; self.class.parse_class; end

    alias_method :__type, :parse_class

    # @return [Hash]
    def attributes
      ATTRIBUTES
    end

    # @return [String] the ISO8601 time string including milliseconds
    def iso
      to_time.utc.iso8601(3)
    end

    # @return (see #iso)
    def to_s(*args)
      args.empty? ? iso : super(*args)
    end
  end
end

# Adds extensions to Time class to be compatible with {Parse::Date}.
class Time
  # @return [Parse::Date] Converts object to Parse::Date
  def parse_date
    Parse::Date.parse iso8601(3)
  end
end

# Adds extensions to DateTime class to be compatible with {Parse::Date}.
class DateTime
  # @return [Parse::Date] Converts object to Parse::Date
  def parse_date
    Parse::Date.parse iso8601(3)
  end
end

# Adds extensions to ActiveSupport class to be compatible with {Parse::Date}.
module ActiveSupport
  # Adds extensions to ActiveSupport::TimeWithZone class to be compatible with {Parse::Date}.
  class TimeWithZone
    # @return [Parse::Date] Converts object to Parse::Date
    def parse_date
      Parse::Date.parse iso8601(3)
    end
  end
end

# Adds extensions to Date class to be compatible with {Parse::Date}.
class Date
  # @return [Parse::Date] Converts object to Parse::Date
  def parse_date
    Parse::Date.parse iso8601
  end
end
