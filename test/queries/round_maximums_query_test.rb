# frozen_string_literal: true

require "test_helper"

class RoundMaximumsQueryTest < ActiveSupport::TestCase
  setup do
    @event1 = Event.create!(
      name: "UFC 300",
      date: Date.new(2024, 4, 13),
      location: "Las Vegas, NV"
    )

    @event2 = Event.create!(
      name: "UFC 301",
      date: Date.new(2024, 5, 4),
      location: "Rio de Janeiro, Brazil"
    )

    @fighter1 = Fighter.create!(name: "Max Holloway")
    @fighter2 = Fighter.create!(name: "Justin Gaethje")
    @fighter3 = Fighter.create!(name: "Calvin Kattar")
    @fighter4 = Fighter.create!(name: "Dustin Poirier")
    @fighter5 = Fighter.create!(name: "Brian Ortega")
    @fighter6 = Fighter.create!(name: "Alexander Volkanovski")

    create_high_volume_fight
    create_knockout_fight
    create_grappling_heavy_fight
  end

  test "returns top 10 single round performances for significant strikes" do
    result = RoundMaximumsQuery.new("significant_strikes").call

    assert_equal 10, result.count
    assert_equal @fighter1.id, result.first[:fighter_id]
    assert_equal "Max Holloway", result.first[:fighter_name]
    assert_equal 80, result.first[:value]
    assert_equal "Calvin Kattar", result.first[:opponent_name]
    assert_equal "UFC 300", result.first[:event_name]
    assert_equal Date.new(2024, 4, 13), result.first[:event_date]
    assert_equal @fight1.id, result.first[:fight_id]
    assert_equal 4, result.first[:round]
  end

  test "returns top 10 single round performances for total strikes" do
    result = RoundMaximumsQuery.new("total_strikes").call

    assert_equal 10, result.count
    assert_equal @fighter1.id, result.first[:fighter_id]
    assert_equal 85, result.first[:value]
    assert_equal 4, result.first[:round]
  end

  test "returns top 10 single round performances for knockdowns" do
    result = RoundMaximumsQuery.new("knockdowns").call

    # We have 3 entries: Justin R1 (2), Justin R2 (2), Dustin R1 (1)
    assert_equal 3, result.count
    assert_equal @fighter2.id, result.first[:fighter_id]
    assert_equal "Justin Gaethje", result.first[:fighter_name]
    assert_equal 2, result.first[:value]
    assert_equal "Dustin Poirier", result.first[:opponent_name]
    # Could be round 1 or 2, both have 2 knockdowns
    assert_includes [1, 2], result.first[:round]
  end

  test "returns top 10 single round performances for takedowns" do
    result = RoundMaximumsQuery.new("takedowns").call

    assert_equal 4, result.count
    assert_equal @fighter5.id, result.first[:fighter_id]
    assert_equal "Brian Ortega", result.first[:fighter_name]
    assert_equal 5, result.first[:value]
    assert_equal "Alexander Volkanovski", result.first[:opponent_name]
    assert_equal 3, result.first[:round]
  end

  test "returns top 10 single round performances for submission attempts" do
    result = RoundMaximumsQuery.new("submission_attempts").call

    assert_equal 3, result.count
    # Round 2 and 3 both have 3 submission attempts
    assert_equal @fighter5.id, result.first[:fighter_id]
    assert_equal 3, result.first[:value]
    assert_includes [2, 3], result.first[:round]
  end

  test "returns top 10 single round performances for control time" do
    result = RoundMaximumsQuery.new("control_time_seconds").call

    assert_equal 3, result.count
    assert_equal @fighter5.id, result.first[:fighter_id]
    assert_equal 300, result.first[:value]
    assert_equal 3, result.first[:round]
  end

  test "supports all strike location statistics" do
    %w[head_strikes body_strikes leg_strikes].each do |stat|
      result = RoundMaximumsQuery.new(stat).call
      assert_not_empty result
      assert result.first[:value].positive?
      assert result.first.key?(:round)
    end
  end

  test "supports all strike position statistics" do
    %w[distance_strikes clinch_strikes ground_strikes].each do |stat|
      result = RoundMaximumsQuery.new(stat).call
      assert_not_empty result
      assert result.first[:value].positive?
      assert result.first.key?(:round)
    end
  end

  test "supports attempted statistics" do
    %w[
      significant_strikes_attempted
      total_strikes_attempted
      head_strikes_attempted
      body_strikes_attempted
      leg_strikes_attempted
      distance_strikes_attempted
      clinch_strikes_attempted
      ground_strikes_attempted
      takedowns_attempted
    ].each do |stat|
      result = RoundMaximumsQuery.new(stat).call
      assert_not_empty result
      assert result.first[:value].positive?
      assert result.first.key?(:round)
    end
  end

  test "does not aggregate statistics across rounds" do
    # Fighter 1 has different stats per round
    result = RoundMaximumsQuery.new("significant_strikes").call

    # Find all Max Holloway entries
    max_entries = result.select { |r| r[:fighter_id] == @fighter1.id }

    # Should have individual round entries, not aggregated
    assert_equal 5, max_entries.count

    # Each entry should have a different round number
    rounds = max_entries.map { |e| e[:round] }
    assert_equal [1, 2, 3, 4, 5].sort, rounds.sort

    # Values should match individual round stats
    round_4_entry = max_entries.find { |e| e[:round] == 4 }
    assert_equal 80, round_4_entry[:value]
  end

  test "limits results to 10" do
    # Create 12 more fighters with varying stats
    12.times do |i|
      fighter = Fighter.create!(name: "Fighter #{i + 7}")
      opponent = Fighter.create!(name: "Opponent #{i + 7}")
      fight = Fight.create!(
        event: @event1,
        bout: "Main Card",
        outcome: "#{fighter.name} def. #{opponent.name}",
        weight_class: "Lightweight"
      )

      FightStat.create!(
        fight: fight,
        fighter: fighter,
        round: 1,
        significant_strikes: 85 + i
      )

      FightStat.create!(
        fight: fight,
        fighter: opponent,
        round: 1,
        significant_strikes: 10 + i
      )
    end

    result = RoundMaximumsQuery.new("significant_strikes").call
    assert_equal 10, result.count
  end

  test "orders by value descending" do
    result = RoundMaximumsQuery.new("significant_strikes").call

    values = result.map { |r| r[:value] }
    assert_equal values.sort.reverse, values
  end

  test "includes all required metadata" do
    result = RoundMaximumsQuery.new("significant_strikes").call.first

    assert result.key?(:fighter_id)
    assert result.key?(:fighter_name)
    assert result.key?(:value)
    assert result.key?(:opponent_name)
    assert result.key?(:event_name)
    assert result.key?(:event_date)
    assert result.key?(:fight_id)
    assert result.key?(:round)
  end

  test "handles fighters with no stats" do
    fighter_no_stats = Fighter.create!(name: "No Stats Fighter")
    result = RoundMaximumsQuery.new("significant_strikes").call

    fighter_ids = result.map { |r| r[:fighter_id] }
    assert_not_includes fighter_ids, fighter_no_stats.id
  end

  test "handles invalid statistic name" do
    assert_raises(ArgumentError) do
      RoundMaximumsQuery.new("invalid_stat").call
    end
  end

  test "prevents SQL injection attempts" do
    assert_raises(ArgumentError) do
      RoundMaximumsQuery.new("knockdowns; DROP TABLE fighters;").call
    end

    assert_raises(ArgumentError) do
      RoundMaximumsQuery.new("1=1 OR knockdowns").call
    end
  end

  test "handles reversals statistic" do
    result = RoundMaximumsQuery.new("reversals").call
    assert_equal 3, result.count
    assert_equal @fighter5.id, result.first[:fighter_id]
    assert_equal 2, result.first[:value]
    # Round 2 and 3 both have 2 reversals
    assert_includes [2, 3], result.first[:round]
  end

  test "returns empty array when no data exists" do
    FightStat.destroy_all
    result = RoundMaximumsQuery.new("significant_strikes").call
    assert_empty result
  end

  test "handles zero values correctly" do
    # Fighter 1 has 0 knockdowns in all rounds
    result = RoundMaximumsQuery.new("knockdowns").call

    # Should not include zero knockdown rounds
    fighter1_entries = result.select { |r| r[:fighter_id] == @fighter1.id }
    assert_empty fighter1_entries
  end

  test "handles nil values correctly" do
    # Create a fight stat with nil values
    fighter = Fighter.create!(name: "Nil Stats Fighter")
    opponent = Fighter.create!(name: "Nil Opponent")
    fight = Fight.create!(
      event: @event1,
      bout: "Prelim",
      outcome: "No Contest",
      weight_class: "Bantamweight"
    )

    FightStat.create!(
      fight: fight,
      fighter: fighter,
      round: 1,
      significant_strikes: nil,
      takedowns: 3
    )

    FightStat.create!(
      fight: fight,
      fighter: opponent,
      round: 1,
      significant_strikes: 20
    )

    # Should not include nil values
    sig_strikes_result = RoundMaximumsQuery.new("significant_strikes").call
    fighter_entries = sig_strikes_result.select do |r|
      r[:fighter_id] == fighter.id
    end
    assert_empty fighter_entries

    # Should include non-nil values
    takedowns_result = RoundMaximumsQuery.new("takedowns").call
    fighter_entry = takedowns_result.find { |r| r[:fighter_id] == fighter.id }
    assert_not_nil fighter_entry
    assert_equal 3, fighter_entry[:value]
  end

  test "returns correct opponent for each round" do
    result = RoundMaximumsQuery.new("significant_strikes").call

    # Find a Max Holloway entry
    max_entry = result.find { |r| r[:fighter_id] == @fighter1.id }
    assert_equal "Calvin Kattar", max_entry[:opponent_name]

    # Find a Justin Gaethje entry
    justin_entry = result.find { |r| r[:fighter_id] == @fighter2.id }
    assert_equal "Dustin Poirier", justin_entry[:opponent_name]
  end

  private

  def create_high_volume_fight
    @fight1 = Fight.create!(
      event: @event1,
      bout: "Main Event",
      outcome: "Max Holloway def. Calvin Kattar",
      weight_class: "Featherweight",
      method: "Decision",
      round: 5,
      time: "5:00",
      time_format: "5 Rds"
    )

    create_max_stats
    create_calvin_stats
  end

  def create_max_stats
    rounds_data = [
      { round: 1, sig: 50, tot: 55, head: 40, dist: 45 },
      { round: 2, sig: 60, tot: 65, head: 50, dist: 55 },
      { round: 3, sig: 70, tot: 75, head: 60, dist: 65 },
      { round: 4, sig: 80, tot: 85, head: 70, dist: 75 },
      { round: 5, sig: 30, tot: 40, head: 25, dist: 28 }
    ]

    rounds_data.each do |data|
      base_stats = build_base_fight_stats(data)
      FightStat.create!(
        base_stats.merge(
          fight: @fight1,
          fighter: @fighter1,
          round: data[:round]
        )
      )
    end
  end

  def build_base_fight_stats(data)
    last_round = data[:round] == 5
    {
      significant_strikes: data[:sig],
      significant_strikes_attempted: data[:sig] + 10,
      total_strikes: data[:tot],
      total_strikes_attempted: data[:tot] + 10,
      head_strikes: data[:head],
      head_strikes_attempted: data[:head] + 10,
      body_strikes: 5,
      body_strikes_attempted: 5,
      leg_strikes: last_round ? 2 : 5,
      leg_strikes_attempted: last_round ? 2 : 5,
      distance_strikes: data[:dist],
      distance_strikes_attempted: data[:dist] + 10,
      clinch_strikes: last_round ? 1 : 3,
      clinch_strikes_attempted: last_round ? 1 : 3,
      ground_strikes: last_round ? 1 : 2,
      ground_strikes_attempted: last_round ? 1 : 2,
      knockdowns: 0,
      takedowns: 0,
      takedowns_attempted: 1,
      submission_attempts: 0,
      reversals: 0,
      control_time_seconds: 0
    }
  end

  def create_calvin_stats
    # Calvin only has one round of stats to keep test data simple
    FightStat.create!(
      fight: @fight1,
      fighter: @fighter3,
      round: 1,
      significant_strikes: 25,
      significant_strikes_attempted: 40,
      total_strikes: 30,
      total_strikes_attempted: 45,
      head_strikes: 20,
      head_strikes_attempted: 35,
      body_strikes: 3,
      body_strikes_attempted: 3,
      leg_strikes: 2,
      leg_strikes_attempted: 2,
      distance_strikes: 22,
      distance_strikes_attempted: 37,
      clinch_strikes: 2,
      clinch_strikes_attempted: 2,
      ground_strikes: 1,
      ground_strikes_attempted: 1
    )
  end

  def create_knockout_fight
    @fight2 = Fight.create!(
      event: @event1,
      bout: "Co-Main Event",
      outcome: "Justin Gaethje def. Dustin Poirier",
      weight_class: "Lightweight",
      method: "TKO",
      round: 2,
      time: "3:22",
      time_format: "3 Rds"
    )

    # Justin's stats - multiple knockdowns
    FightStat.create!(
      fight: @fight2,
      fighter: @fighter2,
      round: 1,
      significant_strikes: 35,
      significant_strikes_attempted: 50,
      total_strikes: 40,
      total_strikes_attempted: 55,
      head_strikes: 30,
      head_strikes_attempted: 45,
      body_strikes: 3,
      body_strikes_attempted: 3,
      leg_strikes: 2,
      leg_strikes_attempted: 2,
      distance_strikes: 32,
      distance_strikes_attempted: 47,
      clinch_strikes: 2,
      clinch_strikes_attempted: 2,
      ground_strikes: 1,
      ground_strikes_attempted: 1,
      knockdowns: 2
    )

    FightStat.create!(
      fight: @fight2,
      fighter: @fighter2,
      round: 2,
      significant_strikes: 25,
      significant_strikes_attempted: 35,
      total_strikes: 30,
      total_strikes_attempted: 40,
      head_strikes: 20,
      head_strikes_attempted: 30,
      body_strikes: 3,
      body_strikes_attempted: 3,
      leg_strikes: 2,
      leg_strikes_attempted: 2,
      distance_strikes: 22,
      distance_strikes_attempted: 32,
      clinch_strikes: 2,
      clinch_strikes_attempted: 2,
      ground_strikes: 1,
      ground_strikes_attempted: 1,
      knockdowns: 2
    )

    # Dustin's stats
    FightStat.create!(
      fight: @fight2,
      fighter: @fighter4,
      round: 1,
      significant_strikes: 30,
      significant_strikes_attempted: 45,
      total_strikes: 35,
      total_strikes_attempted: 50,
      head_strikes: 25,
      head_strikes_attempted: 40,
      body_strikes: 3,
      body_strikes_attempted: 3,
      leg_strikes: 2,
      leg_strikes_attempted: 2,
      distance_strikes: 27,
      distance_strikes_attempted: 42,
      clinch_strikes: 2,
      clinch_strikes_attempted: 2,
      ground_strikes: 1,
      ground_strikes_attempted: 1,
      knockdowns: 1
    )
  end

  def create_grappling_heavy_fight
    @fight3 = Fight.create!(
      event: @event2,
      bout: "Main Event",
      outcome: "Brian Ortega def. Alexander Volkanovski",
      weight_class: "Featherweight",
      method: "Submission",
      round: 3,
      time: "4:15",
      time_format: "5 Rds"
    )

    create_brian_stats
    create_volkanovski_stats
  end

  def create_brian_stats
    rounds_data = [
      { round: 1, sig: 15, tot: 20, td: 3, sub: 2, rev: 1, ctrl: 180 },
      { round: 2, sig: 20, tot: 25, td: 4, sub: 3, rev: 2, ctrl: 240 },
      { round: 3, sig: 25, tot: 30, td: 5, sub: 3, rev: 2, ctrl: 300 }
    ]

    rounds_data.each do |data|
      create_brian_round_stats(data)
    end
  end

  def create_brian_round_stats(data)
    base_stats = {
      fight: @fight3,
      fighter: @fighter5,
      round: data[:round]
    }

    striking_stats = build_brian_striking_stats(data[:sig], data[:tot])
    grappling_stats = build_brian_grappling_stats(data)

    FightStat.create!(
      base_stats.merge(striking_stats).merge(grappling_stats)
    )
  end

  def build_brian_striking_stats(sig, tot)
    {
      significant_strikes: sig,
      significant_strikes_attempted: sig + 10,
      total_strikes: tot,
      total_strikes_attempted: tot + 10,
      head_strikes: sig - 5,
      head_strikes_attempted: sig + 5,
      body_strikes: 3,
      body_strikes_attempted: 3,
      leg_strikes: 2,
      leg_strikes_attempted: 2,
      distance_strikes: sig - 3,
      distance_strikes_attempted: sig + 7,
      clinch_strikes: 2,
      clinch_strikes_attempted: 2,
      ground_strikes: 1,
      ground_strikes_attempted: 1
    }
  end

  def build_brian_grappling_stats(data)
    {
      takedowns: data[:td],
      takedowns_attempted: data[:td] + 1,
      submission_attempts: data[:sub],
      reversals: data[:rev],
      control_time_seconds: data[:ctrl]
    }
  end

  def create_volkanovski_stats
    FightStat.create!(
      fight: @fight3,
      fighter: @fighter6,
      round: 1,
      significant_strikes: 40,
      significant_strikes_attempted: 55,
      total_strikes: 45,
      total_strikes_attempted: 60,
      head_strikes: 35,
      head_strikes_attempted: 50,
      body_strikes: 3,
      body_strikes_attempted: 3,
      leg_strikes: 2,
      leg_strikes_attempted: 2,
      distance_strikes: 37,
      distance_strikes_attempted: 52,
      clinch_strikes: 2,
      clinch_strikes_attempted: 2,
      ground_strikes: 1,
      ground_strikes_attempted: 1,
      takedowns: 1,
      takedowns_attempted: 2
    )
  end
end
