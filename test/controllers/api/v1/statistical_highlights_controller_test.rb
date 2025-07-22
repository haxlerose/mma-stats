# frozen_string_literal: true

require "test_helper"

class Api::V1::StatisticalHighlightsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @event = Event.create!(
      name: "UFC 300: Statistical Test",
      date: "2024-04-13",
      location: "Las Vegas, Nevada"
    )

    @striker = Fighter.create!(
      name: "High Volume Striker",
      height_in_inches: 72,
      reach_in_inches: 74,
      birth_date: "1990-01-01"
    )

    @grappler = Fighter.create!(
      name: "Submission Specialist",
      height_in_inches: 70,
      reach_in_inches: 70,
      birth_date: "1988-02-02"
    )

    # Create comprehensive test data
    create_statistical_test_data
  end

  test "GET index returns statistical highlights" do
    get "/api/v1/statistical_highlights"

    assert_response :success
    assert_equal "application/json; charset=utf-8", response.content_type

    json_response = response.parsed_body

    assert_not_nil json_response["highlights"]
    assert_equal 4, json_response["highlights"].length

    categories = json_response["highlights"].map { |h| h["category"] }
    expected_categories = %w[
      strikes_per_15min
      submission_attempts_per_15min
      takedowns_per_15min
      knockdowns_per_15min
    ]

    assert_equal expected_categories.sort, categories.sort
  end

  test "GET index returns correct highlight structure" do
    get "/api/v1/statistical_highlights"

    assert_response :success

    json_response = response.parsed_body
    highlight = json_response["highlights"].first

    assert_not_nil highlight["category"]
    assert_not_nil highlight["value"]

    if highlight["fighter"]
      assert_not_nil highlight["fighter"]["id"]
      assert_not_nil highlight["fighter"]["name"]
      # Optional fields may be nil
      assert highlight["fighter"].key?("height_in_inches")
      assert highlight["fighter"].key?("reach_in_inches")
      assert highlight["fighter"].key?("birth_date")
    end
  end

  test "GET index handles no qualifying fighters gracefully" do
    # Clear all test data
    FightStat.delete_all
    Fight.delete_all
    Fighter.delete_all

    get "/api/v1/statistical_highlights"

    assert_response :success

    json_response = response.parsed_body

    assert_equal 4, json_response["highlights"].length
    json_response["highlights"].each do |highlight|
      assert_nil highlight["fighter"]
      assert_equal 0, highlight["value"]
    end
  end

  test "GET index includes fighters meeting minimums only" do
    get "/api/v1/statistical_highlights"

    assert_response :success

    json_response = response.parsed_body
    strikes_highlight = json_response["highlights"]
                        .find { |h| h["category"] == "strikes_per_15min" }

    # Should find a leader if our test data meets minimums
    if strikes_highlight["fighter"]
      assert_operator strikes_highlight["value"], :>, 0
      assert_not_nil strikes_highlight["fighter"]["name"]
    end
  end

  test "GET index returns proper JSON content type" do
    get "/api/v1/statistical_highlights"

    assert_response :success
    assert_equal "application/json; charset=utf-8", response.content_type

    json_response = response.parsed_body
    assert_not_nil json_response["highlights"]
  end

  private

  def create_statistical_test_data
    # Create fights and stats to meet minimum requirements
    create_high_volume_striker_data(@striker)
    create_submission_specialist_data(@grappler)
  end

  def create_high_volume_striker_data(fighter)
    # Create 5 fights with high volume to meet minimums
    5.times do |i|
      fight = Fight.create!(
        event: @event,
        bout: "#{fighter.name} vs Opponent #{i}",
        outcome: "W/L",
        weight_class: "Heavyweight",
        method: "Decision",
        round: 3,
        time: "5:00",
        referee: "Herb Dean"
      )

      # Create stats for 3 rounds with high volume
      3.times do |round|
        FightStat.create!(
          fight: fight,
          fighter: fighter,
          round: round + 1,
          significant_strikes: 25, # 125 per fight × 5 fights = 625 total
          significant_strikes_attempted: 30, # 150 per fight × 5 = 750 total
          total_strikes: 35,
          total_strikes_attempted: 40,
          takedowns: 1,
          takedowns_attempted: 2,
          submission_attempts: 0,
          knockdowns: 0,
          head_strikes: 15,
          head_strikes_attempted: 18,
          body_strikes: 6,
          body_strikes_attempted: 8,
          leg_strikes: 4,
          leg_strikes_attempted: 4,
          distance_strikes: 20,
          distance_strikes_attempted: 25,
          clinch_strikes: 3,
          clinch_strikes_attempted: 3,
          ground_strikes: 2,
          ground_strikes_attempted: 2,
          reversals: 0,
          control_time_seconds: 30
        )
      end
    end
  end

  def create_submission_specialist_data(fighter)
    # Create 5 fights with submission attempts
    5.times do |i|
      fight = Fight.create!(
        event: @event,
        bout: "#{fighter.name} vs Opponent #{i}",
        outcome: "W/L",
        weight_class: "Lightweight",
        method: "Submission",
        round: 2,
        time: "3:45",
        referee: "Marc Goddard"
      )

      # Create stats for 2 rounds with submission attempts
      2.times do |round|
        FightStat.create!(
          fight: fight,
          fighter: fighter,
          round: round + 1,
          significant_strikes: 10,
          significant_strikes_attempted: 15,
          total_strikes: 12,
          total_strikes_attempted: 18,
          takedowns: 2,
          takedowns_attempted: 3, # Total: 30 attempts (meets 20 minimum)
          submission_attempts: 2, # High submission rate
          knockdowns: 0,
          head_strikes: 6,
          head_strikes_attempted: 9,
          body_strikes: 3,
          body_strikes_attempted: 4,
          leg_strikes: 1,
          leg_strikes_attempted: 2,
          distance_strikes: 5,
          distance_strikes_attempted: 8,
          clinch_strikes: 3,
          clinch_strikes_attempted: 4,
          ground_strikes: 4,
          ground_strikes_attempted: 5,
          reversals: 1,
          control_time_seconds: 120
        )
      end
    end
  end
end
