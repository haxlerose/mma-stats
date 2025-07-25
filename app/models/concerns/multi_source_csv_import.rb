# frozen_string_literal: true

# Shared functionality for importing from multiple CSV sources
module MultiSourceCsvImport
  extend ActiveSupport::Concern

  private

  def fetch_remote_csv_data
    response = Faraday.get(self.class::CSV_URL)
    CSV.parse(response.body, headers: true)
  rescue Faraday::Error => e
    if defined?(self.class::ImportError)
      raise self.class::ImportError,
            "Failed to fetch remote CSV data: #{e.message}"
    else
      Rails.logger.warn "Failed to fetch remote CSV data: #{e.message}"
      []
    end
  end

  def fetch_supplemental_csv_data
    supplemental_file = supplemental_file_path
    return [] unless File.exist?(supplemental_file)

    CSV.read(supplemental_file, headers: true)
  rescue StandardError => e
    Rails.logger.warn "Failed to read supplemental CSV data: #{e.message}"
    []
  end

  def supplemental_file_path
    filename = self.class.name.underscore.gsub("_importer", "")
    Rails.root.join("db", "supplemental_data", "#{filename}s.csv")
  end
end
