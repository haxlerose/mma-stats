# frozen_string_literal: true

class Api::V1::FightsController < ApplicationController
  def show
    fight = Fight.with_full_details.find(params[:id])
    render json: { fight: serialize_fight_with_full_details(fight) }
  end

  private

  def serialize_fight_with_full_details(fight)
    basic_attrs = %i[id bout outcome weight_class method round time referee]
    fight.as_json(only: basic_attrs).merge(
      event: serialize_event_for_fight(fight.event),
      fighters: serialize_fighters(fight.fighters),
      fight_stats: serialize_fight_stats(fight.fight_stats)
    )
  end

  def serialize_event_for_fight(event)
    event.as_json(only: %i[id name date location])
  end

  def serialize_fighters(fighters)
    fighters.map do |fighter|
      fighter.as_json(
        only: %i[id
                 name
                 height_in_inches
                 reach_in_inches
                 birth_date]
      )
    end
  end

  def serialize_fight_stats(fight_stats)
    fight_stats.map { |stat| build_stat_attributes(stat) }
  end

  def build_stat_attributes(stat)
    {
      fighter_id: stat.fighter.id,
      fighter_name: stat.fighter.name,
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
