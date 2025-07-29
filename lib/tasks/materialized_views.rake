# frozen_string_literal: true

namespace :db do
  namespace :views do
    desc "Create or refresh all materialized views"
    task refresh: :environment do
      puts "Managing materialized views..."
      
      # Check if fight_durations view exists
      view_exists = ActiveRecord::Base.connection.execute(
        "SELECT 1 FROM pg_matviews WHERE matviewname = 'fight_durations'"
      ).any?
      
      if view_exists
        puts "Refreshing fight_durations materialized view..."
        ActiveRecord::Base.connection.execute("REFRESH MATERIALIZED VIEW fight_durations")
        puts "✓ Materialized view refreshed"
      else
        puts "Creating fight_durations materialized view..."
        # Load and run the migration
        require Rails.root.join("db/migrate/20250729184129_create_fight_durations_materialized_view")
        CreateFightDurationsMaterializedView.new.up
        puts "✓ Materialized view created"
      end
      
      # Show row count
      count = ActiveRecord::Base.connection.execute(
        "SELECT COUNT(*) FROM fight_durations"
      ).first["count"]
      puts "fight_durations contains #{count} rows"
    rescue StandardError => e
      puts "Error: #{e.message}"
      puts e.backtrace.first(5)
    end
    
    desc "Drop all materialized views"
    task drop: :environment do
      puts "Dropping materialized views..."
      ActiveRecord::Base.connection.execute("DROP MATERIALIZED VIEW IF EXISTS fight_durations CASCADE")
      puts "✓ Materialized views dropped"
    end
  end
end