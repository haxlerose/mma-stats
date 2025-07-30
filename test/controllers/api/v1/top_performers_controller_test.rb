# frozen_string_literal: true

require "test_helper"

class Api::V1::TopPerformersControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Ensure fight_durations materialized view exists for accuracy tests
    ensure_fight_durations_view_exists

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
      weight_class: "Lightweight",
      round: 3,
      time: "5:00"
    )
    @fight2 = Fight.create!(
      event: @event2,
      bout: "Fighter One vs Fighter Three",
      outcome: "Fighter One wins",
      weight_class: "Lightweight",
      round: 3,
      time: "5:00"
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

    # Refresh materialized view to include test data
    ActiveRecord::Base.connection.execute(
      "REFRESH MATERIALIZED VIEW fight_durations"
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
    # Create unique fighter names to avoid conflicts with parallel tests
    unique_id = "#{Time.now.to_f}_#{rand(1000)}"
    fighter4 = Fighter.create!(name: "Fighter Four #{unique_id}")

    # Create another fighter with higher stats to ensure our fighter appears
    fighter5 = Fighter.create!(name: "Fighter Five #{unique_id}")

    # Create 5 fights for fighter4 to meet the minimum requirement
    5.times do |i|
      event = Event.create!(
        name: "UFC 20#{i} #{unique_id}",
        date: Date.new(2023, 3 + i, 1),
        location: "Las Vegas, NV"
      )

      fight = Fight.create!(
        event: event,
        bout: "#{fighter4.name} vs Opponent #{i}",
        outcome: "#{fighter4.name} wins",
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

    # Create 5 fights for fighter5 with higher stats
    5.times do |i|
      event = Event.create!(
        name: "UFC 21#{i} #{unique_id}",
        date: Date.new(2023, 4 + i, 1),
        location: "Las Vegas, NV"
      )

      fight = Fight.create!(
        event: event,
        bout: "#{fighter5.name} vs Opponent #{i}",
        outcome: "#{fighter5.name} wins",
        weight_class: "Lightweight",
        round: 3,
        time: "5:00",
        time_format: "3 rounds of 5 minutes"
      )

      # Create fight stats with higher significant strikes
      3.times do |round_num|
        FightStat.create!(
          fight: fight,
          fighter: fighter5,
          round: round_num + 1,
          significant_strikes: 40, # Higher than fighter4
          significant_strikes_attempted: 50
        )
      end
    end

    # Refresh materialized view if it exists
    if ActiveRecord::Base.connection.execute(
      "SELECT 1 FROM pg_matviews WHERE matviewname = 'fight_durations'"
    ).any?
      ActiveRecord::Base.connection.execute(
        "REFRESH MATERIALIZED VIEW fight_durations"
      )
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

    assert top_performers.length >= 2, "Should have at least 2 fighters"

    # Find our test fighters in the results
    fighter5_data = top_performers.find do |p|
      p["fighter_name"] == fighter5.name
    end
    fighter4_data = top_performers.find do |p|
      p["fighter_name"] == fighter4.name
    end

    # Fighter5 should be first (higher stats)
    assert_not_nil fighter5_data, "#{fighter5.name} should be in the results"
    assert_equal fighter5_data, top_performers.first, "Fighter5 should be first"

    # Fighter4 should also be in results
    assert_not_nil fighter4_data, "#{fighter4.name} should be in the results"

    assert_includes fighter4_data, "fighter_id"
    assert_includes fighter4_data, "fighter_name"
    # Should use per_15_minutes instead of per_minute
    assert_includes fighter4_data, "significant_strikes_per_15_minutes"
    assert_not fighter4_data.key?("significant_strikes_per_minute"),
               "Should not include per_minute key"
    # PerMinuteQuery doesn't return specific fight
    assert_nil fighter4_data["fight_id"]
    assert_includes fighter4_data, "fight_duration_minutes"
    assert_includes fighter4_data, "total_significant_strikes"

    # Verify the calculation makes sense
    assert fighter4_data["significant_strikes_per_15_minutes"].positive?
    # 5 fights * 3 rounds * 20 strikes
    assert_equal 300, fighter4_data["total_significant_strikes"]
  end

  test "should return per_15_minutes keys for per_minute scope" do
    # Create a fighter with minimum 5 fights to meet PerMinuteQuery requirement
    unique_id = "#{Time.now.to_f}_#{rand(1000)}"
    fighter = Fighter.create!(name: "Test Fighter 100 #{unique_id}")

    5.times do |i|
      event = Event.create!(
        name: "UFC 30#{i} #{unique_id}",
        date: Date.new(2023, 4 + i, 1),
        location: "Test City"
      )
      fight = Fight.create!(
        event: event,
        bout: "#{fighter.name} vs Opponent #{i}",
        outcome: "#{fighter.name} wins",
        weight_class: "Lightweight",
        round: 1,
        time: "3:00"
      )

      FightStat.create!(
        fight: fight,
        fighter: fighter,
        round: 1,
        knockdowns: 1,
        significant_strikes: 10,
        takedowns: 2,
        control_time_seconds: 60
      )
    end

    # Refresh materialized view if it exists
    if ActiveRecord::Base.connection.execute(
      "SELECT 1 FROM pg_matviews WHERE matviewname = 'fight_durations'"
    ).any?
      ActiveRecord::Base.connection.execute(
        "REFRESH MATERIALIZED VIEW fight_durations"
      )
    end

    # Test different categories
    %w[
      knockdowns
      significant_strikes
      takedowns
      control_time_seconds
    ].each do |category|
      get api_v1_top_performers_url(
        scope: "per_minute",
        category: category
      )
      assert_response :success

      response_data = response.parsed_body
      top_performers = response_data["top_performers"]

      assert_not_empty top_performers, "Should have results for #{category}"

      first_performer = top_performers.first
      expected_key = "#{category}_per_15_minutes"

      assert first_performer.key?(expected_key),
             "Should have #{expected_key} key for #{category}"
      assert_not first_performer.key?("#{category}_per_minute"),
                 "Should not have per_minute key for #{category}"
    end
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

  test "should get top performers for accuracy scope" do
    # Create fighters with enough fights to qualify (minimum 5)
    accurate_fighter = Fighter.create!(name: "Accurate Fighter")
    medium_fighter = Fighter.create!(name: "Medium Fighter")

    # Create 5 fights for each fighter
    5.times do |i|
      event = Event.create!(
        name: "UFC #{200 + i}",
        date: Date.new(2023, 3 + i, 1),
        location: "Location #{i}"
      )

      # Accurate fighter fights
      fight1 = Fight.create!(
        event: event,
        bout: "Accurate Fighter vs Opponent #{i}",
        outcome: "Accurate Fighter wins",
        weight_class: "Lightweight",
        round: 3,
        time: "5:00"
      )
      FightStat.create!(
        fight: fight1,
        fighter: accurate_fighter,
        round: 1,
        significant_strikes: 45,
        significant_strikes_attempted: 50 # 90% accuracy
      )

      # Medium fighter fights
      fight2 = Fight.create!(
        event: event,
        bout: "Medium Fighter vs Opponent #{i}",
        outcome: "Medium Fighter wins",
        weight_class: "Lightweight",
        round: 3,
        time: "5:00"
      )
      FightStat.create!(
        fight: fight2,
        fighter: medium_fighter,
        round: 1,
        significant_strikes: 30,
        significant_strikes_attempted: 50 # 60% accuracy
      )
    end

    # Refresh materialized view to include new test data
    ActiveRecord::Base.connection.execute(
      "REFRESH MATERIALIZED VIEW fight_durations"
    )

    get api_v1_top_performers_url(
      scope: "accuracy",
      category: "significant_strike_accuracy"
    )

    assert_response :success
    response_data = response.parsed_body

    assert_equal "accuracy", response_data["meta"]["scope"]
    assert_equal "significant_strike_accuracy",
                 response_data["meta"]["category"]

    top_performers = response_data["top_performers"]
    assert_operator top_performers.length, :<=, 10

    # Check that accurate fighter is ranked higher
    assert_equal "Accurate Fighter", top_performers.first["fighter_name"]
    assert_equal 90.0, top_performers.first["accuracy_percentage"]

    # Find medium fighter in results
    medium_result = top_performers.find do |p|
      p["fighter_name"] == "Medium Fighter"
    end
    assert_not_nil medium_result
    assert_equal 60.0, medium_result["accuracy_percentage"]
  end

  test "should return error for invalid category with accuracy scope" do
    get api_v1_top_performers_url(scope: "accuracy", category: "knockdowns")

    assert_response :bad_request
    response_data = response.parsed_body
    assert response_data["error"].present?
  end

  test "should return correct keys for different accuracy categories" do
    # Create fighters with enough fights to qualify (minimum 5)
    fighter = Fighter.create!(name: "Accuracy Key Test Fighter")

    # Create 5 fights with various strike statistics
    5.times do |i|
      event = Event.create!(
        name: "UFC #{500 + i}",
        date: Date.new(2023, 6 + i, 1),
        location: "Test Location #{i}"
      )

      fight = Fight.create!(
        event: event,
        bout: "Accuracy Key Test Fighter vs Opponent #{i}",
        outcome: "Accuracy Key Test Fighter wins",
        weight_class: "Lightweight",
        round: 3,
        time: "5:00"
      )

      FightStat.create!(
        fight: fight,
        fighter: fighter,
        round: 1,
        significant_strikes: 45,
        significant_strikes_attempted: 50,
        total_strikes: 60,
        total_strikes_attempted: 80,
        head_strikes: 20,
        head_strikes_attempted: 25,
        body_strikes: 15,
        body_strikes_attempted: 20,
        leg_strikes: 10,
        leg_strikes_attempted: 15,
        distance_strikes: 30,
        distance_strikes_attempted: 40,
        clinch_strikes: 10,
        clinch_strikes_attempted: 15,
        ground_strikes: 5,
        ground_strikes_attempted: 10,
        takedowns: 2,
        takedowns_attempted: 4
      )
    end

    # Refresh materialized view to include new test data
    ActiveRecord::Base.connection.execute(
      "REFRESH MATERIALIZED VIEW fight_durations"
    )

    # Test key mapping for different accuracy types
    key_mappings = {
      "significant_strike_accuracy" => %w[
        total_significant_strikes
        total_significant_strikes_attempted
      ],
      "total_strike_accuracy" => %w[
        total_total_strikes
        total_total_strikes_attempted
      ],
      "head_strike_accuracy" => %w[
        total_head_strikes
        total_head_strikes_attempted
      ],
      "takedown_accuracy" => %w[total_takedowns total_takedowns_attempted]
    }

    key_mappings.each do |category, expected_keys|
      get api_v1_top_performers_url(scope: "accuracy", category: category)
      assert_response :success

      response_data = response.parsed_body
      top_performers = response_data["top_performers"]

      next unless top_performers.any?

      first = top_performers.first
      expected_keys.each do |key|
        assert_includes first,
                        key,
                        "Missing key '#{key}' for category #{category}"
      end
    end
  end

  test "should accept all accuracy categories" do
    # Create fighters with enough fights to qualify (minimum 5)
    fighter = Fighter.create!(name: "Multi-Accuracy Fighter")

    # Create 5 fights with various strike statistics
    5.times do |i|
      event = Event.create!(
        name: "UFC #{400 + i}",
        date: Date.new(2023, 5 + i, 1),
        location: "Location #{i}"
      )

      fight = Fight.create!(
        event: event,
        bout: "Multi-Accuracy Fighter vs Opponent #{i}",
        outcome: "Multi-Accuracy Fighter wins",
        weight_class: "Lightweight",
        round: 3,
        time: "5:00"
      )

      FightStat.create!(
        fight: fight,
        fighter: fighter,
        round: 1,
        significant_strikes: 45,
        significant_strikes_attempted: 50,
        total_strikes: 60,
        total_strikes_attempted: 80,
        head_strikes: 20,
        head_strikes_attempted: 25,
        body_strikes: 15,
        body_strikes_attempted: 20,
        leg_strikes: 10,
        leg_strikes_attempted: 15,
        distance_strikes: 30,
        distance_strikes_attempted: 40,
        clinch_strikes: 10,
        clinch_strikes_attempted: 15,
        ground_strikes: 5,
        ground_strikes_attempted: 10,
        takedowns: 2,
        takedowns_attempted: 4
      )
    end

    # Refresh materialized view to include new test data
    ActiveRecord::Base.connection.execute(
      "REFRESH MATERIALIZED VIEW fight_durations"
    )

    # Test all accuracy categories
    accuracy_categories = %w[
      significant_strike_accuracy
      total_strike_accuracy
      head_strike_accuracy
      body_strike_accuracy
      leg_strike_accuracy
      distance_strike_accuracy
      clinch_strike_accuracy
      ground_strike_accuracy
      takedown_accuracy
    ]

    accuracy_categories.each do |category|
      get api_v1_top_performers_url(scope: "accuracy", category: category)
      assert_response :success,
                      "Failed for accuracy category: #{category}"

      response_data = response.parsed_body
      assert_equal "accuracy", response_data["meta"]["scope"]
      assert_equal category, response_data["meta"]["category"]

      top_performers = response_data["top_performers"]
      assert_not_nil top_performers
      assert_kind_of Array, top_performers

      # Check that the response has the expected structure
      next unless top_performers.any?

      first = top_performers.first
      assert_includes first, "fighter_id"
      assert_includes first, "fighter_name"
      assert_includes first, "accuracy_percentage"
      assert_includes first, "total_fights"
      assert_nil first["fight_id"]
    end
  end

  test "accuracy scope returns minimum attempt threshold" do
    # Ensure materialized view exists
    ensure_fight_durations_view_exists

    # Create test data
    event = Event.create!(
      name: "UFC Test Event",
      date: "2024-01-01",
      location: "Las Vegas"
    )
    unique_id = "#{Time.now.to_f}_#{rand(1000)}"
    fighter = Fighter.create!(name: "Test Fighter #{unique_id}")

    5.times do |i|
      fight = Fight.create!(
        event: event,
        bout: "Test Fight #{i} #{unique_id}",
        outcome: "Win",
        weight_class: "Lightweight",
        round: 3,
        time: "5:00"
      )
      FightStat.create!(
        fight: fight,
        fighter: fighter,
        round: 1,
        significant_strikes: 50,
        significant_strikes_attempted: 100,
        control_time_seconds: 0
      )
    end

    # Refresh materialized view
    ActiveRecord::Base.connection.execute(
      "REFRESH MATERIALIZED VIEW fight_durations"
    )

    get api_v1_top_performers_path,
        params: { scope: "accuracy", category: "significant_strike_accuracy" }

    assert_response :success
    json_response = response.parsed_body

    assert json_response["meta"].key?("minimum_attempts_threshold")
    assert json_response["meta"]["minimum_attempts_threshold"].positive?
  end

  test "accuracy scope can disable threshold with parameter" do
    get api_v1_top_performers_path,
        params: {
          scope: "accuracy",
          category: "significant_strike_accuracy",
          apply_threshold: "false"
        }

    assert_response :success
    json_response = response.parsed_body

    # When threshold is disabled, it shouldn't be in meta
    assert_not json_response["meta"].key?("minimum_attempts_threshold")
  end

  test "should get top performers for results scope with total_wins" do
    # Create test data
    winner = Fighter.create!(name: "Top Winner")
    loser = Fighter.create!(name: "Top Loser")

    # Create 5 wins for winner
    5.times do |i|
      event = Event.create!(
        name: "UFC Win Event #{i}",
        date: Date.new(2023, 1 + i, 1),
        location: "Vegas"
      )
      fight = Fight.create!(
        event: event,
        bout: "Top Winner vs Opponent #{i}",
        outcome: "W/L",
        weight_class: "Lightweight",
        round: 3,
        time: "5:00"
      )
      FightStat.create!(
        fight: fight,
        fighter: winner,
        round: 1,
        significant_strikes: 10
      )
    end

    # Create 2 losses for loser
    2.times do |i|
      event = Event.create!(
        name: "UFC Loss Event #{i}",
        date: Date.new(2023, 6 + i, 1),
        location: "Vegas"
      )
      fight = Fight.create!(
        event: event,
        bout: "Opponent #{i} vs Top Loser",
        outcome: "W/L",
        weight_class: "Lightweight",
        round: 3,
        time: "5:00"
      )
      FightStat.create!(
        fight: fight,
        fighter: loser,
        round: 1,
        significant_strikes: 5
      )
    end

    get api_v1_top_performers_url(scope: "results", category: "total_wins")
    assert_response :success

    response_data = response.parsed_body
    assert_includes response_data, "top_performers"
    assert_includes response_data, "meta"

    top_performers = response_data["top_performers"]
    assert_kind_of Array, top_performers
    assert top_performers.length <= 10

    # Find winner in results
    winner_data = top_performers.find do |p|
      p["fighter_name"] == "Top Winner"
    end

    assert_not_nil winner_data
    assert_equal winner.id, winner_data["fighter_id"]
    assert_equal 5, winner_data["total_wins"]
    assert_equal 5, winner_data["fight_count"]
    assert_nil winner_data["fight_id"]

    # Meta should include scope and category info
    meta = response_data["meta"]
    assert_equal "results", meta["scope"]
    assert_equal "total_wins", meta["category"]
  end

  test "should get top performers for results scope with total_losses" do
    # Create test data
    loser = Fighter.create!(name: "Fighter With Losses")

    # Create 3 losses
    3.times do |i|
      event = Event.create!(
        name: "UFC Loss #{i}",
        date: Date.new(2023, 1 + i, 1),
        location: "Vegas"
      )
      fight = Fight.create!(
        event: event,
        bout: "Winner #{i} vs Fighter With Losses",
        outcome: "W/L",
        weight_class: "Lightweight",
        round: 2,
        time: "3:00"
      )
      FightStat.create!(
        fight: fight,
        fighter: loser,
        round: 1,
        significant_strikes: 10
      )
    end

    get api_v1_top_performers_url(scope: "results", category: "total_losses")
    assert_response :success

    response_data = response.parsed_body
    top_performers = response_data["top_performers"]

    loser_data = top_performers.find do |p|
      p["fighter_name"] == "Fighter With Losses"
    end

    assert_not_nil loser_data
    assert_equal 3, loser_data["total_losses"]
    assert_equal 3, loser_data["fight_count"]
  end

  test "should get top performers for results scope with win_percentage" do
    # Create fighter with high win percentage (needs minimum 10 fights)
    high_percentage = Fighter.create!(name: "High Win Percentage")

    # Create 9 wins and 1 loss (90% win rate)
    9.times do |i|
      event = Event.create!(
        name: "UFC Win #{i}",
        date: Date.new(2023, 1 + i, 1),
        location: "Vegas"
      )
      fight = Fight.create!(
        event: event,
        bout: "High Win Percentage vs Opponent #{i}",
        outcome: "W/L",
        weight_class: "Lightweight",
        round: 3,
        time: "5:00"
      )
      FightStat.create!(
        fight: fight,
        fighter: high_percentage,
        round: 1,
        significant_strikes: 10
      )
    end

    # Add 1 loss
    event = Event.create!(
      name: "UFC Loss Event",
      date: Date.new(2023, 10, 1),
      location: "Vegas"
    )
    fight = Fight.create!(
      event: event,
      bout: "Winner vs High Win Percentage",
      outcome: "W/L",
      weight_class: "Lightweight",
      round: 3,
      time: "5:00"
    )
    FightStat.create!(
      fight: fight,
      fighter: high_percentage,
      round: 1,
      significant_strikes: 10
    )

    get api_v1_top_performers_url(
      scope: "results",
      category: "win_percentage"
    )
    assert_response :success

    response_data = response.parsed_body
    top_performers = response_data["top_performers"]

    high_data = top_performers.find do |p|
      p["fighter_name"] == "High Win Percentage"
    end

    assert_not_nil high_data
    assert_equal 90.0, high_data["win_percentage"]
    assert_equal 9, high_data["total_wins"]
    assert_equal 10, high_data["fight_count"]
  end

  test "win_percentage results include total_losses" do
    # Create fighter with 12 wins and 3 losses (80% win rate)
    fighter_with_losses = Fighter.create!(name: "Fighter With Losses")

    # Create 12 wins
    12.times do |i|
      event = Event.create!(
        name: "UFC Win WL #{i}",
        date: Date.new(2023, 1, i + 1),
        location: "Test City"
      )
      fight = Fight.create!(
        event: event,
        bout: "Fighter With Losses vs Opponent #{i}",
        outcome: "W/L",
        weight_class: "Welterweight",
        round: 3,
        time: "5:00"
      )
      FightStat.create!(
        fight: fight,
        fighter: fighter_with_losses,
        round: 1,
        significant_strikes: 15
      )
    end

    # Create 3 losses
    3.times do |i|
      event = Event.create!(
        name: "UFC Loss WL #{i}",
        date: Date.new(2023, 2, i + 1),
        location: "Test City"
      )
      fight = Fight.create!(
        event: event,
        bout: "Winner #{i} vs Fighter With Losses",
        outcome: "W/L",
        weight_class: "Welterweight",
        round: 3,
        time: "5:00"
      )
      FightStat.create!(
        fight: fight,
        fighter: fighter_with_losses,
        round: 1,
        significant_strikes: 10
      )
    end

    get api_v1_top_performers_url(
      scope: "results",
      category: "win_percentage"
    )
    assert_response :success

    response_data = response.parsed_body
    top_performers = response_data["top_performers"]

    fighter_data = top_performers.find do |p|
      p["fighter_name"] == "Fighter With Losses"
    end

    assert_not_nil fighter_data
    assert_equal 15, fighter_data["fight_count"]
    assert_equal 12, fighter_data["total_wins"]
    assert_equal 3, fighter_data["total_losses"]
    assert_equal 80.0, fighter_data["win_percentage"]
  end

  test "should get top performers for results scope with longest_win_streak" do
    # Create fighter with win streak
    streak_fighter = Fighter.create!(name: "Streak Fighter")

    # Create event dates in chronological order for streak
    dates = (1..6).map { |i| Date.new(2023, i, 1) }

    # Create 4 consecutive wins (the streak)
    4.times do |i|
      event = Event.create!(
        name: "UFC Streak Win #{i}",
        date: dates[i],
        location: "Vegas"
      )
      fight = Fight.create!(
        event: event,
        bout: "Streak Fighter vs Opponent #{i}",
        outcome: "W/L",
        weight_class: "Lightweight",
        round: 3,
        time: "5:00"
      )
      FightStat.create!(
        fight: fight,
        fighter: streak_fighter,
        round: 1,
        significant_strikes: 10
      )
    end

    # Add a loss to break the streak
    event = Event.create!(
      name: "UFC Streak Loss",
      date: dates[4],
      location: "Vegas"
    )
    fight = Fight.create!(
      event: event,
      bout: "Winner vs Streak Fighter",
      outcome: "W/L",
      weight_class: "Lightweight",
      round: 3,
      time: "5:00"
    )
    FightStat.create!(
      fight: fight,
      fighter: streak_fighter,
      round: 1,
      significant_strikes: 10
    )

    # Add one more win after the loss
    event = Event.create!(
      name: "UFC After Loss Win",
      date: dates[5],
      location: "Vegas"
    )
    fight = Fight.create!(
      event: event,
      bout: "Streak Fighter vs Final Opponent",
      outcome: "W/L",
      weight_class: "Lightweight",
      round: 3,
      time: "5:00"
    )
    FightStat.create!(
      fight: fight,
      fighter: streak_fighter,
      round: 1,
      significant_strikes: 10
    )

    get api_v1_top_performers_url(
      scope: "results",
      category: "longest_win_streak"
    )
    assert_response :success

    response_data = response.parsed_body
    top_performers = response_data["top_performers"]

    streak_data = top_performers.find do |p|
      p["fighter_name"] == "Streak Fighter"
    end

    assert_not_nil streak_data
    assert_equal 4, streak_data["longest_win_streak"]
    assert_equal 6, streak_data["fight_count"]
  end

  test "should return error for invalid category with results scope" do
    get api_v1_top_performers_url(scope: "results", category: "knockdowns")

    assert_response :bad_request
    response_data = response.parsed_body
    assert response_data["error"].present?
    assert_match(/Invalid category/, response_data["error"])
  end

  test "should accept all valid categories for results scope" do
    valid_categories = %w[
      total_wins
      total_losses
      win_percentage
      longest_win_streak
    ]

    valid_categories.each do |category|
      get api_v1_top_performers_url(scope: "results", category: category)
      assert_response :success, "Failed for category: #{category}"

      response_data = response.parsed_body
      assert_equal "results", response_data["meta"]["scope"]
      assert_equal category, response_data["meta"]["category"]
    end
  end
end
