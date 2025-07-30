# frozen_string_literal: true

module TopPerformers
  # Calculates minimum attempt thresholds for accuracy statistics
  #
  # Formula: (Total Attempts / Total Fight Time) × 1500
  # Where 1500 seconds = 25 minutes (5 rounds × 5 minutes)
  #
  # This calculates the average number of attempts per second across all fights,
  # then multiplies by 1500 seconds to estimate the average number of attempts
  # in a full 5-round fight. This value is used as the minimum threshold for
  # inclusion in top 10 accuracy rankings, ensuring fighters have a meaningful
  # sample size of attempts.
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

      # Calculate average attempts in a 5-round fight (25 min = 1500 sec)
      # attempts per second × 1500 seconds
      threshold = attempt_rate_per_second * 60 * 25
      threshold.round
    end

    private

    def calculate_average_attempt_rate_per_second
      fight_stats = fetch_fight_stats
      return 0.0 if fight_stats.empty?

      calculate_rate_from_stats(fight_stats)
    end

    def fetch_fight_stats
      # Use ActiveRecord query interface to prevent SQL injection
      # Quote column names properly when used in SQL fragments
      quoted_column = connection.quote_column_name(attempted_column)

      FightStat
        .joins("JOIN fight_durations fd " \
               "ON fight_stats.fight_id = fd.fight_id")
        .group("fight_stats.fight_id", "fd.duration_seconds")
        .having("SUM(fight_stats.#{quoted_column}) > 0")
        .pluck(
          Arel.sql("SUM(fight_stats.#{quoted_column})"),
          Arel.sql("fd.duration_seconds")
        )
    end

    def calculate_rate_from_stats(fight_stats)
      total_attempts = fight_stats.sum { |row| row[0].to_f }
      total_seconds = fight_stats.sum { |row| row[1].to_f }

      return 0.0 if total_seconds.zero?

      total_attempts / total_seconds
    end

    def attempted_column
      @mapping[:attempted]
    end

    def connection
      ActiveRecord::Base.connection
    end
  end
end
