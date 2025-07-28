# frozen_string_literal: true

require "test_helper"

module TopPerformers
  class MinimumAttemptThresholdQueryTest < ActiveSupport::TestCase
    def setup
      @event = Event.create!(
        name: "UFC 300: Test Event",
        date: "2024-04-13",
        location: "Las Vegas, Nevada"
      )

      # Ensure fight_durations materialized view exists
      ensure_fight_durations_view_exists
    end

    def teardown
      # Clean up test data
      FightStat.destroy_all
      Fight.destroy_all
      Fighter.destroy_all
      Event.destroy_all
    end

    test "calculates minimum attempt threshold for significant strikes" do
      create_fight_with_stats(
        significant_strikes_attempted: 100,
        fight_duration_minutes: 15
      )
      create_fight_with_stats(
        significant_strikes_attempted: 50,
        fight_duration_minutes: 10
      )

      query = MinimumAttemptThresholdQuery.new(
        category: "significant_strike_accuracy"
      )
      threshold = query.call

      # (150 attempts / 25 minutes) × 60 × 25 = 150
      assert_equal 150, threshold
    end

    test "calculates minimum attempt threshold for takedowns" do
      # Clear data to ensure clean state
      FightStat.destroy_all
      Fight.destroy_all
      Fighter.destroy_all

      create_fight_with_stats(
        takedowns_attempted: 10,
        fight_duration_minutes: 15
      )
      create_fight_with_stats(
        takedowns_attempted: 5,
        fight_duration_minutes: 10
      )

      query = MinimumAttemptThresholdQuery.new(category: "takedown_accuracy")
      threshold = query.call

      # Total attempts: 15
      # Total time: 25 minutes = 1500 seconds
      # Rate per second: 15/1500 = 0.01
      # Rate per minute: 0.01 × 60 = 0.6
      # Threshold: 0.01 × 60 × 25 = 15
      assert_equal 15, threshold
    end

    test "calculates minimum attempt threshold for ground strikes" do
      create_fight_with_stats(
        ground_strikes_attempted: 30,
        fight_duration_minutes: 15
      )
      create_fight_with_stats(
        ground_strikes_attempted: 20,
        fight_duration_minutes: 10
      )

      query = MinimumAttemptThresholdQuery.new(
        category: "ground_strike_accuracy"
      )
      threshold = query.call

      # (50 attempts / 25 minutes) × 60 × 25 = 50
      assert_equal 50, threshold
    end

    test "returns zero when no data exists" do
      query = MinimumAttemptThresholdQuery.new(
        category: "significant_strike_accuracy"
      )
      threshold = query.call

      assert_equal 0, threshold
    end

    test "ignores fights with zero attempts" do
      create_fight_with_stats(
        significant_strikes_attempted: 0,
        fight_duration_minutes: 15
      )
      create_fight_with_stats(
        significant_strikes_attempted: 60,
        fight_duration_minutes: 10
      )

      query = MinimumAttemptThresholdQuery.new(
        category: "significant_strike_accuracy"
      )
      threshold = query.call

      # Only counts the second fight: (60 / 10) × 60 × 25 = 150
      assert_equal 150, threshold
    end

    test "handles all accuracy categories" do
      categories = %w[
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

      categories.each do |category|
        assert_nothing_raised do
          query = MinimumAttemptThresholdQuery.new(category: category)
          query.call
        end
      end
    end

    test "raises error for invalid category" do
      assert_raises ArgumentError do
        MinimumAttemptThresholdQuery.new(category: "invalid_category")
      end
    end

    test "rounds threshold to nearest integer" do
      create_fight_with_stats(
        significant_strikes_attempted: 100,
        fight_duration_minutes: 14 # Will create a decimal rate
      )

      query = MinimumAttemptThresholdQuery.new(
        category: "significant_strike_accuracy"
      )
      threshold = query.call

      # (100 / 14) × 60 × 25 ≈ 178.57, rounds to 179
      assert_equal 179, threshold
    end

    private

    def ensure_fight_durations_view_exists
      # Check if the view exists
      result = ActiveRecord::Base.connection.execute(<<~SQL.squish)
        SELECT EXISTS (
          SELECT 1
          FROM pg_matviews
          WHERE schemaname = 'public' AND matviewname = 'fight_durations'
        )
      SQL

      unless result.first["exists"]
        # Create the materialized view if it doesn't exist
        ActiveRecord::Base.connection.execute(<<~SQL.squish)
          CREATE MATERIALIZED VIEW fight_durations AS
          SELECT DISTINCT
            f.id AS fight_id,
            f.round AS ending_round,
            f.time AS ending_time,
            CASE
              WHEN f.time ~ '^[0-9]+:[0-9]+$' THEN
                ((f.round - 1) * 300) +
                (CAST(SPLIT_PART(f.time, ':', 1) AS INTEGER) * 60 +
                 CAST(SPLIT_PART(f.time, ':', 2) AS INTEGER))
              ELSE
                f.round * 300
            END AS duration_seconds
          FROM fights f;

          CREATE UNIQUE INDEX idx_fight_durations_fight_id
            ON fight_durations (fight_id);
        SQL
      end

      # Refresh the view to include any new fights
      # Use non-concurrent refresh in tests
      ActiveRecord::Base.connection.execute(
        "REFRESH MATERIALIZED VIEW fight_durations"
      )
    end

    def create_fight_with_stats(
      significant_strikes_attempted: 0,
      takedowns_attempted: 0,
      ground_strikes_attempted: 0,
      fight_duration_minutes: 15
    )
      rounds, time = calculate_rounds_and_time(fight_duration_minutes)
      fighter = create_test_fighter
      fight = create_test_fight(fighter, rounds, time)
      create_fight_stat(
        fight,
        fighter,
        significant_strikes_attempted,
        takedowns_attempted,
        ground_strikes_attempted
      )
      refresh_fight_durations_view
    end

    def calculate_rounds_and_time(fight_duration_minutes)
      full_rounds = fight_duration_minutes / 5
      remaining_minutes = fight_duration_minutes % 5

      if remaining_minutes.zero?
        [full_rounds, "5:00"]
      else
        [full_rounds + 1, "#{remaining_minutes}:00"]
      end
    end

    def create_test_fighter
      Fighter.create!(name: "Test Fighter #{Fighter.count}")
    end

    def create_test_fight(_fighter, rounds, time)
      Fight.create!(
        event: @event,
        bout: "Test Fight #{Fight.count}",
        outcome: "Win",
        weight_class: "Lightweight",
        round: rounds,
        time: time
      )
    end

    def create_fight_stat(
      fight, fighter, sig_strikes_att,
      takedowns_att, ground_strikes_att
    )
      FightStat.create!(
        fight: fight,
        fighter: fighter,
        round: 1,
        significant_strikes_attempted: sig_strikes_att,
        significant_strikes: sig_strikes_att / 2,
        takedowns_attempted: takedowns_att,
        takedowns: takedowns_att / 2,
        ground_strikes_attempted: ground_strikes_att,
        ground_strikes: ground_strikes_att / 2,
        total_strikes_attempted: sig_strikes_att,
        total_strikes: sig_strikes_att / 2,
        head_strikes_attempted: 0,
        head_strikes: 0,
        body_strikes_attempted: 0,
        body_strikes: 0,
        leg_strikes_attempted: 0,
        leg_strikes: 0,
        distance_strikes_attempted: 0,
        distance_strikes: 0,
        clinch_strikes_attempted: 0,
        clinch_strikes: 0,
        control_time_seconds: 0
      )
    end

    def refresh_fight_durations_view
      ActiveRecord::Base.connection.execute(
        "REFRESH MATERIALIZED VIEW fight_durations"
      )
    end
  end
end
