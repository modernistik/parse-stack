# encoding: UTF-8
# frozen_string_literal: true

require 'active_model'
require 'active_support'
require 'active_support/inflector'
require 'active_support/core_ext/object'
require_relative '../pointer'


module Parse
    # We use a delegate pattern to send notifications to the parent whenever the content of the internal array changes.
    # The main requirement to using the proxy is to provide the list of initial items if any,
    # the owner to be notified and the name of the attribute 'key'. With that, anytime the array
    # will change, we will notify the delegate by sending :'key'_will_change! . The proxy can also
    # be lazy when fetching the contents of the collection. Whenever the collection is accessed and
    # the list is in a "not loaded" state (empty and loaded == false), we will send :'key_fetch!' to the delegate in order to
    # populate the collection.

    # A CollectionProxy is a special type of array wrapper that notifies a delegate
    # object about changes to the array in order to perform dirty tracking. This is
    # used for all Array properties in Parse::Objects.
    class CollectionProxy
      include ::ActiveModel::Model
      include ::ActiveModel::Dirty
      include ::Enumerable
      # @!attribute [rw] collection
      #  The internal backing store of the collection.
      #  @return [Array]

      # @!attribute [r] delegate
      #  The object to be notified of changes to the collection.
      #  @return [Object]

      # @!attribute [rw] loaded
      #  @return [Boolean] true/false whether the collection has been loaded.

      # @!attribute [r] parse_class
      #  For some subclasses, this helps typecast the items in the collection.
      #  @return [String]

      # @!attribute [r] key
      #  the name of the property key to use when sending notifications for _will_change! and _fetch!
      #  @return [String]

      attr_accessor :collection, :delegate, :loaded, :parse_class
      attr_reader :delegate, :key

      # This is to use dirty tracking within the proxy
      define_attribute_methods :collection

      # Create a new CollectionProxy instance.
      # @param collection [Array] the initial items to add to the collection.
      # @param delegate [Object] the owner of the object that will receive the notifications.
      # @param key [Symbol] the name of the key to use when sending notifications for _will_change! and _fetch!
      # @param parse_class [String] (Optional) the Parse class type are the items of the collection.
      #   This is used to typecast the objects in the array to a particular Parse Object type.
      # @see PointerCollectionProxy
      # @see RelationCollectionProxy
      def initialize(collection = nil, delegate: nil, key: nil, parse_class: nil)
        @delegate = delegate
        @key = key.to_sym if key.present?
        @collection = collection.is_a?(Array) ? collection : []
        @loaded = @collection.count > 0
        @parse_class = parse_class
      end

      # true if the collection has been loaded
      def loaded?
        @loaded
      end

      # Forward a method call to the delegate.
      # @param method [Symbol] the name of the method to forward
      # @param params [Object] method parameters
      # @return [Object] the return value from the forwarded method.
      def forward(method, params = nil)
        return unless @delegate.present? && @delegate.respond_to?(method)
        params.nil? ? @delegate.send(method) : @delegate.send(method, params)
      end

      # Reset the state of the collection.
      def reset!
        @loaded = false
        clear
      end

      # @return [Boolean] true if two collection proxies have similar items.
      def ==(other_list)
        if other_list.is_a?(Array)
          return @collection == other_list
        elsif other_list.is_a?(Parse::CollectionProxy)
          return @collection == other_list.instance_variable_get(:@collection)
        end
      end

      # Reload and restore the collection to its original set of items.
      def reload!
        reset!
        collection #force reload
      end

      # clear all items in the collection
      def clear
        @collection.clear
      end

      # @return [Array]
      def to_a
        collection.to_a
      end; alias_method :to_ary, :to_a

      # @!attribute [rw] collection
      #  Set the internal collection of items without dirty tracking or
      #  change notifications.
      def set_collection!(list)
        @collection = list
      end

      # @!attribute [rw] collection
      #  The internal backing store of the collection.
      # @return [Array] contents of the collection.
      def collection
        if @collection.empty? && @loaded == false
          @collection = forward( :"#{@key}_fetch!" ) || @collection || []
          @loaded = true
        end

        @collection
      end

      def collection=(c)
        notify_will_change!
        @collection = c
      end

      # Add items to the collection
      # @param items [Array] items to add
      def add(*items)
        notify_will_change! if items.count > 0
        items.each do |item|
          collection.push item
        end
        @collection
      end; alias_method :push, :add

      # Remove items from the collection
      # @param items [Array] items to remove
      def remove(*items)
        notify_will_change! if items.count > 0
        items.each do |item|
          collection.delete item
        end
        @collection
      end; alias_method :delete, :remove

      # Atomically adds all items from the array.
      # This request is sent directly to the Parse backend.
      # @param items [Array] items to uniquely add
      # @see #add_unique!
      def add!(*items)
        return false unless @delegate.respond_to?(:op_add!)
        @delegate.send :op_add!, @key, items.flatten
        reset!
      end

      # Atomically adds all items from the array that are not already part of the collection.
      # This request is sent directly to the Parse backend.
      # @param items [Array] items to uniquely add
      # @see #add!
      def add_unique!(*items)
        return false unless @delegate.respond_to?(:op_add_unique!)
        @delegate.send :op_add_unique!, @key, items.flatten
        reset!
      end

      # Atomically deletes all items from the array. This request is sent
      # directly to the Parse backend.
      # @param items [Array] items to remove
      def remove!(*items)
        return false unless @delegate.respond_to?(:op_remove!)
        @delegate.send :op_remove!, @key, items.flatten
        reset!
      end

      # Atomically deletes all items in the array, and marks the field as `undefined` directly
      # with the Parse server. This request is sent directly to the Parse backend.
      def destroy!
        return false unless @delegate.respond_to?(:op_destroy!)
        @delegate.send :op_destroy!, @key
        collection_will_change!
        @collection.clear
        reset!
      end

      # Locally restores previous attributes (not from the persistent store)
      def rollback!
        restore_attributes
      end

      # clears all dirty tracked information.
      def clear_changes!
        clear_changes_information
      end

      # mark that collection changes where applied, which clears dirty tracking.
      def changes_applied!
        changes_applied
      end

      # @param args [Hash] arguments to pass to Array#first.
      # @return [Object] the first item in the collection
      def first(*args)
        collection.first(*args)
      end

      # @return [Object] the second item in the collection
      def second
        collection.second
      end

      # @param args [Hash] arguments to pass to Array#last.
      # @return [Object] the last item in the collection
      def last(*args)
        collection.last(*args)
      end

      # @return [Integer] number of items in the collection.
      def count
        collection.count
      end

      def as_json(*args)
        collection.as_json(args)
      end

      # true if the collection is empty.
      def empty?
        collection.empty?
      end

      # Append items to the collection
      def <<(*list)
        if list.count > 0
          notify_will_change!
          list.flatten.each { |e| collection.push(e) }
        end
      end

      # Notifies the delegate that the collection changed.
      def notify_will_change!
        collection_will_change!
        forward "#{@key}_will_change!"
      end

      def each
        return collection.enum_for(:each) unless block_given?
        collection.each &Proc.new
      end

      def map
        return collection.enum_for(:map) unless block_given?
        collection.map &Proc.new
      end

      def select
        return collection.enum_for(:select) unless block_given?
        collection.select &Proc.new
      end

      def inspect
        "#<#{self.class} changed?=#{changed?} @collection=#{@collection.inspect} >"
      end

    end



  end
