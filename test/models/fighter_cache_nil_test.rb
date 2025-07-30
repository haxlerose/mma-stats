# frozen_string_literal: true

require "test_helper"

class FighterCacheNilTest < ActiveSupport::TestCase
  def setup
    @original_cache = Rails.cache
    Rails.cache = nil
  end

  def teardown
    Rails.cache = @original_cache
  end

  test "top_win_streaks does not raise error when cache is nil" do
    assert_nothing_raised do
      result = Fighter.top_win_streaks(limit: 3)
      assert_equal [], result
    end
  end

  test "statistical_highlights does not raise error when cache is nil" do
    assert_nothing_raised do
      result = Fighter.statistical_highlights
      assert_instance_of Array, result
      assert_equal 4, result.length
    end
  end
end
