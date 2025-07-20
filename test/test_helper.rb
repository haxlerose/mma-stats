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
  config.allow_http_connections_when_no_cassette = false
end

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
