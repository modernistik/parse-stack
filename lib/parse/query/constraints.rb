# encoding: UTF-8
# frozen_string_literal: true

require_relative 'constraint'

# Each constraint type is a subclass of Parse::Constraint
# We register each keyword (which is the Parse query operator)
# and the local operator we want to use. Each of the registered local
# operators are added as methods to the Symbol class.
# For more information: https://parse.com/docs/rest/guide#queries
# For more information about the query design pattern from DataMapper
# that inspired this, see http://datamapper.org/docs/find.html

module Parse
  class Constraint
    # A constraint for matching by a specific objectId value.
    #
    #  # where this Parse object equals the object in the column `field`.
    #  q.where :field => Parse::Pointer("Field", "someObjectId")
    #  # alias, shorthand when we infer `:field` maps to `Field` parse class.
    #  q.where :field.id => "someObjectId"
    #  # "field":{"__type":"Pointer","className":"Field","objectId":"someObjectId"}}
    #
    #  class Artist < Parse::Object
    #  end
    #
    #  class Song < Parse::Object
    #    belongs_to :artist
    #  end
    #
    #  artist = Artist.first # get any artist
    #  artist_id = artist.id # ex. artist.id
    #
    #  # find all songs for this artist object
    #  Song.all :artist => artist
    #
    # In some cases, you do not have the Parse object, but you have its `objectId`.
    # You can use the objectId in the query as follows:
    #
    #  # shorthand if you are using convention. Will infer class `Artist`
    #  Song.all :artist.id => artist_id
    #
    #  # other approaches, same result
    #  Song.all :artist.id => artist # safely supported Parse::Pointer
    #  Song.all :artist => Artist.pointer(artist_id)
    #  Song.all :artist => Parse::Pointer.new("Artist", artist_id)
    #
    class ObjectIdConstraint < Constraint
      # @!method id
      # A registered method on a symbol to create the constraint.
      # @example
      #  q.where :field.id => "someObjectId"
      #  q.where :field.id => pointer # safely supported
      # @return [ObjectIdConstraint]
      register :id

      # @return [Hash] the compiled constraint.
      def build
        className = operand.to_parse_class
        value = formatted_value
        # if it is already a pointer value, just return the constraint. Allows for
        # supporting strings, symbols and pointers.
        return { @operation.operand  => value } if value.is_a?(Parse::Pointer)

        begin
          klass = className.constantize
        rescue NameError => e
          klass = Parse::Model.find_class className
        end

        unless klass.present? && klass.is_a?(Parse::Object) == false
          raise ArgumentError, "#{self.class}: No Parse class defined for #{operand} as '#{className}'"
        end

        # allow symbols
        value = value.to_s if value.is_a?(Symbol)

        unless value.is_a?(String) && value.strip.present?
          raise ArgumentError, "#{self.class}: value must be of string type representing a Parse object id."
        end
        value.strip!
        return { @operation.operand  => klass.pointer(value) }
      end

    end

    # Equivalent to the `$or` Parse query operation. This is useful if you want to
    # find objects that match several queries. We overload the `|` operator in
    # order to have a clean syntax for joining these `or` operations.
    #  or_query = query1 | query2 | query3
    #  query = Player.where(:wins.gt => 150) | Player.where(:wins.lt => 5)
    #
    #  query.or_where :field => value
    #
    class CompoundQueryConstraint < Constraint
      contraint_keyword :$or
      register :or

      # @return [Hash] the compiled constraint.
      def build
        or_clauses = formatted_value
        return { :$or => Array.wrap(or_clauses) }
      end

    end

    # Equivalent to the `$lte` Parse query operation. The alias `on_or_before` is provided for readability.
    #  q.where :field.lte => value
    #  q.where :field.on_or_before => date
    #
    #  q.where :created_at.on_or_before => DateTime.now
    # @see LessThanConstraint
    class LessThanOrEqualConstraint < Constraint
      # @!method lte
      # A registered method on a symbol to create the constraint. Maps to Parse operator "$lte".
      # @example
      #  q.where :field.lte => value
      # @return [LessThanOrEqualConstraint]

      # @!method less_than_or_equal
      # Alias for {lte}
      # @return [LessThanOrEqualConstraint]

      # @!method on_or_before
      # Alias for {lte} that provides better readability when constraining dates.
      # @return [LessThanOrEqualConstraint]
      contraint_keyword :$lte
      register :lte
      register :less_than_or_equal
      register :on_or_before
    end

    # Equivalent to the `$lt` Parse query operation. The alias `before` is provided for readability.
    #  q.where :field.lt => value
    #  q.where :field.before => date
    #
    #  q.where :created_at.before => DateTime.now
    class LessThanConstraint < Constraint
      # @!method lt
      # A registered method on a symbol to create the constraint. Maps to Parse operator "$lt".
      # @example
      #  q.where :field.lt => value
      # @return [LessThanConstraint]

      # @!method less_than
      # # Alias for {lt}.
      # @return [LessThanConstraint]

      # @!method before
      # Alias for {lt} that provides better readability when constraining dates.
      # @return [LessThanConstraint]
      contraint_keyword :$lt
      register :lt
      register :less_than
      register :before
    end
    # Equivalent to the `$gt` Parse query operation. The alias `after` is provided for readability.
    #  q.where :field.gt => value
    #  q.where :field.after => date
    #
    #  q.where :created_at.after => DateTime.now
    # @see GreaterThanOrEqualConstraint
    class GreaterThanConstraint < Constraint
      # @!method gt
      # A registered method on a symbol to create the constraint. Maps to Parse operator "$gt".
      # @example
      #  q.where :field.gt => value
      # @return [GreaterThanConstraint]

      # @!method greater_than
      # # Alias for {gt}.
      # @return [GreaterThanConstraint]

      # @!method after
      # Alias for {gt} that provides better readability when constraining dates.
      # @return [GreaterThanConstraint]
      contraint_keyword :$gt
      register :gt
      register :greater_than
      register :after
    end

    # Equivalent to the `$gte` Parse query operation. The alias `on_or_after` is provided for readability.
    #  q.where :field.gte => value
    #  q.where :field.on_or_after => date
    #
    #  q.where :created_at.on_or_after => DateTime.now
    # @see GreaterThanConstraint
    class GreaterThanOrEqualConstraint < Constraint
      # @!method gte
      # A registered method on a symbol to create the constraint. Maps to Parse operator "$gte".
      # @example
      #  q.where :field.gte => value
      # @return [GreaterThanOrEqualConstraint]

      # @!method greater_than_or_equal
      # # Alias for {gte}.
      # @return [GreaterThanOrEqualConstraint]

      # @!method on_or_after
      # Alias for {gte} that provides better readability when constraining dates.
      # @return [GreaterThanOrEqualConstraint]
      contraint_keyword :$gte
      register :gte
      register :greater_than_or_equal
      register :on_or_after
    end

    # Equivalent to the `$ne` Parse query operation. Where a particular field is not equal to value.
    #  q.where :field.not => value
    class NotEqualConstraint < Constraint
      # @!method not
      # A registered method on a symbol to create the constraint. Maps to Parse operator "$ne".
      # @example
      #  q.where :field.not => value
      # @return [NotEqualConstraint]

      # @!method ne
      # # Alias for {not}.
      # @return [NotEqualConstraint]
      contraint_keyword :$ne
      register :not
      register :ne
    end

    # Provides a mechanism using the equality operator to check for `(undefined)` values.
    # Nullabiliity constraint maps the `$exists` Parse clause to enable checking for
    # existance in a column when performing geoqueries due to a Parse limitation.
    #  q.where :field.null => false
    # @note Parse currently has a bug that if you select items near a location
    #  and want to make sure a different column has a value, you need to
    #  search where the column does not contanin a null/undefined value.
    #  Therefore we override the build method to change the operation to a
    #  {NotEqualConstraint}.
    # @see ExistsConstraint
    class NullabilityConstraint < Constraint
      # @!method null
      # A registered method on a symbol to create the constraint.
      # @example
      #  q.where :field.null => true
      # @return [NullabilityConstraint]
      contraint_keyword :$exists
      register :null

      # @return [Hash] the compiled constraint.
      def build
        # if nullability is equal true, then $exists should be set to false

        value = formatted_value
        unless value == true || value == false
          raise ArgumentError, "#{self.class}: Non-Boolean value passed, it must be either `true` or `false`"
        end

        if value == true
          return { @operation.operand => { key => false} }
        else
          #current bug in parse where if you want exists => true with geo queries
          # we should map it to a "not equal to null" constraint
          return { @operation.operand => { Parse::Constraint::NotEqualConstraint.key => nil } }
        end

      end
    end

    # Equivalent to the `#exists` Parse query operation. Checks whether a value is
    # set for key. The difference between this operation and the nullability check
    # is when using compound queries with location.
    #  q.where :field.exists => true
    #
    # @see NullabilityConstraint
    class ExistsConstraint < Constraint
      # @!method exists
      # A registered method on a symbol to create the constraint. Maps to Parse operator "$exists".
      # @example
      #  q.where :field.exists => true
      # @return [ExistsConstraint]
      contraint_keyword :$exists
      register :exists

      # @return [Hash] the compiled constraint.
      def build
        # if nullability is equal true, then $exists should be set to false
        value = formatted_value

        unless value == true || value == false
          raise ArgumentError, "#{self.class}: Non-Boolean value passed, it must be either `true` or `false`"
        end

        return { @operation.operand => { key => value } }
      end
    end

    # Equivalent to the `$in` Parse query operation. Checks whether the value in the
    # column field is contained in the set of values in the target array. If the
    # field is an array data type, it checks whether at least one value in the
    # field array is contained in the set of values in the target array.
    #  q.where :field.in => array
    #  q.where :score.in => [1,3,5,7,9]
    #
    # @see ContainsAllConstraint
    # @see NotContainedInConstraint
    class ContainedInConstraint < Constraint
      # @!method in
      # A registered method on a symbol to create the constraint. Maps to Parse operator "$in".
      # @example
      #  q.where :field.in => array
      # @return [ContainedInConstraint]

      # @!method contained_in
      # Alias for {in}
      # @return [ContainedInConstraint]
      contraint_keyword :$in
      register :in
      register :contained_in

      # @return [Hash] the compiled constraint.
      def build
        val = formatted_value
        val = [val].compact unless val.is_a?(Array)
        { @operation.operand => { key => val } }
      end

    end

    # Equivalent to the `$nin` Parse query operation. Checks whether the value in
    # the column field is *not* contained in the set of values in the target
    # array. If the field is an array data type, it checks whether at least one
    # value in the field array is *not* contained in the set of values in the
    # target array.
    #
    #  q.where :field.not_in => array
    #  q.where :player_name.not_in => ["Jonathan", "Dario", "Shawn"]
    # @see ContainedInConstraint
    # @see ContainsAllConstraint
    class NotContainedInConstraint < Constraint
      # @!method not_in
      # A registered method on a symbol to create the constraint. Maps to Parse operator "$nin".
      # @example
      #  q.where :field.not_in => array
      # @return [NotContainedInConstraint]

      # @!method nin
      # Alias for {not_in}
      # @return [NotContainedInConstraint]

      # @!method not_contained_in
      # Alias for {not_in}
      # @return [NotContainedInConstraint]
      contraint_keyword :$nin
      register :not_in
      register :nin
      register :not_contained_in

      # @return [Hash] the compiled constraint.
      def build
        val = formatted_value
        val = [val].compact unless val.is_a?(Array)
        { @operation.operand => { key => val } }
      end

    end

    # Equivalent to the $all Parse query operation. Checks whether the value in
    # the column field contains all of the given values provided in the array. Note
    # that the field column should be of type {Array} in your Parse class.
    #
    #  q.where :field.all => array
    #  q.where :array_key.all => [2,3,4]
    #
    # @see ContainedInConstraint
    # @see NotContainedInConstraint
    class ContainsAllConstraint < Constraint
      # @!method all
      # A registered method on a symbol to create the constraint. Maps to Parse operator "$all".
      # @example
      #  q.where :field.all => array
      # @return [ContainsAllConstraint]

      # @!method contains_all
      # Alias for {all}
      # @return [ContainsAllConstraint]
      contraint_keyword :$all
      register :all
      register :contains_all

      # @return [Hash] the compiled constraint.
      def build
        val = formatted_value
        val = [val].compact unless val.is_a?(Array)
        { @operation.operand => { key => val } }
      end
    end

    # Equivalent to the `$select` Parse query operation. This matches a value for a
    # key in the result of a different query.
    #  q.where :field.select => { key: "field", query: query }
    #
    #  # example
    #  value = { key: 'city', query: Artist.where(:fan_count.gt => 50) }
    #  q.where :hometown.select => value
    #
    #  # if the local field is the same name as the foreign table field, you can omit hash
    #  # assumes key: 'city'
    #  q.where :city.select => Artist.where(:fan_count.gt => 50)
    #
    class SelectionConstraint < Constraint
      # @!method select
      # A registered method on a symbol to create the constraint. Maps to Parse operator "$select".
      # @return [SelectionConstraint]
      contraint_keyword :$select
      register :select

      # @return [Hash] the compiled constraint.
      def build

        # if it's a hash, then it should be {:key=>"objectId", :query=>[]}
        remote_field_name = @operation.operand
        query = nil
        if @value.is_a?(Hash)
          res = @value.symbolize_keys
          remote_field_name = res[:key] || remote_field_name
          query = res[:query]
          unless query.is_a?(Parse::Query)
            raise ArgumentError, "Invalid Parse::Query object provided in :query field of value: #{@operation.operand}.#{$dontSelect} => #{@value}"
          end
          query = query.compile(encode: false, includeClassName: true)
        elsif @value.is_a?(Parse::Query)
          # if its a query, then assume dontSelect key is the same name as operand.
          query = @value.compile(encode: false, includeClassName: true)
        else
          raise ArgumentError, "Invalid `:select` query constraint. It should follow the format: :field.select => { key: 'key', query: '<Parse::Query>' }"
        end
        { @operation.operand => { :$select => { key: remote_field_name, query: query } } }
      end
    end

    # Equivalent to the `$dontSelect` Parse query operation. Requires that a field's
    # value not match a value for a key in the result of a different query.
    #
    #  q.where :field.reject => { key: :other_field, query: query }
    #
    #  value = { key: 'city', query: Artist.where(:fan_count.gt => 50) }
    #  q.where :hometown.reject => value
    #
    #  # if the local field is the same name as the foreign table field, you can omit hash
    #  # assumes key: 'city'
    #  q.where :city.reject => Artist.where(:fan_count.gt => 50)
    #
    # @see SelectionConstraint
    class RejectionConstraint < Constraint

      # @!method dont_select
      # A registered method on a symbol to create the constraint. Maps to Parse operator "$dontSelect".
      # @example
      #  q.where :field.reject => { key: :other_field, query: query }
      # @return [RejectionConstraint]

      # @!method reject
      # Alias for {dont_select}
      # @return [RejectionConstraint]
      contraint_keyword :$dontSelect
      register :reject
      register :dont_select

      # @return [Hash] the compiled constraint.
      def build

        # if it's a hash, then it should be {:key=>"objectId", :query=>[]}
        remote_field_name = @operation.operand
        query = nil
        if @value.is_a?(Hash)
          res = @value.symbolize_keys
          remote_field_name = res[:key] || remote_field_name
          query = res[:query]
          unless query.is_a?(Parse::Query)
            raise ArgumentError, "Invalid Parse::Query object provided in :query field of value: #{@operation.operand}.#{$dontSelect} => #{@value}"
          end
          query = query.compile(encode: false, includeClassName: true)
        elsif @value.is_a?(Parse::Query)
          # if its a query, then assume dontSelect key is the same name as operand.
          query = @value.compile(encode: false, includeClassName: true)
        else
          raise ArgumentError, "Invalid `:reject` query constraint. It should follow the format: :field.reject => { key: 'key', query: '<Parse::Query>' }"
        end
        { @operation.operand => { :$dontSelect => { key: remote_field_name, query: query } } }
      end
    end

    # Equivalent to the `$regex` Parse query operation. Requires that a field value
    # match a regular expression.
    #
    #  q.where :field.like => /ruby_regex/i
    #  :name.like => /Bob/i
    #
    class RegularExpressionConstraint < Constraint
      #Requires that a key's value match a regular expression

      # @!method like
      # A registered method on a symbol to create the constraint. Maps to Parse operator "$regex".
      # @example
      #  q.where :field.like => /ruby_regex/i
      # @return [RegularExpressionConstraint]

      # @!method regex
      # Alias for {like}
      # @return [RegularExpressionConstraint]
      contraint_keyword :$regex
      register :like
      register :regex
    end

    # Equivalent to the `$relatedTo` Parse query operation. If you want to
    # retrieve objects that are members of a `Relation` field in your Parse class.
    #
    #  q.where :field.related_to => pointer
    #
    #  # find all Users who have liked this post object
    #  post = Post.first
    #  users = Parse::User.all :likes.related_to => post
    #
    class RelationQueryConstraint < Constraint
      # @!method related_to
      # A registered method on a symbol to create the constraint. Maps to Parse operator "$relatedTo".
      # @example
      #   q.where :field.related_to => pointer
      # @return [RelationQueryConstraint]

      # @!method rel
      # Alias for {related_to}
      # @return [RelationQueryConstraint]
      contraint_keyword :$relatedTo
      register :related_to
      register :rel

      # @return [Hash] the compiled constraint.
      def build
        # pointer = formatted_value
        # unless pointer.is_a?(Parse::Pointer)
        #   raise "Invalid Parse::Pointer passed to :related(#{@operation.operand}) constraint : #{pointer}"
        # end
        { :$relatedTo => { object: formatted_value, key: @operation.operand } }
      end
    end

    # Equivalent to the `$inQuery` Parse query operation. Useful if you want to
    # retrieve objects where a field contains an object that matches another query.
    #
    #  q.where :field.matches => query
    #  # assume Post class has an image column.
    #  q.where :post.matches => Post.where(:image.exists => true )
    #
    class InQueryConstraint < Constraint
      # @!method matches
      # A registered method on a symbol to create the constraint. Maps to Parse operator "$inQuery".
      # @example
      #  q.where :field.matches => query
      # @return [InQueryConstraint]

      # @!method in_query
      # Alias for {matches}
      # @return [InQueryConstraint]
      contraint_keyword :$inQuery
      register :matches
      register :in_query
    end

    # Equivalent to the `$notInQuery` Parse query operation. Useful if you want to
    # retrieve objects where a field contains an object that does not match another query.
    # This is the inverse of the {InQueryConstraint}.
    #
    #  q.where :field.excludes => query
    #
    #  q.where :post.excludes => Post.where(:image.exists => true
    #
    class NotInQueryConstraint < Constraint
      # @!method excludes
      # A registered method on a symbol to create the constraint. Maps to Parse operator "$notInQuery".
      # @example
      #   q.where :field.excludes => query
      # @return [NotInQueryConstraint]

      # @!method not_in_query
      # Alias for {excludes}
      # @return [NotInQueryConstraint]
      contraint_keyword :$notInQuery
      register :excludes
      register :not_in_query

    end

    # Equivalent to the `$nearSphere` Parse query operation. This is only applicable
    # if the field is of type `GeoPoint`. This will query Parse and return a list of
    # results ordered by distance with the nearest object being first.
    #
    #  q.where :field.near => geopoint
    #
    #  geopoint = Parse::GeoPoint.new(30.0, -20.0)
    #  PlaceObject.all :location.near => geopoint
    # If you wish to constrain the geospatial query to a maximum number of _miles_,
    # you can utilize the `max_miles` method on a `Parse::GeoPoint` object. This
    # is equivalent to the `$maxDistanceInMiles` constraint used with `$nearSphere`.
    #
    #  q.where :field.near => geopoint.max_miles(distance)
    #  # or provide a triplet includes max miles constraint
    #  q.where :field.near => [lat, lng, miles]
    #
    #  geopoint = Parse::GeoPoint.new(30.0, -20.0)
    #  PlaceObject.all :location.near => geopoint.max_miles(10)
    #
    # @todo Add support $maxDistanceInKilometers (for kms) and $maxDistanceInRadians (for radian angle).
    class NearSphereQueryConstraint < Constraint
      # @!method near
      # A registered method on a symbol to create the constraint. Maps to Parse operator "$nearSphere".
      # @example
      #  q.where :field.near => geopoint
      #  q.where :field.near => geopoint.max_miles(distance)
      # @return [NearSphereQueryConstraint]
      contraint_keyword :$nearSphere
      register :near

      # @return [Hash] the compiled constraint.
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

    # Equivalent to the `$within` Parse query operation and `$box` geopoint
    # constraint. The rectangular bounding box is defined by a southwest point as
    # the first parameter, followed by the a northeast point. Please note that Geo
    # box queries that cross the international date lines are not currently
    # supported by Parse.
    #
    #  q.where :field.within_box => [soutwestGeoPoint, northeastGeoPoint]
    #
    #  sw = Parse::GeoPoint.new 32.82, -117.23 # San Diego
    #  ne = Parse::GeoPoint.new 36.12, -115.31 # Las Vegas
    #
    #  # get all PlaceObjects inside this bounding box
    #  PlaceObject.all :location.within_box => [sw,ne]
    #
    class WithinGeoBoxQueryConstraint < Constraint
      # @!method within_box
      # A registered method on a symbol to create the constraint. Maps to Parse operator "$within".
      # @example
      #  q.where :field.within_box => [soutwestGeoPoint, northeastGeoPoint]
      # @return [WithinGeoBoxQueryConstraint]
      contraint_keyword :$within
      register :within_box

      # @return [Hash] the compiled constraint.
      def build
        geopoint_values = formatted_value
        unless geopoint_values.is_a?(Array) && geopoint_values.count == 2 &&
          geopoint_values.first.is_a?(Parse::GeoPoint) && geopoint_values.last.is_a?(Parse::GeoPoint)
          raise(ArgumentError, '[Parse::Query] Invalid query value parameter passed to `within_box` constraint. ' +
                  'Values in array must be `Parse::GeoPoint` objects and ' +
                  'it should be in an array format: [southwestPoint, northeastPoint]' )
        end
        { @operation.operand => { :$within => { :$box => geopoint_values } } }
      end
    end

    # Equivalent to the `$geoWithin` Parse query operation and `$polygon` geopoints
    # constraint. The polygon area is defined by a list of {Parse::GeoPoint}
    # objects that make up the enclosed area. A polygon query should have 3 or more geopoints.
    # Please note that some Geo queries that cross the international date lines are not currently
    # supported by Parse.
    #
    #  # As many points as you want, minimum 3
    #  q.where :field.within_polygon => [geopoint1, geopoint2, geopoint3]
    #
    #  # Polygon for the Bermuda Triangle
    #  bermuda  = Parse::GeoPoint.new 32.3078000,-64.7504999 # Bermuda
    #  miami    = Parse::GeoPoint.new 25.7823198,-80.2660226 # Miami, FL
    #  san_juan = Parse::GeoPoint.new 18.3848232,-66.0933608 # San Juan, PR
    #
    #  # get all sunken ships inside the Bermuda Triangle
    #  SunkenShip.all :location.within_polygon => [bermuda, san_juan, miami]
    #
    class WithinPolygonQueryConstraint < Constraint
      # @!method within_polygon
      # A registered method on a symbol to create the constraint. Maps to Parse
      # operator "$geoWithin" with "$polygon" subconstraint. Takes an array of {Parse::GeoPoint} objects.
      # @example
      #  # As many points as you want
      #  q.where :field.within_polygon => [geopoint1, geopoint2, geopoint3]
      # @return [WithinPolygonQueryConstraint]
      # @version 1.7.0 (requires Server v2.4.2 or later)
      contraint_keyword :$geoWithin
      register :within_polygon

      # @return [Hash] the compiled constraint.
      def build
        geopoint_values = formatted_value
        unless geopoint_values.is_a?(Array) &&
               geopoint_values.all? {|point| point.is_a?(Parse::GeoPoint) } &&
               geopoint_values.count > 2
          raise ArgumentError, '[Parse::Query] Invalid query value parameter passed to'\
                      ' `within_polygon` constraint: Value must be an array with 3'\
                      ' or more `Parse::GeoPoint` objects'
        end

        { @operation.operand => { :$geoWithin => { :$polygon => geopoint_values } } }
      end
    end


    class FullTextSearchQueryConstraint < Constraint
      # @!method text_search
      # A registered method on a symbol to create the constraint. Maps to Parse
      # operator "$text" with "$search" subconstraint. Takes a hash of parameters.
      # @example
      #  # As many points as you want
      #  q.where :field.text_search => {parameters}
      #
      # Where `parameters` can be one of:
      #   $term : Specify a field to search (Required)
      #   $language : Determines the list of stop words and the rules for tokenizer.
      #   $caseSensitive : Enable or disable case sensitive search.
      #   $diacriticSensitive : Enable or disable diacritic sensitive search
      #
      # @note This method will automatically add `$` to each key of the parameters
      # hash if it doesn't already have it.
      # @return [WithinPolygonQueryConstraint]
      # @version 1.8.0 (requires Server v2.5.0 or later)
      contraint_keyword :$text
      register :text_search

      # @return [Hash] the compiled constraint.
      def build
        params = formatted_value

        params = { :$term => params.to_s } if params.is_a?(String) || params.is_a?(Symbol)

        unless params.is_a?(Hash)
          raise ArgumentError, '[Parse::Query] Invalid query value parameter passed to'\
                      ' `text_search` constraint: Value must be a string or a hash of parameters.'
        end

        params = params.inject({}) do |h,(k,v)|
          u = k.to_s
          u = u.columnize.prepend('$') unless u.start_with?('$')
          h[u] = v
          h
        end

        unless params["$term"].present?
          raise ArgumentError, "[Parse::Query] Invalid query value parameter passed to"\
                      " `text_search` constraint: Missing required `$term` subkey.\n"\
                      "\tExample: #{@operation.operand}.text_search => { term: 'text to search' }"
        end

        { @operation.operand => { :$text => { :$search => params } } }
      end
    end

  end

end
