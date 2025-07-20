# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

class EventImporterTest < ActiveSupport::TestCase
  def setup
    @sample_csv_data = <<~CSV
      EVENT,URL,DATE,LOCATION
      UFC 315: Muhammad vs. Della Maddalena,http://ufcstats.com/event-details/118463dd8db16e7f,"May 10, 2025","Montreal, Quebec, Canada"
      UFC Fight Night: Burns vs. Morales,http://ufcstats.com/event-details/8ad022dd81224f61,"May 17, 2025","Las Vegas, Nevada, USA"
      UFC 314: Volkanovski vs. Lopes,http://ufcstats.com/event-details/22f4b6cb6b1bd7fd,"April 12, 2025","Miami, Florida, USA"
      UFC Fight Night: Invalid Date Event,http://ufcstats.com/event-details/invalid,"Invalid Date","Las Vegas, Nevada, USA"
      UFC 313: Duplicate Event,http://ufcstats.com/event-details/duplicate,"March 08, 2025","Las Vegas, Nevada, USA"
    CSV

    stub_request(:get, EventImporter::CSV_URL)
      .to_return(status: 200, body: @sample_csv_data, headers: {})
  end

  def teardown
    WebMock.reset!
  end

  test "import creates Event records from CSV data" do
    importer = EventImporter.new

    initial_count = Event.count
    result = importer.import

    assert_not_empty result
    assert Event.count > initial_count

    # Check that Event records were created with correct data
    event = Event.last
    assert_not_nil event
  end

  test "import returns created Event records" do
    importer = EventImporter.new

    result = importer.import

    assert_instance_of Array, result
    assert(result.all?(Event))
    assert result.all?(&:persisted?)
  end

  test "import creates Events with correct attributes from CSV" do
    importer = EventImporter.new

    # Clear any existing events
    Event.destroy_all

    result = importer.import
    event = result.first

    # Test that Event has attributes from CSV
    assert_equal "UFC 315: Muhammad vs. Della Maddalena", event.name
    assert_equal Date.parse("May 10, 2025"), event.date
    assert_equal "Montreal, Quebec, Canada", event.location
    assert event.persisted?
  end

  test "import handles duplicate events gracefully" do
    importer = EventImporter.new
    Event.destroy_all

    # Create a duplicate event first
    Event.create!(
      name: "UFC 313: Duplicate Event",
      date: Date.parse("March 08, 2025"),
      location: "Las Vegas, Nevada, USA"
    )

    initial_count = Event.count
    result = importer.import

    # Should not create duplicate, and invalid date event won't be created
    assert_equal initial_count + 3, Event.count
    assert_equal 4, result.count # 3 new + 1 existing
  end

  test "import handles invalid dates gracefully" do
    importer = EventImporter.new
    Event.destroy_all

    result = importer.import

    # Should not create event with invalid date
    invalid_date_event = Event.find_by(
      name: "UFC Fight Night: Invalid Date Event"
    )
    assert_nil invalid_date_event

    # But should create the other valid events
    assert_equal 4, result.count
    assert_equal 4, Event.count
  end

  test "import handles network errors appropriately" do
    stub_request(:get, EventImporter::CSV_URL)
      .to_raise(Faraday::Error.new("Network error"))

    importer = EventImporter.new

    assert_raises(EventImporter::ImportError) do
      importer.import
    end
  end
end
