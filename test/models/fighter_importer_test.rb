# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

class FighterImporterTest < ActiveSupport::TestCase
  def setup
    @sample_csv_data = <<~CSV
      FIGHTER,HEIGHT,WEIGHT,REACH,STANCE,DOB,URL
      Jon Jones,"6' 4""",248,"84""",Orthodox,"Jul 19, 1987",http://ufcstats.com/fighter-details/jon-jones
      Amanda Nunes,"5' 8""",145,"69""",Orthodox,"May 30, 1988",http://ufcstats.com/fighter-details/amanda-nunes
      Conor McGregor,"5' 9""",170,"74""",Southpaw,"Jul 14, 1988",http://ufcstats.com/fighter-details/conor-mcgregor
      Fighter No Height,,,"72""",Orthodox,"Jan 01, 1990",http://ufcstats.com/fighter-details/no-height
      Fighter Invalid Data,invalid,200,invalid,Orthodox,Invalid Date,http://ufcstats.com/fighter-details/invalid
      Duplicate Fighter,"5' 10""",185,"70""",Orthodox,"Mar 15, 1985",http://ufcstats.com/fighter-details/duplicate
    CSV

    stub_request(:get, FighterImporter::CSV_URL)
      .to_return(status: 200, body: @sample_csv_data, headers: {})
  end

  def teardown
    WebMock.reset!
  end

  test "import creates Fighter records from CSV data" do
    importer = FighterImporter.new

    initial_count = Fighter.count
    result = importer.import

    assert_not_empty result
    assert Fighter.count > initial_count

    # Check that Fighter records were created with correct data
    fighter = Fighter.last
    assert_not_nil fighter
  end

  test "import returns created Fighter records" do
    importer = FighterImporter.new

    result = importer.import

    assert_instance_of Array, result
    assert(result.all?(Fighter))
    assert result.all?(&:persisted?)
  end

  test "import creates Fighters with correct attributes from CSV" do
    importer = FighterImporter.new

    # Clear any existing fighters
    Fighter.destroy_all

    result = importer.import
    fighter = result.first

    # Test that Fighter has attributes from CSV
    assert_equal "Jon Jones", fighter.name
    assert_equal 76, fighter.height_in_inches # 6'4" = 76 inches
    assert_equal 84, fighter.reach_in_inches
    assert_equal Date.parse("Jul 19, 1987"), fighter.birth_date
    assert fighter.persisted?
  end

  test "import converts height from feet-inches format to inches" do
    importer = FighterImporter.new
    Fighter.destroy_all

    importer.import

    # Test various height conversions
    jon_jones = Fighter.find_by(name: "Jon Jones")
    assert_equal 76, jon_jones.height_in_inches # 6'4" = 76

    amanda_nunes = Fighter.find_by(name: "Amanda Nunes")
    assert_equal 68, amanda_nunes.height_in_inches # 5'8" = 68

    conor_mcgregor = Fighter.find_by(name: "Conor McGregor")
    assert_equal 69, conor_mcgregor.height_in_inches # 5'9" = 69
  end

  test "import handles missing or invalid data gracefully" do
    importer = FighterImporter.new
    Fighter.destroy_all

    # Should not raise errors even with missing data
    assert_nothing_raised do
      importer.import

      # Fighter with no height should still be created
      no_height = Fighter.find_by(name: "Fighter No Height")
      assert_not_nil no_height
      assert_nil no_height.height_in_inches
      assert_equal 72, no_height.reach_in_inches

      # Fighter with invalid data should still be created
      invalid = Fighter.find_by(name: "Fighter Invalid Data")
      assert_not_nil invalid
      assert_nil invalid.height_in_inches
      assert_nil invalid.reach_in_inches
      assert_nil invalid.birth_date
    end
  end

  test "import handles duplicate fighters gracefully" do
    importer = FighterImporter.new
    Fighter.destroy_all

    # Create a duplicate fighter first
    Fighter.create!(
      name: "Duplicate Fighter",
      height_in_inches: 70,
      reach_in_inches: 70,
      birth_date: Date.parse("1985-03-15")
    )

    initial_count = Fighter.count
    result = importer.import

    # Should not create duplicate
    assert_equal initial_count + 5, Fighter.count
    assert_equal 6, result.count
  end

  test "import handles network errors appropriately" do
    stub_request(:get, FighterImporter::CSV_URL)
      .to_raise(Faraday::Error.new("Network error"))

    importer = FighterImporter.new

    assert_raises(FighterImporter::ImportError) do
      importer.import
    end
  end

  test "import normalizes fighter names with multiple spaces" do
    # Create CSV with fighter names that have multiple spaces
    csv_with_multiple_spaces = <<~CSV
      FIGHTER,HEIGHT,WEIGHT,REACH,STANCE,DOB,URL
      Test   Fighter    One,"5' 10""",170,"72""",Orthodox,Jan 15 1990,http://example.com
    CSV

    stub_request(:get, FighterImporter::CSV_URL)
      .to_return(status: 200, body: csv_with_multiple_spaces, headers: {})

    importer = FighterImporter.new
    Fighter.destroy_all

    result = importer.import

    # Should normalize fighter name when creating fighter
    assert_equal 1, result.count
    fighter = result.first
    assert_equal "Test Fighter One", fighter.name
  end
end
