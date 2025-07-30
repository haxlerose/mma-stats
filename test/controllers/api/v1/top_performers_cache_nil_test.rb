# frozen_string_literal: true

require "test_helper"

class Api::V1::TopPerformersCacheNilTest < ActionDispatch::IntegrationTest
  def setup
    @original_cache = Rails.cache
    Rails.cache = nil
  end

  def teardown
    Rails.cache = @original_cache
  end

  test "GET /api/v1/top_performers does not raise error when cache is nil" do
    assert_nothing_raised do
      get api_v1_top_performers_path,
          params: { scope: "career", category: "knockdowns" }
      assert_response :success
    end
  end
end
