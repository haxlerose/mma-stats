# frozen_string_literal: true

namespace :ufc do
  desc "Scrape missing UFC events from ufcstats.com"
  task scrape_missing_events: :environment do
    scraper = UfcStatsScraper.new
    
    # Find events without fights
    events_without_fights = Event.left_joins(:fights)
                                 .where(fights: { id: nil })
                                 .order(:date)
    
    if events_without_fights.empty?
      puts "No events found without fights."
      exit
    end
    
    puts "Found #{events_without_fights.count} events without fights:"
    events_without_fights.each do |event|
      puts "  - #{event.name} (#{event.date})"
    end
    
    # Map event names to ufcstats.com URLs
    event_urls = {
      "UFC Fight Night: Holloway vs. The Korean Zombie" => 
        "http://ufcstats.com/event-details/b89a66b88db87eb1",
      "UFC 294: Makhachev vs. Volkanovski 2" => 
        "http://ufcstats.com/event-details/ad8de27b24fdb98f",
      "UFC 308: Topuria vs. Holloway" => 
        "http://ufcstats.com/event-details/ae18d2515ce4f8fc",
      "UFC Fight Night: Adesanya vs. Imavov" => 
        "http://ufcstats.com/event-details/80dbeb1dd5b53e64"
    }
    
    events_without_fights.each do |event|
      url = event_urls[event.name]
      
      unless url
        puts "\nNo URL mapping found for: #{event.name}"
        next
      end
      
      puts "\nScraping #{event.name}..."
      
      begin
        # Scrape the event
        csv_data = scraper.scrape_to_csv(url)
        
        # Write to supplemental CSV files
        write_fights_csv(csv_data[:fights])
        write_fight_stats_csv(csv_data[:fight_stats])
        
        puts "  ✓ Scraped #{csv_data[:fights].count} fights"
        puts "  ✓ Scraped #{csv_data[:fight_stats].count} fight stat records"
        
      rescue StandardError => e
        puts "  ✗ Error scraping #{event.name}: #{e.message}"
        puts "    #{e.backtrace.first(3).join("\n    ")}"
      end
    end
    
    puts "\nScraping complete! Run 'bin/rails db:seed' to import the scraped data."
  end
  
  desc "Scrape a specific UFC event by URL"
  task :scrape_event, [:url] => :environment do |_t, args|
    unless args[:url]
      puts "Usage: bin/rails ufc:scrape_event[URL]"
      puts "Example: bin/rails ufc:scrape_event[http://ufcstats.com/event-details/80dbeb1dd5b53e64]"
      exit
    end
    
    scraper = UfcStatsScraper.new
    
    begin
      puts "Scraping event from #{args[:url]}..."
      
      event_data = scraper.scrape_event(args[:url])
      puts "\nEvent: #{event_data[:name]}"
      puts "Date: #{event_data[:date]}"
      puts "Location: #{event_data[:location]}"
      puts "Fights: #{event_data[:fights].count}"
      
      csv_data = scraper.scrape_to_csv(args[:url])
      
      write_fights_csv(csv_data[:fights])
      write_fight_stats_csv(csv_data[:fight_stats])
      
      puts "\n✓ Data written to supplemental CSV files"
      puts "Run 'bin/rails db:seed' to import the data."
      
    rescue StandardError => e
      puts "Error: #{e.message}"
      puts e.backtrace.first(5).join("\n")
    end
  end
  
  private
  
  def write_fights_csv(fights_data)
    csv_path = Rails.root.join("db", "supplemental_data", "fights.csv")
    
    # Read existing data
    existing_data = []
    if File.exist?(csv_path)
      existing_data = CSV.read(csv_path, headers: true).map(&:to_h)
    end
    
    # Append new data
    CSV.open(csv_path, "w", headers: true) do |csv|
      headers = ["EVENT", "BOUT", "OUTCOME", "WEIGHTCLASS", "METHOD", 
                 "ROUND", "TIME", "TIME FORMAT", "REFEREE", "DETAILS", "URL"]
      csv << headers
      
      # Write existing data
      existing_data.each { |row| csv << row }
      
      # Write new data
      fights_data.each { |row| csv << row }
    end
  end
  
  def write_fight_stats_csv(stats_data)
    csv_path = Rails.root.join("db", "supplemental_data", "fight_stats.csv")
    
    # Read existing data
    existing_data = []
    if File.exist?(csv_path)
      existing_data = CSV.read(csv_path, headers: true).map(&:to_h)
    end
    
    # Append new data
    CSV.open(csv_path, "w", headers: true) do |csv|
      headers = ["EVENT", "BOUT", "ROUND", "FIGHTER", "KD", "SIG.STR.", 
                 "SIG.STR. %", "TOTAL STR.", "TD", "TD %", "SUB.ATT", 
                 "REV.", "CTRL", "HEAD", "BODY", "LEG", "DISTANCE", 
                 "CLINCH", "GROUND"]
      csv << headers
      
      # Write existing data
      existing_data.each { |row| csv << row }
      
      # Write new data
      stats_data.each { |row| csv << row }
    end
  end
end