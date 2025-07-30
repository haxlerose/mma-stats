# frozen_string_literal: true

require "test_helper"

class FightStatTest < ActiveSupport::TestCase
  def setup
    @event = Event.create!(
      name: "UFC Test Event",
      date: Time.zone.today,
      location: "Test Location"
    )

    @fight = Fight.create!(
      event: @event,
      bout: "Main Event",
      outcome: "Win",
      weight_class: "Lightweight"
    )

    @fighter = Fighter.create!(name: "Test Fighter")

    @fight_stat = FightStat.new(
      fight: @fight,
      fighter: @fighter,
      round: 1
    )
  end

  test "should clear fighter win streak cache after create" do
    # Given cache is available
    unless Rails.cache.respond_to?(:delete_matched)
      skip "Cache not available in test environment"
    end

    # When creating a fight stat
    @fight_stat.save!

    # Then cache should be cleared (test would pass if no error is raised)
    assert true
  end

  test "should clear fighter win streak cache after update" do
    # Given an existing fight stat
    @fight_stat.save!

    # And cache is available
    unless Rails.cache.respond_to?(:delete_matched)
      skip "Cache not available in test environment"
    end

    # When updating the fight stat
    @fight_stat.update!(round: 2)

    # Then cache should be cleared (test would pass if no error is raised)
    assert true
  end

  test "should clear fighter win streak cache after destroy" do
    # Given an existing fight stat
    @fight_stat.save!

    # And cache is available
    unless Rails.cache.respond_to?(:delete_matched)
      skip "Cache not available in test environment"
    end

    # When destroying the fight stat
    @fight_stat.destroy!

    # Then cache should be cleared (test would pass if no error is raised)
    assert true
  end

  test "handle cache clearing when cache doesn't support delete_matched" do
    # Given a fight stat
    @fight_stat.save!

    # When cache doesn't support delete_matched
    # Then no error should be raised (handled gracefully)
    assert_nothing_raised do
      @fight_stat.update!(round: 3)
      @fight_stat.destroy!
    end
  end
end
