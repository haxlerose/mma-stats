# frozen_string_literal: true

# Query to find single fight maximum statistics across all fighters
class FightMaximumsQuery
  VALID_STATISTICS = %w[
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

  def initialize(statistic)
    validate_statistic!(statistic)
    @statistic = statistic
  end

  def call
    ActiveRecord::Base.connection.execute(
      build_query
    ).map { |row| format_result(row) }
  end

  private

  attr_reader :statistic

  def validate_statistic!(stat)
    return if VALID_STATISTICS.include?(stat)

    raise ArgumentError,
          "Invalid statistic: #{stat}. " \
          "Valid options: #{VALID_STATISTICS.join(', ')}"
  end

  def build_query
    <<~SQL.squish
      WITH fight_totals AS (
        SELECT
          fs.fighter_id,
          fs.fight_id,
          SUM(fs.#{statistic}) AS total_value
        FROM fight_stats fs
        GROUP BY fs.fighter_id, fs.fight_id
        HAVING SUM(fs.#{statistic}) > 0
      ),
      ranked_fights AS (
        SELECT
          ft.fighter_id,
          ft.fight_id,
          ft.total_value,
          f.event_id,
          ROW_NUMBER() OVER (ORDER BY ft.total_value DESC) as rank
        FROM fight_totals ft
        JOIN fights f ON ft.fight_id = f.id
      )
      SELECT
        rf.fighter_id,
        f.name AS fighter_name,
        rf.total_value AS value,
        (
          SELECT f2.name
          FROM fight_stats fs2
          JOIN fighters f2 ON fs2.fighter_id = f2.id
          WHERE fs2.fight_id = rf.fight_id
            AND fs2.fighter_id != rf.fighter_id
          LIMIT 1
        ) AS opponent_name,
        e.name AS event_name,
        e.date AS event_date,
        rf.fight_id
      FROM ranked_fights rf
      JOIN fighters f ON rf.fighter_id = f.id
      JOIN events e ON rf.event_id = e.id
      WHERE rf.rank <= 10
      ORDER BY rf.total_value DESC
    SQL
  end

  def format_result(row)
    {
      fighter_id: row["fighter_id"],
      fighter_name: row["fighter_name"],
      value: row["value"],
      opponent_name: row["opponent_name"],
      event_name: row["event_name"],
      event_date: row["event_date"],
      fight_id: row["fight_id"]
    }
  end
end
