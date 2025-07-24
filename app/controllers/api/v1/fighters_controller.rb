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
    fighter = Fighter.with_fight_details.find(params[:id])
    render json: { fighter: FighterSerializer.with_fight_details(fighter) }
  end
end
