# frozen_string_literal: true

class Api::V1::FightersController < ApplicationController
  include Pagination
  include ParameterParsing

  def index
    pagination_params = parse_pagination_params
    fighters_query = Fighter.alphabetical.search(params[:search])

    result = paginate(
      fighters_query,
      page: pagination_params[:page],
      per_page: pagination_params[:per_page]
    )

    render json: {
      fighters: result[:items].map do |fighter|
        FighterSerializer.for_index(fighter)
      end,
      meta: result[:meta]
    }
  end

  def show
    fighter = if params[:id].match?(/\A\d+\z/)
                Fighter.with_fight_details.find(params[:id])
              else
                Fighter.with_fight_details.find_by!(slug: params[:id])
              end
    render json: { fighter: FighterSerializer.with_fight_details(fighter) }
  end
end
