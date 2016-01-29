require_relative '../../query'

# This module provides most of the querying methods for Parse Objects.
# It proxies much of the query methods to the Parse::Query object.
module Parse

  module Querying

    def self.included(base)
        base.extend(ClassMethods)
    end

    module ClassMethods

      # This query method helper returns a Query object tied to a parse class.
      # The parse class should be the name of the one that will be sent in the query
      # request pointing to the remote table.
      def query(constraints = {})
        Parse::Query.new self.parse_class, constraints
      end

      def where(clauses = {})
        query.where(clauses)
      end

      # Most common method to use when querying a class. This takes a hash of constraints
      # and conditions and returns the results.
      def all(constraints = {})
        constraints = {limit: :max}.merge(constraints)
        prepared_query = query(constraints)
        return prepared_query.results(&Proc.new) if block_given?
        prepared_query.results
      end

      # returns the first item matching the constraint. If constraint parameter is numeric,
      # then we treat it as a count.
      # Ex. Object.first( :name => "Anthony" ) (returns single object)
      # Ex. Object.first(3) # first 3 objects (array of 3 objects)
      def first(constraints = {})
        fetch_count = 1
        if constraints.is_a?(Numeric)
          fetch_count = constraints.to_i
          constraints = {}
        end
        constraints.merge!( {limit: fetch_count} )
        res = query(constraints).results
        return res.first if fetch_count == 1
        return res.first fetch_count
      end

      # creates a count request (which is more performant when counting objects)
      def count(constraints = {})
        query(constraints).count
      end

      # Find objects based on objectIds. The result is a list (or single item) of the
      # objects that were successfully found.
      # Example:
      # Object.find "<objectId>"
      # Object.find "<objectId>", "<objectId>"....
      # Object.find ["<objectId>", "<objectId>"]
      # Additional named parameters:
      # type: - :parrallel by default - makes all find requests in parallel vs serial.
      #         :batch - makes a single query request for all objects with a "contained in" query.
      # compact: - true by default, removes any nil values from the array as it is potential
      # that an object with a specified ID does not exist.

      def find(*parse_ids, type: :parallel, compact: true)
        # flatten the list of Object ids.
        parse_ids.flatten!
        # determines if the result back to the call site is an array or a single result
        as_array = parse_ids.count > 1
        results = []

        if type == :batch
          # use a .in query with the given id as a list
          results = self.class.all(:id.in => parse_ids)
        else
          # use Parallel to make multiple threaded requests for finding these objects.
          # The benefit of using this as default is that each request goes to a specific URL
          # which is better than Query request (table scan). This in turn allows for caching of
          # individual objects.
          results = parse_ids.threaded_map do |parse_id|
            response = client.fetch_object(parse_class, parse_id)
            next nil if response.error?
            Parse::Object.build response.result, parse_class
          end
        end
        # removes any nil items in the array
        results.compact! if compact

        as_array ? results : results.first
      end; alias_method :get, :find

    end # ClassMethods

  end # Querying


end
