# frozen_string_literal: true

class FightStat < ApplicationRecord
  belongs_to :fight
  belongs_to :fighter

  validates :round, presence: true

  # Cache invalidation callbacks
  after_create :clear_fighter_win_streak_cache
  after_update :clear_fighter_win_streak_cache
  after_destroy :clear_fighter_win_streak_cache

  private

  # Clear win streak cache when fight stats are modified
  def clear_fighter_win_streak_cache
    Rails.cache.delete_matched("fighter_top_win_streaks_*")
  end
end
