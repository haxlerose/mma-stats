# frozen_string_literal: true

class EventSerializer
  def self.for_index(event)
    {
      id: event.id,
      name: event.name,
      date: event.date,
      location: event.location,
      fight_count: event.fights_count
    }
  end

  def self.with_fights(event)
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
                   referee],
          include: {
            fight_stats: {
              only: %i[fighter_id
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
                       control_time_seconds],
              include: {
                fighter: {
                  only: %i[id
                           slug
                           name
                           height_in_inches
                           reach_in_inches
                           birth_date]
                }
              }
            }
          }
        }
      }
    )
  end
end
