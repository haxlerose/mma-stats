# frozen_string_literal: true

class Api::V1::LocationsController < ApplicationController
  def index
    locations = Event.distinct
                     .where.not(location: [nil, ""])
                     .pluck(:location)
                     .sort

    render json: { locations: locations }
  end
end
