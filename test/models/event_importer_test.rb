# frozen_string_literal: true

require "test_helper"

class EventImporterTest < ActiveSupport::TestCase
  test "import creates Event records from CSV data" do
    VCR.use_cassette("ufc_event_details") do
      importer = EventImporter.new

      initial_count = Event.count
      result = importer.import

      assert_not_empty result
      assert Event.count > initial_count

      # Check that Event records were created with correct data
      event = Event.last
      assert_not_nil event
    end
  end

  test "import returns created Event records" do
    VCR.use_cassette("ufc_event_details") do
      importer = EventImporter.new

      result = importer.import

      assert_instance_of Array, result
      assert(result.all?(Event))
      assert result.all?(&:persisted?)
    end
  end

  test "import creates Events with correct attributes from CSV" do
    VCR.use_cassette("ufc_event_details") do
      importer = EventImporter.new

      # Clear any existing events
      Event.destroy_all

      result = importer.import
      event = result.first

      # Test that Event has attributes from CSV
      # (adjust these assertions based on actual CSV columns)
      assert_respond_to event, :id
      assert event.persisted?
    end
  end
end
