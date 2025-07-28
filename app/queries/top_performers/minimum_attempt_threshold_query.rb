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

      sql = <<~SQL.squish
        WITH fight_attempts AS (
          SELECT
            fs.fight_id,
            SUM(fs.#{attempted_column}) as total_attempts,
            fd.duration_seconds
          FROM fight_stats fs
          JOIN fight_durations fd ON fs.fight_id = fd.fight_id
          GROUP BY fs.fight_id, fd.duration_seconds
          HAVING SUM(fs.#{attempted_column}) > 0
        )
        SELECT
          SUM(total_attempts)::float / SUM(duration_seconds) as attempt_rate
        FROM fight_attempts
      SQL

      result = ActiveRecord::Base.connection.execute(sql).first
      return 0.0 unless result && result["attempt_rate"]

      result["attempt_rate"].to_f
    end
  end
end
