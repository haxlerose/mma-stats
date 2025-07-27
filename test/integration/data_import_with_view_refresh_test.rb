# frozen_string_literal: true

require "test_helper"

class DataImportWithViewRefreshTest < ActiveSupport::TestCase
  def setup
    # Clear all data before test
    FightStat.destroy_all
    Fight.destroy_all
    Fighter.destroy_all
    Event.destroy_all
  end

  test "data import completes successfully with view refresh" do
    # Create some test data that will be imported
    event_csv = <<~CSV
      EVENT,DATE,LOCATION
      "UFC Test Event","2024-01-01","Las Vegas, NV"
    CSV

    fighter_csv = <<~CSV
      FIGHTER,HEIGHT,WEIGHT,REACH,STANCE,DOB
      "Test Fighter",72,170,74,Orthodox,1990-01-01
    CSV

    fight_csv = <<~CSV
      EVENT,BOUT,OUTCOME,WEIGHTCLASS,METHOD,ROUND,TIME,TIME_FORMAT,REFEREE,DETAILS
      "UFC Test Event","Test Fighter vs. Another Fighter",W/L,Welterweight,KO/TKO,1,2:30,3 Rnd (5-5-5),John Doe,Punches
    CSV

    # Stub HTTP requests
    stub_request(:get, EventImporter::CSV_URL)
      .to_return(status: 200, body: event_csv, headers: {})
    stub_request(:get, FighterImporter::CSV_URL)
      .to_return(status: 200, body: fighter_csv, headers: {})
    stub_request(:get, FightImporter::CSV_URL)
      .to_return(status: 200, body: fight_csv, headers: {})
    stub_request(:get, FightStatImporter::CSV_URL)
      .to_return(
        status: 200,
        body: "EVENT,BOUT,ROUND,FIGHTER,KD,SIG_STR,SIG_STR_ATTEMPT\n",
        headers: {}
      )

    # Import data - this should complete without errors
    # even if materialized view doesn't exist
    result = DataSeeder.import_all

    # Verify data was imported
    assert_equal 1, Event.count
    assert_equal 1, Fighter.count
    assert_equal 1, Fight.count

    # Verify result contains the counts
    assert_equal 1, result[:events_count]
    assert_equal 1, result[:fighters_count]
    assert_equal 1, result[:fights_count]
  end
end
