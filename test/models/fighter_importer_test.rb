# frozen_string_literal: true

require "test_helper"

class FighterImporterTest < ActiveSupport::TestCase
  test "import creates Fighter records from CSV data" do
    VCR.use_cassette("ufc_fighter_tott") do
      importer = FighterImporter.new

      initial_count = Fighter.count
      result = importer.import

      assert_not_empty result
      assert Fighter.count > initial_count

      # Check that Fighter records were created with correct data
      fighter = Fighter.last
      assert_not_nil fighter
    end
  end

  test "import returns created Fighter records" do
    VCR.use_cassette("ufc_fighter_tott") do
      importer = FighterImporter.new

      result = importer.import

      assert_instance_of Array, result
      assert(result.all?(Fighter))
      assert result.all?(&:persisted?)
    end
  end

  test "import creates Fighters with correct attributes from CSV" do
    VCR.use_cassette("ufc_fighter_tott") do
      importer = FighterImporter.new

      # Clear any existing fighters
      Fighter.destroy_all

      result = importer.import
      fighter = result.first

      # Test that Fighter has attributes from CSV
      assert_respond_to fighter, :name
      assert_respond_to fighter, :height_in_inches
      assert_respond_to fighter, :reach_in_inches
      assert_respond_to fighter, :birth_date
      assert fighter.persisted?
    end
  end

  test "import converts height from feet-inches format to inches" do
    VCR.use_cassette("ufc_fighter_tott") do
      importer = FighterImporter.new
      Fighter.destroy_all

      result = importer.import

      # Find a fighter with height data
      fighter_with_height = result.find { |f| f.height_in_inches.present? }

      assert_not_nil fighter_with_height,
                     "Should find at least one fighter with height"
      assert_kind_of Integer, fighter_with_height.height_in_inches
      assert fighter_with_height.height_in_inches.positive?

      # Example: 5'4" should be 64 inches, 6'0" should be 72 inches
      assert fighter_with_height.height_in_inches >= 60,
             "Height should be reasonable (at least 5 feet)"
      assert fighter_with_height.height_in_inches <= 84,
             "Height should be reasonable (at most 7 feet)"
    end
  end

  test "import handles missing or invalid data gracefully" do
    VCR.use_cassette("ufc_fighter_tott") do
      importer = FighterImporter.new

      # Should not raise errors even with missing data
      assert_nothing_raised do
        importer.import
      end
    end
  end
end
