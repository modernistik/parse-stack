# encoding: UTF-8
# frozen_string_literal: true

require "active_model"
require "active_support"
require "active_support/inflector"
require "active_support/core_ext"
require "time"
require "parallel"
require_relative "../../client/request"
require_relative "fetching"

module Parse
  class Query

    # Supporting the `all` class method to be used in scope chaining with queries.
    # @!visibility private
    def all(expressions = { limit: :max }, &block)
      conditions(expressions)
      return results(&block) if block_given?
      results
    end

    # Supporting the `first_or_create` class method to be used in scope chaining with queries.
    # @!visibility private
    def first_or_create(query_attrs = {}, resource_attrs = {})
      conditions(query_attrs)
      klass = Parse::Model.find_class self.table
      if klass.blank?
        raise ArgumentError, "Parse model with class name #{self.table} is not registered."
      end
      hash_constraints = constraints(true)
      klass.first_or_create(hash_constraints, resource_attrs)
    end

    # Supporting the `save_all` method to be used in scope chaining with queries.
    # @!visibility private
    def save_all(expressions = {}, &block)
      conditions(expressions)
      klass = Parse::Model.find_class self.table
      if klass.blank?
        raise ArgumentError, "Parse model with class name #{self.table} is not registered."
      end
      hash_constraints = constraints(true)

      klass.save_all(hash_constraints, &block) if block_given?
      klass.save_all(hash_constraints)
    end
  end

  # A Parse::RelationAction is special operation that adds one object to a relational
  # table as to another. Depending on the polarity of the action, the objects are
  # either added or removed from the relation. This class is used to generate the proper
  # hash request formats Parse needs in order to modify relational information for classes.
  class RelationAction
    # @!visibility private
    ADD = "AddRelation"
    # @!visibility private
    REMOVE = "RemoveRelation"
    # @!attribute polarity
    # @return [Boolean] whether it is an addition (true) or removal (false) action.
    # @!attribute key
    # @return [String] the name of the Parse field (column).
    # @!attribute objects
    # @return [Array<Parse::Object>] the set of objects in this relation action.
    attr_accessor :polarity, :key, :objects

    # @param field [String] the name of the Parse field tied to this relation.
    # @param polarity [Boolean] whether this is an addition (true) or removal (false) action.
    # @param objects [Array<Parse::Object>] the set of objects tied to this relation action.
    def initialize(field, polarity: true, objects: [])
      @key = field.to_s
      self.polarity = polarity
      @objects = Array.wrap(objects).compact
    end

    # @return [Hash] a hash representing a relation operation.
    def as_json(*args)
      { @key => {
        "__op" => (@polarity == true ? ADD : REMOVE),
        "objects" => objects.parse_pointers,
      } }.as_json
    end
  end
end

# This module is mainly all the basic orm operations. To support batching actions,
# we use temporary Request objects have contain the operation to be performed (in some cases).
# This allows to group a list of Request methods, into a batch for sending all at once to Parse.
module Parse

  # An error raised when a save failure occurs.
  class RecordNotSaved < StandardError
    # @return [Parse::Object] the Parse::Object that failed to save.
    attr_reader :object

    # @param object [Parse::Object] the object that failed.
    def initialize(object)
      @object = object
    end
  end

  module Core
    # Defines some of the save, update and destroy operations for Parse objects.
    module Actions
      # @!visibility private
      def self.included(base)
        base.extend(ClassMethods)
      end

      # Class methods applied to Parse::Object subclasses.
      module ClassMethods
        # @!attribute raise_on_save_failure
        # By default, we return `true` or `false` for save and destroy operations.
        # If you prefer to have `Parse::Object` raise an exception instead, you
        # can tell to do so either globally or on a per-model basis. When a save
        # fails, it will raise a {Parse::RecordNotSaved}.
        #
        # When enabled, if an error is returned by Parse due to saving or
        # destroying a record, due to your `before_save` or `before_delete`
        # validation cloud code triggers, `Parse::Object` will return the a
        # {Parse::RecordNotSaved} exception type. This exception has an instance
        # method of `#object` which contains the object that failed to save.
        # @example
        #  # globally across all models
        #  Parse::Model.raise_on_save_failure = true
        #  Song.raise_on_save_failure = true # per-model
        #
        #  # or per-instance raise on failure
        #  song.save!
        #
        # @return [Boolean] whether to raise a {Parse::RecordNotSaved}
        #   when an object fails to save.
        attr_accessor :raise_on_save_failure

        def raise_on_save_failure
          return @raise_on_save_failure unless @raise_on_save_failure.nil?
          Parse::Model.raise_on_save_failure
        end

        # Finds the first object matching the query conditions, or creates a new
        # unsaved object with the attributes. This method takes the possibility of two hashes,
        # therefore make sure you properly wrap the contents of the input with `{}`.
        # @example
        #   Parse::User.first_or_create({ ..query conditions..})
        #   Parse::User.first_or_create({ ..query conditions..}, {.. resource_attrs ..})
        # @param query_attrs [Hash] a set of query constraints that also are applied.
        # @param resource_attrs [Hash] a set of attribute values to be applied if an object was not found.
        # @return [Parse::Object] a Parse::Object, whether found by the query or newly created.
        def first_or_create(query_attrs = {}, resource_attrs = {})
          query_attrs = query_attrs.symbolize_keys
          resource_attrs = resource_attrs.symbolize_keys
          obj = query(query_attrs).first

          if obj.blank?
            obj = self.new query_attrs
            obj.apply_attributes!(resource_attrs, dirty_track: true)
          end
          obj
        end

        # Finds the first object matching the query conditions, or creates a new
        # *saved* object with the attributes. This method is similar to {first_or_create}
        # but will also {save!} the object if it was newly created.
        # @example
        #   obj = Parse::User.first_or_create!({ ..query conditions..})
        #   obj = Parse::User.first_or_create!({ ..query conditions..}, {.. resource_attrs ..})
        # @param query_attrs [Hash] a set of query constraints that also are applied.
        # @param resource_attrs [Hash] a set of attribute values to be applied if an object was not found.
        # @return [Parse::Object] a Parse::Object, whether found by the query or newly created.
        # @raise {Parse::RecordNotSaved} if the save fails
        # @see #first_or_create
        def first_or_create!(query_attrs = {}, resource_attrs = {})
          obj = first_or_create(query_attrs, resource_attrs)
          obj.save! if obj.new?
          obj
        end

        # Auto save all objects matching the query constraints. This method is
        # meant to be used with a block. Any objects that are modified in the block
        # will be batched for a save operation. This uses the `updated_at` field to
        # continue to query for all matching objects that have not been updated.
        # If you need to use `:updated_at` in your constraints, consider using {Parse::Core::Querying#all} or
        # {Parse::Core::Querying#each}
        # @param constraints [Hash] a set of query constraints.
        # @yield a block which will iterate through each matching object.
        # @example
        #
        #  post = Post.first
        #  Comments.save_all( post: post) do |comment|
        #    # .. modify comment ...
        #    # it will automatically be saved
        #  end
        # @note You cannot use *:updated_at* as a constraint.
        # @return [Boolean] true if all saves succeeded and there were no errors.
        def save_all(constraints = {})
          invalid_constraints = constraints.keys.any? do |k|
            (k == :updated_at || k == :updatedAt) ||
            (k.is_a?(Parse::Operation) && (k.operand == :updated_at || k.operand == :updatedAt))
          end
          if invalid_constraints
            raise ArgumentError,
              "[#{self}] Special method save_all() cannot be used with an :updated_at constraint."
          end

          force = false
          batch_size = 250
          iterator_block = nil
          if block_given?
            iterator_block = Proc.new
            force ||= false
          else
            # if no block given, assume you want to just save all objects
            # regardless of modification.
            force = true
          end
          # Only generate the comparison block once.
          # updated_comparison_block = Proc.new { |x| x.updated_at }

          anchor_date = Parse::Date.now
          constraints.merge! :updated_at.on_or_before => anchor_date
          constraints.merge! cache: false
          # oldest first, so we create a reduction-cycle
          constraints.merge! order: :updated_at.asc, limit: batch_size
          update_query = query(constraints)
          #puts "Setting Anchor Date: #{anchor_date}"
          cursor = nil
          has_errors = false
          loop do
            results = update_query.results

            break if results.empty?

            # verify we didn't get duplicates fetches
            if cursor.is_a?(Parse::Object) && results.any? { |x| x.id == cursor.id }
              warn "[#{self}.save_all] Unbounded update detected with id #{cursor.id}."
              has_errors = true
              break cursor
            end

            results.each(&iterator_block) if iterator_block.present?
            # we don't need to refresh the objects in the array with the results
            # since we will be throwing them away. Force determines whether
            # to save these objects regardless of whether they are dirty.
            batch = results.save(merge: false, force: force)

            # faster version assuming sorting order wasn't messed up
            cursor = results.last
            # slower version, but more accurate
            # cursor_item = results.max_by(&updated_comparison_block).updated_at
            # puts "[Parse::SaveAll] Updated #{results.count} records updated <= #{cursor.updated_at}"

            break if results.count < batch_size # we didn't hit a cap on results.
            if cursor.is_a?(Parse::Object)
              update_query.where :updated_at.gte => cursor.updated_at

              if cursor.updated_at.present? && cursor.updated_at > anchor_date
                warn "[#{self}.save_all] Reached anchor date  #{anchor_date} < #{cursor.updated_at}"
                break cursor
              end
            end

            has_errors ||= batch.error?
          end
          not has_errors
        end
      end # ClassMethods

      # Perform an atomic operation on this field. This operation is done on the
      # Parse server which guarantees the atomicity of the operation. This is the low-level
      # API on performing atomic operations on properties for classes. These methods do not
      # update the current instance with any changes the server may have made to satisfy this
      # operation.
      #
      # @param field [String] the name of the field in the Parse collection.
      # @param op_hash [Hash] The operation hash. It may also be of type {Parse::RelationAction}.
      # @return [Boolean] whether the operation was successful.
      def operate_field!(field, op_hash)
        field = field.to_sym
        field = self.field_map[field] || field
        if op_hash.is_a?(Parse::RelationAction)
          op_hash = op_hash.as_json
        else
          op_hash = { field => op_hash }.as_json
        end

        response = client.update_object(parse_class, id, op_hash, session_token: _session_token)
        if response.error?
          puts "[#{parse_class}:#{field} Operation] #{response.error}"
        end
        response.success?
      end

      # Perform an atomic add operation to the array field.
      # @param field [String] the name of the field in the Parse collection.
      # @param objects [Array] the set of items to add to this field.
      # @return [Boolean] whether it was successful
      # @see #operate_field!
      def op_add!(field, objects)
        operate_field! field, { __op: :Add, objects: objects }
      end

      # Perform an atomic add unique operation to the array field. The objects will
      # only be added if they don't already exists in the array for that particular field.
      # @param field [String] the name of the field in the Parse collection.
      # @param objects [Array] the set of items to add uniquely to this field.
      # @return [Boolean] whether it was successful
      # @see #operate_field!
      def op_add_unique!(field, objects)
        operate_field! field, { __op: :AddUnique, objects: objects }
      end

      # Perform an atomic remove operation to the array field.
      # @param field [String] the name of the field in the Parse collection.
      # @param objects [Array] the set of items to remove to this field.
      # @return [Boolean] whether it was successful
      # @see #operate_field!
      def op_remove!(field, objects)
        operate_field! field, { __op: :Remove, objects: objects }
      end

      # Perform an atomic delete operation on this field.
      # @param field [String] the name of the field in the Parse collection.
      # @return [Boolean] whether it was successful
      # @see #operate_field!
      def op_destroy!(field)
        operate_field! field, { __op: :Delete }.freeze
      end

      # Perform an atomic add operation on this relational field.
      # @param field [String] the name of the field in the Parse collection.
      # @param objects [Array<Parse::Object>] the set of objects to add to this relational field.
      # @return [Boolean] whether it was successful
      # @see #operate_field!
      def op_add_relation!(field, objects = [])
        objects = [objects] unless objects.is_a?(Array)
        return false if objects.empty?
        relation_action = Parse::RelationAction.new(field, polarity: true, objects: objects)
        operate_field! field, relation_action
      end

      # Perform an atomic remove operation on this relational field.
      # @param field [String] the name of the field in the Parse collection.
      # @param objects [Array<Parse::Object>] the set of objects to remove to this relational field.
      # @return [Boolean] whether it was successful
      # @see #operate_field!
      def op_remove_relation!(field, objects = [])
        objects = [objects] unless objects.is_a?(Array)
        return false if objects.empty?
        relation_action = Parse::RelationAction.new(field, polarity: false, objects: objects)
        operate_field! field, relation_action
      end

      # Atomically increment or decrement a specific field.
      # @param field [String] the name of the field in the Parse collection.
      # @param amount [Integer] the amoun to increment. Use negative values to decrement.
      # @see #operate_field!
      def op_increment!(field, amount = 1)
        unless amount.is_a?(Numeric)
          raise ArgumentError, "Amount should be numeric"
        end
        operate_field! field, { __op: :Increment, amount: amount.to_i }.freeze
      end

      # @return [Parse::Request] a destroy_request for the current object.
      def destroy_request
        return nil unless @id.present?
        uri = self.uri_path
        r = Request.new(:delete, uri)
        r.tag = object_id
        r
      end

      # @return [String] the API uri path for this class.
      def uri_path
        self.client.url_prefix.path + Client.uri_path(self)
      end

      # Creates an array of all possible operations that need to be performed
      # on this object. This includes all property and relational operation changes.
      # @param force [Boolean] whether this object should be saved even if does not have
      #  pending changes.
      # @return [Array<Parse::Request>] the list of API requests.
      def change_requests(force = false)
        requests = []
        # get the URI path for this object.
        uri = self.uri_path

        # generate the request to update the object (PUT)
        if attribute_changes? || force
          # if it's new, then we should call :post for creating the object.
          method = new? ? :post : :put
          r = Request.new(method, uri, body: attribute_updates)
          r.tag = object_id
          requests << r
        end

        # if the object is not new, then we can also add all the relational changes
        # we need to perform.
        if @id.present? && relation_changes?
          relation_change_operations.each do |ops|
            next if ops.empty?
            r = Request.new(:put, uri, body: ops)
            r.tag = object_id
            requests << r
          end
        end
        requests
      end

      # This methods sends an update request for this object with the any change
      # information based on its local attributes. The bang implies that it will send
      # the request even though it is possible no changes were performed. This is useful
      # in kicking-off an beforeSave / afterSave hooks
      # Save the object regardless of whether there are changes. This would call
      # any beforeSave and afterSave cloud code hooks you have registered for this class.
      # @return [Boolean] true/false whether it was successful.
      def update!(raw: false)
        if valid? == false
          errors.full_messages.each do |msg|
            warn "[#{parse_class}] warning: #{msg}"
          end
        end
        response = client.update_object(parse_class, id, attribute_updates, session_token: _session_token)
        if response.success?
          result = response.result
          # Because beforeSave hooks can change the fields we are saving, any items that were
          # changed, are returned to us and we should apply those locally to be in sync.
          set_attributes!(result)
        end
        puts "Error updating #{self.parse_class}: #{response.error}" if response.error?
        return response if raw
        response.success?
      end

      # Save all the changes related to this object.
      # @return [Boolean] true/false whether it was successful.
      def update
        return true unless attribute_changes?
        update!
      end

      # Save the object as a new record, running all callbacks.
      # @return [Boolean] true/false whether it was successful.
      def create
        run_callbacks :create do
          res = client.create_object(parse_class, attribute_updates, session_token: _session_token)
          unless res.error?
            result = res.result
            @id = result[Parse::Model::OBJECT_ID] || @id
            @created_at = result["createdAt"] || @created_at
            #if the object is created, updatedAt == createdAt
            @updated_at = result["updatedAt"] || result["createdAt"] || @updated_at
            # Because beforeSave hooks can change the fields we are saving, any items that were
            # changed, are returned to us and we should apply those locally to be in sync.
            set_attributes!(result)
          end
          puts "Error creating #{self.parse_class}: #{res.error}" if res.error?
          res.success?
        end
      end

      # @!visibility private
      def _session_token
        if @_session_token.respond_to?(:session_token)
          @_session_token = @_session_token.session_token
        end
        @_session_token
      end

      # @!visibility private
      def _validate_session_token!(token, action = :save)
        return nil if token.nil? # user explicitly requests no session token
        token = token.session_token if token.respond_to?(:session_token)
        return token if token.is_a?(String) && token.present?
        raise ArgumentError, "#{self.class}##{action} error: Invalid session token passed (#{token})"
      end

      # saves the object. If the object has not changed, it is a noop. If it is new,
      # we will create the object. If the object has an id, we will update the record.
      #
      # You may pass a session token to the `session` argument to perform this actions
      # with the privileges of a certain user.
      #
      # You can define before and after :save callbacks
      # autoraise: set to true will automatically raise an exception if the save fails
      # @raise {Parse::RecordNotSaved} if the save fails
      # @raise ArgumentError if a non-nil value is passed to `session` that doesn't provide a session token string.
      # @param session [String] a session token in order to apply ACLs to this operation.
      # @param autoraise [Boolean] whether to raise an exception if the save fails.
      # @return [Boolean] whether the save was successful.
      def save(session: nil, autoraise: false)
        @_session_token = _validate_session_token! session, :save
        return true unless changed?
        success = false
        run_callbacks :save do
          #first process the create/update action if any
          #then perform any relation changes that need to be performed
          success = new? ? create : update

          # if the save was successful and we have relational changes
          # let's update send those next.
          if success
            if relation_changes?
              # get the list of changed keys
              changed_attribute_keys = changed - relations.keys.map(&:to_s)
              clear_attribute_changes(changed_attribute_keys)
              success = update_relations
              if success
                changes_applied!
              elsif self.class.raise_on_save_failure || autoraise.present?
                raise Parse::RecordNotSaved.new(self), "Failed updating relations. #{self.parse_class} partially saved."
              end
            else
              changes_applied!
            end
          elsif self.class.raise_on_save_failure || autoraise.present?
            raise Parse::RecordNotSaved.new(self), "Failed to create or save attributes. #{self.parse_class} was not saved."
          end
        end #callbacks
        @_session_token = nil
        success
      end

      # Save this object and raise an exception if it fails.
      # @raise {Parse::RecordNotSaved} if the save fails
      # @raise ArgumentError if a non-nil value is passed to `session` that doesn't provide a session token string.
      # @param session (see #save)
      # @return (see #save)
      def save!(session: nil)
        save(autoraise: true, session: session)
      end

      # Delete this record from the Parse collection. Only valid if this object has an `id`.
      # This will run all the `destroy` callbacks.
      # @param session [String] a session token if you want to apply ACLs for a user in this operation.
      # @raise ArgumentError if a non-nil value is passed to `session` that doesn't provide a session token string.
      # @return [Boolean] whether the operation was successful.
      def destroy(session: nil)
        @_session_token = _validate_session_token! session, :destroy
        return false if new?
        success = false
        run_callbacks :destroy do
          res = client.delete_object parse_class, id, session_token: _session_token
          success = res.success?
          if success
            @id = nil
            changes_applied!
          elsif self.class.raise_on_save_failure
            raise Parse::RecordNotSaved.new(self), "Failed to create or save attributes. #{self.parse_class} was not saved."
          end
          # Your create action methods here
        end
        @_session_token = nil
        success
      end

      # Runs all the registered `before_save` related callbacks.
      def prepare_save!
        run_callbacks(:save) { false }
      end

      # @return [Hash] a hash of the list of changes made to this instance.
      def changes_payload
        h = attribute_updates
        if relation_changes?
          r = relation_change_operations.select { |s| s.present? }.first
          h.merge!(r) if r.present?
        end
        #h.merge!(className: parse_class) unless h.empty?
        h.as_json
      end

      alias_method :update_payload, :changes_payload

      # Generates an array with two entries for addition and removal operations. The first entry
      # of the array will contain a hash of all the change operations regarding adding new relational
      # objects. The second entry in the array is a hash of all the change operations regarding removing
      # relation objects from this field.
      # @return [Array] an array with two hashes; the first is a hash of all the addition operations and
      #  the second hash, all the remove operations.
      def relation_change_operations
        return [{}, {}] unless relation_changes?

        additions = []
        removals = []
        # go through all the additions of a collection and generate an action to add.
        relation_updates.each do |field, collection|
          if collection.additions.count > 0
            additions.push Parse::RelationAction.new(field, objects: collection.additions, polarity: true)
          end
          # go through all the additions of a collection and generate an action to remove.
          if collection.removals.count > 0
            removals.push Parse::RelationAction.new(field, objects: collection.removals, polarity: false)
          end
        end
        # merge all additions and removals into one large hash
        additions = additions.reduce({}) { |m, v| m.merge! v.as_json }
        removals = removals.reduce({}) { |m, v| m.merge! v.as_json }
        [additions, removals]
      end

      # Saves and updates all the relational changes for made to this object.
      # @return [Boolean] whether all the save or update requests were successful.
      def update_relations
        # relational saves require an id
        return false unless @id.present?
        # verify we have relational changes before we do work.
        return true unless relation_changes?
        raise "Unable to update relations for a new object." if new?
        # get all the relational changes (both additions and removals)
        additions, removals = relation_change_operations

        responses = []
        # Send parallel Parse requests for each of the items to update.
        # since we will have multiple responses, we will track it in array
        [removals, additions].threaded_each do |ops|
          next if ops.empty? #if no operations to be performed, then we are done
          responses << client.update_object(parse_class, @id, ops, session_token: _session_token)
        end
        # check if any of them ended up in error
        has_error = responses.any? { |response| response.error? }
        # if everything was ok, find the last response to be returned and update
        #their fields in case beforeSave made any changes.
        unless has_error || responses.empty?
          result = responses.last.result #last result to come back
          set_attributes!(result)
        end #unless
        has_error == false
      end

      # Performs mass assignment using a hash with the ability to modify dirty tracking.
      # This is an internal method used to set properties on the object while controlling
      # whether they are dirty tracked. Each defined property has a method defined with the
      # suffix `_set_attribute!` that can will be called if it is contained in the hash.
      # @example
      #  object.set_attributes!( {"myField" => value}, false)
      #
      #  # equivalent to calling the specific method.
      #  object.myField_set_attribute!(value, false)
      # @param hash [Hash] the hash containing all the attribute names and values.
      # @param dirty_track [Boolean] whether the assignment should be tracked in the change tracking
      #  system.
      # @return [Hash]
      def set_attributes!(hash, dirty_track = false)
        return unless hash.is_a?(Hash)
        hash.each do |k, v|
          next if k == Parse::Model::OBJECT_ID || k == Parse::Model::ID
          method = "#{k}_set_attribute!"
          send(method, v, dirty_track) if respond_to?(method)
        end
      end

      # Clears changes information on all collections (array and relations) and all
      # local attributes.
      def changes_applied!
        # find all fields that are of type :array
        fields(:array) do |key, v|
          proxy = send(key)
          # clear changes
          proxy.changes_applied! if proxy.respond_to?(:changes_applied!)
        end

        # for all relational fields,
        relations.each do |key, v|
          proxy = send(key)
          # clear changes if they support the method.
          proxy.changes_applied! if proxy.respond_to?(:changes_applied!)
        end
        changes_applied
      end
    end
  end
end
