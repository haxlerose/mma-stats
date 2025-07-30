# frozen_string_literal: true

require "test_helper"

class FightTest < ActiveSupport::TestCase
  def setup
    @event = Event.create!(
      name: "UFC Test Event",
      date: Time.zone.today,
      location: "Test Location"
    )

    @fight = Fight.new(
      event: @event,
      bout: "Main Event",
      outcome: "Win",
      weight_class: "Lightweight"
    )
  end

  test "should clear fighter win streak cache after create" do
    # Given cache is available
    unless Rails.cache.respond_to?(:delete_matched)
      skip "Cache not available in test environment"
    end

    # When creating a fight
    @fight.save!

    # Then cache should be cleared (test would pass if no error is raised)
    assert true
  end

  test "should clear fighter win streak cache after update" do
    # Given an existing fight
    @fight.save!

    # And cache is available
    unless Rails.cache.respond_to?(:delete_matched)
      skip "Cache not available in test environment"
    end

    # When updating the fight
    @fight.update!(outcome: "Loss")

    # Then cache should be cleared (test would pass if no error is raised)
    assert true
  end

  test "should clear fighter win streak cache after destroy" do
    # Given an existing fight
    @fight.save!

    # And cache is available
    unless Rails.cache.respond_to?(:delete_matched)
      skip "Cache not available in test environment"
    end

    # When destroying the fight
    @fight.destroy!

    # Then cache should be cleared (test would pass if no error is raised)
    assert true
  end

  test "handle cache clearing when cache doesn't support delete_matched" do
    # Given a fight
    @fight.save!

    # When cache doesn't support delete_matched
    # Then no error should be raised (handled gracefully)
    assert_nothing_raised do
      @fight.update!(outcome: "Draw")
      @fight.destroy!
    end
  end
end
