# frozen_string_literal: true

module Api
  module V1
    class StatisticalHighlightsController < ApplicationController
      def index
        highlights = Fighter.statistical_highlights

        render json: { highlights: highlights }
      end
    end
  end
end
