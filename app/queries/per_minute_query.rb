# frozen_string_literal: true

# Query class for calculating fighter statistics per 15 minutes of fight time
# Requires minimum of 5 fights to qualify for top performers list
class PerMinuteQuery
  SECONDS_PER_15_MINUTES = 900 # 15 minutes in seconds
  MINIMUM_FIGHTS = 5

  # List of supported statistic types that can be queried
  SUPPORTED_STATISTICS = %i[
    knockdowns
    significant_strikes
    significant_strikes_attempted
    total_strikes
    total_strikes_attempted
    takedowns
    takedowns_attempted
    submission_attempts
    reversals
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
    control_time_seconds
  ].freeze

  def initialize(statistic_type = :knockdowns)
    @statistic_type = if statistic_type.is_a?(Hash)
                        statistic_type[:category] || :knockdowns
                      else
                        statistic_type
                      end.to_sym
    validate_statistic_type!
  end

  def call
    fighters_with_stats
      .select { |fighter_data| fighter_data[:total_fights] >= MINIMUM_FIGHTS }
      .select { |fighter_data| fighter_data[:total_time_seconds].positive? }
      .map { |fighter_data| calculate_rate_per_15_minutes(fighter_data) }
      .sort_by { |fighter_data| -fighter_data[:rate_per_15_minutes] }
      .first(10)
  end

  private

  def validate_statistic_type!
    return if SUPPORTED_STATISTICS.include?(@statistic_type)

    raise ArgumentError,
          "Invalid statistic type: #{@statistic_type}"
  end

  def fighters_with_stats
    if materialized_view_exists?
      results = ActiveRecord::Base.connection.execute(build_optimized_query)
      results.map do |row|
        {
          fighter_id: row["fighter_id"],
          fighter_name: row["fighter_name"],
          total_fights: row["fight_count"],
          total_time_seconds: row["total_time_seconds"],
          total_statistic: row["stat_total"]
        }
      end
    else
      # Fallback to the original ActiveRecord implementation
      fighters_with_stats_fallback
    end
  end

  def materialized_view_exists?
    ActiveRecord::Base.connection.execute(
      "SELECT 1 FROM pg_matviews WHERE matviewname = 'fight_durations'"
    ).any?
  end

  def fighters_with_stats_fallback
    Fighter
      .select(
        "fighters.id",
        "fighters.name",
        "COUNT(DISTINCT fights.id) as fight_count",
        "SUM(#{calculate_fight_time_sql}) as total_time",
        "SUM(fight_stats.#{@statistic_type}) as stat_total"
      )
      .joins(fight_stats: :fight)
      .group("fighters.id", "fighters.name")
      .having("SUM(#{calculate_fight_time_sql}) > 0")
      .map do |fighter|
        {
          fighter_id: fighter.id,
          fighter_name: fighter.name,
          total_fights: fighter.fight_count,
          total_time_seconds: fighter.total_time.to_i,
          total_statistic: fighter.stat_total.to_i
        }
      end
  end

  def build_optimized_query
    <<~SQL.squish
      WITH fighter_fight_times AS (
        SELECT
          fs.fighter_id,
          fs.fight_id,
          fs.round as stat_round,
          fd.ending_round,
          fd.duration_seconds,
          CASE
            WHEN fs.round < fd.ending_round THEN 300
            WHEN fs.round = fd.ending_round THEN
              fd.duration_seconds - ((fd.ending_round - 1) * 300)
            ELSE 0
          END as round_duration_seconds
        FROM fight_stats fs
        JOIN fight_durations fd ON fs.fight_id = fd.fight_id
      ),
      fighter_stats_aggregated AS (
        SELECT
          fs.fighter_id,
          f.name as fighter_name,
          COUNT(DISTINCT fs.fight_id) as fight_count,
          SUM(fft.round_duration_seconds) as total_time_seconds,
          SUM(fs.#{@statistic_type}) as stat_total
        FROM fight_stats fs
        JOIN fighters f ON fs.fighter_id = f.id
        JOIN fighter_fight_times fft ON fs.fighter_id = fft.fighter_id
          AND fs.fight_id = fft.fight_id
          AND fs.round = fft.stat_round
        GROUP BY fs.fighter_id, f.name
        HAVING COUNT(DISTINCT fs.fight_id) >= #{MINIMUM_FIGHTS}
          AND SUM(fft.round_duration_seconds) > 0
      )
      SELECT
        fighter_id,
        fighter_name,
        fight_count,
        total_time_seconds,
        stat_total
      FROM fighter_stats_aggregated
    SQL
  end

  def calculate_fight_time_sql
    # Calculate actual fight time based on which round the fight ended
    # Each complete round is 5 minutes (300 seconds)
    # Championship fights also have 5-minute rounds
    <<~SQL.squish
      CASE
        WHEN fight_stats.round < fights.round THEN 300
        WHEN fight_stats.round = fights.round THEN
          CASE
            WHEN fights.time ~ '^[0-9]+:[0-9]+$' THEN
              (CAST(SPLIT_PART(fights.time, ':', 1) AS INTEGER) * 60 +
               CAST(SPLIT_PART(fights.time, ':', 2) AS INTEGER))
            ELSE 300
          END
        ELSE 0
      END
    SQL
  end

  def calculate_rate_per_15_minutes(fighter_data)
    rate = if fighter_data[:total_time_seconds].positive?
             (fighter_data[:total_statistic].to_f * SECONDS_PER_15_MINUTES) /
               fighter_data[:total_time_seconds]
           else
             0.0
           end

    fighter_data.merge(
      rate_per_15_minutes: rate.round(2)
    )
  end
end
