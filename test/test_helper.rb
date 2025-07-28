# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "vcr"
require "webmock/minitest"

VCR.configure do |config|
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :webmock
  config.ignore_localhost = true
  config.default_cassette_options = {
    record: :new_episodes,
    match_requests_on: %i[method uri]
  }
  # Allow real HTTP connections when no cassette is being used
  config.allow_http_connections_when_no_cassette = true
end

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
    # Disabled automatic fixture loading to allow tests to create their own data
    # fixtures :all

    # Add more helper methods to be used by all tests here...

    # Ensure fight_durations materialized view exists for tests
    def ensure_fight_durations_view_exists
      # Check if the view exists
      result = ActiveRecord::Base.connection.execute(<<~SQL.squish)
        SELECT EXISTS (
          SELECT 1
          FROM pg_matviews
          WHERE schemaname = 'public' AND matviewname = 'fight_durations'
        )
      SQL

      unless result.first["exists"]
        # Create the materialized view if it doesn't exist
        ActiveRecord::Base.connection.execute(<<~SQL.squish)
          CREATE MATERIALIZED VIEW fight_durations AS
          SELECT DISTINCT
            f.id AS fight_id,
            f.round AS ending_round,
            f.time AS ending_time,
            CASE
              WHEN f.time ~ '^[0-9]+:[0-9]+$' THEN
                ((f.round - 1) * 300) +
                (CAST(SPLIT_PART(f.time, ':', 1) AS INTEGER) * 60 +
                 CAST(SPLIT_PART(f.time, ':', 2) AS INTEGER))
              ELSE
                f.round * 300
            END AS duration_seconds
          FROM fights f;

          CREATE UNIQUE INDEX idx_fight_durations_fight_id
            ON fight_durations (fight_id);
        SQL
      end
    end
  end
end
