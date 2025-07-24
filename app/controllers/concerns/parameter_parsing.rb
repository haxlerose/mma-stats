# frozen_string_literal: true

module ParameterParsing
  extend ActiveSupport::Concern

  private

  def parse_pagination_params
    {
      page: parse_page_param,
      per_page: parse_per_page_param
    }
  end

  def parse_page_param
    params[:page].present? ? [params[:page].to_i, 1].max : 1
  end

  def parse_per_page_param(default: 20, max: 100)
    per_page_param = params[:per_page].to_i
    per_page_param.positive? ? [per_page_param, max].min : default
  end

  def parse_sort_direction(default: "desc")
    if %w[asc desc].include?(params[:sort_direction]&.downcase)
      params[:sort_direction].downcase
    else
      default
    end
  end
end
