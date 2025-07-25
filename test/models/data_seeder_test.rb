# frozen_string_literal: true

require "test_helper"

class DataSeederTest < ActiveSupport::TestCase
  def setup
    # Clear all data before each test
    FightStat.destroy_all
    Fight.destroy_all
    Fighter.destroy_all
    Event.destroy_all
  end

  test "imports all data in the correct order" do
    # Stub all HTTP requests to return empty CSV
    stub_request(:get, EventImporter::CSV_URL)
      .to_return(status: 200, body: "EVENT,DATE,LOCATION\n", headers: {})
    stub_request(:get, FighterImporter::CSV_URL)
      .to_return(status: 200, body: "FIGHTER,HEIGHT,WEIGHT,REACH,STANCE,DOB\n", headers: {})
    stub_request(:get, FightImporter::CSV_URL)
      .to_return(status: 200, body: "EVENT,BOUT,OUTCOME,WEIGHTCLASS,METHOD,ROUND,TIME,TIME_FORMAT,REFEREE,DETAILS\n", headers: {})
    stub_request(:get, FightStatImporter::CSV_URL)
      .to_return(status: 200, body: "EVENT,BOUT,ROUND,FIGHTER,KD,SIG_STR,SIG_STR_ATTEMPT\n", headers: {})

    # Track which importers were called
    import_calls = []

    # Override the new method for each importer class
    original_event_new = EventImporter.method(:new)
    original_fighter_new = FighterImporter.method(:new)
    original_fight_new = FightImporter.method(:new)
    original_fight_stat_new = FightStatImporter.method(:new)

    EventImporter.define_singleton_method(:new) do
      mock = Object.new
      mock.define_singleton_method(:import) { import_calls << :events; [] }
      mock
    end

    FighterImporter.define_singleton_method(:new) do
      mock = Object.new
      mock.define_singleton_method(:import) { import_calls << :fighters; [] }
      mock
    end

    FightImporter.define_singleton_method(:new) do
      mock = Object.new
      mock.define_singleton_method(:import) { import_calls << :fights; [] }
      mock
    end

    FightStatImporter.define_singleton_method(:new) do
      mock = Object.new
      mock.define_singleton_method(:import) { import_calls << :fight_stats; [] }
      mock
    end

    DataSeeder.import_all

    assert_equal %i[events fighters fights fight_stats], import_calls

    # Restore original methods
    EventImporter.define_singleton_method(:new, original_event_new)
    FighterImporter.define_singleton_method(:new, original_fighter_new)
    FightImporter.define_singleton_method(:new, original_fight_new)
    FightStatImporter.define_singleton_method(:new, original_fight_stat_new)
  end

  test "returns import statistics" do
    # Stub all HTTP requests to return empty CSV
    stub_request(:get, EventImporter::CSV_URL)
      .to_return(status: 200, body: "EVENT,DATE,LOCATION\n", headers: {})
    stub_request(:get, FighterImporter::CSV_URL)
      .to_return(status: 200, body: "FIGHTER,HEIGHT,WEIGHT,REACH,STANCE,DOB\n", headers: {})
    stub_request(:get, FightImporter::CSV_URL)
      .to_return(status: 200, body: "EVENT,BOUT,OUTCOME,WEIGHTCLASS,METHOD,ROUND,TIME,TIME_FORMAT,REFEREE,DETAILS\n", headers: {})
    stub_request(:get, FightStatImporter::CSV_URL)
      .to_return(status: 200, body: "EVENT,BOUT,ROUND,FIGHTER,KD,SIG_STR,SIG_STR_ATTEMPT\n", headers: {})

    # Create test data to verify counts
    Event.create!(name: "UFC 1", date: Time.zone.today, location: "Denver, CO")
    Fighter.create!(name: "Fighter One")

    # Mock importers to not actually import
    original_event_new = EventImporter.method(:new)
    original_fighter_new = FighterImporter.method(:new)
    original_fight_new = FightImporter.method(:new)
    original_fight_stat_new = FightStatImporter.method(:new)

    EventImporter.define_singleton_method(:new) do
      mock = Object.new
      mock.define_singleton_method(:import) { [] }
      mock
    end

    FighterImporter.define_singleton_method(:new) do
      mock = Object.new
      mock.define_singleton_method(:import) { [] }
      mock
    end

    FightImporter.define_singleton_method(:new) do
      mock = Object.new
      mock.define_singleton_method(:import) { [] }
      mock
    end

    FightStatImporter.define_singleton_method(:new) do
      mock = Object.new
      mock.define_singleton_method(:import) { [] }
      mock
    end

    stats = DataSeeder.import_all

    assert_equal 1, stats[:events_count]
    assert_equal 1, stats[:fighters_count]
    assert_equal 0, stats[:fights_count]
    assert_equal 0, stats[:fight_stats_count]

    # Restore original methods
    EventImporter.define_singleton_method(:new, original_event_new)
    FighterImporter.define_singleton_method(:new, original_fighter_new)
    FightImporter.define_singleton_method(:new, original_fight_new)
    FightStatImporter.define_singleton_method(:new, original_fight_stat_new)
  end

  test "handles import errors gracefully" do
    # Stub all HTTP requests to return empty CSV
    stub_request(:get, EventImporter::CSV_URL)
      .to_return(status: 200, body: "EVENT,DATE,LOCATION\n", headers: {})
    stub_request(:get, FighterImporter::CSV_URL)
      .to_return(status: 200, body: "FIGHTER,HEIGHT,WEIGHT,REACH,STANCE,DOB\n", headers: {})
    stub_request(:get, FightImporter::CSV_URL)
      .to_return(status: 200, body: "EVENT,BOUT,OUTCOME,WEIGHTCLASS,METHOD,ROUND,TIME,TIME_FORMAT,REFEREE,DETAILS\n", headers: {})
    stub_request(:get, FightStatImporter::CSV_URL)
      .to_return(status: 200, body: "EVENT,BOUT,ROUND,FIGHTER,KD,SIG_STR,SIG_STR_ATTEMPT\n", headers: {})

    # Simulate an error in one of the importers
    original_event_new = EventImporter.method(:new)

    EventImporter.define_singleton_method(:new) do
      mock = Object.new
      mock.define_singleton_method(:import) do
        raise StandardError, "Import failed"
      end
      mock
    end

    assert_raises(StandardError) do
      DataSeeder.import_all
    end

    # Restore original method
    EventImporter.define_singleton_method(:new, original_event_new)
  end

  test "provides detailed import report" do
    # Stub all HTTP requests to return empty CSV
    stub_request(:get, EventImporter::CSV_URL)
      .to_return(status: 200, body: "EVENT,DATE,LOCATION\n", headers: {})
    stub_request(:get, FighterImporter::CSV_URL)
      .to_return(status: 200, body: "FIGHTER,HEIGHT,WEIGHT,REACH,STANCE,DOB\n", headers: {})
    stub_request(:get, FightImporter::CSV_URL)
      .to_return(status: 200, body: "EVENT,BOUT,OUTCOME,WEIGHTCLASS,METHOD,ROUND,TIME,TIME_FORMAT,REFEREE,DETAILS\n", headers: {})
    stub_request(:get, FightStatImporter::CSV_URL)
      .to_return(status: 200, body: "EVENT,BOUT,ROUND,FIGHTER,KD,SIG_STR,SIG_STR_ATTEMPT\n", headers: {})

    # Mock all importers
    original_event_new = EventImporter.method(:new)
    original_fighter_new = FighterImporter.method(:new)
    original_fight_new = FightImporter.method(:new)
    original_fight_stat_new = FightStatImporter.method(:new)

    EventImporter.define_singleton_method(:new) do
      mock = Object.new
      mock.define_singleton_method(:import) { [] }
      mock
    end

    FighterImporter.define_singleton_method(:new) do
      mock = Object.new
      mock.define_singleton_method(:import) { [] }
      mock
    end

    FightImporter.define_singleton_method(:new) do
      mock = Object.new
      mock.define_singleton_method(:import) { [] }
      mock
    end

    FightStatImporter.define_singleton_method(:new) do
      mock = Object.new
      mock.define_singleton_method(:import) { [] }
      mock
    end

    report = DataSeeder.import_with_report

    assert_not_nil report
    assert_kind_of Hash, report
    assert_kind_of Time, report[:started_at]
    assert_kind_of Time, report[:completed_at]
    assert_kind_of Float, report[:duration]
    assert_equal :success, report[:status]
    assert_kind_of Hash, report[:statistics]
    assert_includes report[:statistics], :events_count
    assert_includes report[:statistics], :fighters_count
    assert_includes report[:statistics], :fights_count
    assert_includes report[:statistics], :fight_stats_count

    # Restore original methods
    EventImporter.define_singleton_method(:new, original_event_new)
    FighterImporter.define_singleton_method(:new, original_fighter_new)
    FightImporter.define_singleton_method(:new, original_fight_new)
    FightStatImporter.define_singleton_method(:new, original_fight_stat_new)
  end

  test "raises error when import fails" do
    # Stub all HTTP requests to return empty CSV
    stub_request(:get, EventImporter::CSV_URL)
      .to_return(status: 200, body: "EVENT,DATE,LOCATION\n", headers: {})
    stub_request(:get, FighterImporter::CSV_URL)
      .to_return(status: 200, body: "FIGHTER,HEIGHT,WEIGHT,REACH,STANCE,DOB\n", headers: {})
    stub_request(:get, FightImporter::CSV_URL)
      .to_return(status: 200, body: "EVENT,BOUT,OUTCOME,WEIGHTCLASS,METHOD,ROUND,TIME,TIME_FORMAT,REFEREE,DETAILS\n", headers: {})
    stub_request(:get, FightStatImporter::CSV_URL)
      .to_return(status: 200, body: "EVENT,BOUT,ROUND,FIGHTER,KD,SIG_STR,SIG_STR_ATTEMPT\n", headers: {})

    # Mock EventImporter to fail
    original_event_new = EventImporter.method(:new)

    EventImporter.define_singleton_method(:new) do
      mock = Object.new
      mock.define_singleton_method(:import) do
        raise StandardError, "CSV download failed"
      end
      mock
    end

    # Verify the error is raised
    error = assert_raises(StandardError) do
      DataSeeder.import_with_report
    end

    assert_equal "CSV download failed", error.message

    # Restore original method
    EventImporter.define_singleton_method(:new, original_event_new)
  end
end
