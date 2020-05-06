require_relative "../../../../test_helper"

class TestWithinPolygonQueryConstraint < Minitest::Test
  extend Minitest::Spec::DSL
  include ConstraintTests

  def setup
    @klass = Parse::Constraint::WithinPolygonQueryConstraint
    @key = :$geoWithin
    @operand = :within_polygon
    @keys = [:within_polygon]
    @skip_scalar_values_test = true

    @bermuda = Parse::GeoPoint.new 32.3078000, -64.7504999 # Bermuda
    @miami = Parse::GeoPoint.new 25.7823198, -80.2660226 # Miami, FL
    @san_juan = Parse::GeoPoint.new 18.3848232, -66.0933608 # San Juan, PR
    @san_diego = Parse::GeoPoint.new 32.9201332, -117.1088263
  end

  def build(value)
    { "field" => { @key => { :$polygon => value } } }
  end

  def test_argument_error
    triangle = [@bermuda, @miami] # missing one
    assert_raises(ArgumentError) { User.query(:location.within_polygon => nil).compile }
    assert_raises(ArgumentError) { User.query(:location.within_polygon => []).compile }
    assert_raises(ArgumentError) { User.query(:location.within_polygon => [@bermuda, 2343]).compile }
    assert_raises(ArgumentError) { User.query(:location.within_polygon => triangle).compile }
    triangle.push @san_juan
    refute_raises(ArgumentError) { User.query(:location.within_polygon => triangle).compile }
    quad = triangle + [@san_diego]
    refute_raises(ArgumentError) { User.query(:location.within_polygon => quad).compile }
  end

  def test_compiled_query
    triangle = [@bermuda, @miami, @san_juan]
    compiled_query = { "location" => { "$geoWithin" => { "$polygon" => [
      { :__type => "GeoPoint", :latitude => 32.3078, :longitude => -64.7504999 },
      { :__type => "GeoPoint", :latitude => 25.7823198, :longitude => -80.2660226 },
      { :__type => "GeoPoint", :latitude => 18.3848232, :longitude => -66.0933608 },
    ] } } }
    query = User.query(:location.within_polygon => [@bermuda, @miami, @san_juan])
    assert_equal query.compile_where.as_json, compiled_query.as_json

    compiled_query = { "location" => { "$geoWithin" => { "$polygon" => [
      { :__type => "GeoPoint", :latitude => 32.9201332, :longitude => -117.1088263 },
      { :__type => "GeoPoint", :latitude => 25.7823198, :longitude => -80.2660226 },
      { :__type => "GeoPoint", :latitude => 18.3848232, :longitude => -66.0933608 },
      { :__type => "GeoPoint", :latitude => 32.3078, :longitude => -64.7504999 },
    ] } } }
    query = User.query(:location.within_polygon => [@san_diego, @miami, @san_juan, @bermuda])
    assert_equal query.compile_where.as_json, compiled_query.as_json
  end
end
