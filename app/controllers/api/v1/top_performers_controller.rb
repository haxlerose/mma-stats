# frozen_string_literal: true

class Api::V1::TopPerformersController < ApplicationController
  VALID_SCOPES = %w[career fight round per_minute accuracy].freeze

  SCOPE_TO_QUERY_CLASS = {
    "career" => CareerTotalsQuery,
    "fight" => FightMaximumsQuery,
    "round" => RoundMaximumsQuery,
    "per_minute" => PerMinuteQuery,
    "accuracy" => TopPerformers::AccuracyQuery
  }.freeze

  def index
    validate_parameters!
    results = fetch_top_performers
    render json: build_response(results)
  rescue ArgumentError => e
    render json: { error: e.message }, status: :bad_request
  end

  private

  def validate_parameters!
    raise ArgumentError, "scope parameter is required" if params[:scope].blank?

    if params[:category].blank?
      raise ArgumentError, "category parameter is required"
    end

    unless VALID_SCOPES.include?(params[:scope])
      raise ArgumentError,
            "Invalid scope: #{params[:scope]}. " \
            "Valid scopes are: #{VALID_SCOPES.join(', ')}"
    end
  end

  def fetch_top_performers
    cache_key = build_cache_key
    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      query_class = SCOPE_TO_QUERY_CLASS[params[:scope]]
      query = create_query(query_class, params[:category])
      query.call
    end
  end

  def build_cache_key
    # Cache key based on scope, category, and last updated timestamp
    last_updated = [
      FightStat.maximum(:updated_at),
      Fighter.maximum(:updated_at),
      Fight.maximum(:updated_at),
      Event.maximum(:updated_at)
    ].compact.max

    "top_performers/#{params[:scope]}/#{params[:category]}/" \
      "#{last_updated&.to_i}"
  end

  def build_response(results)
    if accuracy_results_with_threshold?(results)
      build_accuracy_response_with_threshold(results)
    else
      build_standard_response(results)
    end
  end

  def accuracy_results_with_threshold?(results)
    params[:scope] == "accuracy" && results.is_a?(Hash)
  end

  def build_accuracy_response_with_threshold(results)
    {
      top_performers: format_results(
        results[:fighters],
        params[:scope],
        params[:category]
      ),
      meta: base_meta.merge(
        minimum_attempts_threshold: results[:minimum_attempts_threshold]
      )
    }
  end

  def build_standard_response(results)
    {
      top_performers: format_results(
        results,
        params[:scope],
        params[:category]
      ),
      meta: base_meta
    }
  end

  def base_meta
    {
      scope: params[:scope],
      category: params[:category]
    }
  end

  def create_query(query_class, category)
    case query_class.name
    when "CareerTotalsQuery", "PerMinuteQuery"
      query_class.new(category: category.to_sym)
    when "TopPerformers::AccuracyQuery"
      # AccuracyQuery now accepts different accuracy categories
      valid_accuracy_categories = %w[
        significant_strike_accuracy
        total_strike_accuracy
        head_strike_accuracy
        body_strike_accuracy
        leg_strike_accuracy
        distance_strike_accuracy
        clinch_strike_accuracy
        ground_strike_accuracy
        takedown_accuracy
      ]

      unless valid_accuracy_categories.include?(category)
        raise ArgumentError,
              "Invalid category for accuracy scope. " \
              "Valid categories are: #{valid_accuracy_categories.join(', ')}"
      end

      apply_threshold = params[:apply_threshold] != "false"
      query_class.new(category: category, apply_threshold: apply_threshold)
    else
      # FightMaximumsQuery and RoundMaximumsQuery
      # take the statistic as first arg
      query_class.new(category.to_s)
    end
  end

  def format_results(results, scope, category)
    formatter = ResultFormatter.new(scope, category)
    results.map { |result| formatter.format(result) }
  end

  # Encapsulates result formatting logic
  class ResultFormatter
    def initialize(scope, category)
      @scope = scope
      @category = category
    end

    def format(result)
      send("format_#{@scope}", result)
    end

    private

    def format_career(result)
      result
    end

    def format_accuracy(result)
      # Extract the stat type from the category name and ensure it's pluralized
      stat_type = @category.gsub("_accuracy", "")
      pluralized_stat = pluralize_stat_type(stat_type)

      # The AccuracyQuery now returns dynamic keys based on the stat type
      landed_key = :"total_#{pluralized_stat}"
      attempted_key = :"total_#{pluralized_stat}_attempted"

      base_format(result).merge(
        accuracy_percentage: result[:accuracy_percentage],
        "total_#{pluralized_stat}" => result[landed_key],
        "total_#{pluralized_stat}_attempted" => result[attempted_key],
        total_fights: result[:total_fights],
        fight_id: nil
      )
    end

    def pluralize_stat_type(stat_type)
      # Map singular stat types to their plural forms
      stat_pluralization = {
        "total_strike" => "total_strikes",
        "significant_strike" => "significant_strikes",
        "head_strike" => "head_strikes",
        "body_strike" => "body_strikes",
        "leg_strike" => "leg_strikes",
        "distance_strike" => "distance_strikes",
        "clinch_strike" => "clinch_strikes",
        "ground_strike" => "ground_strikes",
        "takedown" => "takedowns"
      }

      stat_pluralization[stat_type] || stat_type
    end

    def format_fight(result)
      base_format(result).merge(
        "max_#{@category}" => result[:value],
        event_name: result[:event_name],
        opponent_name: result[:opponent_name]
      )
    end

    def format_round(result)
      format_fight(result).merge(round: result[:round])
    end

    def format_per_minute(result)
      base_format(result).merge(
        "#{@category}_per_15_minutes" => result[:rate_per_15_minutes],
        fight_id: nil,
        fight_duration_minutes: minutes_from_seconds(
          result[:total_time_seconds]
        ),
        "total_#{@category}" => result[:total_statistic]
      )
    end

    def base_format(result)
      {
        fighter_id: result[:fighter_id],
        fighter_name: result[:fighter_name],
        fight_id: result[:fight_id]
      }
    end

    def minutes_from_seconds(seconds)
      (seconds / 60.0).round(2)
    end
  end
end
