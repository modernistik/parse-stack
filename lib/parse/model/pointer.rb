# encoding: UTF-8
# frozen_string_literal: true

require 'active_model'
require 'active_support'
require 'active_support/inflector'
require 'active_support/core_ext'
require 'active_model_serializers'
require_relative 'model'
module Parse

    # The Pointer class represents the pointer type in Parse and is the superclass
    # of Parse::Object types. A pointer can be considered a type of Parse::Object
    # in which only the class name and id is known. In most cases, you may not
    # deal with Parse::Pointer objects directly if you have defined all your
    # Parse::Object subclasses.
    #
    # A `Parse::Pointer` only contains data about the specific Parse class and
    # the `id` for the object. Therefore, creating an instance of any
    # Parse::Object subclass with only the `:id` field set will be
    # considered in "pointer" state even though its specific class is not
    # `Parse::Pointer` type. The only case that you may have a Parse::Pointer
    # is in the case where an object was received for one of your classes and
    # the framework has no registered class handler for it.
    # Assume you have the tables `Post`, `Comment` and `Author` defined in your
    # remote Parse database, but have only defined `Post` and `Commentary`
    # locally.
    # @example
    #   class Post < Parse::Object
    #   end
    #
    #   class Commentary < Parse::Object
    # 	  belongs_to :post
    # 	  belongs_to :author
    #   end
    #
    #   comment = Commentary.first
    #   comment.post? # true because it is non-nil
    #   comment.artist? # true because it is non-nil
    #
    #   # both are true because they are in a Pointer state
    #   comment.post.pointer? # true
    #   comment.author.pointer? # true
    #
    #   # we have defined a Post class handler
    #   comment.post # <Post @parse_class="Post", @id="xdqcCqfngz">
    #
    #   # we have not defined an Author class handler
    #   comment.author # <Parse::Pointer @parse_class="Author", @id="hZLbW6ofKC">
    #
    #
    #   comment.post.fetch # fetch the relation
    #   comment.post.pointer? # false, it is now a full object.
    #
    # The effect is that for any unknown classes that the framework encounters,
    # it will generate Parse::Pointer instances until you define those classes
    # with valid properties and associations. While this might be ok for some
    # classes you do not use, we still recommend defining all your Parse classes
    # locally in the framework.
    #
    # Once you have a subclass, you may also create a Parse::Pointer object using
    # the _pointer_ method.
    # @example
    #   Parse::User.pointer("123456") # => Parse::Pointer for "_User" class
    #
    # @see Parse::Object
    class Pointer < Model
      ATTRIBUTES = { __type: :string, className: :string, objectId: :string}.freeze
      # @return [String] the name of the Parse class for this pointer.
      attr_accessor :parse_class
      # @return [String] the objectId field
      attr_accessor :id

      # @return [Model::TYPE_POINTER]
      def __type; Parse::Model::TYPE_POINTER; end;
      alias_method :className, :parse_class
      # A Parse object as a className field and objectId. In ruby, we will use the
      # id attribute method, but for usability, we will also alias it to objectId
      alias_method :objectId, :id

      # A Parse pointer only requires the name of the remote Parse collection name,
      # and the `objectId` of the record.
      # @param table [String] The Parse class name in the Parse database.
      # @param oid [String] The objectId
      def initialize(table, oid)
        @parse_class = table.to_s
        @id = oid.to_s
      end

      # @return [String] the name of the collection for this Pointer.
      def parse_class
        @parse_class
      end

      # @return [Hash]
      def attributes
        ATTRIBUTES
      end

      # @return [Hash] serialized JSON structure
      def json_hash
        JSON.parse to_json
      end

      # Create a new pointer with the current class name and id. While this may not make sense
      # for a pointer instance, Parse::Object subclasses use this inherited method to turn themselves into
      # pointer objects.
      # @example
      #  user = Parse::User.first
      #  user.pointer # => Parse::Pointer("_User", user.id)
      #
      # @return [Pointer] a new Pointer for this object.
      # @see Parse::Object
      def pointer
        Pointer.new parse_class, @id
      end

      # Whether this instance is in pointer state. A pointer is determined
      # if we have a parse class and an id, but no created_at or updated_at fields.
      # @return [Boolean] true if instance is in pointer state.
      def pointer?
        present? && @created_at.blank? && @updated_at.blank?
      end

      # Returns true if the data for this instance has been fetched. Because of some autofetching
      # mechanisms, this is useful to know whether the object already has data without actually causing
      # a fetch of the data.
      # @return [Boolean] true if not in pointer state.
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

      # Two Parse::Pointers (or Parse::Objects) are equal if both of them have
      # the same Parse class and the same id.
      # @return [Boolean] true if
      def ==(o)
        return false unless o.is_a?(Pointer)
        #only equal if the Parse class and object ID are the same.
        self.parse_class == o.parse_class && id == o.id
      end
      alias_method :eql?, :==

      # @return [Boolean] true if instance has a Parse class and an id.
      def present?
        parse_class.present? && @id.present?
      end
    end

end

# extensions
class Array
  # This method maps all the ids (String) of all Parse::Objects in the array.
  # @return [Array] an array of strings of ids.
  def objectIds
    map { |m| m.is_?(Parse::Pointer) ? m.id : nil }.compact
  end

  # Filter all objects in the array that do not inherit from Parse::Pointer or
  # Parse::Object.
  # @return [Array] an array of Parse::Objects.
  def valid_parse_objects
    select { |s| s.is_a?(Parse::Pointer) }
  end

  # Convert all potential objects in the array to a list of Parse::Pointer instances.
  # The array can contain a mixture of objects types including JSON Parse-like hashes.
  # @return [Array] an array of Parse::Pointer objects.
  def parse_pointers(table = nil)
    self.map do |m|
      #if its an exact Parse::Pointer
      if m.is_a?(Parse::Pointer) || m.respond_to?(:pointer)
        next m.pointer
      elsif m.is_a?(Hash) && m[Parse::Model::KEY_CLASS_NAME] && m[Parse::Model::OBJECT_ID]
        next Parse::Pointer.new m[Parse::Model::KEY_CLASS_NAME], m[Parse::Model::OBJECT_ID]
      elsif m.is_a?(Hash) && m[:className] && m[:objectId]
        next Parse::Pointer.new m[:className], m[:objectId]
      end
      nil
    end.compact
  end
end
