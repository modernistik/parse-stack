# encoding: UTF-8
# frozen_string_literal: true

require 'active_model'
require 'active_support'
require 'active_support/inflector'
require 'active_support/core_ext/object'
require_relative 'collection_proxy'

# A PointerCollectionProxy is a collection proxy that only allows Parse Pointers (Objects)
# to be part of the collection. This is done by typecasting the collection to a particular
# Parse class. Ex. An Artist may have several Song objects. Therefore an Artist could have a
# column :songs, that is an array (collection) of Song (Parse::Object) objects.
# Because this collection is typecasted, we can do some more interesting things.
module Parse

  class PointerCollectionProxy < CollectionProxy

    def collection=(c)
      notify_will_change!
      @collection = c
    end
    # When we add items, we will verify that they are of type Parse::Pointer at a minimum.
    # If they are not, and it is a hash, we check to see if it is a Parse hash.
    def add(*items)
      notify_will_change! if items.count > 0
      items.flatten.parse_objects.each do |item|
        collection.push(item) if item.is_a?(Parse::Pointer)
      end
      @collection
    end

    # removes items from the collection
    def remove(*items)
      notify_will_change! if items.count > 0
      items.flatten.each do |item|
        collection.delete item
      end
      @collection
    end

    def add!(*items)
      super(items.flatten.parse_pointers)
    end

    def add_unique!(*items)
      super(items.flatten.parse_pointers)
    end

    def remove!(*items)
      super(items.flatten.parse_pointers)
    end

    # We define a fetch and fetch! methods on array
    # that contain pointer objects. This will make requests for each object
    # in the array that is of pointer state (object with unfetch data) and fetch
    # them in parallel.

    def fetch!
      collection.fetch_objects!
    end

    def fetch
      collection.fetch_objects
    end
    # Even though we may have full Parse Objects in the collection, when updating
    # or storing them in Parse, we actually just want Parse::Pointer objects.
    def as_json(*args)
      collection.parse_pointers.as_json
    end

    def parse_pointers
      collection.parse_pointers
    end

  end

end
