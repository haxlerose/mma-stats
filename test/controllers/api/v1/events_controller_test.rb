# frozen_string_literal: true

require "test_helper"

class Api::V1::EventsControllerTest < ActionDispatch::IntegrationTest
  test "should get events index" do
    get api_v1_events_url
    assert_response :success
  end

  test "should return events ordered by date descending" do
    # Create events with different dates
    Event.create!(
      name: "UFC 298",
      date: Date.new(2024, 2, 17),
      location: "Anaheim, CA"
    )
    Event.create!(
      name: "UFC 299",
      date: Date.new(2024, 3, 9),
      location: "Miami, FL"
    )

    get api_v1_events_url
    response_data = response.parsed_body
    events = response_data["events"]

    # First event should be the newer one (most recent first)
    assert_equal "UFC 299", events.first["name"]
    assert_equal "UFC 298", events.last["name"]
  end

  test "should return events with correct JSON structure" do
    event = Event.create!(
      name: "UFC 300",
      date: Date.new(2024, 4, 13),
      location: "Las Vegas, NV"
    )

    get api_v1_events_url
    response_data = response.parsed_body
    events = response_data["events"]
    first_event = events.first

    # Test that each event has the expected structure
    assert_includes first_event, "id"
    assert_includes first_event, "name"
    assert_includes first_event, "date"
    assert_includes first_event, "location"

    # Test that values are correct
    assert_equal event.id, first_event["id"]
    assert_equal "UFC 300", first_event["name"]
    assert_equal "2024-04-13", first_event["date"]
    assert_equal "Las Vegas, NV", first_event["location"]

    # Test that we don't include timestamps in the API response
    assert_not_includes first_event, "created_at"
    assert_not_includes first_event, "updated_at"
  end

  test "should get single event" do
    event = Event.create!(
      name: "UFC 301",
      date: Date.new(2024, 5, 4),
      location: "Rio de Janeiro, Brazil"
    )

    get api_v1_event_url(event)
    assert_response :success
  end

  test "should include associated fights in event response" do
    event = Event.create!(
      name: "UFC 302",
      date: Date.new(2024, 6, 1),
      location: "Newark, NJ"
    )

    fight1 = Fight.create!(
      event: event,
      bout: "Fighter A vs Fighter B",
      outcome: "Fighter A wins",
      weight_class: "Lightweight"
    )

    Fight.create!(
      event: event,
      bout: "Fighter C vs Fighter D",
      outcome: "Fighter D wins",
      weight_class: "Welterweight"
    )

    get api_v1_event_url(event)
    response_data = response.parsed_body
    event_data = response_data["event"]

    # Test that event includes fights
    assert_includes event_data, "fights"
    fights = event_data["fights"]
    assert_equal 2, fights.length

    # Test fight structure
    first_fight = fights.first
    assert_includes first_fight, "id"
    assert_includes first_fight, "bout"
    assert_includes first_fight, "outcome"
    assert_includes first_fight, "weight_class"

    # Test fight values
    assert_equal fight1.id, first_fight["id"]
    assert_equal "Fighter A vs Fighter B", first_fight["bout"]
    assert_equal "Fighter A wins", first_fight["outcome"]
    assert_equal "Lightweight", first_fight["weight_class"]
  end

  test "should return 404 for non-existent event" do
    get api_v1_event_url(99_999)
    assert_response :not_found
  end
end
