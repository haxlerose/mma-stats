# frozen_string_literal: true

# Query to find single round maximum statistics across all fighters
class RoundMaximumsQuery
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
      WITH ranked_rounds AS (
        SELECT
          fs.fighter_id,
          fs.fight_id,
          fs.round,
          fs.#{statistic} AS value,
          f.event_id,
          ROW_NUMBER() OVER (ORDER BY fs.#{statistic} DESC) as rank
        FROM fight_stats fs
        JOIN fights f ON fs.fight_id = f.id
        WHERE fs.#{statistic} IS NOT NULL
          AND fs.#{statistic} > 0
      ),
      top_rounds AS (
        SELECT *
        FROM ranked_rounds
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
        WHERE fs1.fight_id IN (SELECT fight_id FROM top_rounds)
      )
      SELECT
        tr.fighter_id,
        f.name AS fighter_name,
        tr.value,
        tr.round,
        fo.opponent_name,
        e.name AS event_name,
        e.date AS event_date,
        tr.fight_id
      FROM top_rounds tr
      JOIN fighters f ON tr.fighter_id = f.id
      JOIN events e ON tr.event_id = e.id
      LEFT JOIN fight_opponents fo ON tr.fight_id = fo.fight_id
        AND tr.fighter_id = fo.fighter1_id
      ORDER BY tr.value DESC
    SQL
  end

  def format_result(row)
    {
      fighter_id: row["fighter_id"],
      fighter_name: row["fighter_name"],
      value: row["value"],
      round: row["round"],
      opponent_name: row["opponent_name"],
      event_name: row["event_name"],
      event_date: row["event_date"],
      fight_id: row["fight_id"]
    }
  end
end
