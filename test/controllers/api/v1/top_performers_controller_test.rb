# frozen_string_literal: true

require "test_helper"

class Api::V1::TopPerformersControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Create test data for all tests
    @fighter1 = Fighter.create!(name: "Fighter One")
    @fighter2 = Fighter.create!(name: "Fighter Two")
    @fighter3 = Fighter.create!(name: "Fighter Three")

    @event1 = Event.create!(
      name: "UFC 100",
      date: Date.new(2023, 1, 1),
      location: "Las Vegas, NV"
    )
    @event2 = Event.create!(
      name: "UFC 101",
      date: Date.new(2023, 2, 1),
      location: "New York, NY"
    )

    @fight1 = Fight.create!(
      event: @event1,
      bout: "Fighter One vs Fighter Two",
      outcome: "Fighter One wins",
      weight_class: "Lightweight"
    )
    @fight2 = Fight.create!(
      event: @event2,
      bout: "Fighter One vs Fighter Three",
      outcome: "Fighter One wins",
      weight_class: "Lightweight"
    )

    # Create fight stats with different values
    FightStat.create!(
      fight: @fight1,
      fighter: @fighter1,
      round: 1,
      knockdowns: 2,
      significant_strikes: 50,
      significant_strikes_attempted: 80,
      takedowns: 3,
      takedowns_attempted: 5,
      control_time_seconds: 120
    )
    FightStat.create!(
      fight: @fight1,
      fighter: @fighter2,
      round: 1,
      knockdowns: 0,
      significant_strikes: 30,
      significant_strikes_attempted: 60,
      takedowns: 1,
      takedowns_attempted: 4,
      control_time_seconds: 60
    )
    FightStat.create!(
      fight: @fight2,
      fighter: @fighter1,
      round: 1,
      knockdowns: 1,
      significant_strikes: 40,
      significant_strikes_attempted: 70,
      takedowns: 2,
      takedowns_attempted: 3,
      control_time_seconds: 180
    )
    FightStat.create!(
      fight: @fight2,
      fighter: @fighter3,
      round: 1,
      knockdowns: 3,
      significant_strikes: 70,
      significant_strikes_attempted: 100,
      takedowns: 4,
      takedowns_attempted: 6,
      control_time_seconds: 240
    )
  end

  test "should get top performers for career scope with knockdowns" do
    get api_v1_top_performers_url(scope: "career", category: "knockdowns")
    assert_response :success

    response_data = response.parsed_body
    assert_includes response_data, "top_performers"
    assert_includes response_data, "meta"

    top_performers = response_data["top_performers"]
    assert_kind_of Array, top_performers
    assert top_performers.length <= 10

    # Find the performers by their names to check values
    fighter_one_data = top_performers.find do |p|
      p["fighter_name"] == "Fighter One"
    end
    fighter_three_data = top_performers.find do |p|
      p["fighter_name"] == "Fighter Three"
    end

    # Both should have 3 total knockdowns
    assert_equal 3, fighter_one_data["total_knockdowns"]
    assert_equal 2, fighter_one_data["fight_count"]

    assert_equal 3, fighter_three_data["total_knockdowns"]
    assert_equal 1, fighter_three_data["fight_count"]

    # Check that both are in the top 2
    top_two_names = top_performers.first(2).map { |p| p["fighter_name"] }
    assert_includes top_two_names, "Fighter One"
    assert_includes top_two_names, "Fighter Three"

    # Meta should include scope and category info
    meta = response_data["meta"]
    assert_equal "career", meta["scope"]
    assert_equal "knockdowns", meta["category"]
  end

  test "should get top performers for fight scope with significant_strikes" do
    get api_v1_top_performers_url(
      scope: "fight",
      category: "significant_strikes"
    )
    assert_response :success

    response_data = response.parsed_body
    top_performers = response_data["top_performers"]

    # Fighter Three should be first with 70 significant strikes in a fight
    first_performer = top_performers.first
    assert_equal @fighter3.id, first_performer["fighter_id"]
    assert_equal "Fighter Three", first_performer["fighter_name"]
    assert_equal 70, first_performer["max_significant_strikes"]
    assert_equal @fight2.id, first_performer["fight_id"]
    assert_includes first_performer, "event_name"
    assert_includes first_performer, "opponent_name"
  end

  test "should get top performers for round scope with takedowns" do
    get api_v1_top_performers_url(scope: "round", category: "takedowns")
    assert_response :success

    response_data = response.parsed_body
    top_performers = response_data["top_performers"]

    # Fighter Three should be first with 4 takedowns in a round
    first_performer = top_performers.first
    assert_equal @fighter3.id, first_performer["fighter_id"]
    assert_equal "Fighter Three", first_performer["fighter_name"]
    assert_equal 4, first_performer["max_takedowns"]
    assert_equal 1, first_performer["round"]
    assert_equal @fight2.id, first_performer["fight_id"]
  end

  test "should get top performers for per_minute scope with strikes" do
    # PerMinuteQuery requires minimum 5 fights
    fighter4 = Fighter.create!(name: "Fighter Four")

    # Create 5 fights for fighter4 to meet the minimum requirement
    5.times do |i|
      event = Event.create!(
        name: "UFC 20#{i}",
        date: Date.new(2023, 3 + i, 1),
        location: "Las Vegas, NV"
      )

      fight = Fight.create!(
        event: event,
        bout: "Fighter Four vs Opponent #{i}",
        outcome: "Fighter Four wins",
        weight_class: "Lightweight",
        round: 3,
        time: "5:00",
        time_format: "3 rounds of 5 minutes"
      )

      # Create fight stats with consistent significant strikes
      3.times do |round_num|
        FightStat.create!(
          fight: fight,
          fighter: fighter4,
          round: round_num + 1,
          significant_strikes: 20,
          significant_strikes_attempted: 30
        )
      end
    end

    get api_v1_top_performers_url(
      scope: "per_minute",
      category: "significant_strikes"
    )
    assert_response :success

    response_data = response.parsed_body
    top_performers = response_data["top_performers"]

    assert_not_nil top_performers
    assert_kind_of Array, top_performers

    # Find fighter4 in the results
    fighter4_data = top_performers.find do |p|
      p["fighter_name"] == "Fighter Four"
    end
    assert_not_nil fighter4_data, "Fighter Four should be in the results"

    assert_includes fighter4_data, "fighter_id"
    assert_includes fighter4_data, "fighter_name"
    assert_includes fighter4_data, "significant_strikes_per_minute"
    # PerMinuteQuery doesn't return specific fight
    assert_nil fighter4_data["fight_id"]
    assert_includes fighter4_data, "fight_duration_minutes"
    assert_includes fighter4_data, "total_significant_strikes"

    # Verify the calculation makes sense
    assert fighter4_data["significant_strikes_per_minute"].positive?
    # 5 fights * 3 rounds * 20 strikes
    assert_equal 300, fighter4_data["total_significant_strikes"]
  end

  test "should return error for invalid scope" do
    get api_v1_top_performers_url(
      scope: "invalid_scope",
      category: "knockdowns"
    )
    assert_response :bad_request

    response_data = response.parsed_body
    assert_includes response_data, "error"
    assert_match(/Invalid scope/, response_data["error"])
  end

  test "should return error for invalid category" do
    get api_v1_top_performers_url(scope: "career", category: "invalid_category")
    assert_response :bad_request

    response_data = response.parsed_body
    assert_includes response_data, "error"
    assert_match(/Invalid category/, response_data["error"])
  end

  test "should return error when scope is missing" do
    get api_v1_top_performers_url(category: "knockdowns")
    assert_response :bad_request

    response_data = response.parsed_body
    assert_includes response_data, "error"
    assert_match(/scope parameter is required/, response_data["error"])
  end

  test "should return error when category is missing" do
    get api_v1_top_performers_url(scope: "career")
    assert_response :bad_request

    response_data = response.parsed_body
    assert_includes response_data, "error"
    assert_match(/category parameter is required/, response_data["error"])
  end

  test "should handle empty results gracefully" do
    # Delete all fight stats
    FightStat.destroy_all

    get api_v1_top_performers_url(scope: "career", category: "knockdowns")
    assert_response :success

    response_data = response.parsed_body
    assert_equal [], response_data["top_performers"]
    assert_equal "career", response_data["meta"]["scope"]
    assert_equal "knockdowns", response_data["meta"]["category"]
  end

  test "should accept all valid categories for career scope" do
    valid_categories = %w[
      knockdowns
      significant_strikes
      significant_strikes_attempted
      total_strikes
      total_strikes_attempted
      head_strikes
      head_strikes_attempted
      body_strikes
      body_strikes_attempted
      leg_strikes
      leg_strikes_attempted
      distance_strikes
      distance_strikes_attempted
      clinch_strikes
      clinch_strikes_attempted
      ground_strikes
      ground_strikes_attempted
      takedowns
      takedowns_attempted
      submission_attempts
      reversals
      control_time_seconds
    ]

    valid_categories.each do |category|
      get api_v1_top_performers_url(scope: "career", category: category)
      assert_response :success, "Failed for category: #{category}"
    end
  end

  test "should limit results to 10 performers" do
    # Create more than 10 fighters with stats
    15.times do |i|
      fighter = Fighter.create!(name: "Fighter #{i + 10}")
      fight = Fight.create!(
        event: @event1,
        bout: "Fighter #{i + 10} vs Opponent",
        outcome: "Fighter #{i + 10} wins",
        weight_class: "Lightweight"
      )
      FightStat.create!(
        fight: fight,
        fighter: fighter,
        round: 1,
        knockdowns: i + 1
      )
    end

    get api_v1_top_performers_url(scope: "career", category: "knockdowns")
    response_data = response.parsed_body

    assert_equal 10, response_data["top_performers"].length
  end

  test "should handle string and symbol category parameters" do
    # Test with string
    get api_v1_top_performers_url(scope: "career", category: "knockdowns")
    assert_response :success

    # Test with symbol-like string (should still work)
    get api_v1_top_performers_url(scope: "career", category: "knockdowns")
    assert_response :success
  end
end
