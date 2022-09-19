# encoding: UTF-8
# frozen_string_literal: true

require "active_support"
require "active_support/inflector"
require "active_support/core_ext"
require_relative "../object"

module Parse
  # Create all Parse::Object subclasses, including their properties and inferred
  # associations by importing the schema for the remote collections in a Parse
  # application. Uses the default configured client.
  # @return [Array] an array of created Parse::Object subclasses.
  # @see Parse::Model::Builder.build!
  def self.auto_generate_models!
    Parse.schemas.map do |schema|
      Parse::Model::Builder.build!(schema)
    end
  end

  class Model
    # This class provides a method to automatically generate Parse::Object subclasses, including
    # their properties and inferred associations by importing the schema for the remote collections
    # in a Parse application.
    class Builder

      # Builds a ruby Parse::Object subclass with the provided schema information.
      # @param schema [Hash] the Parse-formatted hash schema for a collection. This hash
      #  should two keys:
      #  * className: Contains the name of the collection.
      #  * field: A hash containg the column fields and their type.
      # @raise ArgumentError when the className could not be inferred from the schema.
      # @return [Array] an array of Parse::Object subclass constants.
      def self.build!(schema)
        unless schema.is_a?(Hash)
          raise ArgumentError, "Schema parameter should be a Parse schema hash object."
        end
        schema = schema.with_indifferent_access
        fields = schema[:fields] || {}
        className = schema[:className]

        if className.blank?
          raise ArgumentError, "No valid className provided for schema hash"
        end

        # Remove leading underscore, as ruby constants have to start with an uppercase letter

        className = className[1..] if className[0] == '_'

        begin
          klass = Parse::Model.find_class className
          klass = ::Object.const_get(className.to_parse_class) if klass.nil?
        rescue => e
          klass = ::Class.new(Parse::Object)
          ::Object.const_set(className, klass)
        end

        base_fields = Parse::Properties::BASE.keys
        class_fields = klass.field_map.values + [:className]
        fields.each do |field, type|
          field = field.to_sym
          key = field.to_s.underscore.to_sym
          next if base_fields.include?(field) || class_fields.include?(field)

          data_type = type[:type].downcase.to_sym
          if data_type == :pointer
            klass.belongs_to key, as: type[:targetClass], field: field
          elsif data_type == :relation
            klass.has_many key, through: :relation, as: type[:targetClass], field: field
          else
            klass.property key, data_type, field: field
          end
          class_fields.push(field)
        end
        klass
      end
    end
  end
end
