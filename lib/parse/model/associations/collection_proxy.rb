require 'active_model'
require 'active_support'
require 'active_support/inflector'
require 'active_support/core_ext/object'
require_relative '../pointer'

# A collection proxy is a special type of array wrapper that will allow us to
# notify the parent object about changes to the array. We use a delegate pattern
# to send notifications to the parent whenever the content of the internal array changes.
# The main requirement to using the proxy is to provide the list of initial items if any,
# the owner to be notified and the name of the attribute 'key'. With that, anytime the array
# will change, we will notify the delegate by sending :'key'_will_change! . The proxy can also
# be lazy when fetching the contents of the collection. Whenever the collection is accessed and
# the list is in a "not loaded" state (empty and loaded == false), we will send :'key_fetch!' to the delegate in order to
# populate the collection.
module Parse

    class CollectionProxy
      include ::ActiveModel::Model
      include ::ActiveModel::Dirty

      attr_accessor :collection, :delegate, :loaded
      attr_reader :delegate, :key
      attr_accessor :parse_class
      # This is to use dirty tracking within the proxy
      define_attribute_methods :collection
      include Enumerable

      # To initialize a collection, you need to pass the following named parameters
      # collection - the initial items to add to the collection.
      # :delegate - the owner of the object that will receive the notifications.
      # :key - the name of the key to use when sending notifications for _will_change! and _fetch!
      # :parse_class - what Parse class type are the items of the collection.
      # This is used to typecast the objects in the array to a particular Parse Object type.
      def initialize(collection = nil, delegate: nil, key: nil, parse_class: nil)
        @delegate = delegate
        @key = key.to_sym if key.present?
        @collection = collection.is_a?(Array) ? collection : []
        @loaded = @collection.count > 0
        @parse_class = parse_class
      end

      def loaded?
        @loaded
      end

      # helper method to forward a message to the delegate
      def forward(method, params = nil)
        return unless @delegate.present? && @delegate.respond_to?(method)
        params.nil? ? @delegate.send(method) : @delegate.send(method, params)
      end

      def reset!
        @loaded = false
        clear
      end

      def ==(other_list)
        if other_list.is_a?(Array)
          return @collection == other_list
        elsif other_list.is_a?(Parse::CollectionProxy)
          return @collection == other_list.instance_variable_get(:@collection)
        end
      end

      def reload!
        reset!
        collection #force reload
      end

      def clear
        @collection.clear
      end

      def to_ary
        collection.to_a
      end; alias_method :to_a, :to_ary

      # lazy loading of a collection. If empty and not loaded, then forward _fetch!
      # to the delegate
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

      # Method to add items to the collection.
      def add(*items)
        notify_will_change! if items.count > 0
        items.each do |item|
          collection.push item
        end
        @collection
      end; alias_method :push, :add
      
      # Remove items from the collection
      def remove(*items)
        notify_will_change! if items.count > 0
        items.each do |item|
          collection.delete item
        end
        @collection
      end; alias_method :delete, :remove
      
      def add!(*items)
        return false unless @delegate.respond_to?(:op_add!)
        @delegate.send :op_add!, @key, items
        reset!
      end
      
      def add_unique!(*items)
        return false unless @delegate.respond_to?(:op_add_unique!)
        @delegate.send :op_add_unique!, @key, items
        reset!
      end
      
      def remove!(*items)
        return false unless @delegate.respond_to?(:op_remove!)
        @delegate.send :op_remove!, @key, items
        reset!
      end
      
      def destroy!
        return false unless @delegate.respond_to?(:op_destroy!)
        @delegate.send :op_destroy!, @key
        collection_will_change!
        @collection.clear
        reset!
      end

      def rollback!
        restore_attributes
      end

      def clear_changes!
        clear_changes_information
      end

      def changes_applied!
        changes_applied
      end

      def first(*args)
        collection.first(*args)
      end

      def second
        collection.second
      end

      def last(*args)
        collection.last(*args)
      end

      def count
        collection.count
      end

      def as_json(*args)
        collection.as_json(args)
      end

      def empty?
        collection.empty?
      end

      # append items to the array
      def <<(*list)
        if list.count > 0
          notify_will_change!
          list.flatten.each { |e| collection.push(e) }
        end
      end
      # we call our own dirty tracking and also forward the call
      def notify_will_change!
        collection_will_change!
        forward "#{@key}_will_change!"
      end

      # supported iterator
      def each
        return collection.enum_for(:each) unless block_given?
        collection.each &Proc.new
      end

      def inspect
        "#<#{self.class} changed?=#{changed?} @collection=#{@collection.inspect} >"
      end

    end



  end
