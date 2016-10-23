# encoding: UTF-8
# frozen_string_literal: true

require 'time'
require 'date'
require 'active_model'
require 'active_support'
require 'active_support/inflector'
require 'active_support/core_ext/object'
require 'active_support/core_ext/date/calculations'
require 'active_support/core_ext/date_time/calculations'
require 'active_support/core_ext/time/calculations'
require 'active_model_serializers'
require_relative 'model'

module Parse
  # This class manages dates in the special JSON format it requires for
  # properties of type _:date_. One important note with dates, is that 'created_at' and 'updated_at'
  # columns do not follow this convention all the time. Depending on the
  # Cloud Code SDK, they can be the Parse ISO hash date format or the `iso8601`
  # string format. By default, these are serialized as `iso8601` when sent as
  # responses to Parse for backwards compatibility with some clients. To use
  # the Parse ISO hash format for these fields instead, set
  # `Parse::Object.disable_serialized_string_date = true`.
  class Date < ::DateTime
    ATTRIBUTES = {  __type: :string, iso: :string }.freeze
    include ::ActiveModel::Model
    include ::ActiveModel::Serializers::JSON

    # @return [Parse::Model::TYPE_DATE]
    def self.parse_class; Parse::Model::TYPE_DATE; end;
    # @return [Parse::Model::TYPE_DATE]
    def parse_class; self.class.parse_class; end;
    alias_method :__type, :parse_class

    def attributes
      ATTRIBUTES
    end

    # @return [String] the ISO8601 time string including milliseconds
    def iso
      to_time.utc.iso8601(3)
    end

  end
end


class Time
  # @return [Parse::Date] Converts object to Parse::Date
  def parse_date
    Parse::Date.parse iso8601(3)
  end

end

class DateTime
  # @return [Parse::Date] Converts object to Parse::Date
  def parse_date
    Parse::Date.parse iso8601(3)
  end
end

module ActiveSupport
  class TimeWithZone
    # @return [Parse::Date] Converts object to Parse::Date
    def parse_date
      Parse::Date.parse iso8601(3)
    end
  end
end
