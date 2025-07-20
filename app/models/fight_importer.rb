# frozen_string_literal: true

class FightImporter
  CSV_URL = "https://raw.githubusercontent.com/Greco1899/scrape_ufc_stats/" \
            "refs/heads/main/ufc_fight_results.csv"

  class ImportError < StandardError; end

  def import
    csv_data = parse_csv_data
    results = { imported: [], failed: [] }

    # Preload all events to avoid N+1 queries
    preload_events

    csv_data.each do |row|
      import_fight_row(row, results)
    end

    log_failed_imports(results[:failed]) if results[:failed].any?
    results[:imported]
  end

  private

  def preload_events
    @events_cache = Event.all.index_by(&:name)
  end

  def parse_csv_data
    response = fetch_csv_data
    CSV.parse(response.body, headers: true)
  end

  def fetch_csv_data
    Faraday.get(CSV_URL)
  rescue Faraday::Error => e
    raise ImportError, "Failed to fetch CSV data: #{e.message}"
  end

  def import_fight_row(row, results)
    event_name = row["EVENT"]&.strip
    event = @events_cache[event_name]

    unless event
      results[:failed] << {
        row: row,
        errors: ["Event not found: #{event_name}"]
      }
      return
    end

    fight = Fight.find_or_initialize_by(
      event: event,
      bout: normalize_whitespace(row["BOUT"]),
      outcome: row["OUTCOME"]
    )

    if fight.persisted?
      results[:imported] << fight
    else
      process_new_fight(fight, row, results)
    end
  end

  def process_new_fight(fight, row, results)
    assign_fight_attributes(fight, row)

    if fight.save
      results[:imported] << fight
    else
      results[:failed] << { row: row, errors: fight.errors.full_messages }
    end
  end

  def assign_fight_attributes(fight, row)
    fight.weight_class = row["WEIGHTCLASS"]
    fight.method = row["METHOD"]
    fight.round = parse_round(row["ROUND"])
    fight.time = row["TIME"]
    fight.time_format = row["TIME FORMAT"]
    fight.referee = row["REFEREE"]
    fight.details = row["DETAILS"]
  end

  def parse_round(round_string)
    round_string.to_i if round_string.present?
  end

  def normalize_whitespace(string)
    return nil if string.blank?

    string.strip.gsub(/\s+/, " ")
  end

  def log_failed_imports(failed_imports)
    Rails.logger.error "Failed to import #{failed_imports.count} fights:"
    failed_imports.each do |failure|
      Rails.logger.error "  Fight: #{failure[:row]['BOUT']}, " \
                         "Errors: #{failure[:errors].join(', ')}"
    end
  end
end
