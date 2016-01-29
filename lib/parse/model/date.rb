require 'time'
require 'active_model'
require 'active_support'
require 'active_support/inflector'
require 'active_support/core_ext/object'
require 'active_model_serializers'
require_relative 'model'

# Parse has a specific date format. One of the supported types is a date string in
# ISO 8601 format (including milliseconds). The other is a hash object that contains
# the similar information. When sending data to Parse, we need to use the hash object,
# but when receiving data from Parse, we may either get the string version or the hash version.
# To make things easier to use in ruby, th Parse::Date class inherits from the DateTime class.
# This will allow us to use all the great ActiveSupport methods for date (ex. 3.days.ago) while
# providing our own encoding for sending to Parse.
module Parse
  class Date < ::DateTime
    include ::ActiveModel::Model
    include ::ActiveModel::Serializers::JSON
    def self.parse_class; Parse::Model::TYPE_DATE; end;
    def parse_class; self.class.parse_class; end;
    alias_method :__type, :parse_class

    # called when encoding to JSON.
    def attributes
      {  __type: :string, iso: :string }.freeze
    end

    # this method is defined because it is used by JSON encoding
    def iso
      to_time.utc.iso8601(3) #include milliseconds
    end

  end
end

# To enable conversion of other date class objects, we will add a mixin to turn
# Time and DateTime objects to Parse::Date objects
class Time
  def parse_date
    Parse::Date.parse self.to_s
  end

end

class DateTime
  def parse_date
    Parse::Date.parse self.to_s
  end
end
