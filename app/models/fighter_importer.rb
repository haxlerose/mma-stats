# frozen_string_literal: true

class FighterImporter
  CSV_URL = "https://raw.githubusercontent.com/Greco1899/scrape_ufc_stats/" \
            "refs/heads/main/ufc_fighter_tott.csv"

  class ImportError < StandardError; end

  def import
    csv_data = parse_csv_data
    results = { imported: [], failed: [] }

    csv_data.each do |row|
      import_fighter_row(row, results)
    end

    log_failed_imports(results[:failed]) if results[:failed].any?
    results[:imported]
  end

  private

  def parse_csv_data
    response = fetch_csv_data
    CSV.parse(response.body, headers: true)
  end

  def fetch_csv_data
    Faraday.get(CSV_URL)
  rescue Faraday::Error => e
    raise ImportError, "Failed to fetch CSV data: #{e.message}"
  end

  def import_fighter_row(row, results)
    fighter_name = row["FIGHTER"]&.strip
    fighter = Fighter.find_or_initialize_by(name: fighter_name)

    if fighter.persisted?
      results[:imported] << fighter
    else
      process_new_fighter(fighter, row, results)
    end
  end

  def process_new_fighter(fighter, row, results)
    fighter.height_in_inches = parse_height(row["HEIGHT"])
    fighter.reach_in_inches = parse_reach(row["REACH"])
    fighter.birth_date = parse_date(row["DOB"])

    if fighter.save
      results[:imported] << fighter
    else
      results[:failed] << { row: row, errors: fighter.errors.full_messages }
    end
  end

  def parse_height(height_string)
    return nil if height_string.blank?

    # Convert "5' 4\"" format to inches
    match = height_string.match(/(\d+)'\s*(\d+)"/)
    return nil unless match

    feet = match[1].to_i
    inches = match[2].to_i
    (feet * 12) + inches
  end

  def parse_reach(reach_string)
    return nil if reach_string.blank?

    # Remove quotes and convert to integer
    reach_string.delete('"').to_i if reach_string.match?(/\d+/)
  end

  def parse_date(date_string)
    Date.parse(date_string)
  rescue ArgumentError, TypeError
    nil
  end

  def log_failed_imports(failed_imports)
    Rails.logger.error "Failed to import #{failed_imports.count} fighters:"
    failed_imports.each do |failure|
      Rails.logger.error "  Fighter: #{failure[:row]['FIGHTER']}, " \
                         "Errors: #{failure[:errors].join(', ')}"
    end
  end
end
