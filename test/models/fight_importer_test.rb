# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

class FightImporterTest < ActiveSupport::TestCase
  def setup
    @sample_csv_data = <<~CSV
      EVENT,BOUT,OUTCOME,WEIGHTCLASS,METHOD,ROUND,TIME,TIME FORMAT,REFEREE,DETAILS,URL
      UFC 315: Muhammad vs. Della Maddalena,"Belal Muhammad vs. Gilbert Burns","Belal Muhammad def. Gilbert Burns",Welterweight,Decision - Unanimous,3,5:00,3 Rnd (5-5-5),Herb Dean,"Fighter 1: 48-47, 48-47, 48-47",http://ufcstats.com/fight-details/abc123
      UFC 315: Muhammad vs. Della Maddalena,"Amanda Nunes vs. Valentina Shevchenko","Amanda Nunes def. Valentina Shevchenko",Women's Bantamweight,KO/TKO - Punches,2,3:45,5 Rnd (5-5-5-5-5),Marc Goddard,"Performance of the Night",http://ufcstats.com/fight-details/def456
      UFC 314: Volkanovski vs. Lopes,"Alexander Volkanovski vs. Diego Lopes","Alexander Volkanovski def. Diego Lopes",Featherweight,Submission - Rear Naked Choke,4,2:15,5 Rnd (5-5-5-5-5),Jason Herzog,"Fight of the Night",http://ufcstats.com/fight-details/ghi789
      Invalid Event Name,"Jon Jones vs. Stipe Miocic","Jon Jones def. Stipe Miocic",Heavyweight,Decision - Split,5,5:00,5 Rnd (5-5-5-5-5),Mike Beltran,"Fighter 1: 48-47, 47-48, 48-47",http://ufcstats.com/fight-details/jkl012
      UFC 313: Duplicate Event,"Conor McGregor vs. Dustin Poirier","No Contest",Lightweight,No Contest - Injury,1,2:30,3 Rnd (5-5-5),Dan Miragliotta,"Doctor Stoppage",http://ufcstats.com/fight-details/mno345
    CSV

    stub_request(:get, FightImporter::CSV_URL)
      .to_return(status: 200, body: @sample_csv_data, headers: {})

    # Create test events for association
    @event1 = Event.create!(
      name: "UFC 315: Muhammad vs. Della Maddalena",
      date: Date.parse("2025-05-10"),
      location: "Montreal, Quebec, Canada"
    )
    @event2 = Event.create!(
      name: "UFC 314: Volkanovski vs. Lopes",
      date: Date.parse("2025-04-12"),
      location: "Miami, Florida, USA"
    )
    @event3 = Event.create!(
      name: "UFC 313: Duplicate Event",
      date: Date.parse("2025-03-08"),
      location: "Las Vegas, Nevada, USA"
    )
  end

  def teardown
    WebMock.reset!
    Fight.destroy_all
    Event.destroy_all
  end

  test "import creates Fight records from CSV data" do
    importer = FightImporter.new

    initial_count = Fight.count
    result = importer.import

    assert_not_empty result
    assert Fight.count > initial_count

    # Check that Fight records were created with correct data
    fight = Fight.last
    assert_not_nil fight
  end

  test "import returns created Fight records" do
    importer = FightImporter.new

    result = importer.import

    assert_instance_of Array, result
    assert(result.all?(Fight))
    assert result.all?(&:persisted?)
  end

  test "import creates Fights with correct attributes from CSV" do
    importer = FightImporter.new

    Fight.destroy_all

    result = importer.import
    fight = result.first

    # Test that Fight has attributes from CSV
    assert_equal @event1, fight.event
    assert_equal "Belal Muhammad vs. Gilbert Burns", fight.bout
    assert_equal "Belal Muhammad def. Gilbert Burns", fight.outcome
    assert_equal "Welterweight", fight.weight_class
    assert_equal "Decision - Unanimous", fight.method
    assert_equal 3, fight.round
    assert_equal "5:00", fight.time
    assert_equal "3 Rnd (5-5-5)", fight.time_format
    assert_equal "Herb Dean", fight.referee
    assert_equal "Fighter 1: 48-47, 48-47, 48-47", fight.details
    assert fight.persisted?
  end

  test "import associates fights with correct events" do
    importer = FightImporter.new
    Fight.destroy_all

    importer.import

    # Check that fights are associated with the correct events
    event1_fights = @event1.fights
    assert_equal 2, event1_fights.count

    event2_fights = @event2.fights
    assert_equal 1, event2_fights.count

    event3_fights = @event3.fights
    assert_equal 1, event3_fights.count
  end

  test "import handles missing event gracefully" do
    importer = FightImporter.new
    Fight.destroy_all

    result = importer.import

    # Fight with invalid event name should not be created
    invalid_event_fight = Fight.joins(:event).where(
      events: { name: "Invalid Event Name" }
    ).first
    assert_nil invalid_event_fight

    # But other fights should be created
    assert_equal 4, result.count
  end

  test "import handles network errors appropriately" do
    stub_request(:get, FightImporter::CSV_URL)
      .to_raise(Faraday::Error.new("Network error"))

    importer = FightImporter.new

    assert_raises(FightImporter::ImportError) do
      importer.import
    end
  end

  test "import handles event names with whitespace" do
    # Create CSV with event names that have trailing/leading spaces
    csv_with_whitespace = <<~CSV
      EVENT,BOUT,OUTCOME,WEIGHTCLASS,METHOD,ROUND,TIME,TIME FORMAT,REFEREE,DETAILS,URL
      "UFC 315: Muhammad vs. Della Maddalena ","Test Fighter 1 vs. Test Fighter 2","Test Fighter 1 def. Test Fighter 2",Welterweight,Decision,3,5:00,3 Rnd (5-5-5),John Doe,"Test details",http://example.com/1
      " UFC 314: Volkanovski vs. Lopes","Test Fighter 3 vs. Test Fighter 4","Test Fighter 3 def. Test Fighter 4",Featherweight,KO/TKO,1,2:30,3 Rnd (5-5-5),Jane Doe,"Test details",http://example.com/2
      "  UFC 313: Duplicate Event  ","Test Fighter 5 vs. Test Fighter 6","Test Fighter 5 def. Test Fighter 6",Lightweight,Submission,2,3:45,3 Rnd (5-5-5),Mike Smith,"Test details",http://example.com/3
    CSV

    stub_request(:get, FightImporter::CSV_URL)
      .to_return(status: 200, body: csv_with_whitespace, headers: {})

    importer = FightImporter.new
    Fight.destroy_all

    result = importer.import

    # All fights should be imported despite whitespace in event names
    assert_equal 3, result.count
    assert_equal 3, Fight.count

    # Verify fights are associated with correct events
    assert_equal 1, @event1.fights.count
    assert_equal 1, @event2.fights.count
    assert_equal 1, @event3.fights.count
  end
end
