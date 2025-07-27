# frozen_string_literal: true

# Orchestrates the import of all UFC data from CSV files in the correct order
class DataSeeder
  class << self
    def import_all
      Rails.logger.info "  Starting data import from CSV files..."

      # Import in dependency order
      import_events
      import_fighters
      import_fights
      import_fight_stats

      # Refresh materialized view after successful import
      refresh_fight_durations_view

      Rails.logger.info "  Data import completed successfully!"

      # Return statistics
      {
        events_count: Event.count,
        fighters_count: Fighter.count,
        fights_count: Fight.count,
        fight_stats_count: FightStat.count
      }
    end

    def import_with_report
      started_at = Time.current
      error_message = nil

      begin
        statistics = import_all
        status = :success
      rescue StandardError => e
        statistics = current_counts
        status = :failed
        error_message = e.message
        raise
      ensure
        completed_at = Time.current
        duration = completed_at - started_at

        @report = {
          started_at: started_at,
          completed_at: completed_at,
          duration: duration,
          status: status || :failed,
          statistics: statistics || current_counts
        }

        @report[:error] = error_message if error_message
      end

      @report
    end

    private

    def import_events
      Rails.logger.info "  Importing events..."
      EventImporter.new.import
      Rails.logger.info "  Events imported successfully"
    end

    def import_fighters
      Rails.logger.info "  Importing fighters..."
      FighterImporter.new.import
      Rails.logger.info "  Fighters imported successfully"
    end

    def import_fights
      Rails.logger.info "  Importing fights..."
      FightImporter.new.import
      Rails.logger.info "  Fights imported successfully"
    end

    def import_fight_stats
      Rails.logger.info "  Importing fight stats..."
      FightStatImporter.new.import
      Rails.logger.info "  Fight stats imported successfully"
    end

    def current_counts
      {
        events_count: Event.count,
        fighters_count: Fighter.count,
        fights_count: Fight.count,
        fight_stats_count: FightStat.count
      }
    end

    def refresh_fight_durations_view
      # Check if materialized view exists
      result = ActiveRecord::Base.connection.execute(
        "SELECT matviewname FROM pg_matviews " \
        "WHERE schemaname = 'public' AND matviewname = 'fight_durations'"
      )

      return if result.none?

      Rails.logger.info "  Refreshing fight_durations materialized view..."
      ActiveRecord::Base.connection.execute(
        "REFRESH MATERIALIZED VIEW CONCURRENTLY fight_durations"
      )
      Rails.logger.info "  Materialized view refreshed successfully"
    rescue ActiveRecord::StatementInvalid => e
      # Log the error but don't fail the import
      Rails.logger.warn "  Could not refresh materialized view: #{e.message}"
    end
  end
end
