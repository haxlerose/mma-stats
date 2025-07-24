# frozen_string_literal: true

class Api::V1::FightsController < ApplicationController
  def show
    fight = Fight.with_full_details.find(params[:id])
    render json: { fight: FightSerializer.with_full_details(fight) }
  end
end
