# frozen_string_literal: true

class Api::V1::EventsController < ApplicationController
  def index
    params_parsed = parse_params
    events_query = build_events_query(params_parsed)
    paginated_data = paginate_events(events_query, params_parsed)

    render json: {
      events: serialize_events_for_index(paginated_data[:events]),
      meta: paginated_data[:meta]
    }
  end

  def show
    event = Event.includes(:fights).find(params[:id])
    render json: { event: serialize_event_with_fights(event) }
  end

  def locations
    locations = Event.distinct
                     .where.not(location: [nil, ""])
                     .pluck(:location)
                     .sort

    render json: { locations: locations }
  end

  private

  def parse_params
    {
      page: params[:page].present? ? [params[:page].to_i, 1].max : 1,
      per_page: calculate_per_page,
      location: params[:location].presence,
      sort_direction: determine_sort_direction
    }
  end

  def determine_sort_direction
    params[:sort_direction]&.downcase == "asc" ? "asc" : "desc"
  end

  def calculate_per_page
    per_page_param = params[:per_page].to_i
    per_page_param.positive? ? [per_page_param, 100].min : 20
  end

  def build_events_query(parsed_params)
    events = Event.by_location(parsed_params[:location])
                  .left_joins(:fights)
                  .group(:id)
                  .select("events.*, COUNT(fights.id) as fights_count")

    if parsed_params[:sort_direction] == "asc"
      events.chronological
    else
      events.reverse_chronological
    end
  end

  def paginate_events(events_query, parsed_params)
    # For count, we need to use the base query without grouping
    base_query = Event.by_location(parsed_params[:location])
    total_count = base_query.count
    total_pages = (total_count.to_f / parsed_params[:per_page]).ceil
    offset = (parsed_params[:page] - 1) * parsed_params[:per_page]
    paginated_events = events_query.limit(parsed_params[:per_page])
                                   .offset(offset)

    {
      events: paginated_events,
      meta: {
        current_page: parsed_params[:page],
        total_pages: total_pages,
        total_count: total_count,
        per_page: parsed_params[:per_page]
      }
    }
  end

  def serialize_events_for_index(events)
    events.map do |event|
      {
        id: event.id,
        name: event.name,
        date: event.date,
        location: event.location,
        fight_count: event.fights_count
      }
    end
  end

  def serialize_event_with_fights(event)
    event.as_json(
      only: %i[id name date location],
      include: {
        fights: {
          only: %i[id
                   bout
                   outcome
                   weight_class
                   method
                   round
                   time
                   referee]
        }
      }
    )
  end
end
