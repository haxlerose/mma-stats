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
      )
      SELECT
        rr.fighter_id,
        f.name AS fighter_name,
        rr.value,
        rr.round,
        (
          SELECT f2.name
          FROM fight_stats fs2
          JOIN fighters f2 ON fs2.fighter_id = f2.id
          WHERE fs2.fight_id = rr.fight_id
            AND fs2.fighter_id != rr.fighter_id
          LIMIT 1
        ) AS opponent_name,
        e.name AS event_name,
        e.date AS event_date,
        rr.fight_id
      FROM ranked_rounds rr
      JOIN fighters f ON rr.fighter_id = f.id
      JOIN events e ON rr.event_id = e.id
      WHERE rr.rank <= 10
      ORDER BY rr.value DESC
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
