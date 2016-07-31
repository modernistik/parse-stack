
require_relative "model"

module Parse

  # A basic geo location object in Parse. It represents a location on a map through a
  # latitude and longitue.
  class GeoPoint < Model

    attr_accessor :latitude, :longitude
    FIELD_LAT = "latitude".freeze
    FIELD_LNG = "longitude".freeze
    # Latitude should not be -90.0 or 90.0.
    # Longitude should not be -180.0 or 180.0.
    LAT_MIN = -90.0
    LAT_MAX = 90.0
    LNG_MIN = -180.0
    LNG_MAX = 180.0
    alias_method :lat, :latitude
    alias_method :lng, :longitude
    def self.parse_class; TYPE_GEOPOINT; end;
    def parse_class; self.class.parse_class; end;
    alias_method :__type, :parse_class
    # To create a GeoPoint, you can either pass a hash (ex. {latitude: 32, longitue: -117})
    # or an array (ex. [32,-117]) as the first parameter.
    # You may also pass a GeoPoint object or both a lat/lng pair (Ex. GeoPoint.new(32, -117) )
    # Points should not equal or exceed the extreme ends of the ranges.

    # Attempting to use GeoPoint’s with latitude and/or longitude outside these ranges will cause an error.

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

    def attributes
      {  __type: :string, latitude: :float, longitude: :float }.freeze
    end

    def max_miles(m)
      [@latitude,@longitude,m]
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
        h.symbolize_keys!
        @latitude = h[:latitude].to_f || h[:lat].to_f || @latitude
        @longitude = h[:longitude].to_f || h[:lng].to_f ||  @longitude
      elsif h.is_a?(Array) && h.count == 2
        @latitude = h.first.to_f
        @longitude = h.last.to_f
      end
      _validate_point
    end

    def ==(g)
      return false unless g.is_a?(GeoPoint)
      @latitude == g.latitude && @longitude == g.longitude
    end

    def to_a
      [@latitude,@longitude]
    end

    def inspect
      "#<GeoPoint [#{@latitude},#{@longitude}]>"
    end

    # either GeoPoint, array or lat,lng
    def distance_in_miles(geopoint,lng = nil)
      distance_in_km(geopoint, lng) * 0.621371
    end

    def distance_in_km(geopoint,lng = nil)
      unless geopoint.is_a?(Parse::GeoPoint)
        geopoint = Parse::GeoPoint.new(geopoint, lng)
      end

      dtor = Math::PI/180
      r = 6378.14
      r_lat1 = self.latitude * dtor
      r_lng1 = self.longitude * dtor
      r_lat2 = geopoint.latitude * dtor
      r_lng2 = geopoint.longitude * dtor

      delta_lat = r_lat1 - r_lat2
      delta_lng = r_lng1 - r_lng2

      a = (Math::sin(delta_lat/2.0) ** 2).to_f + (Math::cos(r_lat1) * Math::cos(r_lat2) * ( Math::sin(delta_lng/2.0) ** 2 ) )
      c = 2.0 * Math::atan2(Math::sqrt(a), Math::sqrt(1.0-a))
      d = r * c
      d
    end


  end

end
