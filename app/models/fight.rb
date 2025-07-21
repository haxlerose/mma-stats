# frozen_string_literal: true

class Fight < ApplicationRecord
  belongs_to :event
  has_many :fight_stats, dependent: :destroy

  validates :bout, presence: true
  validates :outcome, presence: true
  validates :weight_class, presence: true

  scope :with_full_details, -> { includes(:event, fight_stats: :fighter) }

  def fighters
    fight_stats.map(&:fighter).uniq
  end
end
