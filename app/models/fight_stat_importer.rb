# frozen_string_literal: true

class FightStatImporter
  include MultiSourceCsvImport

  CSV_URL = "https://raw.githubusercontent.com/Greco1899/scrape_ufc_stats/" \
            "refs/heads/main/ufc_fight_stats.csv"

  def import
    results = { imported: [], failed: [] }

    # Preload all data to avoid N+1 queries
    preload_data

    # Import from primary source
    import_from_source(fetch_remote_csv_data, results)

    # Import from supplemental source
    import_from_source(fetch_supplemental_csv_data, results)

    log_failed_imports(results[:failed]) if results[:failed].any?
    results[:imported]
  end

  def import_from_source(csv_data, results)
    csv_data.each do |row|
      import_fight_stat_row(row, results)
    end
  end

  private

  def preload_data
    @events_cache = Event.includes(fights: :event).index_by(&:name)
    @fighters_cache = Fighter.all.index_by(&:name)
    @fights_cache = Fight.includes(:event).group_by(&:event_id)
                         .transform_values { |fights| fights.index_by(&:bout) }
  end

  def import_fight_stat_row(row, results)
    event = find_event(row, results)
    return unless event

    fight = find_fight(event, row, results)
    return unless fight

    fighter = find_fighter(row, results)
    return unless fighter

    fight_stat = find_or_create_fight_stat(fight, fighter, row)

    if fight_stat.persisted?
      results[:imported] << fight_stat
    else
      process_new_fight_stat(fight_stat, row, results)
    end
  end

  def process_new_fight_stat(fight_stat, row, results)
    assign_fight_stat_attributes(fight_stat, row)

    if fight_stat.save
      results[:imported] << fight_stat
    else
      results[:failed] << { row: row, errors: fight_stat.errors.full_messages }
    end
  end

  def assign_fight_stat_attributes(fight_stat, row)
    assign_basic_stats(fight_stat, row)
    assign_strike_stats(fight_stat, row)
    assign_location_stats(fight_stat, row)
  end

  def parse_round(round_string)
    return nil if round_string.blank?

    # Extract number from "Round X" format
    match = round_string.match(/Round (\d+)/)
    match ? match[1].to_i : nil
  end

  def parse_integer(value)
    return 0 if value.blank? || value == "---"

    value.to_i
  end

  def parse_x_of_y_format(value)
    return { x: 0, y: 0 } if value.blank? || value == "---"

    match = value.match(/(\d+) of (\d+)/)
    if match
      { x: match[1].to_i, y: match[2].to_i }
    else
      { x: 0, y: 0 }
    end
  end

  def parse_control_time(time_string)
    return 0 if time_string.blank? || time_string == "---"

    # Parse MM:SS format to seconds
    match = time_string.match(/(\d+):(\d+)/)
    if match
      minutes = match[1].to_i
      seconds = match[2].to_i
      (minutes * 60) + seconds
    else
      0
    end
  end

  def find_event(row, results)
    event_name = row["EVENT"]&.strip
    event = @events_cache[event_name]

    unless event
      results[:failed] << {
        row: row,
        errors: ["Event not found: #{event_name}"]
      }
    end

    event
  end

  def find_fight(event, row, results)
    bout = normalize_whitespace(row["BOUT"])
    fight = @fights_cache.dig(event.id, bout)

    unless fight
      results[:failed] << {
        row: row,
        errors: ["Fight not found: #{bout}"]
      }
    end

    fight
  end

  def find_fighter(row, results)
    fighter_name = normalize_whitespace(row["FIGHTER"])
    fighter = @fighters_cache[fighter_name]

    unless fighter
      results[:failed] << {
        row: row,
        errors: ["Fighter not found: #{fighter_name}"]
      }
    end

    fighter
  end

  def find_or_create_fight_stat(fight, fighter, row)
    FightStat.find_or_initialize_by(
      fight: fight,
      fighter: fighter,
      round: parse_round(row["ROUND"])
    )
  end

  def assign_basic_stats(fight_stat, row)
    fight_stat.knockdowns = parse_integer(row["KD"])
    fight_stat.submission_attempts = parse_integer(row["SUB.ATT"])
    fight_stat.reversals = parse_integer(row["REV."])
    fight_stat.control_time_seconds = parse_control_time(row["CTRL"])
  end

  def assign_strike_stats(fight_stat, row)
    assign_x_of_y_stats(fight_stat, :significant_strikes, row["SIG.STR."])
    assign_x_of_y_stats(fight_stat, :total_strikes, row["TOTAL STR."])
    assign_x_of_y_stats(fight_stat, :takedowns, row["TD"])
  end

  def assign_location_stats(fight_stat, row)
    assign_x_of_y_stats(fight_stat, :head_strikes, row["HEAD"])
    assign_x_of_y_stats(fight_stat, :body_strikes, row["BODY"])
    assign_x_of_y_stats(fight_stat, :leg_strikes, row["LEG"])
    assign_x_of_y_stats(fight_stat, :distance_strikes, row["DISTANCE"])
    assign_x_of_y_stats(fight_stat, :clinch_strikes, row["CLINCH"])
    assign_x_of_y_stats(fight_stat, :ground_strikes, row["GROUND"])
  end

  def assign_x_of_y_stats(fight_stat, base_name, value)
    parsed = parse_x_of_y_format(value)
    fight_stat.send("#{base_name}=", parsed[:x])
    fight_stat.send("#{base_name}_attempted=", parsed[:y])
  end

  def normalize_whitespace(string)
    return nil if string.blank?

    string.strip.gsub(/\s+/, " ")
  end

  def log_failed_imports(failed_imports)
    Rails.logger.error "Failed to import #{failed_imports.count} fight stats:"
    failed_imports.each do |failure|
      Rails.logger.error "  Fighter: #{failure[:row]['FIGHTER']}, " \
                         "Errors: #{failure[:errors].join(', ')}"
    end
  end
end
