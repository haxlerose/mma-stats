# frozen_string_literal: true

require "test_helper"
require "benchmark"

class ResultsQueryPerformanceTest < ActiveSupport::TestCase
  test "top_win_streaks performance with caching" do
    # Skip in CI to avoid flaky timing tests
    skip if ENV["CI"]

    # Create test data - 50 fighters with various fight records
    fighters = []
    50.times do |i|
      fighters << Fighter.create!(name: "Performance Fighter #{i}")
    end

    # Create events
    events = []
    20.times do |i|
      events << Event.create!(
        name: "Performance Event #{i}",
        date: (30 - i).days.ago,
        location: "Location #{i}"
      )
    end

    # Create fights with varied outcomes
    fighters.each_with_index do |fighter, i|
      # Give each fighter between 5-15 fights
      num_fights = 5 + (i % 11)
      num_fights.times do |j|
        opponent = fighters[(i + j + 1) % fighters.length]
        event = events[j % events.length]

        # Mix wins and losses
        outcome = (i + j).even? ? "W/L" : "L/W"
        bout = "#{fighter.name} vs. #{opponent.name}"

        fight = Fight.create!(
          event: event,
          bout: bout,
          outcome: outcome,
          weight_class: "Lightweight",
          method: "Decision",
          round: 3,
          time: "5:00"
        )

        FightStat.create!(
          fight: fight,
          fighter: fighter,
          round: 1,
          significant_strikes: 20,
          total_strikes: 30
        )

        FightStat.create!(
          fight: fight,
          fighter: opponent,
          round: 1,
          significant_strikes: 15,
          total_strikes: 25
        )
      end
    end

    # Use memory store for testing
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    Rails.cache.clear

    query = ResultsQuery.new(category: :longest_win_streak)

    # First call - should calculate from scratch
    time_without_cache = Benchmark.realtime do
      query.call
    end

    # Second call - should use cache
    time_with_cache = Benchmark.realtime do
      query.call
    end

    # Cache should make it at least 10x faster
    assert_operator time_without_cache / time_with_cache,
                    :>,
                    10,
                    "Cached call should be at least 10x faster"

    # Cached call should be under 100ms
    assert_operator time_with_cache,
                    :<,
                    0.1,
                    "Cached call should complete in under 100ms"
  ensure
    Rails.cache = original_cache
  end
end
