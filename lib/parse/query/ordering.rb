# encoding: UTF-8
# frozen_string_literal: true


module Parse
    # This class adds support for describing ordering for Parse queries. You can
    # either order by ascending (asc) or descending (desc) order.
    #
    # Ordering is implemented similarly to constraints in which we add
    # special methods to the Symbol class. The developer can then pass one
    # or an array of fields (as symbols) and call the particular ordering
    # polarity (ex. _:name.asc_ would create a Parse::Order where we want
    # things to be sortd by the name field in ascending order)
    # For more information about the query design pattern from DataMapper
    # that inspired this, see http://datamapper.org/docs/find.html'
    # @example
    #   :name.asc # => Parse::Order by ascending :name
    #   :like_count.desc # => Parse::Order by descending :like_count
    #
    class Order
      # The Parse operators to indicate ordering direction.
      ORDERING = {asc: '', desc: '-'}.freeze
      # @!attribute [rw] field
      #   @return [Symbol] the name of the field
      # @!attribute [rw] direction
      #   The direction of the sorting. This is either `:asc` or `:desc`.
      #   @return [Symbol]
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
