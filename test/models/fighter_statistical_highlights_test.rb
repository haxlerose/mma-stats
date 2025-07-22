# frozen_string_literal: true

require "test_helper"

class FighterStatisticalHighlightsTest < ActiveSupport::TestCase
  def setup
    # Create test events directly
    @event1 = Event.create!(
      name: "UFC 300: Test Event 1",
      date: "2024-04-13",
      location: "Las Vegas, Nevada"
    )
    @event2 = Event.create!(
      name: "UFC 301: Test Event 2",
      date: "2024-05-04",
      location: "Rio de Janeiro, Brazil"
    )

    # Create test fighters directly
    @striker = Fighter.create!(
      name: "Jon Jones",
      height_in_inches: 76,
      reach_in_inches: 84,
      birth_date: "1987-07-19"
    )
    @grappler = Fighter.create!(
      name: "Khabib Nurmagomedov",
      height_in_inches: 70,
      reach_in_inches: 70,
      birth_date: "1988-09-20"
    )
    @finisher = Fighter.create!(
      name: "Anderson Silva",
      height_in_inches: 74,
      reach_in_inches: 77,
      birth_date: "1975-04-14"
    )
    @inactive = Fighter.create!(
      name: "Chuck Liddell",
      height_in_inches: 74,
      reach_in_inches: 76,
      birth_date: "1969-12-17"
    )
  end

  # Fight Time Calculations
  test "calculates fight time correctly for early first round finish" do
    fight = create_fight(
      @event1,
      "Jon Jones vs Test Opponent",
      "W/L",
      1,
      "2:31"
    )

    expected_minutes = 2 + (31.0 / 60) # 2:31 = 2.52 minutes
    assert_in_delta expected_minutes,
                    @striker.send(:calculate_fight_time, fight),
                    0.01
  end

  test "calculates fight time correctly for second round finish" do
    fight = create_fight(
      @event1,
      "Jon Jones vs Test Opponent",
      "W/L",
      2,
      "1:45"
    )

    expected_minutes = 5 + 1 + (45.0 / 60) # Round 1 + 1:45 = 6.75 minutes
    assert_in_delta expected_minutes,
                    @striker.send(:calculate_fight_time, fight),
                    0.01
  end

  test "calculates fight time correctly for three round decision" do
    fight = create_fight(
      @event1,
      "Jon Jones vs Test Opponent",
      "W/L",
      3,
      "5:00"
    )

    expected_minutes = 15.0 # 3 full rounds = 15 minutes
    assert_in_delta expected_minutes,
                    @striker.send(:calculate_fight_time, fight),
                    0.01
  end

  test "calculates fight time correctly for five round decision" do
    fight = create_fight(
      @event1,
      "Jon Jones vs Test Opponent",
      "W/L",
      5,
      "5:00"
    )

    expected_minutes = 25.0 # 5 full rounds = 25 minutes
    assert_in_delta expected_minutes,
                    @striker.send(:calculate_fight_time, fight),
                    0.01
  end

  # Statistical Calculations
  test "calculates strikes landed per 15 minutes" do
    create_high_volume_striker_data(@striker)

    result = @striker.strikes_landed_per_15_min
    assert_operator result, :>, 0
    assert_instance_of Float, result
  end

  test "calculates submission attempts per 15 minutes" do
    create_submission_specialist_data(@grappler)

    result = @grappler.submission_attempts_per_15_min
    assert_operator result, :>, 0
    assert_instance_of Float, result
  end

  test "calculates takedowns landed per 15 minutes" do
    create_wrestling_specialist_data(@grappler)

    result = @grappler.takedowns_landed_per_15_min
    assert_operator result, :>, 0
    assert_instance_of Float, result
  end

  test "calculates knockdowns per 15 minutes" do
    create_knockout_artist_data(@finisher)

    result = @finisher.knockdowns_per_15_min
    assert_operator result, :>, 0
    assert_instance_of Float, result
  end

  # Minimum Requirements
  test "excludes fighters below 5 fight minimum for strikes" do
    create_low_activity_fighter_data(@inactive)

    leaders = Fighter.statistical_highlights
    fighter_names = leaders.filter_map do |category|
      category[:fighter]&.[](:name)
    end

    assert_not_includes fighter_names, @inactive.name
  end

  test "excludes fighters below 350 strike attempts minimum" do
    create_low_volume_striker_data(@striker)

    leaders = Fighter.statistical_highlights
    strikes_leader = leaders.find do |cat|
      cat[:category] == "strikes_per_15min"
    end

    # Either no leader found (nil fighter) or different fighter found
    assert(
      strikes_leader[:fighter].nil? ||
                 strikes_leader[:fighter][:name] != @striker.name
    )
  end

  test "excludes fighters below 20 takedown attempts minimum" do
    create_low_volume_wrestler_data(@grappler)

    leaders = Fighter.statistical_highlights
    takedowns_leader = leaders.find do |cat|
      cat[:category] == "takedowns_per_15min"
    end

    # Either no leader found (nil fighter) or different fighter found
    assert(
      takedowns_leader[:fighter].nil? ||
                 takedowns_leader[:fighter][:name] != @grappler.name
    )
  end

  # Leader Finding
  test "finds statistical highlights leaders" do
    create_comprehensive_test_data

    leaders = Fighter.statistical_highlights

    assert_equal 4, leaders.length

    categories = leaders.map { |cat| cat[:category] }
    expected_categories = %w[
      strikes_per_15min
      submission_attempts_per_15min
      takedowns_per_15min
      knockdowns_per_15min
    ]

    assert_equal expected_categories.sort, categories.sort

    # Each leader should have required fields
    leaders.each do |leader|
      assert_not_nil leader[:fighter][:name]
      assert_not_nil leader[:value]
      assert_operator leader[:value], :>, 0
    end
  end

  test "returns empty when no fighters meet minimums" do
    # Don't create any qualifying data

    leaders = Fighter.statistical_highlights

    assert_equal 4, leaders.length
    leaders.each do |leader|
      assert_nil leader[:fighter]
      assert_equal 0, leader[:value]
    end
  end

  private

  # Test data creation helpers
  def create_fight(event, bout, outcome, round, time)
    Fight.create!(
      event: event,
      bout: bout,
      outcome: outcome,
      weight_class: "Heavyweight",
      method: "TKO",
      round: round,
      time: time,
      referee: "Herb Dean"
    )
  end

  def create_fight_stat(fight, fighter, round, stats = {})
    default_stats = {
      round: round,
      significant_strikes: 0,
      significant_strikes_attempted: 0,
      total_strikes: 0,
      total_strikes_attempted: 0,
      takedowns: 0,
      takedowns_attempted: 0,
      submission_attempts: 0,
      knockdowns: 0,
      head_strikes: 0,
      head_strikes_attempted: 0,
      body_strikes: 0,
      body_strikes_attempted: 0,
      leg_strikes: 0,
      leg_strikes_attempted: 0,
      distance_strikes: 0,
      distance_strikes_attempted: 0,
      clinch_strikes: 0,
      clinch_strikes_attempted: 0,
      ground_strikes: 0,
      ground_strikes_attempted: 0,
      reversals: 0,
      control_time_seconds: 0
    }

    FightStat.create!(
      fight: fight,
      fighter: fighter,
      **default_stats.merge(stats)
    )
  end

  def create_high_volume_striker_data(fighter)
    # Create 5 fights with high strike volume (meets minimums)
    5.times do |i|
      fight = create_fight(
        @event1,
        "#{fighter.name} vs Opponent #{i}",
        "W/L",
        3,
        "5:00"
      )

      3.times do |round|
        create_fight_stat(
          fight,
          fighter,
          round + 1,
          {
            significant_strikes: 30,
            significant_strikes_attempted: 40,
            total_strikes: 50,
            total_strikes_attempted: 60
          }
        )
      end
    end
  end

  def create_submission_specialist_data(fighter)
    # Create 5 fights with high submission attempts
    5.times do |i|
      fight = create_fight(
        @event2,
        "#{fighter.name} vs Opponent #{i}",
        "W/L",
        2,
        "3:15"
      )

      2.times do |round|
        create_fight_stat(
          fight,
          fighter,
          round + 1,
          {
            submission_attempts: 2,
            takedowns: 3,
            takedowns_attempted: 4
          }
        )
      end
    end
  end

  def create_wrestling_specialist_data(fighter)
    # Create 5 fights with high takedown volume (meets minimums)
    5.times do |i|
      fight = create_fight(
        @event1,
        "#{fighter.name} vs Opponent #{i}",
        "W/L",
        3,
        "5:00"
      )

      3.times do |round|
        create_fight_stat(
          fight,
          fighter,
          round + 1,
          {
            takedowns: 2,
            takedowns_attempted: 3
          }
        )
      end
    end
  end

  def create_knockout_artist_data(fighter)
    # Create 5 fights with knockdowns
    5.times do |i|
      fight = create_fight(
        @event2,
        "#{fighter.name} vs Opponent #{i}",
        "W/L",
        1,
        "4:22"
      )

      create_fight_stat(
        fight,
        fighter,
        1,
        {
          knockdowns: 1,
          significant_strikes: 15,
          significant_strikes_attempted: 20
        }
      )
    end
  end

  def create_low_activity_fighter_data(fighter)
    # Only 3 fights (below 5 minimum)
    3.times do |i|
      fight = create_fight(
        @event1,
        "#{fighter.name} vs Opponent #{i}",
        "W/L",
        3,
        "5:00"
      )

      create_fight_stat(
        fight,
        fighter,
        1,
        {
          significant_strikes: 50,
          significant_strikes_attempted: 60
        }
      )
    end
  end

  def create_low_volume_striker_data(fighter)
    # 5 fights but low strike volume (below 350 attempts minimum)
    5.times do |i|
      fight = create_fight(
        @event1,
        "#{fighter.name} vs Opponent #{i}",
        "W/L",
        3,
        "5:00"
      )

      create_fight_stat(
        fight,
        fighter,
        1,
        {
          significant_strikes: 10,
          significant_strikes_attempted: 15 # Total: 75 attempts (below 350)
        }
      )
    end
  end

  def create_low_volume_wrestler_data(fighter)
    # 5 fights but low takedown volume (below 20 attempts minimum)
    5.times do |i|
      fight = create_fight(
        @event1,
        "#{fighter.name} vs Opponent #{i}",
        "W/L",
        3,
        "5:00"
      )

      create_fight_stat(
        fight,
        fighter,
        1,
        {
          takedowns: 0,
          takedowns_attempted: 1 # Total: 5 attempts (below 20)
        }
      )
    end
  end

  def create_comprehensive_test_data
    create_high_volume_striker_data(@striker)
    create_submission_specialist_data(@grappler)
    create_wrestling_specialist_data(@grappler)
    create_knockout_artist_data(@finisher)
  end
end
