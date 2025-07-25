# frozen_string_literal: true

class EventSerializer
  BASE_ATTRIBUTES = %i[id name date location].freeze

  FIGHT_ATTRIBUTES = %i[
    id
    bout
    outcome
    weight_class
    method
    round
    time
    referee
  ].freeze

  FIGHT_STAT_ATTRIBUTES = %i[
    fighter_id
    round
    knockdowns
    significant_strikes
    significant_strikes_attempted
    total_strikes
    total_strikes_attempted
    head_strikes
    head_strikes_attempted
    body_strikes
    body_strikes_attempted
    leg_strikes
    leg_strikes_attempted
    distance_strikes
    distance_strikes_attempted
    clinch_strikes
    clinch_strikes_attempted
    ground_strikes
    ground_strikes_attempted
    takedowns
    takedowns_attempted
    submission_attempts
    reversals
    control_time_seconds
  ].freeze

  FIGHTER_ATTRIBUTES = %i[
    id
    slug
    name
    height_in_inches
    reach_in_inches
    birth_date
  ].freeze

  def self.for_index(event)
    base_attributes(event).merge(
      fight_count: event.fights_count
    )
  end

  def self.with_fights(event)
    event.as_json(
      only: BASE_ATTRIBUTES,
      include: fights_include_hash
    ).merge(
      fight_count: event.fight_count
    )
  end

  def self.base_attributes(event)
    {
      id: event.id,
      name: event.name,
      date: event.date,
      location: event.location
    }
  end
  private_class_method :base_attributes

  def self.fights_include_hash
    {
      fights: {
        only: FIGHT_ATTRIBUTES,
        include: fight_stats_include_hash
      }
    }
  end
  private_class_method :fights_include_hash

  def self.fight_stats_include_hash
    {
      fight_stats: {
        only: FIGHT_STAT_ATTRIBUTES,
        include: {
          fighter: {
            only: FIGHTER_ATTRIBUTES
          }
        }
      }
    }
  end
  private_class_method :fight_stats_include_hash
end
