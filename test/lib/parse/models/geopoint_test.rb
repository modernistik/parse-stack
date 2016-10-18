require_relative '../../../test_helper'

class TestGeoPoint < Minitest::Test
  SD = {lat: 32.8233, lng: -117.6542}
  LA = {lat: 34.0192341, lng: -118.970792}


  def setup
    @san_diego = Parse::GeoPoint.new(SD[:lat], SD[:lng])
    @los_angeles = Parse::GeoPoint.new [LA[:lat], LA[:lng]]

  end

  def test_constants
    assert_equal Parse::GeoPoint::LAT_MIN, -90.0
    assert_equal Parse::GeoPoint::LAT_MAX, 90.0
    assert_equal Parse::GeoPoint::LNG_MIN, -180.0
    assert_equal Parse::GeoPoint::LNG_MAX, 180.0
    assert_equal Parse::GeoPoint.parse_class, "GeoPoint"
    assert_instance_of(Parse::GeoPoint, @san_diego)
    assert_equal @san_diego.parse_class, "GeoPoint"
  end

  def test_initializers
    loc = Parse::GeoPoint.new
    assert_instance_of Parse::GeoPoint, loc
    assert_equal loc.latitude, 0
    assert_equal loc.longitude, 0

    # standard
    loc = Parse::GeoPoint.new SD[:lat],  SD[:lng]
    assert_equal loc.parse_class, Parse::GeoPoint.parse_class
    assert_equal loc.latitude, SD[:lat]
    assert_equal loc.longitude, SD[:lng]

    # hash version
    loc = Parse::GeoPoint.new({latitude: SD[:lat], longitude: SD[:lng] })
    assert_equal loc.parse_class, Parse::GeoPoint.parse_class
    assert_instance_of Parse::GeoPoint, loc
    assert_equal loc.latitude, SD[:lat]
    assert_equal loc.longitude, SD[:lng]
    # alias methods
    assert_equal loc.lat, SD[:lat]
    assert_equal loc.lng, SD[:lng]

    # array
    loc = Parse::GeoPoint.new [LA[:lat],  LA[:lng]]
    assert_equal loc.parse_class, Parse::GeoPoint.parse_class
    assert_instance_of Parse::GeoPoint, loc
    assert_equal loc.latitude, LA[:lat]
    assert_equal loc.longitude,  LA[:lng]

    # geopoint
    loc2 = Parse::GeoPoint.new loc
    assert_instance_of Parse::GeoPoint, loc2
    assert_equal loc2.parse_class, Parse::GeoPoint.parse_class
    assert_equal loc2.latitude, loc.latitude
    assert_equal loc2.longitude,  loc.longitude

    assert_equal loc2.lat, loc.latitude
    assert_equal loc2.lng,  loc.longitude

    # zero on non-numeric
    loc = Parse::GeoPoint.new "false",  true
    assert_equal loc.latitude, 0
    assert_equal loc.longitude, 0

  end

  def test_equality
    sd = Parse::GeoPoint.new(SD[:lat], SD[:lng])
    assert_equal sd, @san_diego
    assert sd == @san_diego, "Testing equality operator"
    assert (@los_angeles == @san_diego) == false, "Testing equality operator different locations"
    assert (Parse::Object.new == @san_diego) == false, "Testing equality operator different locations"
  end

  def test_array_formatting
    assert_equal @san_diego.to_a, [@san_diego.lat, @san_diego.lng]
  end

  def test_attribute_definitions
    att = @san_diego.attributes
    assert_equal att[:__type], :string
    assert_equal att[:latitude], :float
    assert_equal att[:longitude], :float
  end

  def test_max_miles
    assert_equal @san_diego.max_miles(3), [@san_diego.latitude, @san_diego.longitude, 3]
    assert_equal @san_diego.max_miles(nil), [@san_diego.latitude, @san_diego.longitude, 0]
  end

  def test_haversine_distance_miles
    miles_between_sd_la = 112.33994506861293
    assert_equal @san_diego.distance_in_miles(@los_angeles), miles_between_sd_la
    assert_equal @los_angeles.distance_in_miles(@san_diego), @san_diego.distance_in_miles(@los_angeles)
    assert_equal @san_diego.distance_in_miles(@san_diego), 0
  end

  def test_haversine_distance_miles
    km_between_sd_la = 180.79367248972503
    assert_equal @san_diego.distance_in_km(@los_angeles), km_between_sd_la
    assert_equal @los_angeles.distance_in_km(@san_diego), @san_diego.distance_in_km(@los_angeles)
    assert_equal @san_diego.distance_in_km(@san_diego), 0
  end

  def test_estimated
    @san_diego_estimated = @san_diego.estimated
    lat = @san_diego.latitude.to_f.round(2)
    lng = @san_diego.longitude.to_f.round(2)
    assert_equal @san_diego_estimated.lat, lat
    assert_equal @san_diego_estimated.lng, lng

    @san_diego_estimated = @san_diego.estimated(3)
    lat = @san_diego.latitude.to_f.round(3)
    lng = @san_diego.longitude.to_f.round(3)
    assert_equal @san_diego_estimated.lat, lat
    assert_equal @san_diego_estimated.lng, lng

    @san_diego_estimated = @san_diego.estimated(0)
    lat = @san_diego.latitude.to_f.round(0)
    lng = @san_diego.longitude.to_f.round(0)
    assert_equal @san_diego_estimated.lat, lat
    assert_equal @san_diego_estimated.lng, lng
    assert_equal @san_diego.estimated(0).max_miles(50), [lat,lng,50]

  end

end
