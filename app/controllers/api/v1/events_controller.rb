# frozen_string_literal: true

class Api::V1::EventsController < ApplicationController
  def index
    events = Event.order(date: :desc)
    render json: { events: serialize_events_for_index(events) }
  end

  def show
    event = Event.includes(:fights).find(params[:id])
    render json: { event: serialize_event_with_fights(event) }
  end

  private

  def serialize_events_for_index(events)
    events.as_json(only: %i[id name date location])
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
