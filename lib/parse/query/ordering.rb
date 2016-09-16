# encoding: UTF-8
# frozen_string_literal: true

# Ordering is implemented similarly as constraints in which we add
# special methods to the Symbol class. The developer can then pass one
# or an array of fields (as symbols) and call the particular ordering
# polarity (ex. :name.asc would create a Parse::Order where we want
# things to be sortd by the name field in ascending order)
# For more information about the query design pattern from DataMapper
# that inspired this, see http://datamapper.org/docs/find.html
module Parse
    class Order
      # We only support ascending and descending
      ORDERING = {asc: '', desc: '-'}.freeze
      attr_accessor :field, :direction

      def initialize(field, order = :asc)
        @field = field.to_sym || :objectId
        @direction = order
      end

      def field=(f)
        @field = f.to_sym
      end

      # get the Parse keyword for ordering.
      def polarity
        ORDERING[@direction] || ORDERING[:asc]
      end # polarity

      def to_s
        "" if @field.nil?
         polarity + @field.to_s
      end

      def inspect
        "#{@direction.to_s}(#{@field.inspect})"
      end

    end # Order

end

# Add all the operator instance methods to the symbol classes
class Symbol
  Parse::Order::ORDERING.keys.each do |sym|
    define_method(sym) do
      Parse::Order.new self, sym
    end
  end # each

end
