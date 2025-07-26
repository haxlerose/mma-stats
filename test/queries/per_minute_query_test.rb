# frozen_string_literal: true

require "test_helper"

class PerMinuteQueryTest < ActiveSupport::TestCase
  def setup
    @event = Event.create!(
      name: "UFC 300: Pereira vs Hill",
      date: "2024-04-13",
      location: "Las Vegas, Nevada"
    )
  end

  test "returns top 10 fighters ordered by rate per 15 minutes" do
    create_test_data_with_varying_rates

    result = PerMinuteQuery.new(:knockdowns).call

    assert_equal 10, result.length
    assert_equal "High Rate Fighter", result.first[:fighter_name]
    assert_equal "Medium Rate Fighter", result.second[:fighter_name]
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
        knockdowns: 2,
        control_time_seconds: 0
      )
    end

    result = PerMinuteQuery.new(:knockdowns).call

    fighter_names = result.map { |r| r[:fighter_name] }
    assert_not_includes fighter_names, fighter_with_4_fights.name
  end

  test "calculates rate per 15 minutes correctly" do
    fighter = Fighter.create!(name: "Max Holloway")
    # Create 5 fights with 5 minutes each = 25 minutes total
    # 10 knockdowns total = 6 knockdowns per 15 minutes
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
        knockdowns: 2,
        control_time_seconds: 0
      )
    end

    result = PerMinuteQuery.new(:knockdowns).call
    fighter_result = result.find { |r| r[:fighter_name] == fighter.name }

    assert_not_nil fighter_result
    assert_equal 6.0, fighter_result[:rate_per_15_minutes]
    assert_equal 1500, fighter_result[:total_time_seconds] # 25 minutes
    assert_equal 5, fighter_result[:total_fights]
  end

  test "handles fighters with zero fight time" do
    fighter = Fighter.create!(name: "Charles Oliveira")
    5.times do |i|
      fight = Fight.create!(
        event: @event,
        bout: "Quick Fight #{i}",
        outcome: "No Contest",
        weight_class: "Lightweight",
        round: 0,
        time: "0:00"
      )
      # Create a stat for round 1 but fight ended in round 0
      FightStat.create!(
        fight: fight,
        fighter: fighter,
        round: 1,
        knockdowns: 1,
        control_time_seconds: 0
      )
    end

    result = PerMinuteQuery.new(:knockdowns).call
    fighter_names = result.map { |r| r[:fighter_name] }

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
      time: "2:00" # Fight ended at 2:00 of round 3
    )

    # 3 rounds with different stats
    FightStat.create!(
      fight: fight,
      fighter: fighter,
      round: 1,
      significant_strikes: 20,
      control_time_seconds: 0
    )
    FightStat.create!(
      fight: fight,
      fighter: fighter,
      round: 2,
      significant_strikes: 30,
      control_time_seconds: 0
    )
    FightStat.create!(
      fight: fight,
      fighter: fighter,
      round: 3,
      significant_strikes: 10,
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
        significant_strikes: 10,
        control_time_seconds: 0
      )
    end

    result = PerMinuteQuery.new(:significant_strikes).call
    fighter_result = result.find { |r| r[:fighter_name] == fighter.name }

    # Total: 100 strikes in 1920 seconds
    # Fight 1: 2 full rounds (600s) + 120s = 720s total
    # Fights 2-5: 4 fights * 300s = 1200s
    # Total: 720 + 1200 = 1920 seconds
    # Rate per 15 min: 100 * 900 / 1920 ≈ 46.88
    assert_not_nil fighter_result
    assert_in_delta 46.88, fighter_result[:rate_per_15_minutes], 0.01
  end

  test "supports all statistic types" do
    statistic_types = %i[
      knockdowns
      significant_strikes
      significant_strikes_attempted
      total_strikes
      total_strikes_attempted
      takedowns
      takedowns_attempted
      submission_attempts
      reversals
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
    ]

    statistic_types.each do |stat_type|
      assert_nothing_raised do
        PerMinuteQuery.new(stat_type).call
      end
    end
  end

  test "returns empty array when no fighters meet criteria" do
    # Clear existing data
    FightStat.destroy_all

    result = PerMinuteQuery.new(:knockdowns).call

    assert_equal [], result
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
        time: "2:37" # 157 seconds for precision testing
      )
      FightStat.create!(
        fight: fight,
        fighter: fighter,
        round: 1,
        significant_strikes: 7,
        control_time_seconds: 0
      )
    end

    result = PerMinuteQuery.new(:significant_strikes).call
    fighter_result = result.find { |r| r[:fighter_name] == fighter.name }

    # 35 strikes in 785 seconds
    # Rate per 15 min: 35 * 900 / 785 ≈ 40.13
    assert_not_nil fighter_result
    assert_in_delta 40.13, fighter_result[:rate_per_15_minutes], 0.01
  end

  test "only counts fights with recorded time" do
    fighter = Fighter.create!(name: "Jon Jones")
    # 3 fights with time
    3.times do |i|
      fight = Fight.create!(
        event: @event,
        bout: "Timed Fight #{i}",
        outcome: "Win",
        weight_class: "Light Heavyweight",
        round: 1,
        time: "5:00"
      )
      FightStat.create!(
        fight: fight,
        fighter: fighter,
        round: 1,
        knockdowns: 1,
        control_time_seconds: 0
      )
    end

    # 3 fights without valid stats (fighter not in these fights)
    3.times do |i|
      Fight.create!(
        event: @event,
        bout: "No Time Fight #{i}",
        outcome: "Win",
        weight_class: "Light Heavyweight",
        round: 0,
        time: "0:00"
      )
      # Don't create stats for this fighter in these fights
    end

    result = PerMinuteQuery.new(:knockdowns).call
    fighter_names = result.map { |r| r[:fighter_name] }

    # Should not appear because only 3 fights total (< 5 minimum)
    assert_not_includes fighter_names, fighter.name
  end

  private

  def create_test_data_with_varying_rates
    # High rate fighter: 20 knockdowns in 10 minutes = 30 per 15 min
    high_rate_fighter = Fighter.create!(name: "High Rate Fighter")
    5.times do |i|
      fight = Fight.create!(
        event: @event,
        bout: "High Rate Fight #{i}",
        outcome: "Win",
        weight_class: "Welterweight",
        round: 1,
        time: "2:00" # 2 minutes each
      )
      FightStat.create!(
        fight: fight,
        fighter: high_rate_fighter,
        round: 1,
        knockdowns: 4,
        control_time_seconds: 0
      )
    end

    # Medium rate fighter: 15 knockdowns in 15 minutes = 15 per 15 min
    medium_rate_fighter = Fighter.create!(name: "Medium Rate Fighter")
    5.times do |i|
      fight = Fight.create!(
        event: @event,
        bout: "Medium Rate Fight #{i}",
        outcome: "Win",
        weight_class: "Welterweight",
        round: 1,
        time: "3:00" # 3 minutes each
      )
      FightStat.create!(
        fight: fight,
        fighter: medium_rate_fighter,
        round: 1,
        knockdowns: 3,
        control_time_seconds: 0
      )
    end

    # Create 8 more fighters to ensure we have at least 10 total
    8.times do |j|
      fighter = Fighter.create!(name: "Fighter #{j}")
      5.times do |i|
        fight = Fight.create!(
          event: @event,
          bout: "Fight #{j}-#{i}",
          outcome: "Win",
          weight_class: "Various",
          round: 1,
          time: "5:00"
        )
        FightStat.create!(
          fight: fight,
          fighter: fighter,
          round: 1,
          knockdowns: 1,
          control_time_seconds: 0
        )
      end
    end
  end
end
