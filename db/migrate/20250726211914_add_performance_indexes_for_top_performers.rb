# frozen_string_literal: true

class AddPerformanceIndexesForTopPerformers < ActiveRecord::Migration[8.0]
  def up
    # Create composite indexes for fight_stats aggregation queries
    # These will help with career totals and grouping by fighter_id
    add_index :fight_stats,
              [:fighter_id, :knockdowns],
              name: "idx_fight_stats_fighter_knockdowns"
    add_index :fight_stats,
              [:fighter_id, :significant_strikes],
              name: "idx_fight_stats_fighter_sig_strikes"
    add_index :fight_stats,
              [:fighter_id, :total_strikes],
              name: "idx_fight_stats_fighter_total_strikes"
    add_index :fight_stats,
              [:fighter_id, :takedowns],
              name: "idx_fight_stats_fighter_takedowns"
    add_index :fight_stats,
              [:fighter_id, :submission_attempts],
              name: "idx_fight_stats_fighter_sub_attempts"
    add_index :fight_stats,
              [:fighter_id, :control_time_seconds],
              name: "idx_fight_stats_fighter_control_time"

    # Create indexes for fight-level aggregations
    add_index :fight_stats,
              [:fight_id, :fighter_id, :round],
              name: "idx_fight_stats_fight_fighter_round"

    # Create covering index for per-minute calculations
    # This includes all columns needed for the per-minute query
    add_index :fight_stats,
              [:fighter_id, :fight_id, :round,
               :knockdowns, :significant_strikes, :total_strikes,
               :takedowns, :submission_attempts, :control_time_seconds],
              name: "idx_fight_stats_per_minute_covering"

    # Create materialized view for fight durations
    execute <<-SQL
      CREATE MATERIALIZED VIEW fight_durations AS
      SELECT DISTINCT
        f.id AS fight_id,
        f.round AS ending_round,
        f.time AS ending_time,
        CASE
          WHEN f.time ~ '^[0-9]+:[0-9]+$' THEN
            ((f.round - 1) * 300) +
            (CAST(SPLIT_PART(f.time, ':', 1) AS INTEGER) * 60 +
             CAST(SPLIT_PART(f.time, ':', 2) AS INTEGER))
          ELSE
            f.round * 300
        END AS duration_seconds
      FROM fights f;

      CREATE UNIQUE INDEX idx_fight_durations_fight_id
        ON fight_durations (fight_id);
    SQL
  end

  def down
    # Drop materialized view
    execute "DROP MATERIALIZED VIEW IF EXISTS fight_durations"

    # Remove all the indexes
    remove_index :fight_stats, name: "idx_fight_stats_fighter_knockdowns"
    remove_index :fight_stats, name: "idx_fight_stats_fighter_sig_strikes"
    remove_index :fight_stats, name: "idx_fight_stats_fighter_total_strikes"
    remove_index :fight_stats, name: "idx_fight_stats_fighter_takedowns"
    remove_index :fight_stats, name: "idx_fight_stats_fighter_sub_attempts"
    remove_index :fight_stats, name: "idx_fight_stats_fighter_control_time"
    remove_index :fight_stats, name: "idx_fight_stats_fight_fighter_round"
    remove_index :fight_stats, name: "idx_fight_stats_per_minute_covering"
  end
end
