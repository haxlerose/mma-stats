# frozen_string_literal: true

require "nokogiri"
require "faraday"
require "date"

class UfcStatsScraper
  class ScraperError < StandardError; end

  BASE_URL = "http://ufcstats.com"
  EVENTS_URL = "http://ufcstats.com/statistics/events/completed"

  def scrape_completed_events_list
    # Use ?page=all to get all events at once
    url = "#{EVENTS_URL}?page=all"
    Rails.logger.info "  Fetching all events..."

    html = fetch_page(url)
    doc = Nokogiri::HTML(html)

    # Extract all events
    events = extract_events_from_list(doc)

    Rails.logger.info "  Found #{events.count} total events"
    events
  end

  def find_event_url(event_name, events_list = nil)
    # If no list provided, scrape it
    events_list ||= scrape_completed_events_list

    # Try different matching strategies
    find_exact_match(event_name, events_list) ||
      find_normalized_match(event_name, events_list) ||
      find_partial_match(event_name, events_list)
  end

  def find_exact_match(event_name, events_list)
    event = events_list.find { |e| e[:name] == event_name }
    event&.dig(:url)
  end

  def find_normalized_match(event_name, events_list)
    normalized_name = normalize_event_name(event_name)
    event = events_list.find do |e|
      normalize_event_name(e[:name]) == normalized_name
    end
    event&.dig(:url)
  end

  def find_partial_match(event_name, events_list)
    event = events_list.find do |e|
      e[:name].include?(event_name) || event_name.include?(e[:name])
    end
    event&.dig(:url)
  end

  def scrape_event(event_url)
    html = fetch_page(event_url)
    doc = Nokogiri::HTML(html)

    fights = extract_fights(doc)
    enrich_fights_with_details(fights)

    build_event_data(doc, fights)
  end

  def enrich_fights_with_details(fights)
    fights.each do |fight|
      enrich_single_fight(fight)
    end
  end

  def enrich_single_fight(fight)
    fight_details = scrape_fight_details(fight[:fight_url])
    fight[:referee] = fight_details[:referee]
    fight[:time_format] = fight_details[:time_format]
    fight[:details] = fight_details[:details]
    # Override method if we got better data from details page
    fight[:method] = fight_details[:method] if fight_details[:method]
  rescue StandardError => e
    Rails.logger.info "    ⚠ Could not fetch fight details: #{e.message}"
  end

  def build_event_data(doc, fights)
    {
      name: extract_event_name(doc),
      date: extract_event_date(doc),
      location: extract_event_location(doc),
      fights: fights
    }
  end

  def scrape_fight_details(fight_url)
    html = fetch_page(fight_url)
    doc = Nokogiri::HTML(html)

    {
      fighter1: extract_fighter1(doc),
      fighter2: extract_fighter2(doc),
      winner: extract_winner(doc),
      method: extract_method_from_details(doc),
      round: extract_round(doc),
      time: extract_time(doc),
      time_format: extract_time_format(doc),
      referee: extract_referee(doc),
      details: extract_details(doc),
      rounds: extract_round_stats(doc)
    }
  end

  def scrape_to_csv(event_url)
    event_data = scrape_event(event_url)
    fights_csv = []
    fight_stats_csv = []

    process_fights_for_csv(event_data, fights_csv, fight_stats_csv)

    {
      fights: fights_csv,
      fight_stats: fight_stats_csv
    }
  end

  def process_fights_for_csv(event_data, fights_csv, fight_stats_csv)
    event_data[:fights].each_with_index do |fight, index|
      log_fight_processing(index, event_data[:fights].count, fight)
      process_single_fight_for_csv(
        event_data,
        fight,
        fights_csv,
        fight_stats_csv
      )
    end
  end

  def log_fight_processing(index, total_count, fight)
    Rails.logger.info "  Scraping fight " \
                      "#{index + 1}/#{total_count}: " \
                      "#{fight[:fighter1]} vs #{fight[:fighter2]}..."
  end

  def process_single_fight_for_csv(
    event_data, fight, fights_csv,
    fight_stats_csv
  )
    fight_details = scrape_fight_details(fight[:fight_url])
    fights_csv << build_fight_csv_row(event_data, fight, fight_details)
    add_fight_stats_rows(event_data, fight, fight_details, fight_stats_csv)
  rescue StandardError => e
    Rails.logger.info "    ✗ Error scraping fight details: #{e.message}"
  end

  def add_fight_stats_rows(event_data, fight, fight_details, fight_stats_csv)
    return log_no_round_data unless fight_details[:rounds]&.any?

    fight_details[:rounds].each do |round|
      add_fighter_stat_rows(
        event_data,
        fight,
        round,
        fight_details,
        fight_stats_csv
      )
    end
  end

  def add_fighter_stat_rows(
    event_data, fight, round, fight_details,
    fight_stats_csv
  )
    fight_stats_csv << build_fight_stat_csv_row(
      event_data,
      fight,
      round,
      fight_details[:fighter1],
      :fighter1_stats
    )
    fight_stats_csv << build_fight_stat_csv_row(
      event_data,
      fight,
      round,
      fight_details[:fighter2],
      :fighter2_stats
    )
  end

  def log_no_round_data
    Rails.logger.info "    ⚠ No round data found for this fight"
  end

  private

  def extract_events_from_list(doc)
    events = []

    doc.css("tr.b-statistics__table-row").each do |row|
      event = extract_event_from_row(row)
      events << event if event
    end

    events
  end

  def extract_event_from_row(row)
    return nil if row.css("th").any? # Skip header rows

    event_link = find_event_link(row)
    return nil unless event_link

    build_event_hash(row, event_link)
  end

  def find_event_link(row)
    event_cell = row.css("td.b-statistics__table-col")[0]
    event_cell&.css("a.b-link")&.first
  end

  def build_event_hash(row, event_link)
    event_cell = row.css("td.b-statistics__table-col")[0]
    location_cell = row.css("td.b-statistics__table-col")[1]

    {
      name: event_link.text.strip,
      url: event_link["href"],
      date: event_cell.css("span.b-statistics__date").text.strip,
      location: location_cell&.text&.strip
    }
  end

  def normalize_event_name(name)
    name.downcase
        .gsub(/[^a-z0-9\s]/, "") # Remove special characters
        .gsub(/\s+/, " ")        # Normalize whitespace
        .strip
  end

  def fetch_page(url)
    response = Faraday.get(url)
    raise ScraperError, "Failed to fetch #{url}" unless response.success?

    response.body
  rescue Faraday::Error => e
    raise ScraperError, "Network error: #{e.message}"
  end

  def extract_event_name(doc)
    doc.css("h2.b-content__title span.b-content__title-highlight").text.strip
  end

  def extract_event_date(doc)
    date_item = doc.css("li.b-list__box-list-item")
                   .find { |li| li.text.include?("Date:") }
    return nil unless date_item

    date_text = date_item.text.gsub("Date:", "").strip
    Date.parse(date_text) if date_text.present?
  end

  def extract_event_location(doc)
    location_item = doc.css("li.b-list__box-list-item")
                       .find { |li| li.text.include?("Location:") }
    return nil unless location_item

    location_item.text.gsub("Location:", "").strip
  end

  def extract_fights(doc)
    fights = []

    doc.css("tr.b-fight-details__table-row[data-link]").each do |row|
      fight = extract_fight_from_row(row)
      fights << fight if fight
    end

    fights
  end

  def extract_fight_from_row(row)
    fight_url = row["data-link"]
    return nil unless fight_url

    cells = row.css("td.b-fight-details__table-col")
    fight_data = extract_fight_data_from_cells(cells)
    fight_data[:fight_url] = fight_url
    fight_data
  end

  def extract_fight_data_from_cells(cells)
    winner_indicator = extract_winner_indicator(cells[0])
    fighters = extract_fighters(cells[1])

    build_fight_data_hash(cells, fighters, winner_indicator)
  end

  def extract_winner_indicator(cell)
    cell.css("i.b-flag__text").text.strip
  end

  def build_fight_data_hash(cells, fighters, winner_indicator)
    {
      fighter1: fighters[0],
      fighter2: fighters[1],
      winner: determine_winner(fighters, winner_indicator),
      weight_class: extract_weight_class(cells[6]),
      method: extract_method(cells[7]),
      round: cells[8].text.strip.to_i,
      time: cells[9].text.strip
    }
  end

  def determine_winner(fighters, winner_indicator)
    winner_indicator == "win" ? fighters[0] : fighters[1]
  end

  def extract_fighters(cell)
    cell.css("a.b-link").map { |link| link.text.strip }
  end

  def extract_weight_class(cell)
    cell.text.strip.split("\n").first&.strip || "Unknown"
  end

  def extract_method(cell)
    cell.text.strip.gsub(/\s+/, " ")
  end

  def extract_fighter1(doc)
    person_div = doc.css("div.b-fight-details__person")[0]
    return nil unless person_div

    fighter_link = person_div.css("h3.b-fight-details__person-name a")
    fighter_link.text.strip if fighter_link.any?
  end

  def extract_fighter2(doc)
    person_div = doc.css("div.b-fight-details__person")[1]
    return nil unless person_div

    fighter_link = person_div.css("h3.b-fight-details__person-name a")
    fighter_link.text.strip if fighter_link.any?
  end

  def extract_winner(doc)
    winner_element = doc.css("div.b-fight-details__person")
                        .find do |div|
      green_style = "i.b-fight-details__person-status_style_green"
      div.css(green_style).any?
    end

    return nil unless winner_element

    fighter_link = winner_element.css("h3.b-fight-details__person-name a")
    fighter_link.text.strip if fighter_link.any?
  end

  def extract_round(doc)
    round_element = doc.css("p.b-fight-details__text")
                       .find { |p| p.text.include?("Round:") }
    return nil unless round_element

    match = round_element.text.match(/Round:\s*(\d+)/)
    match[1].to_i if match
  end

  def extract_time(doc)
    time_element = doc.css("p.b-fight-details__text")
                      .find { |p| p.text.include?("Time:") }
    return nil unless time_element

    # Extract time value - it's after "Time:" and before "Time format:"
    text = time_element.text
    match = text.match(/Time:\s*([\d:]+)/m)
    match ? match[1].strip : nil
  end

  def extract_time_format(doc)
    format_element = doc.css("p.b-fight-details__text")
                        .find { |p| p.text.include?("Time format:") }
    return nil unless format_element

    # Extract text between "Time format:" and "Referee:"
    text = format_element.text
    format = text.match(/Time format:\s*([^\n]+?)\s*Referee:/m)&.captures&.first
    format&.strip
  end

  def extract_referee(doc)
    referee_element = doc.css("p.b-fight-details__text")
                         .find { |p| p.text.include?("Referee:") }
    return nil unless referee_element

    # Extract text after "Referee:" and before any other label
    text = referee_element.text
    match = text.match(/Referee:\s*([^\n]+?)(?:\s+\w+:|$)/)
    match ? match[1].strip : nil
  end

  def extract_method_from_details(doc)
    method_element = doc.css("p.b-fight-details__text")
                        .find { |p| p.text.include?("Method:") }
    return nil unless method_element

    # Extract text after "Method:" and before "Round:"
    text = method_element.text
    match = text.match(/Method:\s*([^\n]+?)(?:\s*Round:|$)/m)
    match ? match[1].strip : nil
  end

  def extract_details(doc)
    details_text = extract_details_from_label(doc)
    return details_text if details_text.present?

    extract_details_from_patterns(doc)
  end

  def extract_details_from_label(doc)
    fight_details_section = doc.css("div.b-fight-details__fight")
    return nil unless fight_details_section.any?

    full_text = fight_details_section.text
    return nil unless full_text.include?("Details:")

    extract_and_clean_details_text(full_text)
  end

  def extract_and_clean_details_text(full_text)
    parts = full_text.split("Details:", 2)
    return nil unless parts.length > 1

    details_text = parts[1].strip.gsub(/\s+/, " ")
    details_text = details_text.split(/\n\s*\n/).first if details_text
    details_text
  end

  def extract_details_from_patterns(doc)
    judge_scores = find_judge_scores(doc)
    return nil unless judge_scores.any?

    scores_text = judge_scores.map(&:text).join(" ").strip.gsub(/\s+/, " ")
    scores_text.presence
  end

  def find_judge_scores(doc)
    doc.css("p.b-fight-details__text").find_all do |p|
      p.text.match(/\d+\s*-\s*\d+/)
    end
  end

  def extract_round_stats(doc)
    per_round_sections = find_per_round_sections(doc)
    return [] if per_round_sections.empty?

    rounds = extract_general_stats(per_round_sections.first)
    add_significant_strike_details(per_round_sections, rounds)

    rounds.sort_by { |r| r[:round] }
  end

  def find_per_round_sections(doc)
    doc.css("section.b-fight-details__section").select do |section|
      section.css("a").any? { |a| a.text.strip.downcase == "per round" }
    end
  end

  def extract_general_stats(general_stats_section)
    return [] unless general_stats_section

    table_class = "table.b-fight-details__table"
    general_table = general_stats_section.css(table_class).first
    return [] unless general_table

    process_general_stats_table(general_table)
  end

  def process_general_stats_table(table)
    rounds = []
    data_rows = table.css("tr").select { |tr| tr.css("td").any? }

    data_rows.each_with_index do |row, idx|
      round_stats = build_round_stats(row, idx + 1)
      rounds << round_stats
    end

    rounds
  end

  def build_round_stats(row, round_num)
    cells = row.css("td")
    round_stats = initialize_round_stats(round_num)
    populate_round_stats(cells, round_stats)
    round_stats
  end

  def populate_round_stats(cells, round_stats)
    stat_parsers = {
      1 => :parse_knockdowns,
      2 => :parse_significant_strikes,
      4 => :parse_total_strikes,
      5 => :parse_takedowns,
      7 => :parse_submission_attempts,
      8 => :parse_reversals,
      9 => :parse_control_time
    }

    stat_parsers.each do |index, parser_method|
      send(parser_method, cells[index], round_stats) if cells[index]
    end
  end

  def initialize_round_stats(round_num)
    {
      round: round_num,
      fighter1_stats: {},
      fighter2_stats: {}
    }
  end

  def parse_knockdowns(cell, round_stats)
    kd_data = parse_dual_stat_cell(cell.text)
    round_stats[:fighter1_stats][:knockdowns] = kd_data[:fighter1]
    round_stats[:fighter2_stats][:knockdowns] = kd_data[:fighter2]
  end

  def parse_significant_strikes(cell, round_stats)
    sig_str_data = parse_dual_of_stat_cell(cell.text)
    set_strike_stats(round_stats, :significant_strikes, sig_str_data)
  end

  def parse_total_strikes(cell, round_stats)
    total_str_data = parse_dual_of_stat_cell(cell.text)
    set_strike_stats(round_stats, :total_strikes, total_str_data)
  end

  def parse_takedowns(cell, round_stats)
    td_data = parse_dual_of_stat_cell(cell.text)
    set_takedown_stats(round_stats, td_data)
  end

  def parse_submission_attempts(cell, round_stats)
    sub_data = parse_dual_stat_cell(cell.text)
    round_stats[:fighter1_stats][:submission_attempts] = sub_data[:fighter1]
    round_stats[:fighter2_stats][:submission_attempts] = sub_data[:fighter2]
  end

  def parse_reversals(cell, round_stats)
    rev_data = parse_dual_stat_cell(cell.text)
    round_stats[:fighter1_stats][:reversals] = rev_data[:fighter1]
    round_stats[:fighter2_stats][:reversals] = rev_data[:fighter2]
  end

  def parse_control_time(cell, round_stats)
    ctrl_data = parse_dual_control_time_cell(cell.text)
    round_stats[:fighter1_stats][:control_time_seconds] = ctrl_data[:fighter1]
    round_stats[:fighter2_stats][:control_time_seconds] = ctrl_data[:fighter2]
  end

  def set_strike_stats(round_stats, stat_type, data)
    round_stats[:fighter1_stats][stat_type] = data[:fighter1][:landed]
    round_stats[:fighter1_stats][:"#{stat_type}_attempted"] =
      data[:fighter1][:attempted]
    round_stats[:fighter2_stats][stat_type] = data[:fighter2][:landed]
    round_stats[:fighter2_stats][:"#{stat_type}_attempted"] =
      data[:fighter2][:attempted]
  end

  def set_takedown_stats(round_stats, data)
    round_stats[:fighter1_stats][:takedowns] = data[:fighter1][:landed]
    round_stats[:fighter1_stats][:takedowns_attempted] =
      data[:fighter1][:attempted]
    round_stats[:fighter2_stats][:takedowns] = data[:fighter2][:landed]
    round_stats[:fighter2_stats][:takedowns_attempted] =
      data[:fighter2][:attempted]
  end

  def add_significant_strike_details(per_round_sections, rounds)
    sig_strikes_section = per_round_sections.find do |s|
      s.text.include?("Significant Strikes")
    end
    return unless sig_strikes_section

    sig_table = sig_strikes_section.css("table.b-fight-details__table").first
    add_strike_details_from_per_round_table(sig_table, rounds) if sig_table
  end

  def parse_dual_stat_cell(text)
    # Parse cells like "0\n\n\n0" where first is fighter1, second is fighter2
    lines = text.split("\n").map(&:strip).reject(&:empty?)
    {
      fighter1: lines[0].to_i,
      fighter2: lines[1].to_i
    }
  end

  def parse_dual_of_stat_cell(text)
    lines = text.split("\n").map(&:strip).reject(&:empty?)

    {
      fighter1: parse_of_stat_line(lines[0]),
      fighter2: parse_of_stat_line(lines[1])
    }
  end

  def parse_of_stat_line(line)
    return { landed: 0, attempted: 0 } unless line&.match(/(\d+)\s*of\s*(\d+)/)

    {
      landed: ::Regexp.last_match(1).to_i,
      attempted: ::Regexp.last_match(2).to_i
    }
  end

  def parse_dual_control_time_cell(text)
    lines = text.split("\n").map(&:strip).reject(&:empty?)

    {
      fighter1: parse_time_to_seconds(lines[0]),
      fighter2: parse_time_to_seconds(lines[1])
    }
  end

  def parse_time_to_seconds(time_str)
    return 0 unless time_str&.match(/(\d+):(\d+)/)

    minutes = ::Regexp.last_match(1).to_i
    seconds = ::Regexp.last_match(2).to_i
    (minutes * 60) + seconds
  end

  def add_strike_details_from_per_round_table(table, rounds)
    data_rows = table.css("tr").select { |tr| tr.css("td").any? }

    data_rows.each_with_index do |row, idx|
      process_strike_details_row(row, idx + 1, rounds)
    end
  end

  def process_strike_details_row(row, round_num, rounds)
    round_entry = rounds.find { |r| r[:round] == round_num }
    return unless round_entry

    cells = row.css("td")
    add_all_strike_types_to_round(cells, round_entry)
  end

  def add_all_strike_types_to_round(cells, round_entry)
    strike_mappings = {
      3 => :head_strikes,
      4 => :body_strikes,
      5 => :leg_strikes,
      6 => :distance_strikes,
      7 => :clinch_strikes,
      8 => :ground_strikes
    }

    strike_mappings.each do |index, strike_type|
      add_strike_type(cells[index], round_entry, strike_type) if cells[index]
    end
  end

  def add_strike_type(cell, round_entry, strike_type)
    strike_data = parse_dual_of_stat_cell(cell.text)
    set_strike_stats(round_entry, strike_type, strike_data)
  end

  def parse_fighter_stats(cells, fighter_index)
    stats_data = extract_stat_texts(cells)
    parsed_stats = parse_all_stats(stats_data, fighter_index)
    build_fighter_stats_hash(parsed_stats)
  end

  def extract_stat_texts(cells)
    {
      kd: cells[0],
      sig_str: cells[1],
      total_str: cells[3],
      td: cells[4],
      sub: cells[6],
      rev: cells[7],
      ctrl: cells[8]
    }
  end

  def parse_all_stats(stats_data, fighter_index)
    {
      kd: parse_single_stat(stats_data[:kd], fighter_index),
      sig_str: parse_of_stat(stats_data[:sig_str], fighter_index),
      total_str: parse_of_stat(stats_data[:total_str], fighter_index),
      td: parse_of_stat(stats_data[:td], fighter_index),
      sub: parse_single_stat(stats_data[:sub], fighter_index),
      rev: parse_single_stat(stats_data[:rev], fighter_index),
      ctrl: parse_control_time(stats_data[:ctrl], fighter_index)
    }
  end

  def build_fighter_stats_hash(parsed_stats)
    {
      knockdowns: parsed_stats[:kd],
      significant_strikes: parsed_stats[:sig_str][:landed],
      significant_strikes_attempted: parsed_stats[:sig_str][:attempted],
      total_strikes: parsed_stats[:total_str][:landed],
      total_strikes_attempted: parsed_stats[:total_str][:attempted],
      takedowns: parsed_stats[:td][:landed],
      takedowns_attempted: parsed_stats[:td][:attempted],
      submission_attempts: parsed_stats[:sub],
      reversals: parsed_stats[:rev],
      control_time_seconds: parsed_stats[:ctrl]
    }
  end

  def parse_single_stat(text, fighter_index)
    parts = text.split("/").map(&:strip)
    parts[fighter_index].to_i
  end

  def parse_of_stat(text, fighter_index)
    parts = text.split("/").map(&:strip)
    fighter_stat = parts[fighter_index]

    if fighter_stat&.match(/(\d+)\s*of\s*(\d+)/)
      {
        landed: ::Regexp.last_match(1).to_i,
        attempted: ::Regexp.last_match(2).to_i
      }
    else
      { landed: 0, attempted: 0 }
    end
  end

  def build_fight_csv_row(event_data, fight, fight_details)
    {
      "EVENT" => event_data[:name],
      "BOUT" => determine_bout_type(fight),
      "OUTCOME" => determine_outcome(fight, fight_details),
      "WEIGHTCLASS" => fight[:weight_class],
      "METHOD" => fight_details[:method],
      "ROUND" => fight_details[:round],
      "TIME" => fight_details[:time],
      "TIME FORMAT" => fight_details[:time_format] || "",
      "REFEREE" => fight_details[:referee] || "",
      "DETAILS" => "",
      "URL" => fight[:fight_url]
    }
  end

  def build_fight_stat_csv_row(
    event_data, fight, round_data, fighter_name,
    stats_key
  )
    stats = round_data[stats_key]

    base_stats = build_base_fight_stats(
      event_data,
      fight,
      round_data,
      fighter_name,
      stats
    )
    strike_stats = build_strike_stats(stats)
    location_stats = build_location_strike_stats(stats)

    base_stats.merge(strike_stats).merge(location_stats)
  end

  def build_base_fight_stats(event_data, fight, round_data, fighter_name, stats)
    {
      "EVENT" => event_data[:name],
      "BOUT" => determine_bout_type(fight),
      "ROUND" => round_data[:round],
      "FIGHTER" => fighter_name,
      "KD" => stats[:knockdowns],
      "SUB.ATT" => stats[:submission_attempts],
      "REV." => stats[:reversals],
      "CTRL" => format_control_time(stats[:control_time_seconds])
    }
  end

  def build_strike_stats(stats)
    {
      "SIG.STR." => format_strike_stat(
        stats[:significant_strikes],
        stats[:significant_strikes_attempted]
      ),
      "SIG.STR. %" => calculate_percentage(
        stats[:significant_strikes],
        stats[:significant_strikes_attempted]
      ),
      "TOTAL STR." => format_strike_stat(
        stats[:total_strikes],
        stats[:total_strikes_attempted]
      ),
      "TD" => format_strike_stat(
        stats[:takedowns],
        stats[:takedowns_attempted]
      ),
      "TD %" => calculate_percentage(
        stats[:takedowns],
        stats[:takedowns_attempted]
      )
    }
  end

  def build_location_strike_stats(stats)
    strike_types = %i[
      head
      body
      leg
      distance
      clinch
      ground
    ]

    strike_types.each_with_object({}) do |type, hash|
      key = type.to_s.upcase
      landed_key = :"#{type}_strikes"
      attempted_key = :"#{type}_strikes_attempted"
      hash[key] = format_strike_stat(stats[landed_key], stats[attempted_key])
    end
  end

  def format_strike_stat(landed, attempted)
    "#{landed} of #{attempted}"
  end

  def determine_bout_type(fight)
    # Could enhance this with logic to determine main event, co-main, etc.
    "#{fight[:fighter1]} vs. #{fight[:fighter2]}"
  end

  def determine_outcome(fight, fight_details)
    if fight_details[:winner] == fight[:fighter1]
      "Win"
    else
      "Loss"
    end
  end

  def calculate_percentage(landed, attempted)
    return "---" if attempted.zero?

    "#{((landed.to_f / attempted) * 100).round}%"
  end

  def format_control_time(seconds)
    return "0:00" if seconds.zero?

    minutes = seconds / 60
    secs = seconds % 60
    "#{minutes}:#{secs.to_s.rjust(2, '0')}"
  end
end
