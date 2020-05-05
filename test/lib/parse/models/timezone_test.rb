require_relative "../../../test_helper"

class MyTestTimeZone < Parse::Object; end

class TestTimeZone < Minitest::Test
  def setup
    @la = "America/Los_Angeles"
    @paris = "Europe/Paris"
    @chicago = "America/Chicago"
  end

  def test_property_definition
    assert_nil MyTestTimeZone.fields[:timezone]
    MyTestTimeZone.property :time_zone, :timezone
    refute_nil MyTestTimeZone.fields[:time_zone]
    refute_nil MyTestTimeZone.fields[:timeZone]
    assert_equal MyTestTimeZone.fields[:time_zone], :timezone
    assert_equal MyTestTimeZone.fields[:timeZone], :timezone
    assert_equal MyTestTimeZone.attributes[:timeZone], :timezone
  end

  def test_activesupport_method_forwarding
    as_methods = ActiveSupport::TimeZone.public_instance_methods(false)
    ps_methods = Parse::TimeZone.public_instance_methods(false)
    assert_empty(as_methods - ps_methods)
  end

  def test_creation
    as_tz = ActiveSupport::TimeZone.new @la
    tz = Parse::TimeZone.new @la
    assert_equal tz.name, @la
    assert_equal tz.zone.name, as_tz.name
    assert_equal tz.zone, as_tz

    assert_raises(ArgumentError) { tz.name = 234234 }
    assert_raises(ArgumentError) { tz.name = DateTime.now }
    refute_raises(ArgumentError) { tz.name = @paris }
    assert_equal tz.name, @paris
    assert_equal tz.zone, ActiveSupport::TimeZone.new(@paris)
    refute_raises(ArgumentError) { tz.zone = @chicago }
    assert_equal tz.name, @chicago
    refute_raises(ArgumentError) { tz.zone = Parse::TimeZone.new(@la) }
    assert_equal tz.name, @la

    as_tz = ActiveSupport::TimeZone.new @paris
    refute_raises(ArgumentError) { tz.zone = as_tz }
    assert_equal tz.formatted_offset, as_tz.formatted_offset
  end

  def test_validation
    tz = Parse::TimeZone.new @la
    assert tz.valid?
    tz = Parse::TimeZone.new "Galaxy/Andromeda"
    refute tz.valid?
    tz.name = @chicago
    assert tz.valid?
  end

  def test_encoding
    tz = Parse::TimeZone.new @la
    assert_equal tz.name, tz.as_json
    assert_equal tz.name, tz.to_s
  end
end
