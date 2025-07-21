# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class FighterSpotlightControllerTest < ActionDispatch::IntegrationTest
      def setup
        # Create test data
        @event = Event.create!(
          name: "UFC 300",
          date: 1.month.ago,
          location: "Las Vegas"
        )

        @fighter = Fighter.create!(
          name: "Test Fighter",
          height_in_inches: 72,
          reach_in_inches: 74,
          birth_date: "1990-01-01"
        )

        # Create a win for the fighter
        @fight = Fight.create!(
          event: @event,
          bout: "Test Fighter vs Opponent",
          outcome: "Win",
          weight_class: "Welterweight",
          method: "KO/TKO",
          round: 2,
          time: "3:30",
          referee: "Herb Dean"
        )

        FightStat.create!(
          fight: @fight,
          fighter: @fighter,
          round: 2
        )
      end

      test "should get fighter spotlight" do
        get api_v1_fighter_spotlight_index_url
        assert_response :success

        response_data = response.parsed_body
        assert response_data.key?("fighters")
        assert_instance_of Array, response_data["fighters"]
      end

      test "returns fighter data with win streak and last fight details" do
        get api_v1_fighter_spotlight_index_url

        response_data = response.parsed_body
        fighters = response_data["fighters"]

        # Should have at least our test fighter
        assert_not_empty fighters

        fighter_data = fighters.first
        assert fighter_data.key?("id")
        assert fighter_data.key?("name")
        assert fighter_data.key?("current_win_streak")
        assert fighter_data.key?("last_fight")

        # Check last fight structure
        if fighter_data["last_fight"]
          last_fight = fighter_data["last_fight"]
          assert last_fight.key?("opponent")
          assert last_fight.key?("outcome")
          assert last_fight.key?("method")
          assert last_fight.key?("event_name")
          assert last_fight.key?("event_date")
        end
      end

      test "returns maximum of 3 fighters" do
        # Create additional fighters with wins
        5.times do |i|
          fighter = Fighter.create!(name: "Fighter #{i}")
          fight = Fight.create!(
            event: @event,
            bout: "Fighter #{i} vs Opponent",
            outcome: "Win",
            weight_class: "Lightweight",
            method: "Decision",
            round: 3,
            time: "5:00",
            referee: "Referee"
          )
          FightStat.create!(fight: fight, fighter: fighter, round: 3)
        end

        get api_v1_fighter_spotlight_index_url

        response_data = response.parsed_body
        fighters = response_data["fighters"]

        assert_equal 3, fighters.length
      end
    end
  end
end
