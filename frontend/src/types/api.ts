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