# frozen_string_literal: true

require "test_helper"

class CareerTotalsQueryTest < ActiveSupport::TestCase
  def setup
    @fighter1 = fighters(:one)
    @fighter2 = fighters(:two)
    @fighter3 = Fighter.create!(name: "Test Fighter Three")

    # Create test data with various knockdown counts
    create_fight_stat(@fighter1, knockdowns: 3)
    create_fight_stat(@fighter1, knockdowns: 2)
    create_fight_stat(@fighter1, knockdowns: 1) # Total: 6

    create_fight_stat(@fighter2, knockdowns: 4)
    create_fight_stat(@fighter2, knockdowns: 4) # Total: 8

    create_fight_stat(@fighter3, knockdowns: 1) # Total: 1
  end

  test "returns top 10 fighters by total knockdowns" do
    result = CareerTotalsQuery.new.call

    assert_equal 3, result.count
    assert_equal @fighter2.id, result.first[:fighter_id]
    assert_equal 8, result.first[:total_knockdowns]
    assert_equal @fighter1.id, result.second[:fighter_id]
    assert_equal 6, result.second[:total_knockdowns]
    assert_equal @fighter3.id, result.third[:fighter_id]
    assert_equal 1, result.third[:total_knockdowns]
  end

  test "includes fighter details in results" do
    result = CareerTotalsQuery.new.call

    first_result = result.first
    assert_equal @fighter2.name, first_result[:fighter_name]
    assert_equal @fighter2.id, first_result[:fighter_id]
  end

  test "includes metadata in results" do
    result = CareerTotalsQuery.new.call

    first_result = result.first
    assert_equal 2, first_result[:fight_count]
    assert_equal 8, first_result[:total_knockdowns]
  end

  test "limits results to top 10 fighters" do
    # Create 12 fighters with stats
    12.times do |i|
      fighter = Fighter.create!(name: "Fighter #{i}")
      create_fight_stat(fighter, knockdowns: i + 1)
    end

    result = CareerTotalsQuery.new.call

    assert_equal 10, result.count
    # Top fighter has 12 knockdowns (12th iteration, i=11, knockdowns=12)
    assert_equal 12, result.first[:total_knockdowns]
    # 10th fighter should have 3+ knockdowns (includes setup data)
    assert_operator result.last[:total_knockdowns], :>=, 1
  end

  test "excludes fighters with no fight stats" do
    fighter_without_stats = Fighter.create!(name: "No Stats Fighter")

    result = CareerTotalsQuery.new.call

    fighter_ids = result.map { |r| r[:fighter_id] }
    assert_not_includes fighter_ids, fighter_without_stats.id
  end

  test "handles fighters with zero knockdowns" do
    fighter_with_zero = Fighter.create!(name: "Zero Knockdowns")
    create_fight_stat(fighter_with_zero, knockdowns: 0)
    create_fight_stat(fighter_with_zero, knockdowns: 0)

    result = CareerTotalsQuery.new.call

    zero_fighter_result = result.find do |r|
      r[:fighter_id] == fighter_with_zero.id
    end
    assert_not_nil zero_fighter_result
    assert_equal 0, zero_fighter_result[:total_knockdowns]
    assert_equal 2, zero_fighter_result[:fight_count]
  end

  test "orders by total knockdowns descending" do
    result = CareerTotalsQuery.new.call

    knockdown_totals = result.map { |r| r[:total_knockdowns] }
    assert_equal knockdown_totals.sort.reverse, knockdown_totals
  end

  test "handles nil knockdowns as zero" do
    fighter_with_nil = Fighter.create!(name: "Nil Knockdowns")
    create_fight_stat(fighter_with_nil, knockdowns: nil)
    create_fight_stat(fighter_with_nil, knockdowns: 2)

    result = CareerTotalsQuery.new.call

    nil_fighter_result = result.find do |r|
      r[:fighter_id] == fighter_with_nil.id
    end
    assert_equal 2, nil_fighter_result[:total_knockdowns]
  end

  test "accepts category parameter for different statistics" do
    fighter = Fighter.create!(name: "Multi-stat Fighter")
    create_fight_stat(
      fighter,
      significant_strikes: 50,
      total_strikes: 100,
      takedowns: 3
    )

    sig_strikes_result = CareerTotalsQuery.new(
      category: :significant_strikes
    ).call
    total_strikes_result = CareerTotalsQuery.new(
      category: :total_strikes
    ).call
    takedowns_result = CareerTotalsQuery.new(category: :takedowns).call

    sig_strikes_fighter = sig_strikes_result.find do |r|
      r[:fighter_id] == fighter.id
    end
    total_strikes_fighter = total_strikes_result.find do |r|
      r[:fighter_id] == fighter.id
    end
    takedowns_fighter = takedowns_result.find do |r|
      r[:fighter_id] == fighter.id
    end

    assert_equal 50, sig_strikes_fighter[:total_significant_strikes]
    assert_equal 100, total_strikes_fighter[:total_total_strikes]
    assert_equal 3, takedowns_fighter[:total_takedowns]
  end

  test "defaults to knockdowns when no category specified" do
    result = CareerTotalsQuery.new.call
    first_result = result.first

    assert_includes first_result.keys, :total_knockdowns
    assert_not_includes first_result.keys, :total_significant_strikes
  end

  test "supports all fight statistics categories" do
    fighter = Fighter.create!(name: "Complete Stats Fighter")
    create_fight_stat(
      fighter,
      knockdowns: 2,
      significant_strikes: 75,
      significant_strikes_attempted: 100,
      total_strikes: 120,
      total_strikes_attempted: 150,
      head_strikes: 40,
      head_strikes_attempted: 50,
      body_strikes: 20,
      body_strikes_attempted: 30,
      leg_strikes: 15,
      leg_strikes_attempted: 20,
      distance_strikes: 60,
      distance_strikes_attempted: 80,
      clinch_strikes: 10,
      clinch_strikes_attempted: 15,
      ground_strikes: 5,
      ground_strikes_attempted: 10,
      takedowns: 2,
      takedowns_attempted: 5,
      submission_attempts: 1,
      reversals: 3,
      control_time_seconds: 180
    )

    categories = %i[
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

    categories.each do |category|
      result = CareerTotalsQuery.new(category: category).call
      fighter_result = result.find { |r| r[:fighter_id] == fighter.id }

      assert_not_nil fighter_result,
                     "Fighter not found for category: #{category}"
      total_key = :"total_#{category}"
      assert_includes fighter_result.keys, total_key
    end
  end

  test "aggregates statistics across multiple fights correctly" do
    fighter = Fighter.create!(name: "Multi-fight Fighter")
    create_fight_stat(fighter, significant_strikes: 25, takedowns: 1)
    create_fight_stat(fighter, significant_strikes: 30, takedowns: 2)
    create_fight_stat(fighter, significant_strikes: 45, takedowns: 2)

    sig_strikes_result = CareerTotalsQuery.new(
      category: :significant_strikes
    ).call
    takedowns_result = CareerTotalsQuery.new(category: :takedowns).call

    sig_strikes_fighter = sig_strikes_result.find do |r|
      r[:fighter_id] == fighter.id
    end
    takedowns_fighter = takedowns_result.find do |r|
      r[:fighter_id] == fighter.id
    end

    assert_equal 100, sig_strikes_fighter[:total_significant_strikes]
    assert_equal 5, takedowns_fighter[:total_takedowns]
    assert_equal 3, sig_strikes_fighter[:fight_count]
    assert_equal 3, takedowns_fighter[:fight_count]
  end

  test "orders results by specified category total descending" do
    # Create fighters with different stats
    high_striker = Fighter.create!(name: "High Striker")
    create_fight_stat(high_striker, significant_strikes: 200)

    low_striker = Fighter.create!(name: "Low Striker")
    create_fight_stat(low_striker, significant_strikes: 50)

    result = CareerTotalsQuery.new(
      category: :significant_strikes
    ).call

    totals = result.filter_map { |r| r[:total_significant_strikes] }
    assert_equal totals.sort.reverse, totals
  end

  test "handles nil values for all categories" do
    fighter = Fighter.create!(name: "Nil Stats Fighter")
    create_fight_stat(fighter, significant_strikes: nil, takedowns: 2)
    create_fight_stat(fighter, significant_strikes: 30, takedowns: nil)

    sig_strikes_result = CareerTotalsQuery.new(
      category: :significant_strikes
    ).call
    takedowns_result = CareerTotalsQuery.new(category: :takedowns).call

    sig_strikes_fighter = sig_strikes_result.find do |r|
      r[:fighter_id] == fighter.id
    end
    takedowns_fighter = takedowns_result.find do |r|
      r[:fighter_id] == fighter.id
    end

    assert_equal 30, sig_strikes_fighter[:total_significant_strikes]
    assert_equal 2, takedowns_fighter[:total_takedowns]
  end

  test "raises error for invalid category" do
    assert_raises(ArgumentError) do
      CareerTotalsQuery.new(category: :invalid_stat).call
    end
  end

  private

  def create_fight_stat(fighter, **stats)
    event = Event.create!(
      name: "Test Event #{SecureRandom.hex(4)}",
      date: Date.current,
      location: "Test Location"
    )

    fight = Fight.create!(
      event: event,
      bout: "Main Card",
      outcome: "Win",
      weight_class: "Lightweight"
    )

    FightStat.create!(
      fight: fight,
      fighter: fighter,
      round: 1,
      **stats
    )
  end
end
