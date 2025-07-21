# frozen_string_literal: true

class Fight < ApplicationRecord
  belongs_to :event
  has_many :fight_stats, dependent: :destroy

  validates :bout, presence: true
  validates :outcome, presence: true
  validates :weight_class, presence: true

  scope :with_full_details, -> { includes(:event, fight_stats: :fighter) }

  # Cache invalidation callbacks
  after_create :clear_fighter_win_streak_cache
  after_update :clear_fighter_win_streak_cache
  after_destroy :clear_fighter_win_streak_cache

  def fighters
    if fight_stats.loaded?
      fight_stats.map(&:fighter).uniq
    else
      fight_stats.includes(:fighter).map(&:fighter).uniq
    end
  end

  private

  # Clear win streak cache when fights are modified
  def clear_fighter_win_streak_cache
    Rails.cache.delete_matched("fighter_top_win_streaks_*")
  end
end
