# frozen_string_literal: true

require "test_helper"

class Api::V1::EventsControllerTest < ActionDispatch::IntegrationTest
  def setup
    # Create test events for comprehensive testing
    @event1 = Event.create!(
      name: "UFC 309: Jones vs Miocic",
      date: "2024-11-16",
      location: "Las Vegas, Nevada"
    )
    @event2 = Event.create!(
      name: "UFC 308: Topuria vs Holloway",
      date: "2024-10-26",
      location: "Abu Dhabi, United Arab Emirates"
    )
    @event3 = Event.create!(
      name: "UFC 200: Tate vs Nunes",
      date: "2016-07-09",
      location: "Las Vegas, Nevada"
    )
    @event4 = Event.create!(
      name: "UFC 204: Bisping vs Henderson",
      date: "2016-10-08",
      location: "Manchester, England"
    )

    # Create fights for testing fight_count
    2.times do |i|
      Fight.create!(
        event: @event1,
        bout: "Fight #{i + 1}",
        outcome: "W/L",
        weight_class: "Heavyweight",
        method: "TKO",
        round: 1,
        time: "2:30",
        referee: "Herb Dean"
      )
    end

    3.times do |i|
      Fight.create!(
        event: @event2,
        bout: "Fight #{i + 1}",
        outcome: "W/L",
        weight_class: "Featherweight",
        method: "Decision",
        round: 3,
        time: "5:00",
        referee: "Marc Goddard"
      )
    end
  end

  # Basic functionality tests
  test "GET index returns all events with basic structure" do
    get "/api/v1/events"

    assert_response :success
    assert_equal "application/json; charset=utf-8", response.content_type

    json_response = response.parsed_body
    assert_not_nil json_response["events"]
    assert_not_nil json_response["meta"]

    events = json_response["events"]
    assert_equal 4, events.length

    # Check event structure
    event = events.first
    assert_not_nil event["id"]
    assert_not_nil event["name"]
    assert_not_nil event["date"]
    assert_not_nil event["location"]
    assert_not_nil event["fight_count"]
  end

  test "GET index returns events ordered by date DESC by default" do
    get "/api/v1/events"

    assert_response :success
    events = response.parsed_body["events"]

    # Should be newest first
    assert_equal @event1.name, events[0]["name"]
    assert_equal @event2.name, events[1]["name"]
    assert_equal @event4.name, events[2]["name"]
    assert_equal @event3.name, events[3]["name"]
  end

  test "GET index includes fight count for each event" do
    get "/api/v1/events"

    assert_response :success
    events = response.parsed_body["events"]

    event1_data = events.find { |e| e["id"] == @event1.id }
    event2_data = events.find { |e| e["id"] == @event2.id }
    event3_data = events.find { |e| e["id"] == @event3.id }

    assert_equal 2, event1_data["fight_count"]
    assert_equal 3, event2_data["fight_count"]
    assert_equal 0, event3_data["fight_count"]
  end

  test "GET index returns proper JSON content type" do
    get "/api/v1/events"

    assert_response :success
    assert_equal "application/json; charset=utf-8", response.content_type
  end

  # Pagination tests
  test "GET index respects per_page parameter" do
    get "/api/v1/events", params: { per_page: 2 }

    assert_response :success
    events = response.parsed_body["events"]
    meta = response.parsed_body["meta"]

    assert_equal 2, events.length
    assert_equal 2, meta["per_page"]
  end

  test "GET index defaults to 20 events per page" do
    get "/api/v1/events"

    assert_response :success
    meta = response.parsed_body["meta"]

    assert_equal 20, meta["per_page"]
  end

  test "GET index returns pagination metadata" do
    get "/api/v1/events", params: { per_page: 2 }

    assert_response :success
    meta = response.parsed_body["meta"]

    assert_equal 1, meta["current_page"]
    assert_equal 2, meta["total_pages"]
    assert_equal 4, meta["total_count"]
    assert_equal 2, meta["per_page"]
  end

  test "GET index handles page parameter correctly" do
    get "/api/v1/events", params: { per_page: 2, page: 2 }

    assert_response :success
    events = response.parsed_body["events"]
    meta = response.parsed_body["meta"]

    assert_equal 2, events.length
    assert_equal 2, meta["current_page"]

    # Should contain the 3rd and 4th events (sorted by date desc)
    assert_equal @event4.name, events[0]["name"]
    assert_equal @event3.name, events[1]["name"]
  end

  test "GET index limits per_page to maximum of 100" do
    get "/api/v1/events", params: { per_page: 150 }

    assert_response :success
    meta = response.parsed_body["meta"]

    assert_equal 100, meta["per_page"]
  end

  # Location filtering tests
  test "GET index filters by exact location match" do
    get "/api/v1/events", params: { location: "Las Vegas, Nevada" }

    assert_response :success
    events = response.parsed_body["events"]

    assert_equal 2, events.length
    vegas_event_names = events.map { |e| e["name"] }
    assert_includes vegas_event_names, @event1.name
    assert_includes vegas_event_names, @event3.name
    assert_not_includes vegas_event_names, @event2.name
    assert_not_includes vegas_event_names, @event4.name
  end

  test "GET index returns empty array for non-existent location" do
    get "/api/v1/events", params: { location: "Non-existent Location" }

    assert_response :success
    events = response.parsed_body["events"]
    meta = response.parsed_body["meta"]

    assert_empty events
    assert_equal 0, meta["total_count"]
  end

  test "GET index ignores location filter when nil" do
    get "/api/v1/events", params: { location: nil }

    assert_response :success
    events = response.parsed_body["events"]

    assert_equal 4, events.length
  end

  test "GET index handles location with special characters" do
    special_event = Event.create!(
      name: "UFC Special: Test Event",
      date: "2024-12-01",
      location: "São Paulo, Brazil (Special Chars: àáâãäå)"
    )

    get "/api/v1/events",
        params: { location: "São Paulo, Brazil (Special Chars: àáâãäå)" }

    assert_response :success
    events = response.parsed_body["events"]

    assert_equal 1, events.length
    assert_equal special_event.name, events.first["name"]
  end

  # Sorting tests
  test "GET index sorts by date ASC when sort_direction=asc" do
    get "/api/v1/events", params: { sort_direction: "asc" }

    assert_response :success
    events = response.parsed_body["events"]

    # Should be oldest first
    assert_equal @event3.name, events[0]["name"]
    assert_equal @event4.name, events[1]["name"]
    assert_equal @event2.name, events[2]["name"]
    assert_equal @event1.name, events[3]["name"]
  end

  test "GET index sorts by date DESC when sort_direction=desc" do
    get "/api/v1/events", params: { sort_direction: "desc" }

    assert_response :success
    events = response.parsed_body["events"]

    # Should be newest first (same as default)
    assert_equal @event1.name, events[0]["name"]
    assert_equal @event2.name, events[1]["name"]
    assert_equal @event4.name, events[2]["name"]
    assert_equal @event3.name, events[3]["name"]
  end

  test "GET index defaults to DESC when sort_direction invalid" do
    get "/api/v1/events", params: { sort_direction: "invalid" }

    assert_response :success
    events = response.parsed_body["events"]

    # Should default to newest first
    assert_equal @event1.name, events[0]["name"]
  end

  # Error handling tests
  test "GET index handles invalid page numbers gracefully" do
    get "/api/v1/events", params: { page: -1 }

    assert_response :success
    meta = response.parsed_body["meta"]

    # Should default to page 1
    assert_equal 1, meta["current_page"]
  end

  test "GET index handles malformed parameters" do
    get "/api/v1/events", params: { per_page: "invalid" }

    assert_response :success
    meta = response.parsed_body["meta"]

    # Should use default per_page
    assert_equal 20, meta["per_page"]
  end

  # Combined filtering and sorting tests
  test "GET index applies location filter with sorting" do
    get "/api/v1/events",
        params: {
          location: "Las Vegas, Nevada",
          sort_direction: "asc"
        }

    assert_response :success
    events = response.parsed_body["events"]

    assert_equal 2, events.length
    # Should be oldest Vegas event first
    assert_equal @event3.name, events[0]["name"]
    assert_equal @event1.name, events[1]["name"]
  end

  test "GET index applies location filter with pagination" do
    get "/api/v1/events",
        params: {
          location: "Las Vegas, Nevada",
          per_page: 1,
          page: 1
        }

    assert_response :success
    events = response.parsed_body["events"]
    meta = response.parsed_body["meta"]

    assert_equal 1, events.length
    assert_equal 2, meta["total_count"]
    assert_equal 2, meta["total_pages"]
  end
end
