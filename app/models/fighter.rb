# frozen_string_literal: true

class Fighter < ApplicationRecord
  has_many :fight_stats, dependent: :destroy
  has_many :fights, through: :fight_stats

  validates :name, presence: true

  scope :alphabetical, -> { order(Arel.sql("LOWER(name)")) }
  scope :search,
        lambda { |query|
          return all if query.blank?

          where("name ILIKE ?", "%#{sanitize_sql_like(query)}%")
        }
  scope :with_fight_details, -> { includes(fight_stats: { fight: :event }) }
end
