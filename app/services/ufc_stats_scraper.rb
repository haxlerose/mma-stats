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
    puts "  Fetching all events..."
    
    html = fetch_page(url)
    doc = Nokogiri::HTML(html)
    
    # Extract all events
    events = extract_events_from_list(doc)
    
    puts "  Found #{events.count} total events"
    events
  end

  def find_event_url(event_name, events_list = nil)
    # If no list provided, scrape it
    events_list ||= scrape_completed_events_list
    
    # Try exact match first
    event = events_list.find { |e| e[:name] == event_name }
    return event[:url] if event
    
    # Try normalized match (remove special characters, lowercase)
    normalized_name = normalize_event_name(event_name)
    event = events_list.find { |e| normalize_event_name(e[:name]) == normalized_name }
    return event[:url] if event
    
    # Try partial match
    event = events_list.find { |e| e[:name].include?(event_name) || event_name.include?(e[:name]) }
    return event[:url] if event
    
    nil
  end

  def scrape_event(event_url)
    html = fetch_page(event_url)
    doc = Nokogiri::HTML(html)
    
    fights = extract_fights(doc)
    
    # For each fight, get additional details from the fight page
    fights.each do |fight|
      begin
        fight_details = scrape_fight_details(fight[:fight_url])
        fight[:referee] = fight_details[:referee]
        fight[:time_format] = fight_details[:time_format]
        fight[:details] = fight_details[:details]
        # Override method if we got better data from details page
        fight[:method] = fight_details[:method] if fight_details[:method]
      rescue StandardError => e
        puts "    ⚠ Could not fetch fight details: #{e.message}"
      end
    end
    
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
      method: extract_method(doc),
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

    event_data[:fights].each_with_index do |fight, index|
      puts "  Scraping fight #{index + 1}/#{event_data[:fights].count}: #{fight[:fighter1]} vs #{fight[:fighter2]}..."
      
      begin
        # Get detailed fight data
        fight_details = scrape_fight_details(fight[:fight_url])
        
        # Build fights CSV row
        fights_csv << build_fight_csv_row(event_data, fight, fight_details)
        
        # Build fight_stats CSV rows if rounds data exists
        if fight_details[:rounds] && fight_details[:rounds].any?
          fight_details[:rounds].each do |round|
            fight_stats_csv << build_fight_stat_csv_row(
              event_data, fight, round, fight_details[:fighter1], :fighter1_stats
            )
            fight_stats_csv << build_fight_stat_csv_row(
              event_data, fight, round, fight_details[:fighter2], :fighter2_stats
            )
          end
        else
          puts "    ⚠ No round data found for this fight"
        end
      rescue StandardError => e
        puts "    ✗ Error scraping fight details: #{e.message}"
      end
    end

    {
      fights: fights_csv,
      fight_stats: fight_stats_csv
    }
  end

  private

  def extract_events_from_list(doc)
    events = []
    
    # Find all event rows in the table
    doc.css("tr.b-statistics__table-row").each do |row|
      # Skip header rows
      next if row.css("th").any?
      
      # Extract event link and name from the first column
      event_cell = row.css("td.b-statistics__table-col")[0]
      event_link = event_cell&.css("a.b-link")&.first
      next unless event_link
      
      event_name = event_link.text.strip
      event_url = event_link["href"]
      
      # Extract date from the first cell (it contains both link and date)
      date_text = event_cell.css("span.b-statistics__date").text.strip
      
      # Extract location from the second column
      location_cell = row.css("td.b-statistics__table-col")[1]
      location_text = location_cell&.text&.strip
      
      events << {
        name: event_name,
        url: event_url,
        date: date_text,
        location: location_text
      }
    end
    
    events
  end

  def normalize_event_name(name)
    name.downcase
        .gsub(/[^a-z0-9\s]/, '') # Remove special characters
        .gsub(/\s+/, ' ')        # Normalize whitespace
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
    date_text = doc.css("li.b-list__box-list-item")
                   .find { |li| li.text.include?("Date:") }
                   &.text
                   &.gsub("Date:", "")
                   &.strip
    
    Date.parse(date_text) if date_text
  end

  def extract_event_location(doc)
    doc.css("li.b-list__box-list-item")
       .find { |li| li.text.include?("Location:") }
       &.text
       &.gsub("Location:", "")
       &.strip
  end

  def extract_fights(doc)
    fights = []
    
    doc.css("tr.b-fight-details__table-row[data-link]").each do |row|
      fight_url = row["data-link"]
      next unless fight_url
      
      cells = row.css("td.b-fight-details__table-col")
      
      # Cell 0: Win/Loss indicator
      winner_indicator = cells[0].css("i.b-flag__text").text.strip
      
      # Cell 1: Fighter names
      fighters = cells[1].css("a.b-link")
                         .map(&:text)
                         .map(&:strip)
      
      # Cells 2-5: Stats (KD, SIG.STR., TD, SUB.ATT) - skip for now
      
      # Cell 6: Weight class
      weight_class = cells[6].text.strip.split("\n").first&.strip || "Unknown"
      
      # Cell 7: Method (may have multiple lines)
      method = cells[7].text.strip.gsub(/\s+/, " ")
      
      # Cell 8: Round
      round = cells[8].text.strip.to_i
      
      # Cell 9: Time
      time = cells[9].text.strip
      
      fights << {
        fighter1: fighters[0],
        fighter2: fighters[1],
        winner: winner_indicator == "win" ? fighters[0] : fighters[1],
        weight_class: weight_class,
        method: method,
        round: round,
        time: time,
        fight_url: fight_url
      }
    end
    
    fights
  end

  def extract_fighter1(doc)
    doc.css("div.b-fight-details__person")[0]
       &.css("h3.b-fight-details__person-name a")
       &.text
       &.strip
  end

  def extract_fighter2(doc)
    doc.css("div.b-fight-details__person")[1]
       &.css("h3.b-fight-details__person-name a")
       &.text
       &.strip
  end

  def extract_winner(doc)
    winner_element = doc.css("div.b-fight-details__person")
                        .find { |div| div.css("i.b-fight-details__person-status_style_green").any? }
    
    winner_element&.css("h3.b-fight-details__person-name a")&.text&.strip
  end

  def extract_method(doc)
    method_element = doc.css("p.b-fight-details__text")
                        .find { |p| p.text.include?("Method:") }
    return nil unless method_element
    
    # Extract text between "Method:" and "Round:"
    text = method_element.text
    method = text.match(/Method:\s*([^\n]+?)\s*Round:/m)&.captures&.first
    method&.strip
  end

  def extract_round(doc)
    doc.css("p.b-fight-details__text")
       .find { |p| p.text.include?("Round:") }
       &.text
       &.match(/Round:\s*(\d+)/)
       &.captures
       &.first
       &.to_i
  end

  def extract_time(doc)
    doc.css("p.b-fight-details__text")
       .find { |p| p.text.include?("Time:") && !p.text.include?("Time format:") }
       &.text
       &.match(/Time:\s*([\d:]+)/)
       &.captures
       &.first
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

  def extract_details(doc)
    # Look for the Details: label and get ALL text after it
    details_text = nil
    
    # Find the fight details section
    fight_details_section = doc.css("div.b-fight-details__fight")
    
    if fight_details_section.any?
      # Get all text content and find everything after "Details:"
      full_text = fight_details_section.text
      
      # Look for "Details:" and capture everything after it
      if full_text.include?("Details:")
        # Split by "Details:" and get everything after
        parts = full_text.split("Details:", 2)
        if parts.length > 1
          # Clean up the text - remove extra whitespace and newlines
          details_text = parts[1].strip.gsub(/\s+/, " ")
          
          # Remove any trailing section markers if present
          details_text = details_text.split(/\n\s*\n/).first if details_text
        end
      end
    end
    
    # If no details found with "Details:" label, look for specific detail patterns
    if details_text.nil? || details_text.empty?
      # Check for judge scores in decision fights
      judge_scores = doc.css("p.b-fight-details__text").find_all { |p| p.text.match(/\d+\s*-\s*\d+/) }
      if judge_scores.any?
        scores_text = judge_scores.map(&:text).join(" ").strip.gsub(/\s+/, " ")
        details_text = scores_text unless scores_text.empty?
      end
    end
    
    details_text
  end

  def extract_round_stats(doc)
    rounds = []
    
    # Find sections with "Per round" links
    per_round_sections = doc.css("section.b-fight-details__section").select do |section|
      section.css("a").any? { |a| a.text.strip.downcase == "per round" }
    end
    
    return rounds if per_round_sections.empty?
    
    # Get fighter names from the main fight details
    fighter1_name = extract_fighter1(doc)
    fighter2_name = extract_fighter2(doc)
    
    # Process the first per-round section (general stats)
    general_stats_section = per_round_sections.first
    general_table = general_stats_section.css("table.b-fight-details__table").first
    
    if general_table
      headers = general_table.css("tr").first.css("th").map(&:text).map(&:strip)
      
      # Get all data rows (skip header row)
      data_rows = general_table.css("tr").select { |tr| tr.css("td").any? }
      
      # Each row represents a round
      data_rows.each_with_index do |row, idx|
        round_num = idx + 1
        cells = row.css("td")
        
        # Parse each cell - each contains data for both fighters separated by newlines
        round_stats = {
          round: round_num,
          fighter1_stats: {},
          fighter2_stats: {}
        }
        
        # KD (index 1)
        if cells[1]
          kd_data = parse_dual_stat_cell(cells[1].text)
          round_stats[:fighter1_stats][:knockdowns] = kd_data[:fighter1]
          round_stats[:fighter2_stats][:knockdowns] = kd_data[:fighter2]
        end
        
        # Sig. str. (index 2)
        if cells[2]
          sig_str_data = parse_dual_of_stat_cell(cells[2].text)
          round_stats[:fighter1_stats][:significant_strikes] = sig_str_data[:fighter1][:landed]
          round_stats[:fighter1_stats][:significant_strikes_attempted] = sig_str_data[:fighter1][:attempted]
          round_stats[:fighter2_stats][:significant_strikes] = sig_str_data[:fighter2][:landed]
          round_stats[:fighter2_stats][:significant_strikes_attempted] = sig_str_data[:fighter2][:attempted]
        end
        
        # Total str. (index 4)
        if cells[4]
          total_str_data = parse_dual_of_stat_cell(cells[4].text)
          round_stats[:fighter1_stats][:total_strikes] = total_str_data[:fighter1][:landed]
          round_stats[:fighter1_stats][:total_strikes_attempted] = total_str_data[:fighter1][:attempted]
          round_stats[:fighter2_stats][:total_strikes] = total_str_data[:fighter2][:landed]
          round_stats[:fighter2_stats][:total_strikes_attempted] = total_str_data[:fighter2][:attempted]
        end
        
        # Takedowns (index 5)
        if cells[5]
          td_data = parse_dual_of_stat_cell(cells[5].text)
          round_stats[:fighter1_stats][:takedowns] = td_data[:fighter1][:landed]
          round_stats[:fighter1_stats][:takedowns_attempted] = td_data[:fighter1][:attempted]
          round_stats[:fighter2_stats][:takedowns] = td_data[:fighter2][:landed]
          round_stats[:fighter2_stats][:takedowns_attempted] = td_data[:fighter2][:attempted]
        end
        
        # Sub attempts (index 7)
        if cells[7]
          sub_data = parse_dual_stat_cell(cells[7].text)
          round_stats[:fighter1_stats][:submission_attempts] = sub_data[:fighter1]
          round_stats[:fighter2_stats][:submission_attempts] = sub_data[:fighter2]
        end
        
        # Reversals (index 8)
        if cells[8]
          rev_data = parse_dual_stat_cell(cells[8].text)
          round_stats[:fighter1_stats][:reversals] = rev_data[:fighter1]
          round_stats[:fighter2_stats][:reversals] = rev_data[:fighter2]
        end
        
        # Control time (index 9)
        if cells[9]
          ctrl_data = parse_dual_control_time_cell(cells[9].text)
          round_stats[:fighter1_stats][:control_time_seconds] = ctrl_data[:fighter1]
          round_stats[:fighter2_stats][:control_time_seconds] = ctrl_data[:fighter2]
        end
        
        rounds << round_stats
      end
    end
    
    # Process significant strikes section if exists
    sig_strikes_section = per_round_sections.find { |s| s.text.include?("Significant Strikes") }
    if sig_strikes_section
      sig_table = sig_strikes_section.css("table.b-fight-details__table").first
      if sig_table
        add_strike_details_from_per_round_table(sig_table, rounds)
      end
    end
    
    rounds.sort_by { |r| r[:round] }
  end
  
  def parse_dual_stat_cell(text)
    # Parse cells like "0\n\n\n0" where first is fighter1, second is fighter2
    lines = text.split("\n").map(&:strip).reject(&:empty?)
    {
      fighter1: lines[0]&.to_i || 0,
      fighter2: lines[1]&.to_i || 0
    }
  end
  
  def parse_dual_of_stat_cell(text)
    # Parse cells like "11 of 23\n\n\n7 of 15"
    lines = text.split("\n").map(&:strip).reject(&:empty?)
    
    fighter1 = { landed: 0, attempted: 0 }
    fighter2 = { landed: 0, attempted: 0 }
    
    if lines[0] && lines[0].match(/(\d+)\s*of\s*(\d+)/)
      fighter1[:landed] = $1.to_i
      fighter1[:attempted] = $2.to_i
    end
    
    if lines[1] && lines[1].match(/(\d+)\s*of\s*(\d+)/)
      fighter2[:landed] = $1.to_i
      fighter2[:attempted] = $2.to_i
    end
    
    { fighter1: fighter1, fighter2: fighter2 }
  end
  
  def parse_dual_control_time_cell(text)
    # Parse cells like "1:09\n\n\n0:00"
    lines = text.split("\n").map(&:strip).reject(&:empty?)
    
    fighter1_time = 0
    fighter2_time = 0
    
    if lines[0] && lines[0].match(/(\d+):(\d+)/)
      fighter1_time = ($1.to_i * 60) + $2.to_i
    end
    
    if lines[1] && lines[1].match(/(\d+):(\d+)/)
      fighter2_time = ($1.to_i * 60) + $2.to_i
    end
    
    { fighter1: fighter1_time, fighter2: fighter2_time }
  end
  
  def add_strike_details_from_per_round_table(table, rounds)
    # Similar structure - each row is a round
    data_rows = table.css("tr").select { |tr| tr.css("td").any? }
    
    data_rows.each_with_index do |row, idx|
      round_num = idx + 1
      round_entry = rounds.find { |r| r[:round] == round_num }
      next unless round_entry
      
      cells = row.css("td")
      
      # Head strikes (index 3)
      if cells[3]
        head_data = parse_dual_of_stat_cell(cells[3].text)
        round_entry[:fighter1_stats][:head_strikes] = head_data[:fighter1][:landed]
        round_entry[:fighter1_stats][:head_strikes_attempted] = head_data[:fighter1][:attempted]
        round_entry[:fighter2_stats][:head_strikes] = head_data[:fighter2][:landed]
        round_entry[:fighter2_stats][:head_strikes_attempted] = head_data[:fighter2][:attempted]
      end
      
      # Body strikes (index 4)
      if cells[4]
        body_data = parse_dual_of_stat_cell(cells[4].text)
        round_entry[:fighter1_stats][:body_strikes] = body_data[:fighter1][:landed]
        round_entry[:fighter1_stats][:body_strikes_attempted] = body_data[:fighter1][:attempted]
        round_entry[:fighter2_stats][:body_strikes] = body_data[:fighter2][:landed]
        round_entry[:fighter2_stats][:body_strikes_attempted] = body_data[:fighter2][:attempted]
      end
      
      # Leg strikes (index 5)
      if cells[5]
        leg_data = parse_dual_of_stat_cell(cells[5].text)
        round_entry[:fighter1_stats][:leg_strikes] = leg_data[:fighter1][:landed]
        round_entry[:fighter1_stats][:leg_strikes_attempted] = leg_data[:fighter1][:attempted]
        round_entry[:fighter2_stats][:leg_strikes] = leg_data[:fighter2][:landed]
        round_entry[:fighter2_stats][:leg_strikes_attempted] = leg_data[:fighter2][:attempted]
      end
      
      # Distance strikes (index 6)
      if cells[6]
        distance_data = parse_dual_of_stat_cell(cells[6].text)
        round_entry[:fighter1_stats][:distance_strikes] = distance_data[:fighter1][:landed]
        round_entry[:fighter1_stats][:distance_strikes_attempted] = distance_data[:fighter1][:attempted]
        round_entry[:fighter2_stats][:distance_strikes] = distance_data[:fighter2][:landed]
        round_entry[:fighter2_stats][:distance_strikes_attempted] = distance_data[:fighter2][:attempted]
      end
      
      # Clinch strikes (index 7)
      if cells[7]
        clinch_data = parse_dual_of_stat_cell(cells[7].text)
        round_entry[:fighter1_stats][:clinch_strikes] = clinch_data[:fighter1][:landed]
        round_entry[:fighter1_stats][:clinch_strikes_attempted] = clinch_data[:fighter1][:attempted]
        round_entry[:fighter2_stats][:clinch_strikes] = clinch_data[:fighter2][:landed]
        round_entry[:fighter2_stats][:clinch_strikes_attempted] = clinch_data[:fighter2][:attempted]
      end
      
      # Ground strikes (index 8)
      if cells[8]
        ground_data = parse_dual_of_stat_cell(cells[8].text)
        round_entry[:fighter1_stats][:ground_strikes] = ground_data[:fighter1][:landed]
        round_entry[:fighter1_stats][:ground_strikes_attempted] = ground_data[:fighter1][:attempted]
        round_entry[:fighter2_stats][:ground_strikes] = ground_data[:fighter2][:landed]
        round_entry[:fighter2_stats][:ground_strikes_attempted] = ground_data[:fighter2][:attempted]
      end
    end
  end
  

  def parse_fighter_stats(cells, fighter_index)
    # Parse stats from table cells
    # Format: "X of Y / A of B" where first is fighter1, second is fighter2
    
    kd_text = cells[0] # "0 / 0"
    sig_str_text = cells[1] # "25 of 60 / 17 of 55"
    total_str_text = cells[3] # "145 of 208 / 23 of 63"
    td_text = cells[4] # "2 of 2 / 0 of 0"
    sub_text = cells[6] # "0 / 0"
    rev_text = cells[7] # "0 / 0"
    ctrl_text = cells[8] # "6:17 / 0:00"
    
    # Split by "/" to get fighter-specific data
    kd = parse_single_stat(kd_text, fighter_index)
    sig_str = parse_of_stat(sig_str_text, fighter_index)
    total_str = parse_of_stat(total_str_text, fighter_index)
    td = parse_of_stat(td_text, fighter_index)
    sub = parse_single_stat(sub_text, fighter_index)
    rev = parse_single_stat(rev_text, fighter_index)
    ctrl = parse_control_time(ctrl_text, fighter_index)
    
    {
      knockdowns: kd,
      significant_strikes: sig_str[:landed],
      significant_strikes_attempted: sig_str[:attempted],
      total_strikes: total_str[:landed],
      total_strikes_attempted: total_str[:attempted],
      takedowns: td[:landed],
      takedowns_attempted: td[:attempted],
      submission_attempts: sub,
      reversals: rev,
      control_time_seconds: ctrl
    }
  end

  def parse_single_stat(text, fighter_index)
    parts = text.split("/").map(&:strip)
    parts[fighter_index]&.to_i || 0
  end

  def parse_of_stat(text, fighter_index)
    parts = text.split("/").map(&:strip)
    fighter_stat = parts[fighter_index]
    
    if fighter_stat && fighter_stat.match(/(\d+)\s*of\s*(\d+)/)
      { landed: $1.to_i, attempted: $2.to_i }
    else
      { landed: 0, attempted: 0 }
    end
  end

  def parse_control_time(text, fighter_index)
    parts = text.split("/").map(&:strip)
    time_str = parts[fighter_index]
    
    if time_str && time_str.match(/(\d+):(\d+)/)
      minutes = $1.to_i
      seconds = $2.to_i
      (minutes * 60) + seconds
    else
      0
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

  def build_fight_stat_csv_row(event_data, fight, round_data, fighter_name, stats_key)
    stats = round_data[stats_key]
    
    {
      "EVENT" => event_data[:name],
      "BOUT" => determine_bout_type(fight),
      "ROUND" => round_data[:round],
      "FIGHTER" => fighter_name,
      "KD" => stats[:knockdowns],
      "SIG.STR." => "#{stats[:significant_strikes]} of #{stats[:significant_strikes_attempted]}",
      "SIG.STR. %" => calculate_percentage(stats[:significant_strikes], 
                                          stats[:significant_strikes_attempted]),
      "TOTAL STR." => "#{stats[:total_strikes]} of #{stats[:total_strikes_attempted]}",
      "TD" => "#{stats[:takedowns]} of #{stats[:takedowns_attempted]}",
      "TD %" => calculate_percentage(stats[:takedowns], stats[:takedowns_attempted]),
      "SUB.ATT" => stats[:submission_attempts],
      "REV." => stats[:reversals],
      "CTRL" => format_control_time(stats[:control_time_seconds]),
      "HEAD" => "#{stats[:head_strikes]} of #{stats[:head_strikes_attempted]}",
      "BODY" => "#{stats[:body_strikes]} of #{stats[:body_strikes_attempted]}",
      "LEG" => "#{stats[:leg_strikes]} of #{stats[:leg_strikes_attempted]}",
      "DISTANCE" => "#{stats[:distance_strikes]} of #{stats[:distance_strikes_attempted]}",
      "CLINCH" => "#{stats[:clinch_strikes]} of #{stats[:clinch_strikes_attempted]}",
      "GROUND" => "#{stats[:ground_strikes]} of #{stats[:ground_strikes_attempted]}"
    }
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