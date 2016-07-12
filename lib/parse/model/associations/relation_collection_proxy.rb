require 'active_support'
require 'active_support/inflector'
require 'active_support/core_ext/object'
require_relative 'pointer_collection_proxy'

# The RelationCollectionProxy is similar to a PointerCollectionProxy except that
# there is no actual "array" object in Parse. Parse treats relation through an
# intermediary table (a.k.a. join table). Whenever a developer wants the
# contents of a collection, the foreign table needs to be queried instead.
# In this scenario, the parse_class: initializer argument should be passed in order to
# know which remote table needs to be queried in order to fetch the items of the collection.
#
# Unlike managing an array of Pointers, relations in Parse are done throug atomic operations,
# which have a specific API. The design of this proxy is to maintain two sets of lists,
# items to be added to the relation and a separate list of items to be removed from the
# relation.
#
# Because this relationship is based on queryable Parse table, we are also able to
# not just get all the items in a collection, but also provide additional constraints to
# get matching items within the relation collection.
#
# When creating a Relation proxy, all the delegate methods defined in the superclasses
# need to be implemented, in addition to a few others with the key parameter:
# _relation_query and _commit_relation_updates . :'key'_relation_query should return a
# Parse::Query object that is properly tied to the foreign table class related to this object column.
# Example, if an Artist has many Song objects, then the query to be returned by this method
# should be a Parse::Query for the class 'Song'.
# Because relation changes are separate from object changes, you can call save on a
# relation collection to save the current add and remove operations. Because the delegate needs
# to be informed of the changes being committed, it will be notified
# through :'key'_commit_relation_updates message. The delegate is also in charge of
# clearing out the change information for the collection if saved successfully.

module Parse

  class RelationCollectionProxy < PointerCollectionProxy

    define_attribute_methods :additions, :removals
    attr_reader :additions, :removals

    def initialize(collection = nil, delegate: nil, key: nil, parse_class: nil)
      super
      @additions = []
      @removals = []
    end

    # You can get items within the collection relation filtered by a specific set
    # of query constraints.
    def all(constraints = {})
      q = query( {limit: :max}.merge(constraints) )
      if block_given?
        # if we have a query, then use the Proc with it (more efficient)
        return q.present? ? q.results(&Proc.new) : collection.each(&Proc.new)
      end
      # if no block given, get all the results
      q.present? ? q.results : collection
    end

    # Ask the delegate to return a query for this collection type
    def query(constraints = {})
      q = forward :"#{@key}_relation_query"
    end


    # add the current items to the relation. The process of adding it
    # is adding it to the @additions array and making sure it is
    # removed from the @removals array.
    def add(*items)
      items = items.flatten.parse_pointers
      return @collection if items.empty?

      notify_will_change!
      additions_will_change!
      removals_will_change!
      # take all the items
      items.each do |item|
        @additions.push item
        @collection.push item
        #cleanup
        @removals.delete item
      end
      @collection
    end

    # removes the current items from the relation.
    # The process of removing is deleting it from the @removals array,
    # and adding it to the @additions array.
    def remove(*items)
      items = items.flatten.parse_pointers
      return @collection if items.empty?
      notify_will_change!
      additions_will_change!
      removals_will_change!
      items.each do |item|
        @removals.push item
        @collection.delete item
        # remove it from any add operations
        @additions.delete item
      end
      @collection
    end

    def add!(*items)
      return false unless @delegate.respond_to?(:op_add_relation!)
      items = items.flatten.parse_pointers
      @delegate.send :op_add_relation!, @key, items
    end

    def add_unique!(*items)
      return false unless @delegate.respond_to?(:op_add_relation!)
      items = items.flatten.parse_pointers
      @delegate.send :op_add_relation!, @key, items
    end

    def remove!(*items)
      return false unless @delegate.respond_to?(:op_remove_relation!)
      items = items.flatten.parse_pointers
      @delegate.send :op_remove_relation!, @key, items
    end

    # save the changes if any
    def save
      unless @removals.empty? && @additions.empty?
        forward :"#{@key}_commit_relation_updates"
      end
    end

    def <<(*list)
      list.each { |d| add(d) }
      @collection
    end

  end

end
