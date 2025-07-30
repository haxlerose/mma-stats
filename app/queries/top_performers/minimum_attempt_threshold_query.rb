# frozen_string_literal: true

module TopPerformers
  # Calculates minimum attempt thresholds for accuracy statistics
  # Formula: (Total Attempts / Total Fight Time) × 60 × 25
  class MinimumAttemptThresholdQuery
    CATEGORY_MAPPINGS = AccuracyQuery::CATEGORY_MAPPINGS

    def initialize(category:)
      @category = category
      @mapping = CATEGORY_MAPPINGS[@category]

      raise ArgumentError, "Invalid category: #{@category}" unless @mapping
    end

    def call
      attempt_rate_per_second = calculate_average_attempt_rate_per_second
      return 0 if attempt_rate_per_second.zero?

      # Convert to per minute, then multiply by 25
      # (attempts per second × 60) × 25
      threshold = attempt_rate_per_second * 60 * 25
      threshold.round
    end

    private

    def calculate_average_attempt_rate_per_second
      attempted_column = @mapping[:attempted]
      validate_column_name!(attempted_column)

      fight_stats_aggregated = aggregate_fight_stats(attempted_column)
      return 0.0 if fight_stats_aggregated.empty?

      fight_durations = fetch_fight_durations(fight_stats_aggregated.keys)
      totals = calculate_totals(fight_stats_aggregated, fight_durations)

      return 0.0 if totals[:duration].zero?

      totals[:attempts].to_f / totals[:duration]
    end

    def aggregate_fight_stats(attempted_column)
      fight_stats_table = FightStat.arel_table
      FightStat
        .group(:fight_id)
        .where(fight_stats_table[attempted_column].gt(0))
        .sum(attempted_column)
    end

    def fetch_fight_durations(fight_ids)
      ActiveRecord::Base.connection.select_all(
        ActiveRecord::Base.sanitize_sql_array(
          [
            "SELECT fight_id, duration_seconds " \
            "FROM fight_durations WHERE fight_id IN (?)",
            fight_ids
          ]
        )
      )
    end

    def calculate_totals(fight_stats_aggregated, fight_durations)
      totals = { attempts: 0, duration: 0 }

      fight_durations.each do |duration_record|
        fight_id = duration_record["fight_id"]
        if fight_stats_aggregated[fight_id]
          totals[:attempts] += fight_stats_aggregated[fight_id]
          totals[:duration] += duration_record["duration_seconds"]
        end
      end

      totals
    end

    def validate_column_name!(column)
      allowed_columns = %w[
        significant_strikes_attempted
        total_strikes_attempted
        head_strikes_attempted
        body_strikes_attempted
        leg_strikes_attempted
        distance_strikes_attempted
        clinch_strikes_attempted
        ground_strikes_attempted
        takedowns_attempted
      ]

      unless allowed_columns.include?(column.to_s)
        raise ArgumentError, "Invalid column: #{column}"
      end
    end
  end
end
