# encoding: UTF-8
# frozen_string_literal: true

require_relative "model"

module Parse

  # This class manages the GeoPoint data type that Parse provides to support
  # geo-queries. To define a GeoPoint property, use the `:geopoint` data type.
  # Please note that latitudes should not be between -90.0 and 90.0, and
  # longitudes should be between -180.0 and 180.0.
  # @example
  #   class PlaceObject < Parse::Object
  #     property :location, :geopoint
  #   end
  #
  #   san_diego = Parse::GeoPoint.new(32.8233, -117.6542)
  #   los_angeles = Parse::GeoPoint.new [34.0192341, -118.970792]
  #   san_diego == los_angeles # false
  #
  #   place = PlaceObject.new
  #   place.location = san_diego
  #   place.save
  #
  class GeoPoint < Model
    # The default attributes in a Parse GeoPoint hash.
    ATTRIBUTES = { __type: :string, latitude: :float, longitude: :float }.freeze

    # @return [Float] latitude value between -90.0 and 90.0
    attr_accessor :latitude
    # @return [Float] longitude value between -180.0 and 180.0
    attr_accessor :longitude
    # The key field for latitude
    FIELD_LAT = "latitude".freeze
    # The key field for longitude
    FIELD_LNG = "longitude".freeze

    # The minimum latitude value.
    LAT_MIN = -90.0
    # The maximum latitude value.
    LAT_MAX = 90.0
    # The minimum longitude value.
    LNG_MIN = -180.0
    # The maximum longitude value.
    LNG_MAX = 180.0

    alias_method :lat, :latitude
    alias_method :lng, :longitude
    # @return [Model::TYPE_GEOPOINT]
    def self.parse_class; TYPE_GEOPOINT; end
    # @return [Model::TYPE_GEOPOINT]
    def parse_class; self.class.parse_class; end

    alias_method :__type, :parse_class

    # The initializer can create a GeoPoint with a hash, array or values.
    # @example
    #  san_diego = Parse::GeoPoint.new(32.8233, -117.6542)
    #  san_diego = Parse::GeoPoint.new [32.8233, -117.6542]
    #  san_diego = Parse::GeoPoint.new { latitude: 32.8233, longitude: -117.6542}
    #
    # @param latitude [Numeric] The latitude value between LAT_MIN and LAT_MAX.
    # @param longitude [Numeric] The longitude value between LNG_MIN and LNG_MAX.
    def initialize(latitude = nil, longitude = nil)
      @latitude = @longitude = 0.0
      if latitude.is_a?(Hash) || latitude.is_a?(Array)
        self.attributes = latitude
      elsif latitude.is_a?(Numeric) && longitude.is_a?(Numeric)
        @latitude = latitude
        @longitude = longitude
      elsif latitude.is_a?(GeoPoint)
        @latitude = latitude.latitude
        @longitude = latitude.longitude
      end

      _validate_point
    end

    # @!visibility private
    def _validate_point
      unless @latitude.nil? || @latitude.between?(LAT_MIN, LAT_MAX)
        warn "[Parse::GeoPoint] Latitude (#{@latitude}) is not between #{LAT_MIN}, #{LAT_MAX}!"
        warn "Attempting to use GeoPoint’s with latitudes outside these ranges will raise an exception in a future release."
      end

      unless @longitude.nil? || @longitude.between?(LNG_MIN, LNG_MAX)
        warn "[Parse::GeoPoint] Longitude (#{@longitude}) is not between #{LNG_MIN}, #{LNG_MAX}!"
        warn "Attempting to use GeoPoint’s with longitude outside these ranges will raise an exception in a future release."
      end
    end

    # @return [Hash] attributes for a Parse GeoPoint.
    def attributes
      ATTRIBUTES
    end

    # Helper method for performing geo-queries with radial miles constraints
    # @return [Array] containing [lat,lng,miles]
    def max_miles(m)
      m = 0 if m.nil?
      [@latitude, @longitude, m]
    end

    def latitude=(l)
      @latitude = l
      _validate_point
    end

    def longitude=(l)
      @longitude = l
      _validate_point
    end

    # Setting lat and lng for an GeoPoint can be done using a hash with the attributes set
    # or with an array of two items where the first is the lat and the second is the lng (ex. [32.22,-118.81])
    def attributes=(h)
      if h.is_a?(Hash)
        h = h.symbolize_keys
        @latitude = h[:latitude].to_f || h[:lat].to_f || @latitude
        @longitude = h[:longitude].to_f || h[:lng].to_f || @longitude
      elsif h.is_a?(Array) && h.count == 2
        @latitude = h.first.to_f
        @longitude = h.last.to_f
      end
      _validate_point
    end

    # @return [Boolean] true if two geopoints are equal based on lat and lng.
    def ==(g)
      return false unless g.is_a?(GeoPoint)
      @latitude == g.latitude && @longitude == g.longitude
    end

    # Helper method for reducing the precision of a geopoint.
    # @param precision [Integer] The number of floating digits to keep.
    # @return [GeoPoint] Reduces the precision of a geopoint.
    def estimated(precision = 2)
      Parse::GeoPoint.new(@latitude.to_f.round(precision), @longitude.round(precision))
    end

    # Returns a tuple containing latitude and longitude
    # @return [Array]
    def to_a
      [@latitude, @longitude]
    end

    # @!visibility private
    def inspect
      "#<GeoPoint [#{@latitude},#{@longitude}]>"
    end

    # Calculate the distance in miles to another GeoPoint using Haversine.
    # You may also call this method with a latitude and longitude.
    # @example
    #   point.distance_in_miles(geotpoint)
    #   point.distance_in_miles(lat, lng)
    #
    # @param geopoint [GeoPoint]
    # @param lng [Float] Longitude assuming that the first parameter
    # is longitude instead of a GeoPoint.
    # @return [Float] number of miles between geopoints.
    # @see #distance_in_km
    def distance_in_miles(geopoint, lng = nil)
      distance_in_km(geopoint, lng) * 0.621371
    end

    # Calculate the distance in kilometers to another GeoPoint using Haversine
    # method. You may also call this method with a latitude and longitude.
    # @example
    #   point.distance_in_km(geotpoint)
    #   point.distance_in_km(lat, lng)
    #
    # @param geopoint [GeoPoint]
    # @param lng [Float] Longitude assuming that the first parameter is a latitude instead of a GeoPoint.
    # @return [Float] number of miles between geopoints.
    # @see #distance_in_miles
    def distance_in_km(geopoint, lng = nil)
      unless geopoint.is_a?(Parse::GeoPoint)
        geopoint = Parse::GeoPoint.new(geopoint, lng)
      end

      dtor = Math::PI / 180
      r = 6378.14
      r_lat1 = self.latitude * dtor
      r_lng1 = self.longitude * dtor
      r_lat2 = geopoint.latitude * dtor
      r_lng2 = geopoint.longitude * dtor

      delta_lat = r_lat1 - r_lat2
      delta_lng = r_lng1 - r_lng2

      a = (Math::sin(delta_lat / 2.0) ** 2).to_f + (Math::cos(r_lat1) * Math::cos(r_lat2) * (Math::sin(delta_lng / 2.0) ** 2))
      c = 2.0 * Math::atan2(Math::sqrt(a), Math::sqrt(1.0 - a))
      d = r * c
      d
    end
  end
end
