# frozen_string_literal: true

# Query object for aggregating fighter win/loss statistics
class ResultsQuery
  TOP_PERFORMERS_LIMIT = 10
  MINIMUM_FIGHTS_FOR_PERCENTAGE = 10

  VALID_CATEGORIES = %i[
    total_wins
    total_losses
    win_percentage
    longest_win_streak
  ].freeze

  def initialize(category: :total_wins)
    validate_category!(category)
    @category = category
  end

  def call
    case @category
    when :total_wins
      top_winners
    when :total_losses
      top_losers
    when :win_percentage
      top_win_percentages
    when :longest_win_streak
      top_win_streaks
    end
  end

  private

  def build_fighter_stats_query
    Fighter
      .joins(fight_stats: :fight)
      .where(fights: { outcome: ["W/L", "L/W"] })
      .group("fighters.id", "fighters.name")
      .select(
        "fighters.id AS fighter_id",
        "fighters.name AS fighter_name",
        "COUNT(DISTINCT fights.id) AS fight_count",
        win_count_sql,
        loss_count_sql,
        win_percentage_sql
      )
  end

  def win_count_sql
    "COUNT(DISTINCT CASE " \
      "WHEN fights.outcome = 'W/L' AND " \
      "SPLIT_PART(fights.bout, ' vs', 1) = fighters.name " \
      "THEN fights.id " \
      "WHEN fights.outcome = 'L/W' AND " \
      "TRIM(SPLIT_PART(fights.bout, ' vs', 2), '. ') = fighters.name " \
      "THEN fights.id " \
      "END) AS total_wins"
  end

  def loss_count_sql
    "COUNT(DISTINCT CASE " \
      "WHEN fights.outcome = 'W/L' AND " \
      "TRIM(SPLIT_PART(fights.bout, ' vs', 2), '. ') = fighters.name " \
      "THEN fights.id " \
      "WHEN fights.outcome = 'L/W' AND " \
      "SPLIT_PART(fights.bout, ' vs', 1) = fighters.name " \
      "THEN fights.id " \
      "END) AS total_losses"
  end

  def win_percentage_sql
    "ROUND(" \
      "100.0 * COUNT(DISTINCT CASE " \
      "WHEN fights.outcome = 'W/L' AND " \
      "SPLIT_PART(fights.bout, ' vs', 1) = fighters.name " \
      "THEN fights.id " \
      "WHEN fights.outcome = 'L/W' AND " \
      "TRIM(SPLIT_PART(fights.bout, ' vs', 2), '. ') = fighters.name " \
      "THEN fights.id " \
      "END) / " \
      "NULLIF(COUNT(DISTINCT CASE " \
      "WHEN fights.outcome IN ('W/L', 'L/W') THEN fights.id " \
      "END), 0), " \
      "1" \
      ") AS win_percentage"
  end

  def validate_category!(category)
    return if VALID_CATEGORIES.include?(category)

    raise ArgumentError,
          "Invalid category: #{category}. " \
          "Valid categories are: #{VALID_CATEGORIES.join(', ')}"
  end

  def top_winners
    fighter_stats = build_fighter_stats_query
                    .having(win_count_having_clause)
                    .order("total_wins DESC")
                    .limit(TOP_PERFORMERS_LIMIT)

    fighter_stats.map { |result| format_wins_result(result) }
  end

  def win_count_having_clause
    "COUNT(DISTINCT CASE " \
      "WHEN fights.outcome = 'W/L' AND " \
      "SPLIT_PART(fights.bout, ' vs', 1) = fighters.name " \
      "THEN fights.id " \
      "WHEN fights.outcome = 'L/W' AND " \
      "TRIM(SPLIT_PART(fights.bout, ' vs', 2), '. ') = fighters.name " \
      "THEN fights.id " \
      "END) > 0"
  end

  def top_losers
    fighter_stats = build_fighter_stats_query
                    .having(loss_count_having_clause)
                    .order("total_losses DESC")
                    .limit(TOP_PERFORMERS_LIMIT)

    fighter_stats.map { |result| format_losses_result(result) }
  end

  def loss_count_having_clause
    "COUNT(DISTINCT CASE " \
      "WHEN fights.outcome = 'W/L' AND " \
      "TRIM(SPLIT_PART(fights.bout, ' vs', 2), '. ') = fighters.name " \
      "THEN fights.id " \
      "WHEN fights.outcome = 'L/W' AND " \
      "SPLIT_PART(fights.bout, ' vs', 1) = fighters.name " \
      "THEN fights.id " \
      "END) > 0"
  end

  def top_win_percentages
    fighter_stats = build_fighter_stats_query
                    .having("COUNT(DISTINCT fights.id) >= ?",
                            MINIMUM_FIGHTS_FOR_PERCENTAGE)
                    .order("win_percentage DESC")
                    .limit(TOP_PERFORMERS_LIMIT)

    fighter_stats.map { |result| format_percentage_result(result) }
  end

  def top_win_streaks
    cache_key = "fighter_top_win_streaks_all"

    Rails.cache.fetch(cache_key, expires_in: 24.hours) do
      calculate_top_win_streaks
    end
  end

  def fighter_results
    Fighter
      .joins(fight_stats: :fight)
      .where("fights.outcome IN ('W/L', 'L/W')")
  end

  def calculate_longest_streak(fighter_id)
    fights = fighter_fights_ordered(fighter_id)
    fighter_name = Fighter.find(fighter_id).name

    longest_streak = 0
    current_streak = 0

    fights.each do |fight|
      if fighter_won?(fight, fighter_name)
        current_streak += 1
        longest_streak = [longest_streak, current_streak].max
      else
        current_streak = 0
      end
    end

    longest_streak
  end

  def fighter_fights_ordered(fighter_id)
    Fight
      .joins(:event, :fight_stats)
      .where(fight_stats: { fighter_id: fighter_id })
      .select("fights.*, events.date")
      .order("events.date ASC")
      .distinct
  end

  def fighter_won?(fight, fighter_name)
    if fight.outcome == "W/L"
      fight.bout.index(fighter_name).zero?
    elsif fight.outcome == "L/W"
      fight.bout.index(fighter_name) != 0
    else
      # Draw, No Contest, or any other outcome is not a win
      false
    end
  end

  def fighter_fight_count(fighter_id)
    Fight
      .joins(:fight_stats)
      .where(fight_stats: { fighter_id: fighter_id })
      .distinct
      .count
  end

  def format_wins_result(result)
    {
      fighter_id: result.fighter_id,
      fighter_name: result.fighter_name,
      fight_count: result.fight_count.to_i,
      total_wins: result.total_wins.to_i,
      win_percentage: result.win_percentage.to_f
    }
  end

  def format_losses_result(result)
    {
      fighter_id: result.fighter_id,
      fighter_name: result.fighter_name,
      fight_count: result.fight_count.to_i,
      total_losses: result.total_losses.to_i,
      win_percentage: result.win_percentage.to_f
    }
  end

  def format_percentage_result(result)
    {
      fighter_id: result.fighter_id,
      fighter_name: result.fighter_name,
      fight_count: result.fight_count.to_i,
      total_wins: result.total_wins.to_i,
      total_losses: result.total_losses.to_i,
      win_percentage: result.win_percentage.to_f
    }
  end

  def calculate_top_win_streaks
    fighter_data = fetch_fighter_data_for_streaks
    build_top_win_streaks_optimized(fighter_data)
  end

  def fetch_fighter_data_for_streaks
    Fighter
      .joins(fight_stats: { fight: :event })
      .where(fights: { outcome: ["W/L", "L/W"] })
      .group("fighters.id", "fighters.name")
      .select(
        "fighters.id AS fighter_id",
        "fighters.name AS fighter_name",
        "COUNT(DISTINCT fights.id) AS fight_count",
        win_count_case_statement
      )
      .having("COUNT(DISTINCT fights.id) > 0")
      .order("total_wins DESC", "fighters.name ASC")
  end

  def win_count_case_statement
    "COUNT(DISTINCT CASE " \
      "WHEN fights.outcome = 'W/L' AND " \
      "SPLIT_PART(fights.bout, ' vs', 1) = fighters.name " \
      "THEN fights.id " \
      "WHEN fights.outcome = 'L/W' AND " \
      "TRIM(SPLIT_PART(fights.bout, ' vs', 2), '. ') = fighters.name " \
      "THEN fights.id " \
      "END) AS total_wins"
  end

  def build_top_win_streaks_optimized(fighter_data)
    # Get top candidates based on total wins
    top_candidates = get_top_candidates(fighter_data)

    # Extract fighter IDs for bulk loading
    fighter_ids = top_candidates.map(&:fighter_id)

    # Load ALL fights for ALL candidates in a single query
    all_fights = load_all_fights_for_fighters(fighter_ids)

    # Group fights by fighter_id for efficient access
    fights_by_fighter = all_fights.group_by do |fight|
      fighter_id_from_fight(fight)
    end

    # Calculate streaks using pre-loaded data
    fighters_with_streaks = calculate_streaks_for_fighters(
      top_candidates,
      fights_by_fighter
    )

    # Return top performers by streak
    fighters_with_streaks
      .sort_by { |f| -f[:longest_win_streak] }
      .first(TOP_PERFORMERS_LIMIT)
  end

  def get_top_candidates(fighter_data)
    # Strategy: Include more candidates to ensure we don't miss fighters with
    # long win streaks but fewer total wins (like Kamaru Usman)

    # First, get all fighters sorted by total wins and name for
    # deterministic ordering
    sorted_fighters = fighter_data.sort_by do |f|
      [-f.total_wins.to_i, f.fighter_name]
    end

    # Take a larger pool of candidates to ensure we catch all potential
    # top performers. This should be large enough to include fighters like
    # Kamaru Usman who might have fewer total wins but still have long streaks
    candidate_pool_size = [sorted_fighters.size, TOP_PERFORMERS_LIMIT * 10].min

    sorted_fighters.first(candidate_pool_size)
  end

  def calculate_streaks_for_fighters(top_candidates, fights_by_fighter)
    top_candidates.map do |fighter_record|
      fighter_fights = fights_by_fighter[fighter_record.fighter_id] || []
      streak = calculate_streak_from_fights(
        fighter_fights,
        fighter_record.fighter_name
      )

      {
        fighter_id: fighter_record.fighter_id,
        fighter_name: fighter_record.fighter_name,
        fight_count: fighter_record.fight_count.to_i,
        longest_win_streak: streak
      }
    end
  end

  def build_top_win_streaks(fighter_data)
    fighters_with_streaks = []

    fighter_data.each do |fighter_record|
      next if should_skip_fighter?(fighters_with_streaks, fighter_record)

      fighter_streak = build_fighter_streak_record(fighter_record)
      fighters_with_streaks << fighter_streak

      fighters_with_streaks = trim_to_top_performers(fighters_with_streaks)
    end

    fighters_with_streaks
      .sort_by { |f| -f[:longest_win_streak] }
      .first(TOP_PERFORMERS_LIMIT)
  end

  def should_skip_fighter?(current_streaks, fighter_record)
    return false if current_streaks.size < TOP_PERFORMERS_LIMIT

    min_streak = current_streaks.min_by { |f| f[:longest_win_streak] }
                                &.dig(:longest_win_streak) || 0
    fighter_record.total_wins.to_i < min_streak
  end

  def build_fighter_streak_record(fighter_record)
    streak_data = calculate_fighter_streak_optimized(
      fighter_record.fighter_id,
      fighter_record.fighter_name
    )

    {
      fighter_id: fighter_record.fighter_id,
      fighter_name: fighter_record.fighter_name,
      fight_count: fighter_record.fight_count.to_i,
      longest_win_streak: streak_data
    }
  end

  def trim_to_top_performers(fighters_with_streaks)
    if fighters_with_streaks.size <= TOP_PERFORMERS_LIMIT
      return fighters_with_streaks
    end

    fighters_with_streaks
      .sort_by { |f| -f[:longest_win_streak] }
      .first(TOP_PERFORMERS_LIMIT)
  end

  def calculate_fighter_streak_optimized(fighter_id, fighter_name)
    # Get all fights for this fighter in one query, ordered by date
    fights = Fight
             .joins(:event, :fight_stats)
             .where(fight_stats: { fighter_id: fighter_id })
             .select(
               "fights.id",
               "fights.bout",
               "fights.outcome",
               "events.date"
             )
             .order("events.date ASC")
             .distinct

    longest_streak = 0
    current_streak = 0

    fights.each do |fight|
      if fighter_won?(fight, fighter_name)
        current_streak += 1
        longest_streak = [longest_streak, current_streak].max
      else
        current_streak = 0
      end
    end

    longest_streak
  end

  def load_all_fights_for_fighters(fighter_ids)
    Fight
      .joins(:event, :fight_stats)
      .where(fight_stats: { fighter_id: fighter_ids })
      .select(
        "fights.id",
        "fights.bout",
        "fights.outcome",
        "events.date",
        "fight_stats.fighter_id"
      )
      .order("events.date ASC")
      .distinct
  end

  def fighter_id_from_fight(fight)
    fight.fighter_id
  end

  def calculate_streak_from_fights(fights, fighter_name)
    longest_streak = 0
    current_streak = 0

    fights.each do |fight|
      if fighter_won?(fight, fighter_name)
        current_streak += 1
        longest_streak = [longest_streak, current_streak].max
      else
        current_streak = 0
      end
    end

    longest_streak
  end
end
