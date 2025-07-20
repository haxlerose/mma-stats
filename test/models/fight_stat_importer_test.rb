# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

class FightStatImporterTest < ActiveSupport::TestCase
  def setup
    @sample_csv_data = <<~CSV
      EVENT,BOUT,ROUND,FIGHTER,KD,SIG.STR.,SIG.STR. %,TOTAL STR.,TD,TD %,SUB.ATT,REV.,CTRL,HEAD,BODY,LEG,DISTANCE,CLINCH,GROUND
      UFC 315: Muhammad vs. Della Maddalena,Belal Muhammad vs. Gilbert Burns,Round 1,Belal Muhammad,1,26 of 64,40%,26 of 64,0 of 0,---,0,0,0:08,9 of 39,11 of 16,6 of 9,23 of 57,0 of 0,3 of 7
      UFC 315: Muhammad vs. Della Maddalena,Belal Muhammad vs. Gilbert Burns,Round 2,Belal Muhammad,0,44 of 67,65%,47 of 70,0 of 0,---,0,0,1:24,31 of 52,11 of 12,2 of 3,31 of 51,0 of 0,13 of 16
      UFC 315: Muhammad vs. Della Maddalena,Belal Muhammad vs. Gilbert Burns,Round 1,Gilbert Burns,0,15 of 42,35%,15 of 42,2 of 3,66%,1,1,2:15,8 of 25,4 of 10,3 of 7,12 of 35,1 of 2,2 of 5
      UFC 314: Volkanovski vs. Lopes,Alexander Volkanovski vs. Diego Lopes,Round 3,Alexander Volkanovski,2,18 of 35,51%,20 of 37,1 of 2,50%,0,0,0:45,10 of 20,5 of 8,3 of 7,15 of 30,2 of 3,1 of 2
      Invalid Event Name,Jon Jones vs. Stipe Miocic,Round 1,Jon Jones,0,12 of 25,48%,14 of 27,3 of 4,75%,0,1,3:30,7 of 15,3 of 6,2 of 4,10 of 20,1 of 2,1 of 3
    CSV

    stub_request(:get, FightStatImporter::CSV_URL)
      .to_return(status: 200, body: @sample_csv_data, headers: {})

    # Create test events
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

    # Create test fights
    @fight1 = Fight.create!(
      event: @event1,
      bout: "Belal Muhammad vs. Gilbert Burns",
      outcome: "Belal Muhammad def. Gilbert Burns",
      weight_class: "Welterweight",
      method: "Decision - Unanimous",
      round: 3
    )
    @fight2 = Fight.create!(
      event: @event2,
      bout: "Alexander Volkanovski vs. Diego Lopes",
      outcome: "Alexander Volkanovski def. Diego Lopes",
      weight_class: "Featherweight",
      method: "Submission - Rear Naked Choke",
      round: 4
    )

    # Create test fighters
    @fighter1 = Fighter.create!(name: "Belal Muhammad")
    @fighter2 = Fighter.create!(name: "Gilbert Burns")
    @fighter3 = Fighter.create!(name: "Alexander Volkanovski")
    @fighter4 = Fighter.create!(name: "Diego Lopes")
  end

  def teardown
    WebMock.reset!
    FightStat.destroy_all
    Fight.destroy_all
    Fighter.destroy_all
    Event.destroy_all
  end

  test "import creates FightStat records from CSV data" do
    importer = FightStatImporter.new

    initial_count = FightStat.count
    result = importer.import

    assert_not_empty result
    assert FightStat.count > initial_count

    # Check that FightStat records were created with correct data
    stat = FightStat.last
    assert_not_nil stat
  end

  test "import returns created FightStat records" do
    importer = FightStatImporter.new

    result = importer.import

    assert_instance_of Array, result
    assert(result.all?(FightStat))
    assert result.all?(&:persisted?)
  end

  test "import creates FightStats with correct attributes from CSV" do
    importer = FightStatImporter.new
    FightStat.destroy_all

    result = importer.import
    stat = result.first

    # Test that FightStat has attributes from CSV
    assert_equal @fight1, stat.fight
    assert_equal @fighter1, stat.fighter
    assert_equal 1, stat.round
    assert_equal 1, stat.knockdowns
    assert_equal 26, stat.significant_strikes
    assert_equal 64, stat.significant_strikes_attempted
    assert_equal 26, stat.total_strikes
    assert_equal 64, stat.total_strikes_attempted
    assert_equal 0, stat.takedowns
    assert_equal 0, stat.takedowns_attempted
    assert_equal 0, stat.submission_attempts
    assert_equal 0, stat.reversals
    assert_equal 8, stat.control_time_seconds # 0:08 = 8 seconds
    assert_equal 9, stat.head_strikes
    assert_equal 39, stat.head_strikes_attempted
    assert_equal 11, stat.body_strikes
    assert_equal 16, stat.body_strikes_attempted
    assert_equal 6, stat.leg_strikes
    assert_equal 9, stat.leg_strikes_attempted
    assert_equal 23, stat.distance_strikes
    assert_equal 57, stat.distance_strikes_attempted
    assert_equal 0, stat.clinch_strikes
    assert_equal 0, stat.clinch_strikes_attempted
    assert_equal 3, stat.ground_strikes
    assert_equal 7, stat.ground_strikes_attempted
    assert stat.persisted?
  end

  test "import parses 'X of Y' format correctly" do
    importer = FightStatImporter.new
    FightStat.destroy_all

    result = importer.import

    # Find a stat with takedowns
    burns_stat = result.find { |s| s.fighter == @fighter2 && s.round == 1 }
    assert_not_nil burns_stat
    assert_equal 2, burns_stat.takedowns
    assert_equal 3, burns_stat.takedowns_attempted
  end

  test "import handles control time format MM:SS correctly" do
    importer = FightStatImporter.new
    FightStat.destroy_all

    result = importer.import

    # Check different control times
    stat_8_seconds = result.find { |s| s.fighter == @fighter1 && s.round == 1 }
    assert_equal 8, stat_8_seconds.control_time_seconds # 0:08

    stat_84_seconds = result.find { |s| s.fighter == @fighter1 && s.round == 2 }
    assert_equal 84, stat_84_seconds.control_time_seconds # 1:24

    stat_135_seconds = result.find do |s|
      s.fighter == @fighter2 && s.round == 1
    end
    assert_equal 135, stat_135_seconds.control_time_seconds # 2:15
  end

  test "import handles missing data gracefully" do
    importer = FightStatImporter.new
    FightStat.destroy_all

    result = importer.import

    # Should create stats even with missing takedown percentage (---)
    assert_equal 4, result.count
    assert_equal 4, FightStat.count
  end

  test "import associates stats with correct fights and fighters" do
    importer = FightStatImporter.new
    FightStat.destroy_all

    importer.import

    # Check fight associations
    fight1_stats = @fight1.fight_stats
    assert_equal 3, fight1_stats.count # 2 rounds for Muhammad, 1 for Burns

    fight2_stats = @fight2.fight_stats
    assert_equal 1, fight2_stats.count # 1 round for Volkanovski

    # Check fighter associations
    muhammad_stats = @fighter1.fight_stats
    assert_equal 2, muhammad_stats.count # 2 rounds

    burns_stats = @fighter2.fight_stats
    assert_equal 1, burns_stats.count # 1 round
  end

  test "import handles missing fight or fighter gracefully" do
    importer = FightStatImporter.new
    FightStat.destroy_all

    result = importer.import

    # Should skip stat with invalid event/fight
    assert_equal 4, result.count # Should not include Jon Jones stat
  end

  test "import handles network errors appropriately" do
    stub_request(:get, FightStatImporter::CSV_URL)
      .to_raise(Faraday::Error.new("Network error"))

    importer = FightStatImporter.new

    assert_raises(FightStatImporter::ImportError) do
      importer.import
    end
  end

  test "import handles bout names with whitespace" do
    # Create CSV with bout names that have trailing/leading spaces
    csv_with_whitespace = <<~CSV
      EVENT,BOUT,ROUND,FIGHTER,KD,SIG.STR.,SIG.STR. %,TOTAL STR.,TD,TD %,SUB.ATT,REV.,CTRL,HEAD,BODY,LEG,DISTANCE,CLINCH,GROUND
      UFC 315: Muhammad vs. Della Maddalena," Belal Muhammad vs. Gilbert Burns ",Round 1,Belal Muhammad,1,26 of 64,40%,26 of 64,0 of 0,---,0,0,0:08,9 of 39,11 of 16,6 of 9,23 of 57,0 of 0,3 of 7
    CSV

    stub_request(:get, FightStatImporter::CSV_URL)
      .to_return(status: 200, body: csv_with_whitespace, headers: {})

    importer = FightStatImporter.new
    FightStat.destroy_all

    result = importer.import

    # Should match fight despite whitespace in bout name
    assert_equal 1, result.count
    assert_equal 1, FightStat.count
    assert_equal @fight1, result.first.fight
  end

  test "import handles bout names with multiple spaces" do
    # Create CSV with bout names that have multiple spaces
    csv_with_multiple_spaces = <<~CSV
      EVENT,BOUT,ROUND,FIGHTER,KD,SIG.STR.,SIG.STR. %,TOTAL STR.,TD,TD %,SUB.ATT,REV.,CTRL,HEAD,BODY,LEG,DISTANCE,CLINCH,GROUND
      UFC 315: Muhammad vs. Della Maddalena,"Belal  Muhammad   vs.    Gilbert  Burns",Round 1,Belal Muhammad,1,26 of 64,40%,26 of 64,0 of 0,---,0,0,0:08,9 of 39,11 of 16,6 of 9,23 of 57,0 of 0,3 of 7
    CSV

    stub_request(:get, FightStatImporter::CSV_URL)
      .to_return(status: 200, body: csv_with_multiple_spaces, headers: {})

    importer = FightStatImporter.new
    FightStat.destroy_all

    result = importer.import

    # Should match fight despite multiple spaces in bout name
    assert_equal 1, result.count
    assert_equal 1, FightStat.count
    assert_equal @fight1, result.first.fight
  end
end
