# frozen_string_literal: true

class Fighter < ApplicationRecord
  validates :name, presence: true
end
