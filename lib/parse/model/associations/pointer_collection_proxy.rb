# encoding: UTF-8
# frozen_string_literal: true

require "active_model"
require "active_support"
require "active_support/inflector"
require "active_support/core_ext/object"
require_relative "collection_proxy"

module Parse
  # A PointerCollectionProxy is a collection proxy that only allows Parse Pointers (Objects)
  # to be part of the collection. This is done by typecasting the collection to a particular
  # Parse class. Ex. An Artist may have several Song objects. Therefore an Artist could have a
  # column :songs, that is an array (collection) of Song (Parse::Object subclass) objects.
  class PointerCollectionProxy < CollectionProxy

    # @!attribute [rw] collection
    #  The internal backing store of the collection.
    #  @note If you modify this directly, it is highly recommended that you
    #   call {CollectionProxy#notify_will_change!} to notify the dirty tracking system.
    #  @return [Array<Parse::Object>]
    #  @see CollectionProxy#collection
    def collection=(c)
      notify_will_change!
      @collection = c
    end

    # Add Parse::Objects to the collection.
    # @overload add(parse_object)
    #  Add a Parse::Object or Parse::Pointer to this collection.
    #  @param parse_object [Parse::Object,Parse::Pointer] the object to add
    # @overload add(parse_objects)
    #  Add an array of Parse::Objects or Parse::Pointers to this collection.
    #  @param parse_objects [Array<Parse::Object,Parse::Pointer>] the array to append.
    # @return [Array<Parse::Object>] the collection
    def add(*items)
      notify_will_change! if items.count > 0
      items.flatten.parse_objects.each do |item|
        collection.push(item) if item.is_a?(Parse::Pointer)
      end
      @collection
    end

    # Removes Parse::Objects from the collection.
    # @overload remove(parse_object)
    #  Remove a Parse::Object or Parse::Pointer to this collection.
    #  @param parse_object [Parse::Object,Parse::Pointer] the object to remove
    # @overload remove(parse_objects)
    #  Remove an array of Parse::Objects or Parse::Pointers from this collection.
    #  @param parse_objects [Array<Parse::Object,Parse::Pointer>] the array of objects to remove.
    # @return [Array<Parse::Object>] the collection
    def remove(*items)
      notify_will_change! if items.count > 0
      items.flatten.parse_objects.each do |item|
        collection.delete item
      end
      @collection
    end

    # Atomically add a set of Parse::Objects to this collection.
    # This is done by making the API request directly with Parse server; the
    # local object is not updated with changes.
    # @see CollectionProxy#add!
    # @see #add_unique!
    def add!(*items)
      super(items.flatten.parse_pointers)
    end

    # Atomically add a set of Parse::Objects to this collection for those not already
    # in the collection.
    # This is done by making the API request directly with Parse server; the
    # local object is not updated with changes.
    # @see CollectionProxy#add_unique!
    # @see #add!
    def add_unique!(*items)
      super(items.flatten.parse_pointers)
    end

    # Atomically remove a set of Parse::Objects to this collection.
    # This is done by making the API request directly with Parse server; the
    # local object is not updated with changes.
    # @see CollectionProxy#remove!
    def remove!(*items)
      super(items.flatten.parse_pointers)
    end

    # Force fetch the set of pointer objects in this collection.
    # @see Array.fetch_objects!
    def fetch!
      collection.fetch_objects!
    end

    # Fetch the set of pointer objects in this collection.
    # @see Array.fetch_objects
    def fetch
      collection.fetch_objects
    end

    # Encode the collection as a JSON object of Parse::Pointers.
    def as_json(opts = nil)
      parse_pointers.as_json(opts)
    end
  end
end
