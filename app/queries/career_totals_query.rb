# frozen_string_literal: true

# Query object for aggregating career statistics for fighters
class CareerTotalsQuery
  TOP_PERFORMERS_LIMIT = 10

  VALID_CATEGORIES = %i[
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

  def initialize(category: :knockdowns)
    validate_category!(category)
    @category = category
  end

  def call
    aggregated_stats
      .order("total_#{@category} DESC")
      .limit(TOP_PERFORMERS_LIMIT)
      .map { |result| format_result(result) }
  end

  private

  def aggregated_stats
    FightStat
      .joins(:fighter)
      .group("fighters.id", "fighters.name")
      .select(
        fighter_columns,
        aggregate_columns
      )
  end

  def validate_category!(category)
    return if VALID_CATEGORIES.include?(category)

    raise ArgumentError,
          "Invalid category: #{category}. " \
          "Valid categories are: #{VALID_CATEGORIES.join(', ')}"
  end

  def fighter_columns
    <<~SQL.squish
      fighters.id AS fighter_id,
      fighters.name AS fighter_name
    SQL
  end

  def aggregate_columns
    <<~SQL.squish
      COUNT(DISTINCT fight_stats.fight_id) AS fight_count,
      SUM(COALESCE(fight_stats.#{@category}, 0)) AS total_#{@category}
    SQL
  end

  def format_result(result)
    total_value = result.send("total_#{@category}").to_i

    {
      fighter_id: result.fighter_id,
      fighter_name: result.fighter_name,
      fight_count: result.fight_count
    }.merge(
      "total_#{@category}" => total_value
    ).transform_keys(&:to_sym)
  end
end
