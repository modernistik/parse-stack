require_relative 'constraint'

# Eac constraint type is a subclass of Parse::Constraint
# We register each keyword (which is the Parse query operator)
# and the local operator we want to use. Each of the registered local
# operators are added as methods to the Symbol class.
# For more information: https://parse.com/docs/rest/guide#queries
# For more information about the query design pattern from DataMapper
# that inspired this, see http://datamapper.org/docs/find.html
module Parse

  class CompoundQueryConstraint < Constraint
    contraint_keyword :$or
    register :or

    def build
      or_clauses = formatted_value
      or_clauses = [or_clauses] unless or_clauses.is_a?(Array)
      return { :$or => or_clauses }
    end

  end

  class LessOrEqualConstraint < Constraint
    contraint_keyword :$lte
    register :lte
  end

  class LessThanConstraint < Constraint
    contraint_keyword :$lt
    register :lt
  end

  class GreaterThanConstraint < Constraint
    contraint_keyword :$gt
    register :gt
  end

  class GreaterOrEqualConstraint < Constraint
    contraint_keyword :$gte
    register :gte
  end

  class NotEqualConstraint < Constraint
    contraint_keyword :$ne
    register :not
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

      if formatted_value == true
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
      return { @operation.operand => { key => formatted_value } }
    end
  end

  class NotContainedInConstraint < Constraint
    contraint_keyword :$nin
    register :not_in
    register :not_contained_in
  end

  # All Things must be contained
  class ContainsAllConstraint < Constraint
    contraint_keyword :$all
    register :all
    register :contains_all
  end

  class SelectionConstraint < Constraint
    #This matches a value for a key in the result of a different query
    contraint_keyword :$select
    register :select
  end

  class RejectionConstraint < Constraint
    #requires that a key's value not match a value for a key in the result of a different query
    contraint_keyword :$dontSelect
    register :reject

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

  class JoinQueryConstraint < Constraint
    contraint_keyword :$inQuery
    register :join
    register :in_query

  end

  class DisjointQueryConstraint < Constraint
    contraint_keyword :$notInQuery
    register :exclude
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

end
