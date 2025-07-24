# frozen_string_literal: true

class Api::V1::EventsController < ApplicationController
  include Pagination
  include ParameterParsing

  def index
    params_parsed = parse_params
    events_query = build_events_query(params_parsed)
    # Use the concern's paginate method with base collection for count
    result = paginate(
      events_query,
      page: params_parsed[:page],
      per_page: params_parsed[:per_page],
      base_collection: Event.by_location(params_parsed[:location])
    )

    render json: {
      events: result[:items].map { |event| EventSerializer.for_index(event) },
      meta: result[:meta]
    }
  end

  def show
    event = Event.includes(fights: { fight_stats: :fighter }).find(params[:id])
    render json: { event: EventSerializer.with_fights(event) }
  end

  private

  def parse_params
    pagination_params = parse_pagination_params
    {
      page: pagination_params[:page],
      per_page: pagination_params[:per_page],
      location: params[:location].presence,
      sort_direction: parse_sort_direction
    }
  end

  def build_events_query(parsed_params)
    Event.by_location(parsed_params[:location])
         .with_fight_counts
         .sorted_by_date(parsed_params[:sort_direction])
  end
end
