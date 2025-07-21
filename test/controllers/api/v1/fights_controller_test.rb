# frozen_string_literal: true

require "test_helper"

class Api::V1::FightsControllerTest < ActionDispatch::IntegrationTest
  test "should get single fight" do
    event = Event.create!(
      name: "UFC 300",
      date: Date.new(2024, 4, 13),
      location: "Las Vegas, NV"
    )
    fight = Fight.create!(
      event: event,
      bout: "Fighter A vs Fighter B",
      outcome: "Fighter A wins",
      weight_class: "Lightweight"
    )

    get api_v1_fight_url(fight)
    assert_response :success
  end

  test "should return fight with correct JSON structure" do
    event = Event.create!(
      name: "UFC 301",
      date: Date.new(2024, 5, 4),
      location: "Rio de Janeiro, Brazil"
    )
    fight = Fight.create!(
      event: event,
      bout: "Jon Jones vs Stipe Miocic",
      outcome: "Jon Jones wins",
      weight_class: "Heavyweight",
      method: "TKO",
      round: 3,
      time: "4:29",
      referee: "Herb Dean"
    )

    get api_v1_fight_url(fight)
    response_data = response.parsed_body
    fight_data = response_data["fight"]

    # Test that fight has the expected basic structure
    assert_includes fight_data, "id"
    assert_includes fight_data, "bout"
    assert_includes fight_data, "outcome"
    assert_includes fight_data, "weight_class"
    assert_includes fight_data, "method"
    assert_includes fight_data, "round"
    assert_includes fight_data, "time"
    assert_includes fight_data, "referee"

    # Test that values are correct
    assert_equal fight.id, fight_data["id"]
    assert_equal "Jon Jones vs Stipe Miocic", fight_data["bout"]
    assert_equal "Jon Jones wins", fight_data["outcome"]
    assert_equal "Heavyweight", fight_data["weight_class"]
    assert_equal "TKO", fight_data["method"]
    assert_equal 3, fight_data["round"]
    assert_equal "4:29", fight_data["time"]
    assert_equal "Herb Dean", fight_data["referee"]

    # Test that we don't include timestamps in the API response
    assert_not_includes fight_data, "created_at"
    assert_not_includes fight_data, "updated_at"
  end

  test "should include event data in fight response" do
    event = Event.create!(
      name: "UFC 302",
      date: Date.new(2024, 6, 1),
      location: "Newark, NJ"
    )
    fight = Fight.create!(
      event: event,
      bout: "Islam Makhachev vs Dustin Poirier",
      outcome: "Islam Makhachev wins",
      weight_class: "Lightweight"
    )

    get api_v1_fight_url(fight)
    response_data = response.parsed_body
    fight_data = response_data["fight"]

    # Test that fight includes event data
    assert_includes fight_data, "event"
    event_data = fight_data["event"]

    assert_includes event_data, "id"
    assert_includes event_data, "name"
    assert_includes event_data, "date"
    assert_includes event_data, "location"

    assert_equal event.id, event_data["id"]
    assert_equal "UFC 302", event_data["name"]
    assert_equal "2024-06-01", event_data["date"]
    assert_equal "Newark, NJ", event_data["location"]
  end

  test "should include both fighters and fight stats in fight response" do
    # Create event
    event = Event.create!(
      name: "UFC 303",
      date: Date.new(2024, 7, 6),
      location: "Las Vegas, NV"
    )

    # Create fighters
    fighter1 = Fighter.create!(
      name: "Alex Pereira",
      height_in_inches: 76,
      reach_in_inches: 79
    )
    fighter2 = Fighter.create!(
      name: "Jiri Prochazka",
      height_in_inches: 75,
      reach_in_inches: 80
    )

    # Create fight
    fight = Fight.create!(
      event: event,
      bout: "Alex Pereira vs Jiri Prochazka",
      outcome: "Alex Pereira wins",
      weight_class: "Light Heavyweight"
    )

    # Create fight stats for both fighters
    FightStat.create!(
      fight: fight,
      fighter: fighter1,
      round: 1,
      significant_strikes: 12,
      significant_strikes_attempted: 18,
      takedowns: 0,
      takedowns_attempted: 0
    )
    FightStat.create!(
      fight: fight,
      fighter: fighter1,
      round: 2,
      significant_strikes: 8,
      significant_strikes_attempted: 15,
      takedowns: 1,
      takedowns_attempted: 2
    )
    FightStat.create!(
      fight: fight,
      fighter: fighter2,
      round: 1,
      significant_strikes: 15,
      significant_strikes_attempted: 22,
      takedowns: 2,
      takedowns_attempted: 3
    )
    FightStat.create!(
      fight: fight,
      fighter: fighter2,
      round: 2,
      significant_strikes: 5,
      significant_strikes_attempted: 10,
      takedowns: 0,
      takedowns_attempted: 1
    )

    get api_v1_fight_url(fight)
    response_data = response.parsed_body
    fight_data = response_data["fight"]

    # Test that fight includes fighters
    assert_includes fight_data, "fighters"
    fighters = fight_data["fighters"]
    assert_equal 2, fighters.length

    # Test fighter data structure
    alex_pereira = fighters.find { |f| f["name"] == "Alex Pereira" }
    jiri_prochazka = fighters.find { |f| f["name"] == "Jiri Prochazka" }

    assert_not_nil alex_pereira
    assert_not_nil jiri_prochazka

    assert_includes alex_pereira, "id"
    assert_includes alex_pereira, "name"
    assert_includes alex_pereira, "height_in_inches"
    assert_includes alex_pereira, "reach_in_inches"

    assert_equal fighter1.id, alex_pereira["id"]
    assert_equal 76, alex_pereira["height_in_inches"]
    assert_equal 79, alex_pereira["reach_in_inches"]

    # Test fight stats are included
    assert_includes fight_data, "fight_stats"
    fight_stats = fight_data["fight_stats"]
    assert_equal 4, fight_stats.length # 2 rounds × 2 fighters

    # Test fight stats structure includes fighter information
    alex_round_one = fight_stats.find do |s|
      s["fighter_id"] == fighter1.id && s["round"] == 1
    end
    assert_not_nil alex_round_one

    assert_includes alex_round_one, "fighter_id"
    assert_includes alex_round_one, "fighter_name"
    assert_includes alex_round_one, "round"
    assert_includes alex_round_one, "significant_strikes"
    assert_includes alex_round_one, "significant_strikes_attempted"
    assert_includes alex_round_one, "takedowns"
    assert_includes alex_round_one, "takedowns_attempted"

    assert_equal fighter1.id, alex_round_one["fighter_id"]
    assert_equal "Alex Pereira", alex_round_one["fighter_name"]
    assert_equal 1, alex_round_one["round"]
    assert_equal 12, alex_round_one["significant_strikes"]
    assert_equal 18, alex_round_one["significant_strikes_attempted"]
  end

  test "should return 404 for non-existent fight" do
    get api_v1_fight_url(99_999)
    assert_response :not_found
  end
end
