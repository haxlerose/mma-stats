# frozen_string_literal: true

class Event < ApplicationRecord
  has_many :fights, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :date, presence: true
  validates :location, presence: true
end
