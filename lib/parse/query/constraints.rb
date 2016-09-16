# encoding: UTF-8
# frozen_string_literal: true

require_relative 'constraint'

# Eac constraint type is a subclass of Parse::Constraint
# We register each keyword (which is the Parse query operator)
# and the local operator we want to use. Each of the registered local
# operators are added as methods to the Symbol class.
# For more information: https://parse.com/docs/rest/guide#queries
# For more information about the query design pattern from DataMapper
# that inspired this, see http://datamapper.org/docs/find.html
class ParseConstraintError < Exception; end;
module Parse

  class ObjectIdConstraint < Constraint
    register :id


    def build
      className = operand.to_parse_class
      value = formatted_value
      begin
        klass = className.constantize
      rescue NameError => e
        klass = Parse::Model.find_class className
      end

      unless klass.present? && klass.is_a?(Parse::Object) == false
        raise ParseConstraintError, "#{self.class}: No Parse class defined for #{operand} as '#{className}'"
      end

      # allow symbols
      value = value.to_s if value.is_a?(Symbol)

      unless value.is_a?(String) && value.strip.present?
        raise ParseConstraintError, "#{self.class}: value must be of string type representing a Parse object id."
      end
      value.strip!
      return { @operation.operand  => klass.pointer(value) }
    end

  end

  class CompoundQueryConstraint < Constraint
    contraint_keyword :$or
    register :or

    def build
      or_clauses = formatted_value
      or_clauses = [or_clauses] unless or_clauses.is_a?(Array)
      return { :$or => or_clauses }
    end

  end

  class LessThanOrEqualConstraint < Constraint
    contraint_keyword :$lte
    register :lte
    register :less_than_or_equal
    register :on_or_before
  end

  class LessThanConstraint < Constraint
    contraint_keyword :$lt
    register :lt
    register :less_than
    register :before
  end

  class GreaterThanConstraint < Constraint
    contraint_keyword :$gt
    register :gt
    register :greater_than
    register :after
  end

  class GreaterThanOrEqualConstraint < Constraint
    contraint_keyword :$gte
    register :gte
    register :greater_than_or_equal
    register :on_or_after
  end

  class NotEqualConstraint < Constraint
    contraint_keyword :$ne
    register :not
    register :ne
  end

  # Nullabiliity constraint maps $exist Parse clause a bit differently
  # Parse currently has a bug that if you select items near a location
  # and want to make sure a different column has a value, you need to
  # search where the column does not contani a null/undefined value.
  # Therefore we override the build method to change the operation to a
  # NotEqualConstraint
  class NullabilityConstraint < Constraint
    contraint_keyword :$exists
    register :null
    def build
      # if nullability is equal true, then $exists should be set to false

      value = formatted_value
      unless value == true || value == false
        raise ParseConstraintError, "#{self.class}: Non-Boolean value passed, it must be either `true` or `false`"
      end

      if value == true
        return { @operation.operand => { key => false} }
      else
        #current bug in parse where if you want exists => true with geo queries
        # we should map it to a "not equal to null" constraint
        return { @operation.operand => { Parse::NotEqualConstraint.key => nil } }
      end

    end
  end

  class ExistsConstraint < Constraint
    contraint_keyword :$exists
    register :exists
    def build
      # if nullability is equal true, then $exists should be set to false
      value = formatted_value

      unless value == true || value == false
        raise ParseConstraintError, "#{self.class}: Non-Boolean value passed, it must be either `true` or `false`"
      end

      return { @operation.operand => { key => value } }
    end
  end

  # Mapps all items contained in the array
  class ContainedInConstraint < Constraint
    contraint_keyword :$in
    register :in
    register :contained_in

    def build
      val = formatted_value
      val = [val].compact unless val.is_a?(Array)
      { @operation.operand => { key => val } }
    end

  end

  class NotContainedInConstraint < Constraint
    contraint_keyword :$nin
    register :not_in
    register :nin
    register :not_contained_in

    def build
      val = formatted_value
      val = [val].compact unless val.is_a?(Array)
      { @operation.operand => { key => val } }
    end

  end

  # All Things must be contained
  class ContainsAllConstraint < Constraint
    contraint_keyword :$all
    register :all
    register :contains_all

    def build
      val = formatted_value
      val = [val].compact unless val.is_a?(Array)
      { @operation.operand => { key => val } }
    end
  end

  class SelectionConstraint < Constraint
    #This matches a value for a key in the result of a different query
    contraint_keyword :$select
    register :select

    def build

      # if it's a hash, then it should be {:key=>"objectId", :query=>[]}
      remote_field_name = @operation.operand
      query = nil
      if @value.is_a?(Hash)
        res = @value.symbolize_keys
        remote_field_name = res[:key] || remote_field_name
        query = res[:query]
        unless query.is_a?(Parse::Query)
          raise "Invalid Parse::Query object provided in :query field of value: #{@operation.operand}.#{$dontSelect} => #{@value}"
        end
        query = query.compile(encode: false, includeClassName: true)
      elsif @value.is_a?(Parse::Query)
        # if its a query, then assume dontSelect key is the same name as operand.
        query = @value.compile(encode: false, includeClassName: true)
      else
        raise "Invalid `:select` query constraint. It should follow the format: :field.select => { key: 'key', query: '<Parse::Query>' }"
      end
      { @operation.operand => { :$select => { key: remote_field_name, query: query } } }
    end
  end

  class RejectionConstraint < Constraint
    #requires that a key's value not match a value for a key in the result of a different query
    contraint_keyword :$dontSelect
    register :dont_select
    register :reject
    def build

      # if it's a hash, then it should be {:key=>"objectId", :query=>[]}
      remote_field_name = @operation.operand
      query = nil
      if @value.is_a?(Hash)
        res = @value.symbolize_keys
        remote_field_name = res[:key] || remote_field_name
        query = res[:query]
        unless query.is_a?(Parse::Query)
          raise ParseConstraintError, "Invalid Parse::Query object provided in :query field of value: #{@operation.operand}.#{$dontSelect} => #{@value}"
        end
        query = query.compile(encode: false, includeClassName: true)
      elsif @value.is_a?(Parse::Query)
        # if its a query, then assume dontSelect key is the same name as operand.
        query = @value.compile(encode: false, includeClassName: true)
      else
        raise ParseConstraintError, "Invalid `:reject` query constraint. It should follow the format: :field.reject => { key: 'key', query: '<Parse::Query>' }"
      end
      { @operation.operand => { :$dontSelect => { key: remote_field_name, query: query } } }
    end
  end

  class RegularExpressionConstraint < Constraint
    #Requires that a key's value match a regular expression
    contraint_keyword :$regex
    register :like
    register :regex
  end

  # Does the propert relational constraint.
  class RelationQueryConstraint < Constraint
    # matches objects in a specific column in a different class table
    contraint_keyword :$relatedTo
    register :related_to
    register :rel
    def build
      # pointer = formatted_value
      # unless pointer.is_a?(Parse::Pointer)
      #   raise "Invalid Parse::Pointer passed to :related(#{@operation.operand}) constraint : #{pointer}"
      # end
      { :$relatedTo => { object: formatted_value, key: @operation.operand } }
    end
  end

  class InQueryConstraint < Constraint
    contraint_keyword :$inQuery
    register :matches
    register :in_query
  end

  class NotInQueryConstraint < Constraint
    contraint_keyword :$notInQuery
    register :excludes
    register :not_in_query

  end

  class NearSphereQueryConstraint < Constraint
    contraint_keyword :$nearSphere
    register :near

    def build
      point = formatted_value
      max_miles = nil
      if point.is_a?(Array) && point.count > 1
        max_miles = point[2] if point.count == 3
        point = { __type: "GeoPoint", latitude: point[0], longitude: point[1] }
      end
      if max_miles.present? && max_miles > 0
        return { @operation.operand => { key => point, :$maxDistanceInMiles => max_miles.to_f } }
      end
      { @operation.operand => { key => point } }
    end

  end

  class WithinGeoBoxQueryConstraint < Constraint
    contraint_keyword :$within
    register :within_box

    def build
      geopoint_values = formatted_value
      unless geopoint_values.is_a?(Array) && geopoint_values.count == 2 &&
        geopoint_values.first.is_a?(Parse::GeoPoint) && geopoint_values.last.is_a?(Parse::GeoPoint)
        raise(ParseConstraintError, '[Parse::Query] Invalid query value parameter passed to `within_box` constraint. ' +
                'Values in array must be `Parse::GeoPoint` objects and ' +
                'it should be in an array format: [southwestPoint, northeastPoint]' )
      end
      { @operation.operand => { :$within => { :$box => geopoint_values } } }
    end

  end

end
