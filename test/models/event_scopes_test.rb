# frozen_string_literal: true

require "test_helper"

class EventScopesTest < ActiveSupport::TestCase
  def setup
    # Create test events with different dates and locations
    @event_vegas_recent = Event.create!(
      name: "UFC 309: Jones vs Miocic",
      date: "2024-11-16",
      location: "Las Vegas, Nevada"
    )
    @event_vegas_older = Event.create!(
      name: "UFC 200: Tate vs Nunes",
      date: "2016-07-09",
      location: "Las Vegas, Nevada"
    )
    @event_london = Event.create!(
      name: "UFC 204: Bisping vs Henderson",
      date: "2016-10-08",
      location: "Manchester, England"
    )
    @event_future = Event.create!(
      name: "UFC 310: Future Event",
      date: "2025-01-01",
      location: "New York, New York"
    )

    # Create fights for testing fight_count
    @fight1 = Fight.create!(
      event: @event_vegas_recent,
      bout: "Jon Jones vs Stipe Miocic",
      outcome: "W/L",
      weight_class: "Heavyweight",
      method: "TKO",
      round: 3,
      time: "4:29",
      referee: "Herb Dean"
    )
    @fight2 = Fight.create!(
      event: @event_vegas_recent,
      bout: "Charles Oliveira vs Michael Chandler",
      outcome: "W/L",
      weight_class: "Lightweight",
      method: "Submission",
      round: 1,
      time: "3:31",
      referee: "Marc Goddard"
    )
  end

  # by_location scope tests
  test "by_location scope filters by exact location match" do
    vegas_events = Event.by_location("Las Vegas, Nevada")

    assert_includes vegas_events, @event_vegas_recent
    assert_includes vegas_events, @event_vegas_older
    assert_not_includes vegas_events, @event_london
    assert_not_includes vegas_events, @event_future
  end

  test "by_location scope returns empty for non-existent location" do
    result = Event.by_location("Non-existent Location")

    assert_empty result
  end

  test "by_location scope returns all events when location is nil" do
    all_events = Event.by_location(nil)

    assert_equal Event.count, all_events.count
    assert_includes all_events, @event_vegas_recent
    assert_includes all_events, @event_london
  end

  test "by_location scope returns all events when location is empty string" do
    all_events = Event.by_location("")

    assert_equal Event.count, all_events.count
  end

  # chronological scope tests
  test "chronological scope orders events by date ASC" do
    events = Event.chronological

    assert_equal @event_vegas_older, events.first
    assert_equal @event_future, events.last
  end

  # reverse_chronological scope tests
  test "reverse_chronological scope orders events by date DESC" do
    events = Event.reverse_chronological

    assert_equal @event_future, events.first
    assert_equal @event_vegas_older, events.last
  end

  # fight_count method tests
  test "fight_count returns correct number of associated fights" do
    assert_equal 2, @event_vegas_recent.fight_count
    assert_equal 0, @event_london.fight_count
  end

  # main_event method tests
  test "main_event returns name of main event fight" do
    # Create fights with different bout orders
    Fight.create!(
      event: @event_london,
      bout: "Michael Bisping vs Dan Henderson",
      outcome: "W/L",
      weight_class: "Middleweight",
      method: "Decision",
      round: 5,
      time: "5:00",
      referee: "Herb Dean"
    )
    Fight.create!(
      event: @event_london,
      bout: "Prelim Fight: Fighter A vs Fighter B",
      outcome: "W/L",
      weight_class: "Welterweight",
      method: "TKO",
      round: 2,
      time: "2:15",
      referee: "John McCarthy"
    )

    # The first fight created should be the main event
    expected_main_event = "Michael Bisping vs Dan Henderson"
    assert_equal expected_main_event, @event_london.main_event
  end

  test "main_event returns nil when no fights exist" do
    empty_event = Event.create!(
      name: "Empty Event",
      date: "2024-12-01",
      location: "Test Location"
    )

    assert_nil empty_event.main_event
  end

  # Combined scope tests
  test "scopes can be chained together" do
    vegas_events_desc = Event.by_location("Las Vegas, Nevada")
                             .reverse_chronological

    assert_equal @event_vegas_recent, vegas_events_desc.first
    assert_equal @event_vegas_older, vegas_events_desc.last
  end

  test "scopes work with includes for eager loading" do
    events_with_fights = Event.by_location("Las Vegas, Nevada")
                              .includes(:fights)
                              .reverse_chronological

    # Should not trigger N+1 queries when accessing fights
    assert_equal 2, events_with_fights.first.fights.length
  end
end
