# frozen_string_literal: true

class FightStat < ApplicationRecord
  belongs_to :fight
  belongs_to :fighter

  validates :round, presence: true
end
