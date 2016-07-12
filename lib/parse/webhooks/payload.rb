require 'active_model'
require 'active_support'
require 'active_support/inflector'
require 'active_support/core_ext/object'
require 'active_support/core_ext/string'
require 'active_model_serializers'

module Parse

    class Payload
    include ::ActiveModel::Serializers::JSON
    attr_accessor :master, :user, :installation_id, :params, :function_name, :object, :trigger_name

    attr_accessor :original, :update, :raw
    alias_method :installationId, :installation_id
    alias_method :functionName, :function_name
    alias_method :triggerName, :trigger_name

    def initialize(hash = {})
      hash = JSON.parse(hash) if hash.is_a?(String)
      hash = Hash[hash.map{ |k, v| [k.to_s.underscore.to_sym, v] }]
      @raw = hash
      @master = hash[:master]
      @user = Parse::User.new hash[:user] if hash[:user].present?
      @installation_id = hash[:installation_id]
      @params = hash[:params]
      @function_name = hash[:function_name]
      @object = hash[:object]
      @trigger_name = hash[:trigger_name]
      @original = hash[:original]
      @update = hash[:update] || {} #it comes as an update hash
    end

    def function?
      @function_name.present?
    end

    def parse_class
      return nil unless @object.present?
      @object["className".freeze] || @object[:className]
    end

    def parse_id
      return nil unless @object.present?
      @object["objectId".freeze] || @object[:objectId]
    end; alias_method :objectId, :parse_id

    def trigger?
      @trigger_name.present?
    end

    def before_trigger?
      before_save? || before_delete?
    end

    def after_trigger?
      after_save? || after_delete?
    end

    def before_save?
      trigger? && @trigger_name.to_sym == :beforeSave
    end

    def after_save?
      trigger? && @trigger_name.to_sym == :afterSave
    end

    def before_delete?
      trigger? && @trigger_name.to_sym == :beforeDelete
    end

    def after_delete?
      trigger? && @trigger_name.to_sym == :afterDelete
    end

    def object?
      trigger? && @object.present?
    end

    def original_parse_object
      return nil unless @original.is_a?(Hash)
      Parse::Object.build(@original)
    end

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


    def attributes
      { master: nil, user: nil, installationId: nil, params: nil,
        functionName: nil, object: nil, original: nil, update: nil, triggerName: nil }.freeze
    end

    end # Payload

end
