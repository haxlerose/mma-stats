class FixFightDurationsMaterializedView < ActiveRecord::Migration[8.0]
  def up
    # Drop and recreate the materialized view with correct time calculation
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
      WHERE f.time IS NOT NULL AND f.time \!= ''
    SQL

    # Create unique index on materialized view
    execute "CREATE UNIQUE INDEX index_fight_durations_on_fight_id ON fight_durations (fight_id)"
    
    # Refresh the view immediately if there's data
    if ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM fights").first["count"] > 0
      execute "REFRESH MATERIALIZED VIEW fight_durations"
    end
  end

  def down
    # Revert to the previous (incorrect) calculation
    execute "DROP MATERIALIZED VIEW IF EXISTS fight_durations CASCADE"
    
    execute <<~SQL
      CREATE MATERIALIZED VIEW fight_durations AS
      SELECT 
        f.id AS fight_id,
        CASE
          WHEN f.round = 1 THEN 
            (EXTRACT(EPOCH FROM f.time::time) + ((1 - 1) * 300))::integer
          WHEN f.round = 2 THEN 
            (EXTRACT(EPOCH FROM f.time::time) + ((2 - 1) * 300))::integer
          WHEN f.round = 3 THEN 
            (EXTRACT(EPOCH FROM f.time::time) + ((3 - 1) * 300))::integer
          WHEN f.round = 4 THEN 
            (EXTRACT(EPOCH FROM f.time::time) + ((4 - 1) * 300))::integer
          WHEN f.round = 5 THEN 
            (EXTRACT(EPOCH FROM f.time::time) + ((5 - 1) * 300))::integer
          ELSE 
            EXTRACT(EPOCH FROM f.time::time)::integer
        END AS duration_seconds
      FROM fights f
      WHERE f.time IS NOT NULL AND f.time \!= ''
    SQL

    execute "CREATE UNIQUE INDEX index_fight_durations_on_fight_id ON fight_durations (fight_id)"
    
    if ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM fights").first["count"] > 0
      execute "REFRESH MATERIALIZED VIEW fight_durations"
    end
  end
end
