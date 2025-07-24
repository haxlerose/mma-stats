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
      fighters: serialize_fighters_for_index(result[:items]),
      meta: result[:meta]
    }
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
    stats.map { |stat| fight_stat_attributes(stat) }
  end

  def fight_stat_attributes(stat)
    {
      round: stat.round,
      knockdowns: stat.knockdowns
    }.merge(
      striking_attributes(stat)
    ).merge(
      grappling_attributes(stat)
    )
  end

  def striking_attributes(stat)
    {
      significant_strikes: stat.significant_strikes,
      significant_strikes_attempted: stat.significant_strikes_attempted,
      total_strikes: stat.total_strikes,
      total_strikes_attempted: stat.total_strikes_attempted,
      head_strikes: stat.head_strikes,
      head_strikes_attempted: stat.head_strikes_attempted,
      body_strikes: stat.body_strikes,
      body_strikes_attempted: stat.body_strikes_attempted,
      leg_strikes: stat.leg_strikes,
      leg_strikes_attempted: stat.leg_strikes_attempted,
      distance_strikes: stat.distance_strikes,
      distance_strikes_attempted: stat.distance_strikes_attempted,
      clinch_strikes: stat.clinch_strikes,
      clinch_strikes_attempted: stat.clinch_strikes_attempted,
      ground_strikes: stat.ground_strikes,
      ground_strikes_attempted: stat.ground_strikes_attempted
    }
  end

  def grappling_attributes(stat)
    {
      takedowns: stat.takedowns,
      takedowns_attempted: stat.takedowns_attempted,
      submission_attempts: stat.submission_attempts,
      reversals: stat.reversals,
      control_time_seconds: stat.control_time_seconds
    }
  end
end
