# frozen_string_literal: true

module Api
  module V1
    class FighterSpotlightController < ApplicationController
      def index
        # Get top 3 fighters with longest current win streaks
        spotlight_data = Fighter.top_win_streaks(limit: 3)

        # Format the response
        fighters = spotlight_data.map do |data|
          fighter = data[:fighter]

          {
            id: fighter.id,
            slug: fighter.slug,
            name: fighter.name,
            height_in_inches: fighter.height_in_inches,
            reach_in_inches: fighter.reach_in_inches,
            birth_date: fighter.birth_date,
            current_win_streak: data[:win_streak],
            last_fight: data[:last_fight]
          }
        end

        render json: { fighters: fighters }
      end
    end
  end
end
