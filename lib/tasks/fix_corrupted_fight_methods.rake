# frozen_string_literal: true

namespace :data do
  desc "Fix corrupted fight method data that contains HTML/JavaScript"
  task fix_corrupted_fight_methods: :environment do
    scraper = UfcStatsScraper.new
    corrupted_fights = Fight.where("method LIKE ?", "%GoogleAnalyticsObject%")
    
    puts "Found #{corrupted_fights.count} fights with corrupted method data"
    
    corrupted_fights.find_each.with_index do |fight, index|
      print "\rProcessing fight #{index + 1}/#{corrupted_fights.count}: " \
            "#{fight.bout} (Event: #{fight.event.name})"
      
      begin
        # Try to extract the actual method from the corrupted data
        if fight.method.include?("Method:")
          # Extract method from the corrupted HTML content
          match = fight.method.match(/Method:\s*([A-Za-z\s\-\/()]+?)(?:\s*Round:|$)/)
          if match
            clean_method = match[1].strip
            # Remove any remaining noise
            clean_method = clean_method.split(/\s{2,}/).first&.strip || clean_method
            
            if clean_method.present? && clean_method.length < 50
              fight.update!(method: clean_method)
              print " ✓ Fixed: #{clean_method}"
            else
              print " ⚠ Could not extract clean method"
            end
          else
            print " ⚠ No method pattern found"
          end
        else
          print " ⚠ No 'Method:' label found in corrupted data"
        end
      rescue StandardError => e
        print " ✗ Error: #{e.message}"
      end
    end
    
    puts "\n\nCompleted! Remaining corrupted fights: " \
         "#{Fight.where('method LIKE ?', '%GoogleAnalyticsObject%').count}"
    
    # Show some examples of what was fixed
    puts "\nExamples of fixed fights:"
    Fight.where("method NOT LIKE ?", "%GoogleAnalyticsObject%")
         .joins(:event)
         .order("fights.updated_at DESC")
         .limit(5)
         .each do |fight|
      puts "  - #{fight.bout}: #{fight.method} (#{fight.event.name})"
    end
  end
  
  desc "Re-scrape fights with corrupted method data"
  task rescrape_corrupted_fights: :environment do
    scraper = UfcStatsScraper.new
    corrupted_fights = Fight.where("method LIKE ?", "%GoogleAnalyticsObject%")
                            .includes(:event)
    
    puts "Found #{corrupted_fights.count} fights with corrupted method data"
    puts "This will attempt to re-scrape the fight details from UFC Stats"
    
    # Group by event for efficiency
    events_to_process = corrupted_fights.map(&:event).uniq
    
    events_to_process.each_with_index do |event, event_index|
      puts "\nProcessing event #{event_index + 1}/#{events_to_process.count}: " \
           "#{event.name}"
      
      begin
        # Find the event URL
        event_url = scraper.find_event_url(event.name)
        
        if event_url
          puts "  Found event URL: #{event_url}"
          
          # Scrape the event
          event_data = scraper.scrape_event(event_url)
          
          # Update each corrupted fight from this event
          event_fights = corrupted_fights.select { |f| f.event_id == event.id }
          
          event_fights.each do |fight|
            # Find matching fight in scraped data
            scraped_fight = event_data[:fights].find do |sf|
              bout = "#{sf[:fighter1]} vs. #{sf[:fighter2]}"
              bout == fight.bout || fight.bout.include?(sf[:fighter1]) && 
                                    fight.bout.include?(sf[:fighter2])
            end
            
            if scraped_fight
              # Update with clean data
              fight.update!(
                method: scraped_fight[:method],
                time_format: scraped_fight[:time_format],
                referee: scraped_fight[:referee],
                details: scraped_fight[:details]
              )
              puts "    ✓ Fixed: #{fight.bout} - Method: #{scraped_fight[:method]}"
            else
              puts "    ⚠ Could not find match for: #{fight.bout}"
            end
          end
        else
          puts "  ⚠ Could not find event URL"
        end
      rescue StandardError => e
        puts "  ✗ Error processing event: #{e.message}"
      end
    end
    
    puts "\n\nCompleted! Remaining corrupted fights: " \
         "#{Fight.where('method LIKE ?', '%GoogleAnalyticsObject%').count}"
  end
end