/**
 * TypeScript interfaces matching Rails API responses
 * These interfaces ensure type safety when consuming API data
 */

export interface Event {
  id: number;
  name: string;
  date: string; // ISO date string
  location: string;
  fight_count?: number;
  fights?: Fight[];
}

export interface Fighter {
  id: number;
  name: string;
  slug: string;
  height_in_inches: number | null;
  reach_in_inches: number | null;
  birth_date: string | null; // ISO date string
  fights?: FightWithStats[];
}

export interface Fight {
  id: number;
  bout: string;
  outcome: string;
  weight_class: string;
  method: string;
  round: number;
  time: string;
  time_format?: string;
  referee: string;
  details?: string;
  event?: Event;
  fighters?: Fighter[];
  fight_stats?: FightStat[];
}

export interface FightStat {
  id?: number;
  fighter_id: number;
  fighter_name?: string;
  fighter?: Fighter;
  round: number;
  
  // Striking statistics
  knockdowns: number;
  significant_strikes: number;
  significant_strikes_attempted: number;
  total_strikes: number;
  total_strikes_attempted: number;
  
  // Target-specific strikes
  head_strikes: number;
  head_strikes_attempted: number;
  body_strikes: number;
  body_strikes_attempted: number;
  leg_strikes: number;
  leg_strikes_attempted: number;
  
  // Position-specific strikes  
  distance_strikes: number;
  distance_strikes_attempted: number;
  clinch_strikes: number;
  clinch_strikes_attempted: number;
  ground_strikes: number;
  ground_strikes_attempted: number;
  
  // Grappling statistics
  takedowns: number;
  takedowns_attempted: number;
  submission_attempts: number;
  reversals: number;
  control_time_seconds: number;
}

// Extended types for detailed responses
export interface FightWithStats extends Fight {
  fight_stats: FightStat[];
}

// API Response wrappers (Rails wraps responses in resource names)
export interface EventsResponse {
  events: Event[];
  meta?: PaginationMeta;
}

export interface EventResponse {
  event: Event;
}

export interface LocationsResponse {
  locations: string[];
}

export interface PaginationMeta {
  current_page: number;
  total_pages: number;
  total_count: number;
  per_page: number;
}

export interface FightersResponse {
  fighters: Fighter[];
  meta?: PaginationMeta;
}

export interface FighterResponse {
  fighter: Fighter;
}

export interface FightResponse {
  fight: Fight;
}

// API Error response
export interface ApiError {
  message: string;
  status: number;
}

// Search parameters
export interface FighterSearchParams {
  search?: string;
  page?: number;
  per_page?: number;
}

export interface EventsSearchParams {
  page?: number;
  per_page?: number;
  location?: string;
  sort_direction?: "asc" | "desc";
}

// Fighter Spotlight specific types
export interface FighterSpotlight extends Fighter {
  current_win_streak: number;
  last_fight?: {
    opponent: string;
    outcome: string;
    method: string;
    event_name: string;
    event_date: string;
  };
}

export interface FighterSpotlightResponse {
  fighters: FighterSpotlight[];
}

// Statistical Highlights types
export interface StatisticalHighlight {
  category: string;
  fighter: {
    id: number;
    name: string;
    slug: string;
    height_in_inches: number | null;
    reach_in_inches: number | null;
    birth_date: string | null;
  } | null;
  value: number;
}

export interface StatisticalHighlightsResponse {
  highlights: StatisticalHighlight[];
}

// Top Performers types
export type TopPerformerScope = "career" | "fight" | "round" | "per_minute" | "accuracy";

export type TopPerformerCategory =
  | "knockdowns"
  | "significant_strikes"
  | "significant_strikes_attempted"
  | "total_strikes"
  | "total_strikes_attempted"
  | "head_strikes"
  | "head_strikes_attempted"
  | "body_strikes"
  | "body_strikes_attempted"
  | "leg_strikes"
  | "leg_strikes_attempted"
  | "distance_strikes"
  | "distance_strikes_attempted"
  | "clinch_strikes"
  | "clinch_strikes_attempted"
  | "ground_strikes"
  | "ground_strikes_attempted"
  | "takedowns"
  | "takedowns_attempted"
  | "submission_attempts"
  | "reversals"
  | "control_time_seconds"
  | "significant_strike_accuracy";

export interface TopPerformer {
  fighter_id: number;
  fighter_name: string;
  fight_id?: number | null;
  // Career scope
  total_knockdowns?: number;
  total_significant_strikes?: number;
  total_significant_strikes_attempted?: number;
  total_total_strikes?: number;
  total_total_strikes_attempted?: number;
  total_head_strikes?: number;
  total_head_strikes_attempted?: number;
  total_body_strikes?: number;
  total_body_strikes_attempted?: number;
  total_leg_strikes?: number;
  total_leg_strikes_attempted?: number;
  total_distance_strikes?: number;
  total_distance_strikes_attempted?: number;
  total_clinch_strikes?: number;
  total_clinch_strikes_attempted?: number;
  total_ground_strikes?: number;
  total_ground_strikes_attempted?: number;
  total_takedowns?: number;
  total_takedowns_attempted?: number;
  total_submission_attempts?: number;
  total_reversals?: number;
  total_control_time_seconds?: number;
  // Fight/Round scope
  max_knockdowns?: number;
  max_significant_strikes?: number;
  max_significant_strikes_attempted?: number;
  max_total_strikes?: number;
  max_total_strikes_attempted?: number;
  max_head_strikes?: number;
  max_head_strikes_attempted?: number;
  max_body_strikes?: number;
  max_body_strikes_attempted?: number;
  max_leg_strikes?: number;
  max_leg_strikes_attempted?: number;
  max_distance_strikes?: number;
  max_distance_strikes_attempted?: number;
  max_clinch_strikes?: number;
  max_clinch_strikes_attempted?: number;
  max_ground_strikes?: number;
  max_ground_strikes_attempted?: number;
  max_takedowns?: number;
  max_takedowns_attempted?: number;
  max_submission_attempts?: number;
  max_reversals?: number;
  max_control_time_seconds?: number;
  event_name?: string;
  opponent_name?: string;
  round?: number;
  // Per 15 minutes scope
  knockdowns_per_15_minutes?: number;
  significant_strikes_per_15_minutes?: number;
  significant_strikes_attempted_per_15_minutes?: number;
  total_strikes_per_15_minutes?: number;
  total_strikes_attempted_per_15_minutes?: number;
  head_strikes_per_15_minutes?: number;
  head_strikes_attempted_per_15_minutes?: number;
  body_strikes_per_15_minutes?: number;
  body_strikes_attempted_per_15_minutes?: number;
  leg_strikes_per_15_minutes?: number;
  leg_strikes_attempted_per_15_minutes?: number;
  distance_strikes_per_15_minutes?: number;
  distance_strikes_attempted_per_15_minutes?: number;
  clinch_strikes_per_15_minutes?: number;
  clinch_strikes_attempted_per_15_minutes?: number;
  ground_strikes_per_15_minutes?: number;
  ground_strikes_attempted_per_15_minutes?: number;
  takedowns_per_15_minutes?: number;
  takedowns_attempted_per_15_minutes?: number;
  submission_attempts_per_15_minutes?: number;
  reversals_per_15_minutes?: number;
  control_time_seconds_per_15_minutes?: number;
  fight_duration_minutes?: number;
  // Accuracy scope
  value?: number;
  accuracy_percentage?: number;
  fight_count?: number;
  total_fights?: number;
}

export interface TopPerformersResponse {
  top_performers: TopPerformer[];
  meta: {
    scope: TopPerformerScope;
    category: TopPerformerCategory;
  };
}

export interface TopPerformersSearchParams {
  scope: TopPerformerScope;
  category: TopPerformerCategory;
}