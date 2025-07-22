# frozen_string_literal: true

class Event < ApplicationRecord
  has_many :fights, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :date, presence: true
  validates :location, presence: true

  # Scopes for filtering and sorting
  scope :by_location,
        lambda { |location|
          return all if location.blank?

          where(location: location)
        }
  scope :chronological, -> { order(:date) }
  scope :reverse_chronological, -> { order(date: :desc) }

  # Instance methods
  def fight_count
    fights.count
  end

  def main_event
    fights.first&.bout
  end
end
