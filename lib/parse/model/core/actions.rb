# encoding: UTF-8
# frozen_string_literal: true

require 'active_model'
require 'active_support'
require 'active_support/inflector'
require 'active_support/core_ext'
require 'time'
require 'parallel'
require_relative '../../client/request'

#This module provides many of the CRUD operations on Parse::Object.

# A Parse::RelationAction is special operation that adds one object to a relational
# table as to another. Depending on the polarity of the action, the objects are
# either added or removed from the relation. This class is used to generate the proper
# hash request format Parse needs in order to modify relational information for classes.
module Parse
  class RelationAction
    ADD = "AddRelation"
    REMOVE = "RemoveRelation"
    attr_accessor :polarity, :key, :objects
    # provide the column name of the field, polarity (true = add, false = remove) and the
    # list of objects.
    def initialize(field, polarity: true, objects: [])
      @key = field.to_s
      self.polarity = polarity
      @objects = [objects].flatten.compact
    end

    # generate the proper Parse hash-format operation
    def as_json(*args)
      { @key =>
        {
          "__op" => ( @polarity == true ? ADD : REMOVE ),
          "objects" => objects.parse_pointers
        }
      }.as_json
    end

  end

end

# This module is mainly all the basic orm operations. To support batching actions,
# we use temporary Request objects have contain the operation to be performed (in some cases).
# This allows to group a list of Request methods, into a batch for sending all at once to Parse.
module Parse
  class SaveFailureError < StandardError
    attr_reader :object
    def initialize(object)
      @object = object
    end
  end

  module Actions

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      attr_accessor :raise_on_save_failure

      def raise_on_save_failure
        return @raise_on_save_failure unless @raise_on_save_failure.nil?
        Parse::Model.raise_on_save_failure
      end

      def first_or_create(query_attrs = {}, resource_attrs = {})
        # force only one result
        query_attrs.symbolize_keys!
        resource_attrs.symbolize_keys!
        obj = query(query_attrs).first

        if obj.blank?
          obj = self.new query_attrs
          obj.apply_attributes!(resource_attrs, dirty_track: false)
        end
        obj.save if obj.new? && Parse::Model.autosave_on_create
        obj
      end

      # not quite sure if I like the name of this API.
      def save_all(constraints = {})
        force = false

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
        constraints.merge! order: :updated_at.asc, limit: 100
        update_query = query(constraints)
        #puts "Setting Anchor Date: #{anchor_date}"
        cursor = nil
        has_errors = false
        loop do
          results = update_query.results

          break if results.empty?

          # verify we didn't get duplicates fetches
          if cursor.is_a?(Parse::Object) && results.any? { |x| x.id == cursor.id }
            warn "[Parse::SaveAll] Unbounded update detected with id #{cursor.id}."
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

          if cursor.is_a?(Parse::Object)
            update_query.where :updated_at.gte => cursor.updated_at

            if cursor.updated_at.present? && cursor.updated_at > anchor_date
              warn "[Parse::SaveAll] Reached anchor date  #{anchor_date} < #{cursor.updated_at}"
              break cursor
            end

          end

          has_errors ||= batch.error?
        end
        has_errors
      end

    end # ClassMethods

    def operate_field!(field, op_hash)
      field = field.to_sym
      field = self.field_map[field] || field
      if op_hash.is_a?(Parse::RelationAction)
        op_hash = op_hash.as_json
      else
        op_hash = { field => op_hash }.as_json
      end

      response = client.update_object(parse_class, id, op_hash, session_token: _session_token )
      if response.error?
        puts "[#{parse_class}:#{field} Operation] #{response.error}"
      end
      response.success?
    end

    def op_add!(field,objects)
      operate_field! field, { __op: :Add, objects: objects }
    end

    def op_add_unique!(field,objects)
      operate_field! field, { __op: :AddUnique, objects: objects }
    end

    def op_remove!(field, objects)
      operate_field! field, { __op: :Remove, objects: objects }
    end

    def op_destroy!(field)
      operate_field! field, { __op: :Delete }
    end

    def op_add_relation!(field, objects = [])
      objects = [objects] unless objects.is_a?(Array)
      return false if objects.empty?
      relation_action = Parse::RelationAction.new(field, polarity: true, objects: objects)
      operate_field! field, relation_action
    end

    def op_remove_relation!(field, objects = [])
      objects = [objects] unless objects.is_a?(Array)
      return false if objects.empty?
      relation_action = Parse::RelationAction.new(field, polarity: false, objects: objects)
      operate_field! field, relation_action
    end

    # This creates a destroy_request for the current object.
    def destroy_request
      return nil unless @id.present?
      uri = self.uri_path
      r = Request.new( :delete, uri )
      r.tag = object_id
      r
    end

    def uri_path
      self.client.url_prefix.path + Client.uri_path(self)
    end
    # Creates an array of all possible PUT operations that need to be performed
    # on this local object. The reason it is a list is because attribute operations,
    # relational add operations and relational remove operations are treated as separate
    # Parse requests.
    def change_requests(force = false)
      requests = []
      # get the URI path for this object.
      uri = self.uri_path

      # generate the request to update the object (PUT)
      if attribute_changes? || force
        # if it's new, then we should call :post for creating the object.
        method = new? ? :post : :put
        r = Request.new( method, uri, body: attribute_updates)
        r.tag = object_id
        requests << r
      end

      # if the object is not new, then we can also add all the relational changes
      # we need to perform.
      if @id.present? && relation_changes?
        relation_change_operations.each do |ops|
          next if ops.empty?
          r = Request.new( :put, uri, body: ops)
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

    # save the updates on the objects, if any
    def update
      return true unless attribute_changes?
      update!
    end

    # create this object in Parse
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

    def _session_token
      if @_session_token.respond_to?(:session_token)
        @_session_token = @_session_token.session_token
      end
      @_session_token
    end

    # saves the object. If the object has not changed, it is a noop. If it is new,
    # we will create the object. If the object has an id, we will update the record.
    # You can define before and after :save callbacks
    # autoraise: set to true will automatically raise an exception if the save fails
    def save(autoraise: false, session: nil)
      return true unless changed?
      success = false
      @_session_token = session
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
            clear_attribute_changes( changed_attribute_keys )
            success = update_relations
            if success
              changes_applied!
            elsif self.class.raise_on_save_failure || autoraise.present?
              raise Parse::SaveFailureError.new(self), "Failed updating relations. #{self.parse_class} partially saved."
            end
          else
            changes_applied!
          end
        elsif self.class.raise_on_save_failure || autoraise.present?
          raise Parse::SaveFailureError.new(self), "Failed to create or save attributes. #{self.parse_class} was not saved."
        end

      end #callbacks
      @_session_token = nil
      success
    end

    # shortcut for raising an exception of saving this object failed.
    def save!(session: nil)
      save(autoraise: true, session: session)
    end

    # only destroy the object if it has an id. You can setup before and after
    #callback hooks on :destroy
    def destroy(session: nil)
      return false if new?
      @_session_token = session
      success = false
      run_callbacks :destroy do
        res = client.delete_object parse_class, id, session_token: _session_token
        success = res.success?
        if success
          @id = nil
          changes_applied!
        elsif self.class.raise_on_save_failure
          raise Parse::SaveFailureError.new(self), "Failed to create or save attributes. #{self.parse_class} was not saved."
        end
        # Your create action methods here
      end
      @_session_token = nil
      success
    end

    def prepare_save!
      run_callbacks(:save) { false }
    end

    def changes_payload
      h = attribute_updates
      if relation_changes?
        r =  relation_change_operations.select { |s| s.present? }.first
        h.merge!(r) if r.present?
      end
      h.merge!(className: parse_class) unless h.empty?
      h.as_json
    end

    alias_method :update_payload, :changes_payload

    # this method is useful to generate an array of additions and removals to a relational
    # column.
    def relation_change_operations
      return [{},{}] unless relation_changes?

      additions = []
      removals = []
      # go through all the additions of a collection and generate an action to add.
      relation_updates.each do |field,collection|
        if collection.additions.count > 0
          additions.push Parse::RelationAction.new(field, objects: collection.additions, polarity: true)
        end
        # go through all the additions of a collection and generate an action to remove.
        if collection.removals.count > 0
          removals.push Parse::RelationAction.new(field, objects: collection.removals, polarity: false)
        end
      end
      # merge all additions and removals into one large hash
      additions = additions.reduce({}) { |m,v| m.merge! v.as_json }
      removals = removals.reduce({}) { |m,v| m.merge! v.as_json }
      [additions, removals]
    end

    # update relations updates all the relational data that needs to be updated.
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

    def set_attributes!(hash, dirty_track = false)
      return unless hash.is_a?(Hash)
      hash.each do |k,v|
        next if k == Parse::Model::OBJECT_ID || k == Parse::Model::ID
        method = "#{k}_set_attribute!"
        send(method, v, dirty_track) if respond_to?(method)
      end
    end

    # clears changes information on all collections (array and relations) and all
    # local attributes.
    def changes_applied!
      # find all fields that are of type :array
      fields(:array) do |key,v|
        proxy = send(key)
        # clear changes
        proxy.changes_applied! if proxy.respond_to?(:changes_applied!)
      end

      # for all relational fields,
      relations.each do |key,v|
        proxy = send(key)
        # clear changes if they support the method.
        proxy.changes_applied! if proxy.respond_to?(:changes_applied!)
      end
      changes_applied
    end


  end

  module Fetching

    # force fetches the current object with the data contained in Parse.
    def fetch!
      response = client.fetch_object(parse_class, id)
      if response.error?
        puts "[Fetch Error] #{response.code}: #{response.error}"
      end
      # take the result hash and apply it to the attributes.
      apply_attributes!(response.result, dirty_track: false)
      clear_changes!
      self
    end

    # fetches the object if needed
    def fetch
      # if it is a pointer, then let's go fetch the rest of the content
      pointer? ? fetch! : self
    end

    # autofetches the object based on a key. If the key is not a Parse standard
    # key, the current object is a pointer, then fetch the object - but only if
    # the current object is currently autofetching.
    def autofetch!(key)
      key = key.to_sym
      @fetch_lock ||= false
      if @fetch_lock != true && pointer? && key != :acl && Parse::Properties::BASE_KEYS.include?(key) == false && respond_to?(:fetch)
        #puts "AutoFetching Triggerd by: #{self.class}.#{key} (#{id})"
        @fetch_lock = true
        send :fetch
        @fetch_lock = false
      end

    end

  end

end

class Array

    # Support for threaded operations on array items
    def threaded_each(threads = 2)
      Parallel.each(self, {in_threads: threads}, &Proc.new)
    end

    def threaded_map(threads = 2)
      Parallel.map(self, {in_threads: threads}, &Proc.new)
    end

    def self.threaded_select(threads = 2)
      Parallel.select(self, {in_threads: threads}, &Proc.new)
    end

    # fetches all the objects in the array (force)
    # a parameter symbol can be passed indicating the lookup methodology. Default
    # is parallel which fetches all objects in parallel HTTP requests.
    # If nil is passed in, then all the fetching happens sequentially.
    def fetch_objects!(lookup = :parallel)
      # this gets all valid parse objects from the array
      items = valid_parse_objects

      # make parallel requests.
      unless lookup == :parallel
        # force fetch all objects
        items.threaded_each { |o| o.fetch! }
      else
        # serially fetch each object
        items.each { |o| o.fetch! }
      end
      self #return for chaining.
    end

    # fetches all pointer objects in the array. You can pass a symbol argument
    # that provides the lookup methodology, default is :parallel. Objects that have
    # already been fetched (not in a pointer state) are skipped.
    def fetch_objects(lookup = :parallel)
      items = valid_parse_objects
      if lookup == :parallel
        items.threaded_each { |o| o.fetch }
      else
        items.each { |e| e.fetch }
      end
      #self.replace items
      self
    end

end
