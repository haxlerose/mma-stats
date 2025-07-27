# frozen_string_literal: true

require "test_helper"

class FightMaximumsQueryTest < ActiveSupport::TestCase
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

  test "returns top 10 fighters for significant strikes" do
    result = FightMaximumsQuery.new("significant_strikes").call

    assert_equal 6, result.count
    assert_equal @fighter1.id, result.first[:fighter_id]
    assert_equal "Max Holloway", result.first[:fighter_name]
    assert_equal 290, result.first[:value]
    assert_equal "Calvin Kattar", result.first[:opponent_name]
    assert_equal "UFC 300", result.first[:event_name]
    assert_equal Date.new(2024, 4, 13), result.first[:event_date]
    assert_equal @fight1.id, result.first[:fight_id]
  end

  test "returns top 10 fighters for total strikes" do
    result = FightMaximumsQuery.new("total_strikes").call

    assert_equal 6, result.count
    assert_equal @fighter1.id, result.first[:fighter_id]
    assert_equal 320, result.first[:value]
  end

  test "returns top 10 fighters for knockdowns" do
    result = FightMaximumsQuery.new("knockdowns").call

    assert_equal 2, result.count
    assert_equal @fighter2.id, result.first[:fighter_id]
    assert_equal "Justin Gaethje", result.first[:fighter_name]
    assert_equal 4, result.first[:value]
    assert_equal "Dustin Poirier", result.first[:opponent_name]
  end

  test "returns top 10 fighters for takedowns" do
    result = FightMaximumsQuery.new("takedowns").call

    assert_equal 2, result.count
    assert_equal @fighter5.id, result.first[:fighter_id]
    assert_equal "Brian Ortega", result.first[:fighter_name]
    assert_equal 12, result.first[:value]
    assert_equal "Alexander Volkanovski", result.first[:opponent_name]
  end

  test "returns top 10 fighters for submission attempts" do
    result = FightMaximumsQuery.new("submission_attempts").call

    assert_equal 1, result.count
    assert_equal @fighter5.id, result.first[:fighter_id]
    assert_equal 8, result.first[:value]
  end

  test "returns top 10 fighters for control time" do
    result = FightMaximumsQuery.new("control_time_seconds").call

    assert_equal 1, result.count
    assert_equal @fighter5.id, result.first[:fighter_id]
    assert_equal 720, result.first[:value]
  end

  test "supports all strike location statistics" do
    %w[head_strikes body_strikes leg_strikes].each do |stat|
      result = FightMaximumsQuery.new(stat).call
      assert_not_empty result
      assert result.first[:value].positive?
    end
  end

  test "supports all strike position statistics" do
    %w[distance_strikes clinch_strikes ground_strikes].each do |stat|
      result = FightMaximumsQuery.new(stat).call
      assert_not_empty result
      assert result.first[:value].positive?
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
      result = FightMaximumsQuery.new(stat).call
      assert_not_empty result
      assert result.first[:value].positive?
    end
  end

  test "aggregates statistics across all rounds" do
    # Fighter 1 has stats in rounds 1-5 of fight1
    result = FightMaximumsQuery.new("significant_strikes").call
    fighter1_result = result.find { |r| r[:fighter_id] == @fighter1.id }

    # Should sum all 5 rounds: 50 + 60 + 70 + 80 + 30 = 290
    assert_equal 290, fighter1_result[:value]
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
        significant_strikes: 20 + i
      )

      FightStat.create!(
        fight: fight,
        fighter: opponent,
        round: 1,
        significant_strikes: 10 + i
      )
    end

    result = FightMaximumsQuery.new("significant_strikes").call
    assert_equal 10, result.count
  end

  test "orders by value descending" do
    result = FightMaximumsQuery.new("significant_strikes").call

    values = result.map { |r| r[:value] }
    assert_equal values.sort.reverse, values
  end

  test "includes all required metadata" do
    result = FightMaximumsQuery.new("significant_strikes").call.first

    assert result.key?(:fighter_id)
    assert result.key?(:fighter_name)
    assert result.key?(:value)
    assert result.key?(:opponent_name)
    assert result.key?(:event_name)
    assert result.key?(:event_date)
    assert result.key?(:fight_id)
  end

  test "handles fighters with no stats" do
    fighter_no_stats = Fighter.create!(name: "No Stats Fighter")
    result = FightMaximumsQuery.new("significant_strikes").call

    fighter_ids = result.map { |r| r[:fighter_id] }
    assert_not_includes fighter_ids, fighter_no_stats.id
  end

  test "handles invalid statistic name" do
    assert_raises(ArgumentError) do
      FightMaximumsQuery.new("invalid_stat").call
    end
  end

  test "prevents SQL injection attempts" do
    assert_raises(ArgumentError) do
      FightMaximumsQuery.new("knockdowns; DROP TABLE fighters;").call
    end

    assert_raises(ArgumentError) do
      FightMaximumsQuery.new("1=1 OR knockdowns").call
    end
  end

  test "handles reversals statistic" do
    result = FightMaximumsQuery.new("reversals").call
    assert_equal 1, result.count
    assert_equal @fighter5.id, result.first[:fighter_id]
    assert_equal 5, result.first[:value]
  end

  test "returns empty array when no data exists" do
    FightStat.destroy_all
    result = FightMaximumsQuery.new("significant_strikes").call
    assert_empty result
  end

  private

  def create_high_volume_fight
    create_max_holloway_fight
  end

  def create_max_holloway_fight
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
    FightStat.create!(
      fight: @fight1,
      fighter: @fighter3,
      round: 1,
      significant_strikes: 25,
      significant_strikes_attempted: 40,
      total_strikes: 30,
      total_strikes_attempted: 45
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
      FightStat.create!(
        fight: @fight3,
        fighter: @fighter5,
        round: data[:round],
        significant_strikes: data[:sig],
        significant_strikes_attempted: data[:sig] + 10,
        total_strikes: data[:tot],
        total_strikes_attempted: data[:tot] + 10,
        takedowns: data[:td],
        takedowns_attempted: data[:td] + 1,
        submission_attempts: data[:sub],
        reversals: data[:rev],
        control_time_seconds: data[:ctrl]
      )
    end
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
      takedowns: 1,
      takedowns_attempted: 2
    )
  end
end
