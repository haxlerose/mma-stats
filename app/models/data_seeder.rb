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
  end
end
