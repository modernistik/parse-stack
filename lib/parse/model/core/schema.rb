# encoding: UTF-8
# frozen_string_literal: true

require_relative "properties"

module Parse
  module Core
    # Defines the Schema methods applied to a Parse::Object.
    module Schema

        # Generate a Parse-server compatible schema hash for performing changes to the
        # structure of the remote collection.
        # @return [Hash] the schema for this Parse::Object subclass.
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
              result[:type] = Parse::Model::TYPE_NUMBER
            when :geopoint, :geo_point
              result[:type] = Parse::Model::TYPE_GEOPOINT
            when :pointer
              result = { type: Parse::Model::TYPE_POINTER, targetClass: references[k] }
            when :acl
              result[:type] = Parse::Model::ACL
            else
              result[:type] = v.to_s.camelize
            end

            sch[:fields][k] = result

          end
          #then add all the relational column attributes
          relations.each do |k,v|
            sch[:fields][k] = { type: Parse::Model::TYPE_RELATION, targetClass: relations[k] }
          end
          sch
        end

        # Update the remote schema for this Parse collection.
        # @param schema_updates [Hash] the changes to be made to the schema.
        # @return [Parse::Response]
        def update_schema(schema_updates = nil)
          schema_updates ||= schema
          client.update_schema parse_class, schema_updates
        end

        # Create a new collection for this model with the schema defined by the local
        # model.
        # @return [Parse::Response]
        # @see Schema.schema
        def create_schema
          client.create_schema parse_class, schema
        end

        # Fetche the current schema for this collection from Parse server.
        # @return [Parse::Response]
        def fetch_schema
          client.schema parse_class
        end

        # A class method for non-destructive auto upgrading a remote schema based
        # on the properties and relations you have defined in your local model. If
        # the collection doesn't exist, we create the schema. If the collection already
        # exists, the current schema is fetched, and only add the additional fields
        # that are missing.
        # @note No columns or fields are removed, this is a safe non-destructive upgrade.
        # @return [Parse::Response] if the remote schema was modified.
        # @return [Boolean] if no changes were made to the schema, it returns true.
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
          end
          create_schema
        end

    end
  end
end
