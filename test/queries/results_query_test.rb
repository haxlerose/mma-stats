# frozen_string_literal: true

require "test_helper"

class ResultsQueryTest < ActiveSupport::TestCase
  def setup
    setup_test_fighters
    setup_test_events
    setup_fighter_records
  end

  def setup_test_fighters
    @fighter1 = Fighter.create!(name: "Winner McGee")
    @fighter2 = Fighter.create!(name: "Loser Smith")
    @fighter3 = Fighter.create!(name: "Mixed Results")
    @fighter4 = Fighter.create!(name: "Veteran Fighter")
    @fighter5 = Fighter.create!(name: "Rookie Fighter")
  end

  def setup_test_events
    @event1 = Event.create!(
      name: "UFC 100",
      date: 3.months.ago,
      location: "Las Vegas"
    )
    @event2 = Event.create!(
      name: "UFC 101",
      date: 2.months.ago,
      location: "Philadelphia"
    )
    @event3 = Event.create!(
      name: "UFC 102",
      date: 1.month.ago,
      location: "Portland"
    )
    @event4 = Event.create!(
      name: "UFC 103",
      date: 2.weeks.ago,
      location: "Dallas"
    )
  end

  # Test total wins category
  test "returns top 10 fighters by total wins" do
    result = ResultsQuery.new(category: :total_wins).call

    assert_equal 5, result.count
    assert_equal @fighter1.id, result.first[:fighter_id]
    assert_equal 4, result.first[:total_wins]
    assert_equal @fighter4.id, result.second[:fighter_id]
    assert_equal 3, result.second[:total_wins]
  end

  test "includes fighter details in wins results" do
    result = ResultsQuery.new(category: :total_wins).call

    first_result = result.first
    assert_equal @fighter1.name, first_result[:fighter_name]
    assert_equal @fighter1.id, first_result[:fighter_id]
    assert_equal 4, first_result[:fight_count]
  end

  test "includes win percentage in wins results" do
    result = ResultsQuery.new(category: :total_wins).call

    first_result = result.first
    assert_includes first_result.keys, :win_percentage
    # Fighter1 has 4 wins, 0 losses
    assert_equal 100.0, first_result[:win_percentage]

    # Find fighter4 (3 wins, 2 losses)
    fighter4_result = result.find { |r| r[:fighter_id] == @fighter4.id }
    assert_not_nil fighter4_result
    assert_equal 60.0, fighter4_result[:win_percentage] # 3/5 = 60%
  end

  # Test total losses category
  test "returns top 10 fighters by total losses" do
    result = ResultsQuery.new(category: :total_losses).call

    assert_equal 5, result.count
    assert_equal @fighter2.id, result.first[:fighter_id]
    assert_equal 4, result.first[:total_losses]
  end

  test "includes fighter details in losses results" do
    result = ResultsQuery.new(category: :total_losses).call

    first_result = result.first
    assert_equal @fighter2.name, first_result[:fighter_name]
    assert_equal @fighter2.id, first_result[:fighter_id]
    assert_equal 4, first_result[:fight_count]
  end

  test "includes win percentage in losses results" do
    result = ResultsQuery.new(category: :total_losses).call

    first_result = result.first
    assert_includes first_result.keys, :win_percentage
    # Fighter2 has 0 wins, 4 losses
    assert_equal 0.0, first_result[:win_percentage]

    # Find fighter3 (2 wins, 2 losses)
    fighter3_result = result.find { |r| r[:fighter_id] == @fighter3.id }
    assert_not_nil fighter3_result
    assert_equal 50.0, fighter3_result[:win_percentage] # 2/4 = 50%
  end

  # Test win percentage category
  test "returns top 10 fighters by win percentage with minimum 10 fights" do
    # Create a fighter with perfect record but many fights
    perfect_fighter = Fighter.create!(name: "Perfect Record")
    10.times do |i|
      create_fight_with_outcome(
        perfect_fighter,
        Fighter.create!(name: "Opponent #{i}"),
        "W/L",
        Event.create!(
          name: "Event #{i}",
          date: i.days.ago,
          location: "Location #{i}"
        )
      )
    end

    result = ResultsQuery.new(category: :win_percentage).call

    # Should include only fighters with 10+ fights
    assert_includes result.map { |r| r[:fighter_id] }, perfect_fighter.id

    perfect_result = result.find { |r| r[:fighter_id] == perfect_fighter.id }
    assert_equal 100.0, perfect_result[:win_percentage]
    assert_equal 10, perfect_result[:fight_count]
    assert_equal 10, perfect_result[:total_wins]
  end

  test "excludes fighters with less than 10 fights from win percentage" do
    result = ResultsQuery.new(category: :win_percentage).call

    # Our setup fighters have less than 10 fights
    fighter_ids = result.map { |r| r[:fighter_id] }
    assert_not_includes fighter_ids, @fighter1.id
    assert_not_includes fighter_ids, @fighter2.id
    assert_not_includes fighter_ids, @fighter3.id
  end

  test "calculates win percentage correctly" do
    # Create a fighter with 12 fights, 9 wins (75% win rate)
    experienced_fighter = Fighter.create!(name: "Experienced Fighter")

    # 9 wins
    9.times do |i|
      create_fight_with_outcome(
        experienced_fighter,
        Fighter.create!(name: "Win Opponent #{i}"),
        "W/L",
        Event.create!(
          name: "Win Event #{i}",
          date: (20 + i).days.ago,
          location: "Win Location #{i}"
        )
      )
    end

    # 3 losses
    3.times do |i|
      create_fight_with_outcome(
        Fighter.create!(name: "Loss Opponent #{i}"),
        experienced_fighter,
        "W/L",
        Event.create!(
          name: "Loss Event #{i}",
          date: (10 + i).days.ago,
          location: "Loss Location #{i}"
        )
      )
    end

    result = ResultsQuery.new(category: :win_percentage).call

    experienced_result = result.find do |r|
      r[:fighter_id] == experienced_fighter.id
    end

    assert_not_nil experienced_result
    assert_equal 75.0, experienced_result[:win_percentage]
    assert_equal 12, experienced_result[:fight_count]
    assert_equal 9, experienced_result[:total_wins]
  end

  test "includes total losses in win percentage results" do
    # Create a fighter with 15 fights, 10 wins, 5 losses
    percentage_fighter = Fighter.create!(name: "Percentage Fighter")

    # 10 wins
    10.times do |i|
      create_fight_with_outcome(
        percentage_fighter,
        Fighter.create!(name: "Win Opponent P#{i}"),
        "W/L",
        Event.create!(
          name: "Win Event P#{i}",
          date: (30 + i).days.ago,
          location: "Win Location P#{i}"
        )
      )
    end

    # 5 losses
    5.times do |i|
      create_fight_with_outcome(
        Fighter.create!(name: "Loss Opponent P#{i}"),
        percentage_fighter,
        "W/L",
        Event.create!(
          name: "Loss Event P#{i}",
          date: (15 + i).days.ago,
          location: "Loss Location P#{i}"
        )
      )
    end

    result = ResultsQuery.new(category: :win_percentage).call

    percentage_result = result.find do |r|
      r[:fighter_id] == percentage_fighter.id
    end

    assert_not_nil percentage_result
    assert_includes percentage_result.keys, :total_losses
    assert_equal 5, percentage_result[:total_losses]
    assert_equal 10, percentage_result[:total_wins]
    assert_equal 15, percentage_result[:fight_count]
    assert_equal 66.7, percentage_result[:win_percentage]
  end

  # Test longest win streak category
  test "returns top 10 fighters by longest win streak" do
    result = ResultsQuery.new(category: :longest_win_streak).call

    # We have more fighters because some are created as opponents
    assert_operator result.count, :>=, 5
    assert_equal @fighter1.id, result.first[:fighter_id]
    assert_equal 4, result.first[:longest_win_streak]
  end

  test "calculates longest win streak correctly" do
    # Create a fighter with complex win/loss pattern
    streak_fighter = Fighter.create!(name: "Streak Fighter")

    # Events in chronological order (oldest to newest)
    events = []
    10.times do |i|
      events << Event.create!(
        name: "Streak Event #{i}",
        date: (30 - i).days.ago,
        location: "Streak Location #{i}"
      )
    end

    # Fight history: W W W L W W W W L W (streaks of 3, 4, 1)
    # Wins at indices 0, 1, 2
    create_fight_with_outcome(
      streak_fighter,
      Fighter.create!(name: "Streak Opponent 0"),
      "W/L",
      events[0]
    )
    create_fight_with_outcome(
      streak_fighter,
      Fighter.create!(name: "Streak Opponent 1"),
      "W/L",
      events[1]
    )
    create_fight_with_outcome(
      streak_fighter,
      Fighter.create!(name: "Streak Opponent 2"),
      "W/L",
      events[2]
    )

    # Loss at index 3
    create_fight_with_outcome(
      Fighter.create!(name: "Streak Opponent 3"),
      streak_fighter,
      "W/L",
      events[3]
    )

    # Wins at indices 4, 5, 6, 7
    create_fight_with_outcome(
      streak_fighter,
      Fighter.create!(name: "Streak Opponent 4"),
      "W/L",
      events[4]
    )
    create_fight_with_outcome(
      streak_fighter,
      Fighter.create!(name: "Streak Opponent 5"),
      "W/L",
      events[5]
    )
    create_fight_with_outcome(
      streak_fighter,
      Fighter.create!(name: "Streak Opponent 6"),
      "W/L",
      events[6]
    )
    create_fight_with_outcome(
      streak_fighter,
      Fighter.create!(name: "Streak Opponent 7"),
      "W/L",
      events[7]
    )

    # Loss at index 8
    create_fight_with_outcome(
      Fighter.create!(name: "Streak Opponent 8"),
      streak_fighter,
      "W/L",
      events[8]
    )

    # Win at index 9
    create_fight_with_outcome(
      streak_fighter,
      Fighter.create!(name: "Streak Opponent 9"),
      "W/L",
      events[9]
    )

    result = ResultsQuery.new(category: :longest_win_streak).call

    streak_result = result.find { |r| r[:fighter_id] == streak_fighter.id }
    assert_not_nil streak_result
    assert_equal 4, streak_result[:longest_win_streak] # Longest streak was 4
  end

  test "draw breaks win streak" do
    # Create a fighter with wins interrupted by a draw
    draw_streak_fighter = Fighter.create!(name: "Draw Streak Fighter")

    # Events in chronological order
    events = []
    6.times do |i|
      events << Event.create!(
        name: "Draw Streak Event #{i}",
        date: (10 - i).days.ago,
        location: "Draw Streak Location #{i}"
      )
    end

    # Fight history: W W W D W W (streaks of 3, then 2)
    # Wins at indices 0, 1, 2
    create_fight_with_outcome(
      draw_streak_fighter,
      Fighter.create!(name: "Draw Streak Opponent 0"),
      "W/L",
      events[0]
    )
    create_fight_with_outcome(
      draw_streak_fighter,
      Fighter.create!(name: "Draw Streak Opponent 1"),
      "W/L",
      events[1]
    )
    create_fight_with_outcome(
      draw_streak_fighter,
      Fighter.create!(name: "Draw Streak Opponent 2"),
      "W/L",
      events[2]
    )

    # Draw at index 3 - should break the streak
    create_fight_with_outcome(
      draw_streak_fighter,
      Fighter.create!(name: "Draw Streak Opponent 3"),
      "D",
      events[3]
    )

    # Wins at indices 4, 5
    create_fight_with_outcome(
      draw_streak_fighter,
      Fighter.create!(name: "Draw Streak Opponent 4"),
      "W/L",
      events[4]
    )
    create_fight_with_outcome(
      draw_streak_fighter,
      Fighter.create!(name: "Draw Streak Opponent 5"),
      "W/L",
      events[5]
    )

    result = ResultsQuery.new(category: :longest_win_streak).call

    streak_result = result.find { |r| r[:fighter_id] == draw_streak_fighter.id }
    assert_not_nil streak_result
    assert_equal 3,
                 streak_result[:longest_win_streak],
                 "Draw should break the win streak"
  end

  test "no contest breaks win streak" do
    # Create a fighter with wins interrupted by a no contest
    nc_streak_fighter = Fighter.create!(name: "NC Streak Fighter")

    # Events in chronological order
    events = []
    7.times do |i|
      events << Event.create!(
        name: "NC Streak Event #{i}",
        date: (14 - i).days.ago,
        location: "NC Streak Location #{i}"
      )
    end

    # Fight history: W W NC W W W W (streaks of 2, then 4)
    # Wins at indices 0, 1
    create_fight_with_outcome(
      nc_streak_fighter,
      Fighter.create!(name: "NC Streak Opponent 0"),
      "W/L",
      events[0]
    )
    create_fight_with_outcome(
      nc_streak_fighter,
      Fighter.create!(name: "NC Streak Opponent 1"),
      "W/L",
      events[1]
    )

    # No Contest at index 2 - should break the streak
    create_fight_with_outcome(
      nc_streak_fighter,
      Fighter.create!(name: "NC Streak Opponent 2"),
      "NC",
      events[2]
    )

    # Wins at indices 3, 4, 5, 6
    create_fight_with_outcome(
      nc_streak_fighter,
      Fighter.create!(name: "NC Streak Opponent 3"),
      "W/L",
      events[3]
    )
    create_fight_with_outcome(
      nc_streak_fighter,
      Fighter.create!(name: "NC Streak Opponent 4"),
      "W/L",
      events[4]
    )
    create_fight_with_outcome(
      nc_streak_fighter,
      Fighter.create!(name: "NC Streak Opponent 5"),
      "W/L",
      events[5]
    )
    create_fight_with_outcome(
      nc_streak_fighter,
      Fighter.create!(name: "NC Streak Opponent 6"),
      "W/L",
      events[6]
    )

    result = ResultsQuery.new(category: :longest_win_streak).call

    streak_result = result.find { |r| r[:fighter_id] == nc_streak_fighter.id }
    assert_not_nil streak_result
    assert_equal 4,
                 streak_result[:longest_win_streak],
                 "No contest should break the win streak"
  end

  test "complex fight history with draws and no contests" do
    # Create a fighter with a complex fight history including all outcome types
    complex_fighter = Fighter.create!(name: "Complex Fighter")

    # Events in chronological order
    events = []
    12.times do |i|
      events << Event.create!(
        name: "Complex Event #{i}",
        date: (20 - i).days.ago,
        location: "Complex Location #{i}"
      )
    end

    # Fight history: W W D W L NC W W W D W L
    # Streaks: 2 (broken by D), 1 (broken by L), 3 (broken by D),
    # 1 (broken by L)
    # Longest should be 3

    # 2 wins
    create_fight_with_outcome(
      complex_fighter,
      Fighter.create!(name: "Complex Opponent 0"),
      "W/L",
      events[0]
    )
    create_fight_with_outcome(
      complex_fighter,
      Fighter.create!(name: "Complex Opponent 1"),
      "W/L",
      events[1]
    )

    # Draw
    create_fight_with_outcome(
      complex_fighter,
      Fighter.create!(name: "Complex Opponent 2"),
      "D",
      events[2]
    )

    # 1 win
    create_fight_with_outcome(
      complex_fighter,
      Fighter.create!(name: "Complex Opponent 3"),
      "W/L",
      events[3]
    )

    # Loss
    create_fight_with_outcome(
      Fighter.create!(name: "Complex Opponent 4"),
      complex_fighter,
      "W/L",
      events[4]
    )

    # No Contest
    create_fight_with_outcome(
      complex_fighter,
      Fighter.create!(name: "Complex Opponent 5"),
      "NC",
      events[5]
    )

    # 3 wins
    create_fight_with_outcome(
      complex_fighter,
      Fighter.create!(name: "Complex Opponent 6"),
      "W/L",
      events[6]
    )
    create_fight_with_outcome(
      complex_fighter,
      Fighter.create!(name: "Complex Opponent 7"),
      "W/L",
      events[7]
    )
    create_fight_with_outcome(
      complex_fighter,
      Fighter.create!(name: "Complex Opponent 8"),
      "W/L",
      events[8]
    )

    # Draw
    create_fight_with_outcome(
      complex_fighter,
      Fighter.create!(name: "Complex Opponent 9"),
      "D",
      events[9]
    )

    # 1 win
    create_fight_with_outcome(
      complex_fighter,
      Fighter.create!(name: "Complex Opponent 10"),
      "W/L",
      events[10]
    )

    # Loss
    create_fight_with_outcome(
      Fighter.create!(name: "Complex Opponent 11"),
      complex_fighter,
      "W/L",
      events[11]
    )

    result = ResultsQuery.new(category: :longest_win_streak).call

    streak_result = result.find { |r| r[:fighter_id] == complex_fighter.id }
    assert_not_nil streak_result
    assert_equal 3,
                 streak_result[:longest_win_streak],
                 "Should calculate correct longest streak " \
                 "considering all outcome types"
  end

  test "handles fighters with no wins for win streak" do
    # Fighter 2 has only losses
    result = ResultsQuery.new(category: :longest_win_streak).call

    loser_result = result.find { |r| r[:fighter_id] == @fighter2.id }
    assert_not_nil loser_result
    assert_equal 0, loser_result[:longest_win_streak]
  end

  test "handles draws and no contests correctly" do
    draw_fighter = Fighter.create!(name: "Draw Fighter")
    opponent = Fighter.create!(name: "Draw Opponent")

    # Create a draw fight
    create_fight_with_outcome(
      draw_fighter,
      opponent,
      "D",
      Event.create!(
        name: "Draw Event",
        date: 1.day.ago,
        location: "Draw Location"
      )
    )

    # Create a no contest fight
    create_fight_with_outcome(
      draw_fighter,
      Fighter.create!(name: "NC Opponent"),
      "NC",
      Event.create!(
        name: "NC Event",
        date: 2.days.ago,
        location: "NC Location"
      )
    )

    # Draws and NC should not count as wins or losses
    wins_result = ResultsQuery.new(category: :total_wins).call
    losses_result = ResultsQuery.new(category: :total_losses).call

    draw_wins = wins_result.find { |r| r[:fighter_id] == draw_fighter.id }
    draw_losses = losses_result.find { |r| r[:fighter_id] == draw_fighter.id }

    assert_nil draw_wins # Should not appear in wins list (0 wins)
    assert_nil draw_losses # Should not appear in losses list (0 losses)
  end

  test "defaults to total_wins when no category specified" do
    result = ResultsQuery.new.call
    first_result = result.first

    assert_includes first_result.keys, :total_wins
    assert_not_includes first_result.keys, :total_losses
    assert_includes first_result.keys, :win_percentage
  end

  test "raises error for invalid category" do
    assert_raises(ArgumentError) do
      ResultsQuery.new(category: :invalid_category).call
    end
  end

  test "handles fighters with no valid fights for win percentage calculation" do
    # Create a fighter with only draws and no contests
    no_valid_fighter = Fighter.create!(name: "No Valid Fighter")
    opponent1 = Fighter.create!(name: "Draw Opponent 1")
    opponent2 = Fighter.create!(name: "NC Opponent 1")

    # Create only draw and NC fights
    create_fight_with_outcome(
      no_valid_fighter,
      opponent1,
      "D",
      Event.create!(
        name: "Draw Only Event",
        date: 1.day.ago,
        location: "Draw Only Location"
      )
    )

    create_fight_with_outcome(
      no_valid_fighter,
      opponent2,
      "NC",
      Event.create!(
        name: "NC Only Event",
        date: 2.days.ago,
        location: "NC Only Location"
      )
    )

    # This fighter should not appear in wins or losses results
    wins_result = ResultsQuery.new(category: :total_wins).call
    losses_result = ResultsQuery.new(category: :total_losses).call

    # Should not appear in either list (no wins or losses)
    assert_nil(wins_result.find { |r| r[:fighter_id] == no_valid_fighter.id })
    assert_nil(losses_result.find { |r| r[:fighter_id] == no_valid_fighter.id })
  end

  test "limits results to top 10" do
    # Create 12 fighters with wins
    12.times do |i|
      fighter = Fighter.create!(name: "Fighter #{i}")
      create_fight_with_outcome(
        fighter,
        Fighter.create!(name: "Opponent #{i}"),
        "W/L",
        Event.create!(
          name: "Event Top #{i}",
          date: i.days.ago,
          location: "Location Top #{i}"
        )
      )
    end

    result = ResultsQuery.new(category: :total_wins).call

    assert_equal 10, result.count
  end

  test "caches top win streaks results" do
    # Temporarily use memory store for testing
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new

    # Clear cache first
    Rails.cache.clear

    # First call should calculate and cache
    query = ResultsQuery.new(category: :longest_win_streak)
    result1 = query.call

    # Second call should use cache (should be much faster)
    # We can't easily test timing, but we can verify the same results
    result2 = query.call

    assert_equal result1, result2

    # Verify cache key exists
    cache_key = "fighter_top_win_streaks_all"
    assert_not_nil Rails.cache.read(cache_key)
  ensure
    # Restore original cache
    Rails.cache = original_cache
  end

  test "invalidates win streak cache when fights change" do
    # Temporarily use memory store for testing
    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new

    # Clear cache and get initial results
    Rails.cache.clear
    query = ResultsQuery.new(category: :longest_win_streak)
    query.call

    # Create a new fight which should invalidate cache
    new_fighter = Fighter.create!(name: "New Streak Fighter")
    create_fight_with_outcome(
      new_fighter,
      @fighter2,
      "W/L",
      Event.create!(
        name: "New Event",
        date: 1.hour.ago,
        location: "New Location"
      )
    )

    # Results should be recalculated (cache invalidated)
    new_results = query.call

    # The new fighter should appear in results if they have a win
    fighter_ids = new_results.map { |r| r[:fighter_id] }
    assert_includes fighter_ids, new_fighter.id
  ensure
    # Restore original cache
    Rails.cache = original_cache
  end

  test "generates safe SQL without string interpolation vulnerabilities" do
    # This test ensures we're using parameterized queries
    query = ResultsQuery.new(category: :total_wins)

    # The query should work without SQL injection issues
    result = query.call

    # Should return results
    assert_kind_of Array, result

    # Verify the query doesn't use dangerous string interpolation
    # by checking that it can handle special characters safely
    fighter_with_special_chars = Fighter.create!(
      name: "Test'; DROP TABLE fighters;--"
    )
    create_fight_with_outcome(
      fighter_with_special_chars,
      @fighter2,
      "W/L",
      @event1
    )

    # Should not raise SQL errors with special characters
    assert_nothing_raised do
      ResultsQuery.new(category: :total_wins).call
    end
  end

  test "avoids N+1 queries when calculating win streaks" do
    # Create 15 fighters with varying win patterns to ensure we test
    # optimization with more than TOP_PERFORMERS_LIMIT candidates
    fighters = []
    15.times do |i|
      fighter = Fighter.create!(name: "N+1 Test Fighter #{i}")
      fighters << fighter

      # Give each fighter a different number of wins
      (i + 1).times do |j|
        create_fight_with_outcome(
          fighter,
          Fighter.create!(name: "N+1 Opponent #{i}-#{j}"),
          "W/L",
          Event.create!(
            name: "N+1 Event #{i}-#{j}",
            date: ((i * 10) + j).days.ago,
            location: "N+1 Location #{i}-#{j}"
          )
        )
      end
    end

    # Clear any cached data
    Rails.cache.clear if Rails.cache.respond_to?(:clear)

    # Count queries during the operation
    query_count = 0
    query_logger = lambda do |_name, _start, _finish, _id, payload|
      sql = payload[:sql]
      skip_pattern = /^(BEGIN|COMMIT|PRAGMA|SELECT @@|SELECT sqlite_version)/
      query_count += 1 if sql && !sql.match?(skip_pattern)
    end

    ActiveSupport::Notifications.subscribed(
      query_logger,
      "sql.active_record"
    ) do
      ResultsQuery.new(category: :longest_win_streak).call
    end

    # We should have at most:
    # 1. One query to get potential candidates with basic stats
    # 2. One query to load all fights for all candidates
    # Total should be significantly less than 15+ queries (one per fighter)
    assert_operator query_count,
                    :<=,
                    5,
                    "Too many queries executed (#{query_count}). " \
                    "Likely N+1 query problem in win streak calculation."
  end

  test "includes fighters with long win streaks not in top 30 by wins" do
    # Create scenario where there are many fighters with 16 wins
    # but some have longer streaks than others

    # Create 35 fighters with exactly 16 wins each
    # But only give 10 of them 16-fight win streaks
    fighters_with_16_wins = []
    35.times do |i|
      fighter = Fighter.create!(name: "Fighter with 16 wins #{i}")
      fighters_with_16_wins << fighter

      if i < 5
        # First 5 fighters: give them 16-fight win streaks
        16.times do |j|
          create_fight_with_outcome(
            fighter,
            Fighter.create!(name: "Opponent for F16-#{i}-#{j}"),
            "W/L",
            Event.create!(
              name: "Event F16-#{i}-#{j}",
              date: ((i * 20) + j).days.ago,
              location: "Location F16-#{i}-#{j}"
            )
          )
        end
      else
        # Remaining 30: interrupted streaks (8 wins, 1 loss, 8 wins)
        # First 8 wins
        8.times do |j|
          create_fight_with_outcome(
            fighter,
            Fighter.create!(name: "Opponent for F16-#{i}-#{j}"),
            "W/L",
            Event.create!(
              name: "Event F16-#{i}-#{j}",
              date: ((i * 20) + j + 10).days.ago,
              location: "Location F16-#{i}-#{j}"
            )
          )
        end

        # 1 loss
        create_fight_with_outcome(
          Fighter.create!(name: "Opponent for F16-#{i}-loss"),
          fighter,
          "W/L",
          Event.create!(
            name: "Event F16-#{i}-loss",
            date: ((i * 20) + 8).days.ago,
            location: "Location F16-#{i}-loss"
          )
        )

        # Another 8 wins
        8.times do |j|
          create_fight_with_outcome(
            fighter,
            Fighter.create!(name: "Opponent for F16-#{i}-#{j + 8}"),
            "W/L",
            Event.create!(
              name: "Event F16-#{i}-#{j + 8}",
              date: ((i * 20) + j).days.ago,
              location: "Location F16-#{i}-#{j + 8}"
            )
          )
        end
      end
    end

    # Create Kamaru Usman with 19 wins but a 15-fight win streak
    kamaru = Fighter.create!(name: "Kamaru Usman")

    # First 4 fights: mixed results (2 wins, 2 losses)
    create_fight_with_outcome(
      kamaru,
      Fighter.create!(name: "Early Opponent 1"),
      "W/L",
      Event.create!(
        name: "Early Event 1",
        date: 100.days.ago,
        location: "Location 1"
      )
    )
    create_fight_with_outcome(
      Fighter.create!(name: "Early Opponent 2"),
      kamaru,
      "W/L",
      Event.create!(
        name: "Early Event 2",
        date: 95.days.ago,
        location: "Location 2"
      )
    )
    create_fight_with_outcome(
      kamaru,
      Fighter.create!(name: "Early Opponent 3"),
      "W/L",
      Event.create!(
        name: "Early Event 3",
        date: 90.days.ago,
        location: "Location 3"
      )
    )
    create_fight_with_outcome(
      Fighter.create!(name: "Early Opponent 4"),
      kamaru,
      "W/L",
      Event.create!(
        name: "Early Event 4",
        date: 85.days.ago,
        location: "Location 4"
      )
    )

    # Next 15 fights: all wins (15-fight win streak)
    15.times do |i|
      create_fight_with_outcome(
        kamaru,
        Fighter.create!(name: "Streak Opponent #{i}"),
        "W/L",
        Event.create!(
          name: "Streak Event #{i}",
          date: (80 - i).days.ago,
          location: "Streak Location #{i}"
        )
      )
    end

    # Clear cache
    Rails.cache.clear if Rails.cache.respond_to?(:clear)

    # Debug: Check Kamaru's actual win count
    Fighter
      .joins(fight_stats: { fight: :event })
      .where(fighters: { id: kamaru.id })
      .where(fights: { outcome: ["W/L", "L/W"] })
      .group("fighters.id", "fighters.name")
      .select(
        "fighters.id",
        "fighters.name",
        "COUNT(DISTINCT CASE " \
        "WHEN fights.outcome = 'W/L' AND " \
        "SPLIT_PART(fights.bout, ' vs', 1) = fighters.name " \
        "THEN fights.id " \
        "WHEN fights.outcome = 'L/W' AND " \
        "TRIM(SPLIT_PART(fights.bout, ' vs', 2), '. ') = fighters.name " \
        "THEN fights.id " \
        "END) AS total_wins"
      ).first

    # Get results
    result = ResultsQuery.new(category: :longest_win_streak).call

    # Kamaru should be in the top 10 with his 15-fight win streak
    kamaru_result = result.find { |r| r[:fighter_id] == kamaru.id }
    assert_not_nil kamaru_result,
                   "Kamaru Usman should appear in top 10 win streaks"
    assert_equal 15, kamaru_result[:longest_win_streak]

    # Verify he's actually in the top 10
    assert_includes result.first(10).map { |r| r[:fighter_id] },
                    kamaru.id,
                    "Kamaru Usman should be in the top 10"
  end

  test "produces deterministic results for win streaks" do
    # Create fighters with same number of wins to test deterministic ordering
    fighters = []
    10.times do |i|
      fighter = Fighter.create!(name: "Same Wins Fighter #{i}")
      fighters << fighter

      # Give each fighter exactly 10 wins
      10.times do |j|
        create_fight_with_outcome(
          fighter,
          Fighter.create!(name: "Opponent SWF-#{i}-#{j}"),
          "W/L",
          Event.create!(
            name: "Event SWF-#{i}-#{j}",
            date: ((i * 15) + j).days.ago,
            location: "Location SWF-#{i}-#{j}"
          )
        )
      end
    end

    # Clear cache and run query multiple times
    Rails.cache.clear if Rails.cache.respond_to?(:clear)

    results = []
    3.times do
      Rails.cache.clear if Rails.cache.respond_to?(:clear)
      result = ResultsQuery.new(category: :longest_win_streak).call
      results << result.map { |r| r[:fighter_id] }
    end

    # All runs should produce identical results
    assert_equal results[0],
                 results[1],
                 "Results should be deterministic (run 1 vs 2)"
    assert_equal results[1],
                 results[2],
                 "Results should be deterministic (run 2 vs 3)"
  end

  test "orders results correctly by category value descending" do
    result = ResultsQuery.new(category: :total_wins).call

    win_totals = result.map { |r| r[:total_wins] }
    assert_equal win_totals.sort.reverse, win_totals
  end

  test "counts fights correctly with multiple rounds" do
    # Create a fighter with multi-round fights to ensure we count fights,
    # not rounds
    multi_round_fighter = Fighter.create!(name: "Multi Round Fighter")
    opponent1 = Fighter.create!(name: "Multi Round Opponent 1")
    opponent2 = Fighter.create!(name: "Multi Round Opponent 2")

    event = Event.create!(
      name: "Multi Round Event",
      date: 1.day.ago,
      location: "Multi Round Location"
    )

    # Create first fight with 3 rounds
    fight1 = Fight.create!(
      event: event,
      bout: "#{multi_round_fighter.name} vs. #{opponent1.name}",
      outcome: "W/L",
      weight_class: "Lightweight",
      method: "Decision",
      round: 3,
      time: "5:00"
    )

    # Create 3 rounds of stats for the first fight
    3.times do |i|
      FightStat.create!(
        fight: fight1,
        fighter: multi_round_fighter,
        round: i + 1,
        significant_strikes: 20,
        total_strikes: 30
      )
      FightStat.create!(
        fight: fight1,
        fighter: opponent1,
        round: i + 1,
        significant_strikes: 15,
        total_strikes: 25
      )
    end

    # Create second fight with 5 rounds
    fight2 = Fight.create!(
      event: event,
      bout: "#{multi_round_fighter.name} vs. #{opponent2.name}",
      outcome: "W/L",
      weight_class: "Lightweight",
      method: "Decision",
      round: 5,
      time: "5:00"
    )

    # Create 5 rounds of stats for the second fight
    5.times do |i|
      FightStat.create!(
        fight: fight2,
        fighter: multi_round_fighter,
        round: i + 1,
        significant_strikes: 20,
        total_strikes: 30
      )
      FightStat.create!(
        fight: fight2,
        fighter: opponent2,
        round: i + 1,
        significant_strikes: 15,
        total_strikes: 25
      )
    end

    # Test that we count 2 wins, not 8 (3 rounds + 5 rounds)
    result = ResultsQuery.new(category: :total_wins).call
    fighter_result = result.find do |r|
      r[:fighter_id] == multi_round_fighter.id
    end

    assert_not_nil fighter_result
    assert_equal 2,
                 fighter_result[:total_wins],
                 "Should count 2 fights, not 8 rounds"
    assert_equal 2, fighter_result[:fight_count]

    # Also test losses
    losses_result = ResultsQuery.new(category: :total_losses).call
    opponent1_result = losses_result.find { |r| r[:fighter_id] == opponent1.id }
    opponent2_result = losses_result.find { |r| r[:fighter_id] == opponent2.id }

    assert_not_nil opponent1_result
    assert_equal 1,
                 opponent1_result[:total_losses],
                 "Should count 1 loss, not 3 rounds"
    assert_not_nil opponent2_result
    assert_equal 1,
                 opponent2_result[:total_losses],
                 "Should count 1 loss, not 5 rounds"
  end

  private

  def setup_fighter_records
    # Fighter 1: 4 wins, 0 losses (perfect record)
    create_fight_with_outcome(@fighter1, @fighter2, "W/L", @event1)
    create_fight_with_outcome(@fighter1, @fighter3, "W/L", @event2)
    create_fight_with_outcome(@fighter1, @fighter4, "W/L", @event3)
    create_fight_with_outcome(@fighter1, @fighter5, "W/L", @event4)

    # Fighter 2: 0 wins, 4 losses
    # (already has loss to fighter1)
    create_fight_with_outcome(@fighter3, @fighter2, "W/L", @event3)
    create_fight_with_outcome(@fighter4, @fighter2, "W/L", @event4)
    create_fight_with_outcome(@fighter5, @fighter2, "W/L", @event1)

    # Fighter 3: 2 wins, 2 losses (mixed record)
    # (already has win over fighter2 and loss to fighter1)
    create_fight_with_outcome(@fighter3, @fighter4, "W/L", @event1)
    create_fight_with_outcome(@fighter5, @fighter3, "W/L", @event4)

    # Fighter 4: 3 wins, 2 losses
    # (already has win over fighter2, loss to fighter1, loss to fighter3)
    create_fight_with_outcome(@fighter4, @fighter5, "W/L", @event2)
    create_fight_with_outcome(
      @fighter4,
      Fighter.create!(name: "Extra Opponent"),
      "W/L",
      @event4
    )

    # Fighter 5: 2 wins, 3 losses
    # (already has wins over fighter2 and fighter3,
    # losses to fighter1 and fighter4)
    # Needs one more loss
    create_fight_with_outcome(
      Fighter.create!(name: "Another Opponent"),
      @fighter5,
      "W/L",
      @event3
    )
  end

  def create_fight_with_outcome(winner, loser, outcome, event)
    bout = if outcome == "W/L"
             "#{winner.name} vs. #{loser.name}"
           else
             "#{loser.name} vs. #{winner.name}"
           end

    fight = Fight.create!(
      event: event,
      bout: bout,
      outcome: outcome,
      weight_class: "Lightweight",
      method: "Decision",
      round: 3,
      time: "5:00"
    )

    # Create fight stats for both fighters
    FightStat.create!(
      fight: fight,
      fighter: winner,
      round: 1,
      significant_strikes: 20,
      total_strikes: 30
    )

    FightStat.create!(
      fight: fight,
      fighter: loser,
      round: 1,
      significant_strikes: 15,
      total_strikes: 25
    )

    fight
  end
end
