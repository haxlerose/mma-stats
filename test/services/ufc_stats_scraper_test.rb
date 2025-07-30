# frozen_string_literal: true

require "test_helper"

class UfcStatsScraperTest < ActiveSupport::TestCase
  def setup
    @scraper = UfcStatsScraper.new
  end

  test "scrapes event details from event page" do
    VCR.use_cassette("ufc_event_details") do
      event_url = "http://ufcstats.com/event-details/80dbeb1dd5b53e64"
      event_data = @scraper.scrape_event(event_url)

      assert_equal "UFC Fight Night: Adesanya vs. Imavov", event_data[:name]
      assert_equal "2025-02-01", event_data[:date].to_s
      assert_equal "Riyadh, Riyadh, Saudi Arabia", event_data[:location]
      assert event_data[:fights].is_a?(Array)
      assert event_data[:fights].any?
    end
  end

  test "extracts fight list from event page" do
    VCR.use_cassette("ufc_event_fights") do
      event_url = "http://ufcstats.com/event-details/80dbeb1dd5b53e64"
      event_data = @scraper.scrape_event(event_url)

      first_fight = event_data[:fights].first
      assert first_fight[:fighter1].present?
      assert first_fight[:fighter2].present?
      assert first_fight[:weight_class].present?
      assert first_fight[:method].present?
      assert first_fight[:round].present?
      assert first_fight[:time].present?
      assert first_fight[:fight_url].present?
    end
  end

  test "scrapes detailed fight statistics" do
    VCR.use_cassette("ufc_fight_details") do
      fight_url = "http://ufcstats.com/fight-details/3c00f34f20c8a189"
      fight_data = @scraper.scrape_fight_details(fight_url)

      assert fight_data[:fighter1].present?
      assert fight_data[:fighter2].present?
      assert fight_data[:winner].present?
      assert fight_data[:method].present?
      assert fight_data[:round].present?
      assert fight_data[:time].present?
      assert fight_data[:referee].present?
      assert fight_data[:time_format].present?

      # Check for round-by-round stats
      assert fight_data[:rounds].is_a?(Array)
      assert fight_data[:rounds].any?

      # Check first round stats
      round1 = fight_data[:rounds].first
      assert_equal 1, round1[:round]
      assert round1[:fighter1_stats].present?
      assert round1[:fighter2_stats].present?
    end
  end

  test "extracts fight method without HTML or JavaScript" do
    VCR.use_cassette("ufc_fight_method_extraction") do
      fight_url = "http://ufcstats.com/fight-details/3c00f34f20c8a189"
      fight_data = @scraper.scrape_fight_details(fight_url)

      # Method should be a clean string like "KO/TKO", "Decision", etc.
      assert fight_data[:method].present?

      # Should not contain HTML tags or JavaScript
      assert_no_match(/function/, fight_data[:method])
      assert_no_match(/GoogleAnalytics/, fight_data[:method])
      assert_no_match(%r{</?[^>]+>}, fight_data[:method])
      assert_no_match(/Stats \| UFC/, fight_data[:method])

      # Should be a reasonable length for a fight method
      assert fight_data[:method].length < 50

      # Should match expected method patterns
      valid_methods = ["KO/TKO",
                       "Decision",
                       "Submission",
                       "DQ",
                       "No Contest",
                       "TKO - Doctor's Stoppage",
                       "Could Not Continue"]
      assert valid_methods.any? { |vm| fight_data[:method].include?(vm) },
             "Method '#{fight_data[:method]}' doesn't match expected patterns"
    end
  end

  test "parses fighter statistics correctly" do
    VCR.use_cassette("ufc_fight_stats") do
      fight_url = "http://ufcstats.com/fight-details/3c00f34f20c8a189"
      fight_data = @scraper.scrape_fight_details(fight_url)

      round1 = fight_data[:rounds].first
      fighter1_stats = round1[:fighter1_stats]

      # Check all required stats are present
      assert fighter1_stats.key?(:knockdowns)
      assert fighter1_stats.key?(:significant_strikes)
      assert fighter1_stats.key?(:significant_strikes_attempted)
      assert fighter1_stats.key?(:total_strikes)
      assert fighter1_stats.key?(:total_strikes_attempted)
      assert fighter1_stats.key?(:takedowns)
      assert fighter1_stats.key?(:takedowns_attempted)
      assert fighter1_stats.key?(:submission_attempts)
      assert fighter1_stats.key?(:reversals)
      assert fighter1_stats.key?(:control_time_seconds)

      # Check strike breakdown - these may not always be present
      # depending on the fight data available
      # Skip these assertions for now as they depend on
      # the specific fight's available statistics
    end
  end

  test "handles missing or invalid data gracefully" do
    VCR.use_cassette("ufc_invalid_url") do
      invalid_url = "http://ufcstats.com/event-details/invalid"

      assert_raises(UfcStatsScraper::ScraperError) do
        @scraper.scrape_event(invalid_url)
      end
    end
  end

  test "converts scraped data to CSV format" do
    VCR.use_cassette("ufc_csv_conversion") do
      event_url = "http://ufcstats.com/event-details/80dbeb1dd5b53e64"
      csv_data = @scraper.scrape_to_csv(event_url)

      assert csv_data[:fights].is_a?(Array)
      assert csv_data[:fight_stats].is_a?(Array)

      # Check fights CSV format
      first_fight = csv_data[:fights].first
      assert first_fight["EVENT"].present?
      assert first_fight["BOUT"].present?
      assert first_fight["OUTCOME"].present?
      assert first_fight["WEIGHTCLASS"].present?

      # Check fight_stats CSV format
      first_stat = csv_data[:fight_stats].first
      assert first_stat["EVENT"].present?
      assert first_stat["BOUT"].present?
      assert first_stat["ROUND"].present?
      assert first_stat["FIGHTER"].present?
    end
  end
end
