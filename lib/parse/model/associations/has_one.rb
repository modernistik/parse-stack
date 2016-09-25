# encoding: UTF-8
# frozen_string_literal: true

require_relative '../pointer'
require_relative 'collection_proxy'
require_relative 'pointer_collection_proxy'
require_relative 'relation_collection_proxy'
# a given Parse Pointer. The key of the property is implied to be the
# name of the class/parse table that contains the foreign associated record.
# All belongs to relationship column types have the special data type of :pointer.
module Parse
  module Associations

    module HasOne

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods

        # has one are not property but instance scope methods
        def has_one(key, scope = nil, **opts)

          opts.reverse_merge!({as: key, field: parse_class.columnize})
          klassName = opts[:as].to_parse_class
          foreign_field = opts[:field].to_sym
          ivar = :"@_has_one_#{key}"

          if self.method_defined?(key)
            puts "Creating has_one :#{key} association. Will overwrite existing method #{self}##{key}."
          end

          define_method(key) do |*args|
            return nil if @id.nil?
            _pointer = instance_variable_get(ivar)
            # only cache the result if the scope takes no arguments that could change the query
            return _pointer if (scope.nil? || scope.arity.zero?) && args.empty? && _pointer.is_a?(Parse::Pointer)
            query = Parse::Query.new(klassName, foreign_field => self )
            query.instance_exec(*args,&scope) if scope
            _pointer = query.first
            instance_variable_set(ivar, _pointer)
            _pointer
          end

        end

      end

    end

  end
end
