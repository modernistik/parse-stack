# encoding: UTF-8
# frozen_string_literal: true

require_relative "properties"

module Parse
  # Upgrade all
  def self.auto_upgrade!
    klassModels = Parse::Object.descendants
    klassModels.sort_by { |c| c.parse_class }.each do |klass|
      yield(klass) if block_given?
      klass.auto_upgrade!
    end
  end

  module Schema

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      # returns the schema of the defined class in the Parse JSON format.
      def schema
        sch = { className: parse_class, fields: {} }
        #first go through all the attributes
        attributes.each do |k,v|
          # don't include the base Parse fields
          next if Parse::Properties::BASE.include?(k)
          next if v.nil?
          result = { type: v.to_s.camelize }
          # if it is a basic column property, find the right datatype
          case v
          when :integer, :float
            result[:type] = "Number"
          when :geopoint, :geo_point
            result[:type] = "GeoPoint"
          when :pointer
            result = { type: "Pointer", targetClass: references[k] }
          when :acl
            result[:type] = "ACL"
          else
            result[:type] = v.to_s.camelize
          end

          sch[:fields][k] = result

        end
        #then add all the relational column attributes
        relations.each do |k,v|
          sch[:fields][k] = { type: "Relation", targetClass: relations[k] }
        end
        sch
      end

      # updates the remote schema using Parse::Client
      def update_schema(schema_updates = nil)
        schema_updates ||= schema
        client.update_schema parse_class, schema_updates
      end

      def create_schema
        client.create_schema parse_class, schema
      end

      # fetches the current schema of this table.
      def fetch_schema
        client.schema parse_class
      end

      # A class method for non-destructive auto upgrading a remote schema based on the properties
      # and relations you have defined. If the table doesn't exist, we create the schema
      # from scratch - otherwise we fetched the current schema, calculate the differences
      # and add the missing columns. WE DO NOT REMOVE any columns.
      def auto_upgrade!
        response = fetch_schema
        if response.success?
          #let's figure out the diff fields
          remote_fields = response.result["fields"]
          current_schema = schema
          current_schema[:fields] = current_schema[:fields].reduce({}) do |h,(k,v)|
            #if the field does not exist in Parse, then add it to the update list
            h[k] = v if remote_fields[k.to_s].nil?
            h
          end
          return true if current_schema[:fields].empty?
          return update_schema( current_schema )
        else
          return create_schema
        end
        #fetch_schema.success? ? update_schema : create_schema
      end
    #def diff(h2);self.dup.delete_if { |k, v| h2[k] == v }.merge(h2.dup.delete_if { |k, v| self.has_key?(k) }); end;

    end

    def schema
      self.class.schema
    end

  end
end
