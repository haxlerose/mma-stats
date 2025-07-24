# frozen_string_literal: true

# Seeds the database with UFC data from CSV files and any missing data
# This file is idempotent - it can be run multiple times safely

puts "Starting database seeding..."
start_time = Time.current

# Import all data from CSV files in the correct order
puts "\n=== Importing data from CSV files ==="
begin
  report = DataSeeder.import_with_report

  puts "Import completed in #{report[:duration].round(2)} seconds"
  puts "Statistics:"
  puts "  - Events: #{report[:statistics][:events_count]}"
  puts "  - Fighters: #{report[:statistics][:fighters_count]}"
  puts "  - Fights: #{report[:statistics][:fights_count]}"
  puts "  - Fight Stats: #{report[:statistics][:fight_stats_count]}"
rescue StandardError => e
  puts "ERROR: Data import failed - #{e.message}"
  puts e.backtrace.first(5).join("\n")
  exit 1
end

# Scrape missing fight data from ufcstats.com
puts "\n=== Scraping missing fight data from ufcstats.com ==="

# Find events without fights
events_without_fights = Event.left_joins(:fights)
                             .where(fights: { id: nil })
                             .order(:date)

if events_without_fights.any?
  puts "Found #{events_without_fights.count} events without fights:"
  events_without_fights.each do |event|
    puts "  - #{event.name} (#{event.date})"
  end

  scraper = UfcStatsScraper.new

  # Get the list of all completed events from ufcstats.com
  puts "\nFetching completed events list from ufcstats.com..."
  begin
    all_ufc_events = scraper.scrape_completed_events_list
    puts "Found #{all_ufc_events.count} total events on ufcstats.com"

    # Process each event without fights
    events_without_fights.each do |event|
      puts "\n--- Processing: #{event.name} ---"

      # Find the URL for this event
      event_url = scraper.find_event_url(event.name, all_ufc_events)

      unless event_url
        puts "  ✗ Could not find URL for event: #{event.name}"
        next
      end

      puts "  ✓ Found event URL: #{event_url}"

      begin
        # Scrape the event data
        puts "  Scraping event data..."
        event_data = scraper.scrape_event(event_url)

        # Import the fights
        puts "  Importing #{event_data[:fights].count} fights..."

        event_data[:fights].each_with_index do |fight_data, index|
          puts "    Processing fight #{index + 1}: #{fight_data[:fighter1]} vs #{fight_data[:fighter2]}"

          # Create the fight
          fight = Fight.find_or_initialize_by(
            event: event,
            bout: "#{fight_data[:fighter1]} vs. #{fight_data[:fighter2]}"
          )

          # Determine outcome - W/L means first fighter won, L/W means second fighter won
          outcome = if fight_data[:winner] == fight_data[:fighter1]
                      "W/L"
                    elsif fight_data[:winner] == fight_data[:fighter2]
                      "L/W"
                    else
                      "Draw" # or "No Contest"
                    end

          fight.assign_attributes(
            outcome: outcome,
            weight_class: fight_data[:weight_class] || "Unknown",
            method: fight_data[:method],
            round: fight_data[:round],
            time: fight_data[:time],
            referee: fight_data[:referee] || "",
            time_format: fight_data[:time_format] || "",
            details: fight_data[:details] || ""
          )

          if fight.save
            puts "      ✓ Fight saved"

            # Now scrape detailed fight statistics
            begin
              fight_details = scraper.scrape_fight_details(fight_data[:fight_url])

              if fight_details[:rounds] && fight_details[:rounds].any?
                puts "      Importing statistics for #{fight_details[:rounds].count} rounds..."

                fight_details[:rounds].each do |round_data|
                  # Fighter 1 stats
                  fighter1 = Fighter.find_by(name: fight_details[:fighter1])
                  if fighter1
                    stat1 = FightStat.find_or_initialize_by(
                      fight: fight,
                      fighter: fighter1,
                      round: round_data[:round]
                    )
                    stat1.update!(round_data[:fighter1_stats])
                  end

                  # Fighter 2 stats
                  fighter2 = Fighter.find_by(name: fight_details[:fighter2])
                  if fighter2
                    stat2 = FightStat.find_or_initialize_by(
                      fight: fight,
                      fighter: fighter2,
                      round: round_data[:round]
                    )
                    stat2.update!(round_data[:fighter2_stats])
                  end
                end

                puts "      ✓ Statistics imported"
              else
                puts "      ⚠ No round statistics found"
              end
            rescue StandardError => e
              puts "      ✗ Error scraping fight details: #{e.message}"
            end
          else
            puts "      ✗ Failed to save fight: #{fight.errors.full_messages.join(', ')}"
          end
        end

      rescue StandardError => e
        puts "  ✗ Error scraping event: #{e.message}"
        puts e.backtrace.first(3).join("\n")
      end
    end

  rescue StandardError => e
    puts "Failed to fetch events list: #{e.message}"
    puts e.backtrace.first(3).join("\n")
  end
else
  puts "All events have fights - no scraping needed!"
end

# Final statistics
puts "\n=== Final Database Statistics ==="
puts "Events: #{Event.count}"
puts "Fighters: #{Fighter.count}"
puts "Fights: #{Fight.count}"
puts "Fight Stats: #{FightStat.count}"

# Check for any remaining issues
events_still_without_fights = Event.left_joins(:fights)
                                   .where(fights: { id: nil })
                                   .count

if events_still_without_fights.positive?
  puts "\nWARNING: Still have #{events_still_without_fights} events without fights"
end

total_time = Time.current - start_time
puts "\n=== Seeding completed in #{total_time.round(2)} seconds ==="
puts "Database is ready!"

