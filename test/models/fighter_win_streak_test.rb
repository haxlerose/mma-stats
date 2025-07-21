# frozen_string_literal: true

require "test_helper"

class FighterWinStreakTest < ActiveSupport::TestCase
  def setup
    # Create test events with different dates
    @recent_event = Event.create!(
      name: "UFC 300",
      date: 1.month.ago,
      location: "Las Vegas"
    )

    @older_event = Event.create!(
      name: "UFC 299",
      date: 3.months.ago,
      location: "Miami"
    )

    @ancient_event = Event.create!(
      name: "UFC 200",
      date: 3.years.ago,
      location: "Las Vegas"
    )

    # Create test fighters
    @fighter_on_streak = Fighter.create!(name: "Winner McGee")
    @fighter_lost_recent = Fighter.create!(name: "Recent Loser")
    @fighter_inactive = Fighter.create!(name: "Inactive Fighter")
  end

  test "calculates win streak correctly for fighter with consecutive wins" do
    # Create 3 consecutive wins for fighter_on_streak
    fight1 = Fight.create!(
      event: @older_event,
      bout: "Winner McGee vs Opponent One",
      outcome: "W/L",  # Winner McGee wins
      weight_class: "Welterweight",
      method: "KO/TKO",
      round: 1,
      time: "2:30",
      referee: "Herb Dean"
    )

    fight2 = Fight.create!(
      event: @recent_event,
      bout: "Winner McGee vs Opponent Two",
      outcome: "W/L",  # Winner McGee wins
      weight_class: "Welterweight",
      method: "Decision",
      round: 3,
      time: "5:00",
      referee: "Marc Goddard"
    )

    # Create fight stats linking fighter to fights
    FightStat.create!(
      fight: fight1,
      fighter: @fighter_on_streak,
      round: 1
    )

    FightStat.create!(
      fight: fight2,
      fighter: @fighter_on_streak,
      round: 3
    )

    assert_equal 2, @fighter_on_streak.current_win_streak
  end

  test "returns zero win streak for fighter who lost most recent fight" do
    # Fighter won first, then lost most recent
    fight1 = Fight.create!(
      event: @older_event,
      bout: "Recent Loser vs Opponent One",
      outcome: "W/L",  # Recent Loser wins
      weight_class: "Lightweight",
      method: "Submission",
      round: 2,
      time: "3:45",
      referee: "Jason Herzog"
    )

    fight2 = Fight.create!(
      event: @recent_event,
      bout: "Recent Loser vs Opponent Two",
      outcome: "L/W",  # Recent Loser loses
      weight_class: "Lightweight",
      method: "Decision",
      round: 3,
      time: "5:00",
      referee: "Keith Peterson"
    )

    FightStat.create!(
      fight: fight1,
      fighter: @fighter_lost_recent,
      round: 2
    )

    FightStat.create!(
      fight: fight2,
      fighter: @fighter_lost_recent,
      round: 3
    )

    assert_equal 0, @fighter_lost_recent.current_win_streak
  end

  test "excludes inactive fighters from top win streaks" do
    # Create a win for inactive fighter 3 years ago
    old_fight = Fight.create!(
      event: @ancient_event,
      bout: "Inactive Fighter vs Old Opponent",
      outcome: "W/L", # Inactive Fighter wins
      weight_class: "Heavyweight",
      method: "KO/TKO",
      round: 1,
      time: "1:30",
      referee: "Dan Miragliotta"
    )

    FightStat.create!(
      fight: old_fight,
      fighter: @fighter_inactive,
      round: 1
    )

    # Get top win streaks - should not include inactive fighter
    top_fighters = Fighter.top_win_streaks(limit: 3)
    fighter_ids = top_fighters.map { |data| data[:fighter].id }

    assert_not_includes fighter_ids, @fighter_inactive.id
  end

  test "correctly identifies top 3 fighters by win streak" do
    # Create multiple fighters with different streaks
    fighters_data = [
      { name: "Five Streak", wins: 5 },
      { name: "Three Streak", wins: 3 },
      { name: "Seven Streak", wins: 7 },
      { name: "Two Streak", wins: 2 },
      { name: "Four Streak", wins: 4 }
    ]

    fighters_data.each do |data|
      fighter = Fighter.create!(name: data[:name])

      # Create wins for this fighter
      data[:wins].times do |i|
        fight = Fight.create!(
          event: @recent_event,
          bout: "#{data[:name]} vs Opponent #{i}",
          outcome: "W/L", # Fighter wins
          weight_class: "Middleweight",
          method: "Decision",
          round: 3,
          time: "5:00",
          referee: "Referee"
        )

        FightStat.create!(
          fight: fight,
          fighter: fighter,
          round: 3
        )
      end
    end

    top_fighters = Fighter.top_win_streaks(limit: 3)

    assert_equal 3, top_fighters.length
    assert_equal "Seven Streak", top_fighters[0][:fighter].name
    assert_equal 7, top_fighters[0][:win_streak]
    assert_equal "Five Streak", top_fighters[1][:fighter].name
    assert_equal 5, top_fighters[1][:win_streak]
    assert_equal "Four Streak", top_fighters[2][:fighter].name
    assert_equal 4, top_fighters[2][:win_streak]
  end

  test "handles fighter as second fighter in bout correctly" do
    # Create fight where our fighter is listed second and wins
    fight = Fight.create!(
      event: @recent_event,
      bout: "Opponent vs Winner McGee",
      outcome: "L/W", # First fighter lost, second fighter (Winner McGee) won
      weight_class: "Bantamweight",
      method: "Submission",
      round: 1,
      time: "4:20",
      referee: "Mario Yamasaki"
    )

    # Fighter stats for both fighters
    FightStat.create!(
      fight: fight,
      fighter: Fighter.create!(name: "Opponent"),
      round: 1
    )

    FightStat.create!(
      fight: fight,
      fighter: @fighter_on_streak,
      round: 1
    )

    assert_equal 1, @fighter_on_streak.current_win_streak
  end
end
