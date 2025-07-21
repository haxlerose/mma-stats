# frozen_string_literal: true

class Fighter < ApplicationRecord
  has_many :fight_stats, dependent: :destroy
  has_many :fights, -> { distinct }, through: :fight_stats

  validates :name, presence: true

  scope :alphabetical, -> { order(Arel.sql("LOWER(name)")) }
  scope :search,
        lambda { |query|
          return all if query.blank?

          where("name ILIKE ?", "%#{sanitize_sql_like(query)}%")
        }
  scope :with_fight_details, -> { includes(fight_stats: { fight: :event }) }

  # Calculate the current win streak for this fighter
  def current_win_streak
    # Get unique fights ordered by event date (most recent first)
    # Use subquery to get distinct fight IDs, then join back for proper ordering
    fight_subquery = FightStat
                     .where(fighter_id: id)
                     .select("DISTINCT fight_id")

    unique_fights = Fight
                    .joins(:event)
                    .where(id: fight_subquery)
                    .order("events.date DESC")

    streak_count = 0

    unique_fights.each do |fight|
      if won_fight?(fight)
        streak_count += 1
      else
        # Streak broken, stop counting
        break
      end
    end

    streak_count
  end

  # Find fighters with the longest current win streaks
  # Only considers active fighters (last 2 years) who won their last fight
  def self.top_win_streaks(limit: 3)
    # Use Rails cache to store results since win streaks change infrequently
    cache_key = "fighter_top_win_streaks_#{limit}_#{cache_timestamp}"

    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      calculate_top_win_streaks(limit)
    end
  end

  # Generate cache timestamp based on most recent fight update
  def self.cache_timestamp
    Fight.maximum(:updated_at).to_i
  end

  # Perform the actual win streak calculation (extracted for caching)
  def self.calculate_top_win_streaks(limit)
    two_years_ago = 2.years.ago.to_date

    # Get fighters who are active AND won their most recent fight
    # This reduces dataset since fighters who lost can't have win streaks
    potential_streak_fighter_ids =
      find_active_fighters_with_recent_wins(two_years_ago)

    return [] if potential_streak_fighter_ids.empty?

    # Calculate win streaks in bulk using optimized dataset
    fighters_with_streaks =
      calculate_bulk_win_streaks(potential_streak_fighter_ids)

    # Sort by win streak (descending) and take top N
    fighters_with_streaks
      .sort_by { |f| -f[:win_streak] }
      .first(limit)
  end

  # Calculate win streaks using raw SQL with window functions
  # This eliminates Ruby processing and memory overhead
  def self.raw_sql_win_streaks(two_years_ago, limit)
    sql = <<~SQL
      WITH fighter_fights_ordered AS (
        SELECT DISTINCT ON (fs.fighter_id, f.id)
          fs.fighter_id,
          f.id as fight_id,
          f.bout,
          f.outcome,
          f.method,
          e.date as event_date,
          e.name as event_name,
          fig.name as fighter_name,
          fig.height_in_inches,
          fig.reach_in_inches,
          fig.birth_date,
          ROW_NUMBER() OVER (PARTITION BY fs.fighter_id ORDER BY e.date DESC) as fight_sequence
        FROM fight_stats fs
        JOIN fights f ON f.id = fs.fight_id
        JOIN events e ON e.id = f.event_id
        JOIN fighters fig ON fig.id = fs.fighter_id
        WHERE e.date >= $1
      ),
      fight_results AS (
        SELECT *,
          CASE
            WHEN outcome = 'W/L' AND position(upper(fighter_name) in upper(bout)) = 1 THEN true
            WHEN outcome = 'L/W' AND position(upper(fighter_name) in upper(bout)) != 1 THEN true
            WHEN outcome = 'Win' THEN true
            ELSE false
          END as won_fight
        FROM fighter_fights_ordered
      ),
      win_streaks AS (
        SELECT
          fighter_id,
          fighter_name,
          height_in_inches,
          reach_in_inches,
          birth_date,
          COUNT(*) FILTER (
            WHERE won_fight = true
            AND fight_sequence <= (
              SELECT MIN(fight_sequence)
              FROM fight_results fr2
              WHERE fr2.fighter_id = fight_results.fighter_id
              AND fr2.won_fight = false
            )
          ) as current_win_streak,
          -- Get last fight details
          MAX(CASE WHEN fight_sequence = 1 THEN event_date END) as last_fight_date,
          MAX(CASE WHEN fight_sequence = 1 THEN event_name END) as last_fight_event,
          MAX(CASE WHEN fight_sequence = 1 THEN method END) as last_fight_method,
          MAX(CASE WHEN fight_sequence = 1 THEN bout END) as last_fight_bout,
          MAX(CASE WHEN fight_sequence = 1 THEN
            CASE WHEN won_fight THEN 'Win' ELSE 'Loss' END
          END) as last_fight_outcome
        FROM fight_results
        WHERE fight_sequence = 1 AND won_fight = true  -- Only fighters who won last fight
        GROUP BY fighter_id, fighter_name, height_in_inches, reach_in_inches, birth_date
      )
      SELECT
        fighter_id,
        fighter_name,
        height_in_inches,
        reach_in_inches,
        birth_date,
        COALESCE(current_win_streak, 0) as current_win_streak,
        last_fight_date,
        last_fight_event,
        last_fight_method,
        last_fight_bout,
        last_fight_outcome
      FROM win_streaks
      WHERE current_win_streak > 0
      ORDER BY current_win_streak DESC
      LIMIT $2
    SQL

    result = connection.exec_query(
      sql,
      "Fighter.raw_sql_win_streaks",
      [two_years_ago, limit]
    )

    result.map do |row|
      fighter = build_fighter_from_row(row)
      opponent = extract_opponent_from_bout_string(
        row["last_fight_bout"],
        row["fighter_name"]
      )

      {
        fighter: fighter,
        win_streak: row["current_win_streak"],
        last_fight: build_last_fight_from_row(row, opponent)
      }
    end
  end

  # Extract opponent name from bout string (helper for SQL results)
  def self.extract_opponent_from_bout_string(bout, fighter_name)
    return "Unknown" if bout.blank? || fighter_name.blank?

    parts = bout.split(/\s+vs\.?\s+/i, 2)
    return "Unknown" if parts.length < 2

    fighter1_name = parts[0].strip
    fighter2_name = parts[1].strip

    determine_opponent(fighter_name, fighter1_name, fighter2_name)
  end

  # Helper method to determine opponent from fighter names
  def self.determine_opponent(fighter_name, fighter1_name, fighter2_name)
    if names_match?(fighter_name, fighter1_name)
      fighter2_name
    elsif names_match?(fighter_name, fighter2_name)
      fighter1_name
    else
      "Unknown"
    end
  end

  # Check if fighter names match (exact or partial)
  def self.names_match?(name1, name2)
    name1.downcase.include?(name2.downcase) ||
      name2.downcase.include?(name1.downcase)
  end

  # Build fighter object from SQL result row
  def self.build_fighter_from_row(row)
    new(
      id: row["fighter_id"],
      name: row["fighter_name"],
      height_in_inches: row["height_in_inches"],
      reach_in_inches: row["reach_in_inches"],
      birth_date: row["birth_date"]
    )
  end

  # Build last fight details from SQL result row
  def self.build_last_fight_from_row(row, opponent)
    {
      opponent: opponent,
      outcome: row["last_fight_outcome"],
      method: row["last_fight_method"],
      event_name: row["last_fight_event"],
      event_date: row["last_fight_date"]
    }
  end

  # Get details of the fighter's most recent fight
  def last_fight_details
    last_fight_id = find_last_fight_id
    return nil unless last_fight_id

    last_fight = Fight
                 .includes(:event, fight_stats: :fighter)
                 .find(last_fight_id)
    build_fight_details(last_fight)
  end

  # Find active fighters who won their most recent fight
  # This dramatically reduces the dataset for win streak calculation
  def self.find_active_fighters_with_recent_wins(two_years_ago)
    # Get recent fighters with their most recent fight preloaded
    recent_fighters = joins(fight_stats: { fight: :event })
                      .where(events: { date: two_years_ago.. })
                      .distinct
                      .includes(fights: :event)

    # Filter to only those whose most recent fight was a win
    recent_fighters.filter_map do |fighter|
      # Get most recent fight within the active period
      last_fight = fighter.fights
                          .select { |f| f.event.date >= two_years_ago }
                          .max_by { |f| f.event.date }

      # Return fighter ID if they won their last fight
      fighter.id if last_fight && fighter.send(:won_fight?, last_fight)
    end
  end

  # Calculate win streaks for multiple fighters efficiently
  def self.calculate_bulk_win_streaks(fighter_ids)
    return [] if fighter_ids.empty?

    # Get all fighters with fights preloaded, including all fight participants
    fighters = where(id: fighter_ids).includes(
      fight_stats: {
        fight: [:event,
                { fight_stats: :fighter }]
      }
    )

    fighters.map do |fighter|
      {
        fighter: fighter,
        win_streak: fighter.current_win_streak_from_preloaded_data,
        last_fight: fighter.last_fight_details_from_preloaded_data
      }
    end
  end

  # Calculate win streak using preloaded fight data (avoids N+1 queries)
  def current_win_streak_from_preloaded_data
    # Get unique fights from preloaded fight_stats, ordered by date
    unique_fights = fight_stats
                    .map(&:fight)
                    .uniq
                    .sort_by { |fight| fight.event.date }
                    .reverse

    streak_count = 0

    unique_fights.each do |fight|
      if won_fight?(fight)
        streak_count += 1
      else
        break
      end
    end

    streak_count
  end

  # Get last fight details using preloaded data
  def last_fight_details_from_preloaded_data
    # Get the most recent fight from preloaded data
    last_fight = fight_stats
                 .map(&:fight)
                 .uniq
                 .max_by { |fight| fight.event.date }

    return nil unless last_fight

    build_fight_details(last_fight)
  end

  private

  # Find the ID of the fighter's most recent fight
  def find_last_fight_id
    FightStat
      .joins(fight: :event)
      .where(fighter_id: id)
      .select("DISTINCT fights.id, events.date")
      .order("events.date DESC")
      .limit(1)
      .pick("fights.id")
  end

  # Build fight details hash from fight record
  def build_fight_details(fight)
    {
      opponent: find_opponent_name(fight),
      outcome: won_fight?(fight) ? "Win" : "Loss",
      method: fight.method,
      event_name: fight.event.name,
      event_date: fight.event.date
    }
  end

  # Find opponent name efficiently based on available data
  def find_opponent_name(fight)
    if preloaded_fighters?(fight)
      find_opponent_from_fight_stats(fight)
    else
      find_opponent_from_bout(fight.bout)
    end
  end

  # Check if fight has preloaded fighter data
  def preloaded_fighters?(fight)
    fight.fight_stats.loaded? &&
      fight.fight_stats.all? { |fs| fs.fighter.present? }
  end

  # Extract opponent from preloaded fight stats
  def find_opponent_from_fight_stats(fight)
    opponent_stat = fight.fight_stats.find { |fs| fs.fighter_id != id }
    opponent_stat&.fighter&.name || find_opponent_from_bout(fight.bout)
  end

  # Extract opponent name from bout string as fallback
  def find_opponent_from_bout(bout)
    return "Unknown" if bout.blank?

    parts = bout.split(/\s+vs\.?\s+/i, 2)
    return "Unknown" if parts.length < 2

    fighter1_name = parts[0].strip
    fighter2_name = parts[1].strip
    current_name = name.strip

    if name_matches?(current_name, fighter1_name)
      fighter2_name
    elsif name_matches?(current_name, fighter2_name)
      fighter1_name
    else
      "Unknown"
    end
  end

  # Determine if this fighter won the fight by parsing bout string
  def won_fight?(fight)
    outcome = fight.outcome.to_s.strip
    bout = fight.bout

    return false if outcome.blank? || bout.blank?

    fighter_position = determine_fighter_position(bout)
    return false if fighter_position.nil?

    outcome_indicates_win?(outcome, fighter_position)
  end

  # Determine fighter's position in bout (1 or 2, nil if not found)
  def determine_fighter_position(bout)
    parts = bout.split(/\s+vs\.?\s+/i, 2)
    return nil if parts.length < 2

    fighter1_name = parts[0].strip
    fighter2_name = parts[1].strip
    current_name = name.strip

    return 1 if name_matches?(current_name, fighter1_name)
    return 2 if name_matches?(current_name, fighter2_name)

    nil
  end

  # Check if outcome indicates a win for the given fighter position
  def outcome_indicates_win?(outcome, fighter_position)
    case outcome
    when "W/L"
      fighter_position == 1
    when "L/W"
      fighter_position == 2
    when "Win", "Loss"
      # Legacy test formats
      win_result = outcome == "Win" ? 1 : 2
      fighter_position == win_result
    else
      false
    end
  end

  # Check if two fighter names match (exact or partial match)
  def name_matches?(name1, name2)
    name1.downcase == name2.downcase ||
      name1.downcase.include?(name2.downcase) ||
      name2.downcase.include?(name1.downcase)
  end
end
