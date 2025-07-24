# frozen_string_literal: true

require "test_helper"

class Api::V1::LocationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    # Create events with different locations for testing
    Event.create!(
      name: "UFC 309: Jones vs Miocic",
      date: "2024-11-16",
      location: "Las Vegas, Nevada"
    )
    Event.create!(
      name: "UFC 308: Topuria vs Holloway",
      date: "2024-10-26",
      location: "Abu Dhabi, United Arab Emirates"
    )
    Event.create!(
      name: "UFC 200: Tate vs Nunes",
      date: "2016-07-09",
      location: "Las Vegas, Nevada"
    )
    Event.create!(
      name: "UFC 204: Bisping vs Henderson",
      date: "2016-10-08",
      location: "Manchester, England"
    )
    # Create event with special characters
    Event.create!(
      name: "UFC Special Event",
      date: "2024-12-01",
      location: "São Paulo, Brazil"
    )
  end

  test "GET index returns unique locations alphabetically" do
    get "/api/v1/locations"

    assert_response :success
    assert_equal "application/json; charset=utf-8", response.content_type

    json_response = response.parsed_body
    assert_not_nil json_response["locations"]

    locations = json_response["locations"]
    expected_locations = [
      "Abu Dhabi, United Arab Emirates",
      "Las Vegas, Nevada",
      "Manchester, England",
      "São Paulo, Brazil"
    ]

    assert_equal expected_locations, locations
  end

  test "GET index excludes null/empty locations" do
    # Create event with nil location (should be excluded by validation)
    # Create event with empty location (should be excluded)
    event_with_empty = Event.new(
      name: "UFC Empty Location",
      date: "2024-12-15",
      location: ""
    )
    # Skip validation to test the exclusion logic
    event_with_empty.save(validate: false)

    get "/api/v1/locations"

    assert_response :success
    locations = response.parsed_body["locations"]

    # Should not include empty string
    assert_not_includes locations, ""
    assert_not_includes locations, nil
  end

  test "GET index returns proper JSON structure" do
    get "/api/v1/locations"

    assert_response :success
    json_response = response.parsed_body

    # Should have locations key
    assert_includes json_response, "locations"

    # Locations should be an array
    assert_instance_of Array, json_response["locations"]

    # Each location should be a string
    json_response["locations"].each do |location|
      assert_instance_of String, location
    end
  end

  test "GET index handles empty database" do
    # Delete all events
    Event.delete_all

    get "/api/v1/locations"

    assert_response :success
    json_response = response.parsed_body

    assert_equal [], json_response["locations"]
  end

  test "GET index handles special characters correctly" do
    get "/api/v1/locations"

    assert_response :success
    locations = response.parsed_body["locations"]

    # Should include the special character location
    assert_includes locations, "São Paulo, Brazil"
  end

  test "GET index removes duplicate locations" do
    # Las Vegas appears twice in our test data
    get "/api/v1/locations"

    assert_response :success
    locations = response.parsed_body["locations"]

    # Should only appear once
    vegas_count = locations.count("Las Vegas, Nevada")
    assert_equal 1, vegas_count
  end
end
