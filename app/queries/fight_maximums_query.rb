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
      ),
      top_fights AS (
        SELECT *
        FROM ranked_fights
        WHERE rank <= 10
      ),
      fight_opponents AS (
        SELECT DISTINCT
          fs1.fight_id,
          fs1.fighter_id AS fighter1_id,
          fs2.fighter_id AS fighter2_id,
          f2.name AS opponent_name
        FROM fight_stats fs1
        JOIN fight_stats fs2 ON fs1.fight_id = fs2.fight_id
          AND fs1.fighter_id != fs2.fighter_id
        JOIN fighters f2 ON fs2.fighter_id = f2.id
        WHERE fs1.fight_id IN (SELECT fight_id FROM top_fights)
      )
      SELECT
        tf.fighter_id,
        f.name AS fighter_name,
        tf.total_value AS value,
        fo.opponent_name,
        e.name AS event_name,
        e.date AS event_date,
        tf.fight_id
      FROM top_fights tf
      JOIN fighters f ON tf.fighter_id = f.id
      JOIN events e ON tf.event_id = e.id
      LEFT JOIN fight_opponents fo ON tf.fight_id = fo.fight_id
        AND tf.fighter_id = fo.fighter1_id
      ORDER BY tf.total_value DESC
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
