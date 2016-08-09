require 'active_model'
require 'active_support/inflector'
require 'active_model_serializers'
require_relative 'model'
require 'active_model_serializers'
module Parse

    # A Parse Pointer is the superclass of Parse::Object types. A pointer can be considered
    # a type of Parse::Object in which only the class name and id is known. In most cases,
    # you may not see Parse::Pointer object be used if you have defined all your Parse::Object subclasses
    # based on your Parse application tables - however they are used for when a class is found that cannot be
    # associated with a defined ruby class or used when specifically saving Parse relation types.
    class Pointer < Model

      attr_accessor :parse_class, :id

      def __type; "Pointer".freeze; end;
      alias_method :className, :parse_class
      # A Parse object as a className field and objectId. In ruby, we will use the
      # id attribute method, but for usability, we will also alias it to objectId
      alias_method :objectId, :id

      def initialize(table, oid)
        @parse_class = table.to_s
        @id = oid.to_s
      end

      def parse_class
        @parse_class
      end

      def attributes
        { __type: :string, className: :string, objectId: :string}.freeze
      end


      def json_hash
        JSON.parse to_json
      end

      # Create a new pointer with the current class name and id. While this may not make sense
      # for a pointer instance, Parse::Object subclasses use this inherited method to turn themselves into
      # pointer objects.
      def pointer
        Pointer.new parse_class, @id
      end

      # determines if an object (or subclass) is a pointer type. A pointer is determined
      # if we have a parse class and an id, but no timestamps, then we probably are a pointer.
      def pointer?
        present? && @created_at.blank? && @updated_at.blank?
      end

      # boolean whether this object has data and is not a pointer. Because of some autofetching
      # mechanisms, this is useful to know whether the object already has data without actually causing
      # a fetch of the data.
      def fetched?
        present? && pointer? == false
      end

      # This method is a general implementation that gets overriden by Parse::Object subclass.
      # Given the class name and the id, we will go to Parse and fetch the actual record, returning the
      # JSON object. Note that the subclass implementation does something a bit different.
      def fetch
        response = client.fetch_object(parse_class, id)
        return nil if response.error?
        response.result
      end

      def ==(o)
        return false unless o.is_a?(Pointer)
        #only equal if the Parse class and object ID are the same.
        self.parse_class == o.parse_class && id == o.id
      end
      alias_method :eql?, :==

      def present?
        parse_class.present? && @id.present?
      end
    end

end

# extensions
class Array
  def objectIds
    map { |m| m.is_?(Parse::Pointer) ? m.id : nil }.reject { |r| r.nil? }
  end

  def valid_parse_objects
    select { |s| s.is_a?(Parse::Pointer) }
  end

  def parse_pointers(table = nil)
    self.map do |m|
      #if its an exact Parse::Pointer
      if m.is_a?(Parse::Pointer) || m.respond_to?(:pointer)
        next m.pointer
      elsif m.is_a?(Hash) && m["className"] && m["objectId"]
        next Parse::Pointer.new m["className"], m["objectId"]
      elsif m.is_a?(Hash) && m[:className] && m[:objectId]
        next Parse::Pointer.new m[:className], m[:objectId]
      end
      nil
    end.compact
  end
end
