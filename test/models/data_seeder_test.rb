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
    # Track which importers were called
    import_calls = []

    # Mock each importer
    EventImporter.define_singleton_method(:import) { import_calls << :events }
    FighterImporter.define_singleton_method(:import) do
      import_calls << :fighters
    end
    FightImporter.define_singleton_method(:import) { import_calls << :fights }
    FightStatImporter.define_singleton_method(:import) do
      import_calls << :fight_stats
    end

    DataSeeder.import_all

    assert_equal %i[events fighters fights fight_stats], import_calls

    # Clean up singleton methods
    EventImporter.singleton_class.remove_method(:import)
    FighterImporter.singleton_class.remove_method(:import)
    FightImporter.singleton_class.remove_method(:import)
    FightStatImporter.singleton_class.remove_method(:import)
  end

  test "returns import statistics" do
    # Create test data to verify counts
    Event.create!(name: "UFC 1", date: Time.zone.today, location: "Denver, CO")
    Fighter.create!(name: "Fighter One")

    # Mock importers to not actually import
    EventImporter.define_singleton_method(:import) { nil }
    FighterImporter.define_singleton_method(:import) { nil }
    FightImporter.define_singleton_method(:import) { nil }
    FightStatImporter.define_singleton_method(:import) { nil }

    stats = DataSeeder.import_all

    assert_equal 1, stats[:events_count]
    assert_equal 1, stats[:fighters_count]
    assert_equal 0, stats[:fights_count]
    assert_equal 0, stats[:fight_stats_count]

    # Clean up
    EventImporter.singleton_class.remove_method(:import)
    FighterImporter.singleton_class.remove_method(:import)
    FightImporter.singleton_class.remove_method(:import)
    FightStatImporter.singleton_class.remove_method(:import)
  end

  test "handles import errors gracefully" do
    # Simulate an error in one of the importers
    EventImporter.define_singleton_method(:import) do
      raise StandardError, "Import failed"
    end

    assert_raises(StandardError) do
      DataSeeder.import_all
    end

    # Clean up
    EventImporter.singleton_class.remove_method(:import)
  end

  test "provides detailed import report" do
    # Mock all importers
    EventImporter.define_singleton_method(:import) { nil }
    FighterImporter.define_singleton_method(:import) { nil }
    FightImporter.define_singleton_method(:import) { nil }
    FightStatImporter.define_singleton_method(:import) { nil }

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

    # Clean up
    EventImporter.singleton_class.remove_method(:import)
    FighterImporter.singleton_class.remove_method(:import)
    FightImporter.singleton_class.remove_method(:import)
    FightStatImporter.singleton_class.remove_method(:import)
  end

  test "raises error when import fails" do
    # Mock EventImporter to fail
    EventImporter.define_singleton_method(:import) do
      raise StandardError, "CSV download failed"
    end

    # Mock other importers
    FighterImporter.define_singleton_method(:import) { nil }
    FightImporter.define_singleton_method(:import) { nil }
    FightStatImporter.define_singleton_method(:import) { nil }

    # Verify the error is raised
    error = assert_raises(StandardError) do
      DataSeeder.import_with_report
    end

    assert_equal "CSV download failed", error.message

    # Clean up
    EventImporter.singleton_class.remove_method(:import)
    FighterImporter.singleton_class.remove_method(:import)
    FightImporter.singleton_class.remove_method(:import)
    FightStatImporter.singleton_class.remove_method(:import)
  end
end
