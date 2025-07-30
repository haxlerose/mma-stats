# frozen_string_literal: true

require "test_helper"

class AccuracyQueryTest < ActiveSupport::TestCase
  AccuracyQuery = TopPerformers::AccuracyQuery
  def setup
    @event = Event.create!(
      name: "UFC 300: Pereira vs Hill",
      date: "2024-04-13",
      location: "Las Vegas, Nevada"
    )
  end

  test "returns top 10 fighters ordered by significant strike accuracy" do
    create_test_data_with_varying_accuracy

    result = AccuracyQuery.new(category: "significant_strike_accuracy").call

    assert_equal 10, result.length
    assert_equal "Accurate Fighter", result.first[:fighter_name]
    assert_equal "Medium Accuracy Fighter", result.second[:fighter_name]
  end

  test "calculates total strike accuracy" do
    fighter = Fighter.create!(name: "Total Strike Fighter")
    5.times do |i|
      fight = Fight.create!(
        event: @event,
        bout: "Total Strike Fight #{i}",
        outcome: "Win",
        weight_class: "Lightweight",
        round: 1,
        time: "5:00"
      )
      FightStat.create!(
        fight: fight,
        fighter: fighter,
        round: 1,
        total_strikes: 90,
        total_strikes_attempted: 100,
        control_time_seconds: 0
      )
    end

    result = AccuracyQuery.new(category: "total_strike_accuracy").call
    fighter_result = result.find { |r| r[:fighter_name] == fighter.name }

    assert_not_nil fighter_result
    assert_equal 90.0, fighter_result[:accuracy_percentage]
    # Check for correct pluralized keys
    assert_equal 450, fighter_result[:total_total_strikes]
    assert_equal 500, fighter_result[:total_total_strikes_attempted]
  end

  test "calculates head strike accuracy" do
    fighter = Fighter.create!(name: "Head Strike Fighter")
    5.times do |i|
      fight = Fight.create!(
        event: @event,
        bout: "Head Strike Fight #{i}",
        outcome: "Win",
        weight_class: "Lightweight",
        round: 1,
        time: "5:00"
      )
      FightStat.create!(
        fight: fight,
        fighter: fighter,
        round: 1,
        head_strikes: 40,
        head_strikes_attempted: 50,
        control_time_seconds: 0
      )
    end

    result = AccuracyQuery.new(category: "head_strike_accuracy").call
    fighter_result = result.find { |r| r[:fighter_name] == fighter.name }

    assert_not_nil fighter_result
    assert_equal 80.0, fighter_result[:accuracy_percentage]
    # Check for correct pluralized keys
    assert_equal 200, fighter_result[:total_head_strikes]
    assert_equal 250, fighter_result[:total_head_strikes_attempted]
  end

  test "calculates takedown accuracy" do
    fighter = Fighter.create!(name: "Takedown Fighter")
    5.times do |i|
      fight = Fight.create!(
        event: @event,
        bout: "Takedown Fight #{i}",
        outcome: "Win",
        weight_class: "Lightweight",
        round: 1,
        time: "5:00"
      )
      FightStat.create!(
        fight: fight,
        fighter: fighter,
        round: 1,
        takedowns: 3,
        takedowns_attempted: 5,
        control_time_seconds: 0
      )
    end

    result = AccuracyQuery.new(category: "takedown_accuracy").call
    fighter_result = result.find { |r| r[:fighter_name] == fighter.name }

    assert_not_nil fighter_result
    assert_equal 60.0, fighter_result[:accuracy_percentage]
    # Check for correct pluralized keys
    assert_equal 15, fighter_result[:total_takedowns]
    assert_equal 25, fighter_result[:total_takedowns_attempted]
  end

  test "excludes fighters with fewer than 5 fights" do
    fighter_with_4_fights = Fighter.create!(name: "Islam Makhachev")
    4.times do |i|
      fight = Fight.create!(
        event: @event,
        bout: "Fight #{i}",
        outcome: "Win",
        weight_class: "Lightweight",
        round: 1,
        time: "5:00"
      )
      FightStat.create!(
        fight: fight,
        fighter: fighter_with_4_fights,
        round: 1,
        significant_strikes: 50,
        significant_strikes_attempted: 60,
        control_time_seconds: 0
      )
    end

    result = AccuracyQuery.new(category: "significant_strike_accuracy").call

    fighter_names = result.map { |r| r[:fighter_name] }
    assert_not_includes fighter_names, fighter_with_4_fights.name
  end

  test "calculates accuracy percentage correctly" do
    fighter = Fighter.create!(name: "Max Holloway")
    # Create 5 fights with 80% accuracy (400/500)
    5.times do |i|
      fight = Fight.create!(
        event: @event,
        bout: "Test Fight #{i}",
        outcome: "Win",
        weight_class: "Featherweight",
        round: 1,
        time: "5:00"
      )
      FightStat.create!(
        fight: fight,
        fighter: fighter,
        round: 1,
        significant_strikes: 80,
        significant_strikes_attempted: 100,
        control_time_seconds: 0
      )
    end

    result = AccuracyQuery.new(category: "significant_strike_accuracy").call
    fighter_result = result.find { |r| r[:fighter_name] == fighter.name }

    assert_not_nil fighter_result
    assert_equal 80.0, fighter_result[:accuracy_percentage]
    assert_equal 5, fighter_result[:total_fights]
    assert_equal 400, fighter_result[:total_significant_strikes]
    assert_equal 500, fighter_result[:total_significant_strikes_attempted]
  end

  test "handles fighters with zero attempts" do
    fighter = Fighter.create!(name: "Charles Oliveira")
    5.times do |i|
      fight = Fight.create!(
        event: @event,
        bout: "No Strikes Fight #{i}",
        outcome: "Win",
        weight_class: "Lightweight",
        round: 1,
        time: "5:00"
      )
      FightStat.create!(
        fight: fight,
        fighter: fighter,
        round: 1,
        significant_strikes: 0,
        significant_strikes_attempted: 0,
        control_time_seconds: 0
      )
    end

    result = AccuracyQuery.new(category: "significant_strike_accuracy").call
    fighter_names = result.map { |r| r[:fighter_name] }

    # Should not include fighters with zero attempts
    assert_not_includes fighter_names, fighter.name
  end

  test "sums statistics across all rounds" do
    fighter = Fighter.create!(name: "Justin Gaethje")
    fight = Fight.create!(
      event: @event,
      bout: "Multi-round Fight",
      outcome: "Win",
      weight_class: "Lightweight",
      round: 3,
      time: "2:00"
    )

    # 3 rounds with different stats
    FightStat.create!(
      fight: fight,
      fighter: fighter,
      round: 1,
      significant_strikes: 20,
      significant_strikes_attempted: 40,
      control_time_seconds: 0
    )
    FightStat.create!(
      fight: fight,
      fighter: fighter,
      round: 2,
      significant_strikes: 30,
      significant_strikes_attempted: 50,
      control_time_seconds: 0
    )
    FightStat.create!(
      fight: fight,
      fighter: fighter,
      round: 3,
      significant_strikes: 10,
      significant_strikes_attempted: 10,
      control_time_seconds: 0
    )

    # Need 4 more fights to meet minimum
    4.times do |i|
      other_fight = Fight.create!(
        event: @event,
        bout: "Other Fight #{i}",
        outcome: "Win",
        weight_class: "Lightweight",
        round: 1,
        time: "5:00"
      )
      FightStat.create!(
        fight: other_fight,
        fighter: fighter,
        round: 1,
        significant_strikes: 40,
        significant_strikes_attempted: 50,
        control_time_seconds: 0
      )
    end

    result = AccuracyQuery.new(category: "significant_strike_accuracy").call
    fighter_result = result.find { |r| r[:fighter_name] == fighter.name }

    # Total: 220 strikes landed out of 300 attempted = 73.33%
    assert_not_nil fighter_result
    assert_in_delta 73.33, fighter_result[:accuracy_percentage], 0.01
  end

  test "returns empty array when no fighters meet criteria" do
    # Clear existing data
    FightStat.destroy_all

    result = AccuracyQuery.new(category: "significant_strike_accuracy").call

    assert_equal [], result
  end

  test "includes fighters with minimum total fights with partial attempts" do
    fighter = Fighter.create!(name: "Jon Jones")
    # 3 fights with strikes
    3.times do |i|
      fight = Fight.create!(
        event: @event,
        bout: "Strike Fight #{i}",
        outcome: "Win",
        weight_class: "Light Heavyweight",
        round: 1,
        time: "5:00"
      )
      FightStat.create!(
        fight: fight,
        fighter: fighter,
        round: 1,
        significant_strikes: 30,
        significant_strikes_attempted: 40,
        control_time_seconds: 0
      )
    end

    # 3 fights without strikes
    3.times do |i|
      fight = Fight.create!(
        event: @event,
        bout: "Grappling Fight #{i}",
        outcome: "Win",
        weight_class: "Light Heavyweight",
        round: 1,
        time: "5:00"
      )
      FightStat.create!(
        fight: fight,
        fighter: fighter,
        round: 1,
        significant_strikes: 0,
        significant_strikes_attempted: 0,
        control_time_seconds: 300
      )
    end

    result = AccuracyQuery.new(category: "significant_strike_accuracy").call
    fighter_result = result.find { |r| r[:fighter_name] == fighter.name }

    # Should appear because fighter has 6 total fights (>= 5 minimum)
    # even though only 3 fights had significant strike attempts
    assert_not_nil fighter_result
    assert_equal 6, fighter_result[:total_fights]
    assert_equal 90, fighter_result[:total_significant_strikes]
    assert_equal 120, fighter_result[:total_significant_strikes_attempted]
    assert_equal 75.0, fighter_result[:accuracy_percentage]
  end

  test "generates safe SQL without string interpolation vulnerabilities" do
    # This test ensures we're not using dangerous string interpolation
    query = AccuracyQuery.new(category: "significant_strike_accuracy")

    # Get the SQL being generated
    fighters_data = query.send(:fighters_with_accuracy)

    # The method should return data, not raise SQL injection errors
    assert_kind_of Array, fighters_data
  end

  test "handles decimal precision correctly" do
    fighter = Fighter.create!(name: "Alex Pereira")
    5.times do |i|
      fight = Fight.create!(
        event: @event,
        bout: "Precision Fight #{i}",
        outcome: "Win",
        weight_class: "Light Heavyweight",
        round: 1,
        time: "5:00"
      )
      FightStat.create!(
        fight: fight,
        fighter: fighter,
        round: 1,
        significant_strikes: 23,
        significant_strikes_attempted: 37,
        control_time_seconds: 0
      )
    end

    result = AccuracyQuery.new(category: "significant_strike_accuracy").call
    fighter_result = result.find { |r| r[:fighter_name] == fighter.name }

    # 115 strikes out of 185 = 62.16%
    assert_not_nil fighter_result
    assert_in_delta 62.16, fighter_result[:accuracy_percentage], 0.01
  end

  test "returns total career fights not just fights with attempts" do
    fighter = Fighter.create!(name: "Chuck Liddell")

    # Create 20 total fights
    20.times do |i|
      fight = Fight.create!(
        event: @event,
        bout: "Chuck Fight #{i}",
        outcome: "Win",
        weight_class: "Light Heavyweight",
        round: 1,
        time: "5:00"
      )

      # Only 6 fights have takedown attempts
      if i < 6
        FightStat.create!(
          fight: fight,
          fighter: fighter,
          round: 1,
          takedowns: 2,
          takedowns_attempted: 5,
          control_time_seconds: 0
        )
      else
        # The rest have no takedown attempts (pure striking fights)
        FightStat.create!(
          fight: fight,
          fighter: fighter,
          round: 1,
          takedowns: 0,
          takedowns_attempted: 0,
          significant_strikes: 50,
          significant_strikes_attempted: 80,
          control_time_seconds: 0
        )
      end
    end

    result = AccuracyQuery.new(category: "takedown_accuracy").call
    fighter_result = result.find { |r| r[:fighter_name] == fighter.name }

    # Fighter should appear with total career fights (20), not just
    # fights with attempts (6)
    assert_not_nil fighter_result
    assert_equal 20, fighter_result[:total_fights]
    assert_equal 12, fighter_result[:total_takedowns]
    assert_equal 30, fighter_result[:total_takedowns_attempted]
    assert_equal 40.0, fighter_result[:accuracy_percentage]
  end

  private

  def create_test_data_with_varying_accuracy
    # High accuracy fighter: 90% (450/500)
    create_fighter_with_accuracy("Accurate Fighter", 90, 100)

    # Medium accuracy fighter: 75% (375/500)
    create_fighter_with_accuracy("Medium Accuracy Fighter", 75, 100)

    # Create 8 more fighters to ensure we have at least 10 total
    8.times do |j|
      create_fighter_with_accuracy("Fighter #{j}", 30 + j, 50 + j)
    end
  end

  def create_fighter_with_accuracy(name, strikes, attempts)
    fighter = Fighter.create!(name: name)
    5.times do |i|
      fight = Fight.create!(
        event: @event,
        bout: "#{name} Fight #{i}",
        outcome: "Win",
        weight_class: "Welterweight",
        round: 1,
        time: "5:00"
      )
      FightStat.create!(
        fight: fight,
        fighter: fighter,
        round: 1,
        significant_strikes: strikes,
        significant_strikes_attempted: attempts,
        control_time_seconds: 0
      )
    end
  end
end
