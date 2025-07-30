class AddEndingRoundToFightDurations < ActiveRecord::Migration[8.0]
  def up
    # Drop and recreate the materialized view with ending_round column
    execute "DROP MATERIALIZED VIEW IF EXISTS fight_durations CASCADE"
    
    execute <<~SQL
      CREATE MATERIALIZED VIEW fight_durations AS
      SELECT 
        f.id AS fight_id,
        f.round AS ending_round,
        CASE
          -- Parse time as MM:SS format
          WHEN f.time ~ '^[0-9]+:[0-9]+$' THEN
            -- Previous rounds (round - 1) * 300 seconds + current round time
            ((f.round - 1) * 300) + 
            (CAST(SPLIT_PART(f.time, ':', 1) AS INTEGER) * 60 + 
             CAST(SPLIT_PART(f.time, ':', 2) AS INTEGER))
          ELSE 
            -- If time format is invalid, assume full rounds
            f.round * 300
        END AS duration_seconds
      FROM fights f
      WHERE f.time IS NOT NULL AND f.time != ''
    SQL

    # Create unique index on materialized view
    execute "CREATE UNIQUE INDEX index_fight_durations_on_fight_id ON fight_durations (fight_id)"
    
    # Refresh the view immediately if there's data
    if ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM fights").first["count"] > 0
      execute "REFRESH MATERIALIZED VIEW fight_durations"
    end
  end

  def down
    # Revert to the previous version without ending_round
    execute "DROP MATERIALIZED VIEW IF EXISTS fight_durations CASCADE"
    
    execute <<~SQL
      CREATE MATERIALIZED VIEW fight_durations AS
      SELECT 
        f.id AS fight_id,
        CASE
          -- Parse time as MM:SS format
          WHEN f.time ~ '^[0-9]+:[0-9]+$' THEN
            -- Previous rounds (round - 1) * 300 seconds + current round time
            ((f.round - 1) * 300) + 
            (CAST(SPLIT_PART(f.time, ':', 1) AS INTEGER) * 60 + 
             CAST(SPLIT_PART(f.time, ':', 2) AS INTEGER))
          ELSE 
            -- If time format is invalid, assume full rounds
            f.round * 300
        END AS duration_seconds
      FROM fights f
      WHERE f.time IS NOT NULL AND f.time != ''
    SQL

    execute "CREATE UNIQUE INDEX index_fight_durations_on_fight_id ON fight_durations (fight_id)"
    
    if ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM fights").first["count"] > 0
      execute "REFRESH MATERIALIZED VIEW fight_durations"
    end
  end
end