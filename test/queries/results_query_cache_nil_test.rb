# frozen_string_literal: true

require "test_helper"

class ResultsQueryCacheNilTest < ActiveSupport::TestCase
  def setup
    @original_cache = Rails.cache
    Rails.cache = nil
  end

  def teardown
    Rails.cache = @original_cache
  end

  test "#call for longest_win_streak does not raise error when cache is nil" do
    query = ResultsQuery.new(category: :longest_win_streak)

    assert_nothing_raised do
      result = query.call
      assert_instance_of Array, result
    end
  end
end
