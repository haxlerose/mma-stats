# frozen_string_literal: true

class Api::V1::FightersController < ApplicationController
  def index
    fighters = Fighter.alphabetical.search(params[:search])
    render json: { fighters: serialize_fighters_for_index(fighters) }
  end

  def show
    fighter = Fighter.with_fight_details.find(params[:id])
    render json: { fighter: serialize_fighter_with_fight_details(fighter) }
  end

  private

  def serialize_fighters_for_index(fighters)
    fighters.as_json(
      only: %i[id
               name
               height_in_inches
               reach_in_inches
               birth_date]
    )
  end

  def serialize_fighter_with_fight_details(fighter)
    fights_data = fighter.fight_stats.group_by(&:fight).map do |fight, stats|
      serialize_fight_with_stats(fight, stats)
    end

    fighter.as_json(
      only: %i[id
               name
               height_in_inches
               reach_in_inches
               birth_date]
    ).merge(
      fights: fights_data
    )
  end

  def serialize_fight_with_stats(fight, stats)
    {
      id: fight.id,
      bout: fight.bout,
      outcome: fight.outcome,
      weight_class: fight.weight_class,
      method: fight.method,
      round: fight.round,
      time: fight.time,
      referee: fight.referee,
      event: serialize_event_for_fight(fight.event),
      fight_stats: serialize_fight_stats(stats)
    }
  end

  def serialize_event_for_fight(event)
    {
      id: event.id,
      name: event.name,
      date: event.date
    }
  end

  def serialize_fight_stats(stats)
    stats.map do |stat|
      {
        round: stat.round,
        significant_strikes: stat.significant_strikes,
        significant_strikes_attempted: stat.significant_strikes_attempted,
        total_strikes: stat.total_strikes,
        total_strikes_attempted: stat.total_strikes_attempted,
        takedowns: stat.takedowns,
        takedowns_attempted: stat.takedowns_attempted,
        submission_attempts: stat.submission_attempts,
        reversals: stat.reversals,
        control_time_seconds: stat.control_time_seconds
      }
    end
  end
end
