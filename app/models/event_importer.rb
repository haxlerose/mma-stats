# frozen_string_literal: true

class EventImporter
  include MultiSourceCsvImport

  CSV_URL = "https://raw.githubusercontent.com/Greco1899/scrape_ufc_stats/refs/heads/main/ufc_event_details.csv"

  def import
    results = { imported: [], failed: [] }

    # Import from primary source
    import_from_source(fetch_remote_csv_data, results)

    # Import from supplemental source
    import_from_source(fetch_supplemental_csv_data, results)

    log_failed_imports(results[:failed]) if results[:failed].any?
    results[:imported]
  end

  def import_from_source(csv_data, results)
    csv_data.each do |row|
      import_event_row(row, results)
    end
  end

  private

  def import_event_row(row, results)
    event_name = row["EVENT"]&.strip
    event = Event.find_or_initialize_by(name: event_name)

    if event.persisted?
      results[:imported] << event
    else
      process_new_event(event, row, results)
    end
  end

  def process_new_event(event, row, results)
    event.date = parse_date(row["DATE"])
    event.location = row["LOCATION"]

    if event.save
      results[:imported] << event
    else
      results[:failed] << { row: row, errors: event.errors.full_messages }
    end
  end

  def parse_date(date_string)
    Date.parse(date_string)
  rescue ArgumentError, TypeError
    nil
  end

  def log_failed_imports(failed_imports)
    Rails.logger.error "Failed to import #{failed_imports.count} events:"
    failed_imports.each do |failure|
      Rails.logger.error "  Event: #{failure[:row]['EVENT']}, " \
                         "Errors: #{failure[:errors].join(', ')}"
    end
  end
end
