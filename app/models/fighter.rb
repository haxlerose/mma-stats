# frozen_string_literal: true

class Fighter < ApplicationRecord
  has_many :fight_stats, dependent: :destroy

  validates :name, presence: true
end
