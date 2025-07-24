# frozen_string_literal: true

module FightStatSerialization
  extend ActiveSupport::Concern

  private

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
