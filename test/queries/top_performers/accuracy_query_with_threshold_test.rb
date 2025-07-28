# frozen_string_literal: true

require "test_helper"

module TopPerformers
  class AccuracyQueryWithThresholdTest < ActiveSupport::TestCase
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

    test "filters fighters below minimum attempt threshold" do
      # Create fighter with high accuracy but low attempts
      create_fighter_with_stats(
        "Low Volume Fighter",
        significant_strikes: 36,
        significant_strikes_attempted: 40,
        fights: 10
      )

      # Create fighter with lower accuracy but high attempts
      create_fighter_with_stats(
        "High Volume Fighter",
        significant_strikes: 300,
        significant_strikes_attempted: 500,
        fights: 10
      )

      query = AccuracyQuery.new(
        category: "significant_strike_accuracy",
        apply_threshold: true
      )
      results = query.call

      fighter_names = results[:fighters].map { |r| r[:fighter_name] }

      # Low volume fighter (50 attempts) should be filtered out
      # High volume fighter (500 attempts) should be included
      assert_not_includes fighter_names, "Low Volume Fighter"
      assert_includes fighter_names, "High Volume Fighter"
    end

    test "includes minimum threshold in response when requested" do
      create_fighter_with_stats(
        "Test Fighter",
        significant_strikes: 400,
        significant_strikes_attempted: 500,
        fights: 10
      )

      query = AccuracyQuery.new(
        category: "significant_strike_accuracy",
        apply_threshold: true
      )
      results = query.call

      assert results.is_a?(Hash)
      assert results.key?(:fighters)
      assert results.key?(:minimum_attempts_threshold)
      assert results[:minimum_attempts_threshold].positive?
    end

    test "can disable threshold filtering" do
      create_fighter_with_stats(
        "Low Volume Fighter",
        significant_strikes: 9,
        significant_strikes_attempted: 10,
        fights: 5
      )

      query = AccuracyQuery.new(
        category: "significant_strike_accuracy",
        apply_threshold: false
      )
      results = query.call

      # When threshold is disabled, returns array as before
      assert results.is_a?(Array)
      fighter_names = results.map { |r| r[:fighter_name] }
      assert_includes fighter_names, "Low Volume Fighter"
    end

    test "calculates threshold based on actual fight data" do
      # Create multiple fights with known durations
      5.times do |i|
        fighter = Fighter.create!(name: "Fighter #{i}")
        fight = Fight.create!(
          event: @event,
          bout: "Fight #{i}",
          outcome: "Win",
          weight_class: "Lightweight",
          round: 3,
          time: "5:00" # 15 minutes total
        )
        FightStat.create!(
          fight: fight,
          fighter: fighter,
          round: 1,
          significant_strikes: 30,
          significant_strikes_attempted: 60, # 60 attempts in 15 minutes
          control_time_seconds: 0
        )
      end

      # Refresh materialized view after creating all fights
      ActiveRecord::Base.connection.execute(
        "REFRESH MATERIALIZED VIEW fight_durations"
      )

      query = AccuracyQuery.new(
        category: "significant_strike_accuracy",
        apply_threshold: true
      )
      results = query.call

      # Total: 5 fighters × 60 attempts = 300 attempts
      # Total: 5 fights × 15 minutes = 75 minutes = 4500 seconds
      # Rate: 300/4500 = 0.0667 per second
      # Threshold: 0.0667 × 60 × 25 = 100
      assert_equal 100, results[:minimum_attempts_threshold]
    end

    test "applies different thresholds for different stat types" do
      # Clear any leftover data
      FightStat.destroy_all
      Fight.destroy_all
      Fighter.destroy_all

      # Create data for takedown accuracy
      fighter = Fighter.create!(name: "Wrestler")
      5.times do |i|
        fight = Fight.create!(
          event: @event,
          bout: "Wrestling Match #{i}",
          outcome: "Win",
          weight_class: "Lightweight",
          round: 3,
          time: "5:00"
        )
        FightStat.create!(
          fight: fight,
          fighter: fighter,
          round: 1,
          takedowns: 3,
          takedowns_attempted: 5, # Much lower rate than strikes
          control_time_seconds: 0
        )
      end

      # Refresh materialized view after creating all fights
      ActiveRecord::Base.connection.execute(
        "REFRESH MATERIALIZED VIEW fight_durations"
      )

      query = AccuracyQuery.new(
        category: "takedown_accuracy",
        apply_threshold: true
      )
      results = query.call

      # Takedown threshold should be much lower than strike threshold
      # Total: 5 fights × 5 attempts = 25 attempts
      # Total: 5 fights × 15 minutes = 75 minutes = 4500 seconds
      # Rate: 25/4500 = 0.00556 per second
      # Threshold: 0.00556 × 60 × 25 = 8.33, rounds to 8
      assert_equal 8, results[:minimum_attempts_threshold]
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
      ActiveRecord::Base.connection.execute(
        "REFRESH MATERIALIZED VIEW CONCURRENTLY fight_durations"
      )
    end

    def create_fighter_with_stats(
      name, significant_strikes:,
      significant_strikes_attempted:, fights:
    )
      fighter = Fighter.create!(name: name)

      fights.times do |i|
        fight = Fight.create!(
          event: @event,
          bout: "#{name} Fight #{i}",
          outcome: "Win",
          weight_class: "Lightweight",
          round: 3,
          time: "5:00"
        )

        # Distribute stats across fights
        strikes_per_fight = significant_strikes / fights
        attempts_per_fight = significant_strikes_attempted / fights

        FightStat.create!(
          fight: fight,
          fighter: fighter,
          round: 1,
          significant_strikes: strikes_per_fight,
          significant_strikes_attempted: attempts_per_fight,
          total_strikes: strikes_per_fight,
          total_strikes_attempted: attempts_per_fight,
          control_time_seconds: 0
        )
      end

      # Refresh materialized view after creating all fights for this fighter
      ActiveRecord::Base.connection.execute(
        "REFRESH MATERIALIZED VIEW fight_durations"
      )

      fighter
    end
  end
end
