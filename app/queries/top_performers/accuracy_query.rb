# frozen_string_literal: true

module TopPerformers
  # Query class for calculating fighter accuracy percentages
  # Requires minimum of 5 fights to qualify for top performers list
  class AccuracyQuery
    MINIMUM_FIGHTS = 5

    CATEGORY_MAPPINGS = {
      "significant_strike_accuracy" => {
        landed: "significant_strikes",
        attempted: "significant_strikes_attempted"
      },
      "total_strike_accuracy" => {
        landed: "total_strikes",
        attempted: "total_strikes_attempted"
      },
      "head_strike_accuracy" => {
        landed: "head_strikes",
        attempted: "head_strikes_attempted"
      },
      "body_strike_accuracy" => {
        landed: "body_strikes",
        attempted: "body_strikes_attempted"
      },
      "leg_strike_accuracy" => {
        landed: "leg_strikes",
        attempted: "leg_strikes_attempted"
      },
      "distance_strike_accuracy" => {
        landed: "distance_strikes",
        attempted: "distance_strikes_attempted"
      },
      "clinch_strike_accuracy" => {
        landed: "clinch_strikes",
        attempted: "clinch_strikes_attempted"
      },
      "ground_strike_accuracy" => {
        landed: "ground_strikes",
        attempted: "ground_strikes_attempted"
      },
      "takedown_accuracy" => {
        landed: "takedowns",
        attempted: "takedowns_attempted"
      }
    }.freeze

    def initialize(category:, apply_threshold: false)
      @category = category
      @mapping = CATEGORY_MAPPINGS[@category]
      @apply_threshold = apply_threshold

      raise ArgumentError, "Invalid category: #{@category}" unless @mapping
    end

    def call
      fighters = fighters_with_accuracy
      filtered_fighters = apply_base_filters(fighters)

      if @apply_threshold
        call_with_threshold(filtered_fighters)
      else
        calculate_top_fighters(filtered_fighters)
      end
    end

    private

    def apply_base_filters(fighters)
      fighters.select do |fighter_data|
        fighter_data[:total_fights] >= MINIMUM_FIGHTS &&
          fighter_data[:total_attempted].positive?
      end
    end

    def call_with_threshold(filtered_fighters)
      threshold = calculate_minimum_threshold

      threshold_filtered = filtered_fighters.select do |fighter_data|
        fighter_data[:total_attempted] >= threshold
      end

      {
        fighters: calculate_top_fighters(threshold_filtered),
        minimum_attempts_threshold: threshold
      }
    end

    def calculate_top_fighters(fighters)
      fighters
        .map { |fighter_data| calculate_accuracy_percentage(fighter_data) }
        .sort_by { |fighter_data| -fighter_data[:accuracy_percentage] }
        .first(10)
    end

    def calculate_minimum_threshold
      MinimumAttemptThresholdQuery.new(category: @category).call
    end

    def fighters_with_accuracy
      landed_column = @mapping[:landed]
      attempted_column = @mapping[:attempted]

      # Validate column names to prevent SQL injection
      validate_column_names!(landed_column, attempted_column)

      fighter_stats = build_fighter_stats_query(landed_column, attempted_column)
      format_fighter_stats(fighter_stats)
    end

    def build_fighter_stats_query(landed_column, attempted_column)
      fighters_table = Fighter.arel_table
      fight_stats_table = FightStat.arel_table

      Fighter
        .joins(:fight_stats)
        .group(fighters_table[:id], fighters_table[:name])
        .select(
          build_select_columns(
            fighters_table,
            fight_stats_table,
            landed_column,
            attempted_column
          )
        )
        .having(
          fight_stats_table[attempted_column].sum.gt(0)
        )
    end

    def build_select_columns(
      fighters_table, fight_stats_table,
      landed_column, attempted_column
    )
      [
        fighters_table[:id].as("fighter_id"),
        fighters_table[:name].as("fighter_name"),
        fight_stats_table[:fight_id]
          .count(true).as("total_fights"),
        fight_stats_table[landed_column]
          .sum.as("total_landed"),
        fight_stats_table[attempted_column]
          .sum.as("total_attempted")
      ]
    end

    def format_fighter_stats(fighter_stats)
      fighter_stats.map do |row|
        {
          fighter_id: row.fighter_id,
          fighter_name: row.fighter_name,
          total_fights: row.total_fights,
          total_landed: row.total_landed.to_i,
          total_attempted: row.total_attempted.to_i
        }
      end
    end

    def validate_column_names!(*columns)
      allowed_columns = %w[
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
      ]

      columns.each do |column|
        unless allowed_columns.include?(column.to_s)
          raise ArgumentError, "Invalid column: #{column}"
        end
      end
    end

    def calculate_accuracy_percentage(fighter_data)
      accuracy = if fighter_data[:total_attempted].positive?
                   (fighter_data[:total_landed].to_f /
                    fighter_data[:total_attempted]) * 100
                 else
                   0.0
                 end

      # Generate dynamic key names based on the category
      landed_key = :"total_#{@mapping[:landed]}"
      attempted_key = :"total_#{@mapping[:attempted]}"

      fighter_data.merge(
        accuracy_percentage: accuracy.round(2),
        landed_key => fighter_data[:total_landed],
        attempted_key => fighter_data[:total_attempted]
      )
    end
  end
end
