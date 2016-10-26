# encoding: UTF-8
# frozen_string_literal: true

require 'active_model'
require 'active_support'
require 'active_support/inflector'
require 'active_support/core_ext/object'
require 'active_support/core_ext/string'
require 'active_support/core_ext'
require 'active_model_serializers'

module Parse
    # Represents the data structure that Parse server sends to a registered webhook.
    # Parse Parse allows you to receive Cloud Code webhooks on your own hosted
    # server. The `Parse::Webhooks` class is a lightweight Rack application that
    # routes incoming Cloud Code webhook requests and payloads to locally
    # registered handlers. The payloads are `Parse::Payload` type of objects that
    # represent that data that Parse sends webhook handlers.
    class Payload
    ATTRIBUTES = { master: nil, user: nil,
           installationId: nil, params: nil,
             functionName: nil, object: nil,
                 original: nil, update: nil,
                 triggerName: nil }.freeze
    include ::ActiveModel::Serializers::JSON
    # @!attribute [rw] master
    #   @return [Boolean] whether the master key was used for this request.
    # @!attribute [rw] user
    #   @return [Parse::User] the user who performed this request or action.
    # @!attribute [rw] installation_id
    #   @return [String] The identifier of the device that submitted the request.
    # @!attribute [rw] params
    #   @return [Hash] The list of function arguments submitted for a function request.
    # @!attribute [rw] function_name
    #   @return [String] the name of the function.
    # @!attribute [rw] object
    #  In a beforeSave, this attribute is the final object that will be persisted.
    #  @return [Hash] the object hash related to a webhook trigger request.
    #  @see #parse_object
    # @!attribute [rw] trigger_name
    #  @return [String] the name of the trigger (ex. beforeSave, afterSave, etc.)
    # @!attribute [rw] original
    #  In a beforeSave, for previously saved objects, this attribute is the Parse::Object
    #  that was previously in the persistent store.
    #  @return [Hash] the object hash related to a webhook trigger request.
    #  @see #parse_object
    # @!attribute [rw] raw
    #   @return [Hash] the raw payload from Parse server.
    # @!attribute [rw] update
    #   @return [Hash] the update payload in the request.
    attr_accessor :master, :user, :installation_id, :params, :function_name, :object, :trigger_name

    attr_accessor :original, :update, :raw
    alias_method :installationId, :installation_id
    alias_method :functionName, :function_name
    alias_method :triggerName, :trigger_name

    # You would normally never create a Parse::Payload object since it is automatically
    # provided to you when using Parse::Webhooks.
    # @see Parse::Webhooks
    def initialize(hash = {})
      hash = JSON.parse(hash) if hash.is_a?(String)
      hash = Hash[hash.map{ |k, v| [k.to_s.underscore.to_sym, v] }]
      @raw = hash
      @master = hash[:master]
      @user = Parse::User.new hash[:user] if hash[:user].present?
      @installation_id = hash[:installation_id]
      @params = hash[:params]
      @params = @params.with_indifferent_access if @params.is_a?(Hash)
      @function_name = hash[:function_name]
      @object = hash[:object]
      @trigger_name = hash[:trigger_name]
      @original = hash[:original]
      @update = hash[:update] || {} #it comes as an update hash
    end

    # @return [Hash]
    def attributes
      ATTRIBUTES
    end

    # true if this is a webhook function request.
    def function?
      @function_name.present?
    end

    # @return [String] the name of the Parse class for this request.
    def parse_class
      return nil unless @object.present?
      @object[Parse::Model::KEY_CLASS_NAME] || @object[:className]
    end

    # @return [String] the objectId in this request.
    def parse_id
      return nil unless @object.present?
      @object[Parse::Model::OBJECT_ID] || @object[:objectId]
    end; alias_method :objectId, :parse_id

    # true if this is a webhook trigger request.
    def trigger?
      @trigger_name.present?
    end

    # true if this is a beforeSave or beforeDelete webhook trigger request.
    def before_trigger?
      before_save? || before_delete?
    end

    # true if this is a afterSave or afterDelete webhook trigger request.
    def after_trigger?
      after_save? || after_delete?
    end

    # true if this is a beforeSave webhook trigger request.
    def before_save?
      trigger? && @trigger_name.to_sym == :beforeSave
    end

    # true if this is a afterSave webhook trigger request.
    def after_save?
      trigger? && @trigger_name.to_sym == :afterSave
    end

    # true if this is a beforeDelete webhook trigger request.
    def before_delete?
      trigger? && @trigger_name.to_sym == :beforeDelete
    end

    # true if this is a afterDelete webhook trigger request.
    def after_delete?
      trigger? && @trigger_name.to_sym == :afterDelete
    end

    # true if this request is a trigger that contains an object.
    def object?
      trigger? && @object.present?
    end

    # @return [Parse::Object] a Parse::Object from the original object
    def original_parse_object
      return nil unless @original.is_a?(Hash)
      Parse::Object.build(@original)
    end

    # This method returns a Parse::Object by combining the original object, if was provided,
    # with the final object. This will return a dirty tracked Parse::Object subclass,
    # that will have information on which fields have changed between the previous state
    # in the persistent store and the one about to be saved.
    # @param pristine [Boolean] whether the object should be returned without dirty tracking.
    # @return [Parse::Object] a dirty tracked Parse::Object subclass instance
    def parse_object(pristine = false)
      return nil unless object?
      return Parse::Object.build(@object) if pristine
      # if its a before trigger, then we build the original object and apply the updates
      # in order to create a Parse::Object that has the dirty tracking information
      # if no original is nil, then it means this is a brand new object, so we create
      # one from the className
      if before_trigger?
        # if original is present, then this is a modified object
        if @original.present? && @original.is_a?(Hash)
          o = Parse::Object.build @original
          o.apply_attributes! @object, dirty_track: true

          if o.is_a?(Parse::User) && @update.present? && @update["authData"].present?
            o.auth_data = @update["authData"]
          end
          return o
        else #else the object must be new
          klass = Parse::Object.find_class parse_class
          # if we have a class, return that with updated changes, otherwise
          # default to regular object
          if klass.present?
            o = klass.new(@object || {})
            if o.is_a?(Parse::User) && @update.present? && @update["authData"].present?
              o.auth_data = @update["authData"]
            end
            return o
          end # if klass.present?
        end # if we have original

      end # if before_trigger?
      Parse::Object.build(@object)
    end

    end # Payload

end
