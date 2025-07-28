# frozen_string_literal: true

module TopPerformers
  # Query class for calculating fighter significant strike accuracy percentage
  # Requires minimum of 5 fights to qualify for top performers list
  class AccuracyQuery
    MINIMUM_FIGHTS = 5

    def call
      fighters = fighters_with_accuracy

      filtered_fighters = fighters.select do |fighter_data|
        fighter_data[:total_fights] >= MINIMUM_FIGHTS &&
          fighter_data[:total_significant_strikes_attempted].positive?
      end

      filtered_fighters
        .map { |fighter_data| calculate_accuracy_percentage(fighter_data) }
        .sort_by { |fighter_data| -fighter_data[:accuracy_percentage] }
        .first(10)
    end

    private

    def fighters_with_accuracy
      sql = <<~SQL.squish
        WITH fights_with_attempts AS (
          SELECT DISTINCT
            fs.fighter_id,
            fs.fight_id
          FROM fight_stats fs
          GROUP BY fs.fighter_id, fs.fight_id
          HAVING SUM(fs.significant_strikes_attempted) > 0
        )
        SELECT
          f.id as fighter_id,
          f.name as fighter_name,
          COUNT(DISTINCT fwa.fight_id) as total_fights,
          SUM(fs.significant_strikes) as total_significant_strikes,
          SUM(fs.significant_strikes_attempted) as total_significant_strikes_attempted
        FROM fighters f
        JOIN fight_stats fs ON f.id = fs.fighter_id
        JOIN fights_with_attempts fwa
          ON fs.fighter_id = fwa.fighter_id
          AND fs.fight_id = fwa.fight_id
        GROUP BY f.id, f.name
        HAVING SUM(fs.significant_strikes_attempted) > 0
      SQL

      results = ActiveRecord::Base.connection.execute(sql)
      results.map do |row|
        {
          fighter_id: row["fighter_id"],
          fighter_name: row["fighter_name"],
          total_fights: row["total_fights"],
          total_significant_strikes: row["total_significant_strikes"].to_i,
          total_significant_strikes_attempted:
            row["total_significant_strikes_attempted"].to_i
        }
      end
    end

    def calculate_accuracy_percentage(fighter_data)
      accuracy = if fighter_data[:total_significant_strikes_attempted].positive?
                   (fighter_data[:total_significant_strikes].to_f /
                    fighter_data[:total_significant_strikes_attempted]) * 100
                 else
                   0.0
                 end

      fighter_data.merge(
        accuracy_percentage: accuracy.round(2)
      )
    end
  end
end
