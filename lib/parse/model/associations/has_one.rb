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

          opts.reverse_merge!({as: key, field: parse_class.columnize, scope_only: false})
          klassName = opts[:as].to_parse_class
          foreign_field = opts[:field].to_sym
          ivar = :"@_has_one_#{key}"

          if self.method_defined?(key)
            puts "Creating has_one :#{key} association. Will overwrite existing method #{self}##{key}."
          end

          define_method(key) do |*args, &block|
            return nil if @id.nil?
            query = Parse::Query.new(klassName, limit: 1)
            query.where(foreign_field => self) unless opts[:scope_only] == true

            if scope.is_a?(Proc)
              # any method not part of Query, gets delegated to the instance object
              instance = self
              query.define_singleton_method(:method_missing) { |m, *args, &block| instance.send(m, *args, &block) }
              query.define_singleton_method(:i) { instance }

              if scope.arity.zero?
                query.instance_eval &scope
                query.conditions(*args) if args.present?
              else
                query.instance_exec(*args,&scope)
              end
              instance = nil # help clean up ruby gc
            elsif args.present?
              query.conditions(*args)
            end
            query.define_singleton_method(:method_missing) { |m, *args, &block| self.first.send(m, *args, &block) }
            return query if block.nil?
            block.call(query.first)
          end

        end

      end

    end

  end
end
