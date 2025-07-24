/**
 * API Client for communicating with Rails backend
 * Provides type-safe methods for all API endpoints
 */

import {
  Event,
  Fighter,
  Fight,
  EventsResponse,
  EventResponse,
  LocationsResponse,
  FightersResponse,
  FighterResponse,
  FightResponse,
  FighterSearchParams,
  EventsSearchParams,
  PaginationMeta,
  FighterSpotlight,
  FighterSpotlightResponse,
  StatisticalHighlight,
  StatisticalHighlightsResponse,
  ApiError,
} from "@/types/api";

/**
 * Base API configuration
 */
const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:3000";
const API_VERSION = "v1";

/**
 * Custom error class for API errors
 */
class ApiClientError extends Error {
  constructor(
    message: string,
    public status: number,
    public response?: Response
  ) {
    super(message);
    this.name = "ApiClientError";
  }
}

/**
 * Generic fetch wrapper with error handling
 */
async function apiFetch<T>(endpoint: string): Promise<T> {
  const url = `${API_BASE_URL}/api/${API_VERSION}${endpoint}`;
  
  try {
    const response = await fetch(url, {
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
    });

    if (!response.ok) {
      const errorMessage = `API request failed: ${response.status} ${response.statusText}`;
      throw new ApiClientError(errorMessage, response.status, response);
    }

    const data: T = await response.json();
    return data;
  } catch (error) {
    if (error instanceof ApiClientError) {
      throw error;
    }
    
    // Handle network errors, parsing errors, etc.
    throw new ApiClientError(
      `Network error: ${error instanceof Error ? error.message : 'Unknown error'}`,
      0
    );
  }
}

/**
 * API client methods for all endpoints
 */
export const apiClient = {
  // Events API
  events: {
    /**
     * Get events with optional filtering, sorting, and pagination
     */
    list: (params?: EventsSearchParams): Promise<EventsResponse> => {
      const searchParams = new URLSearchParams();
      
      if (params?.page) {
        searchParams.append("page", params.page.toString());
      }
      if (params?.per_page) {
        searchParams.append("per_page", params.per_page.toString());
      }
      if (params?.location) {
        searchParams.append("location", params.location);
      }
      if (params?.sort_direction) {
        searchParams.append("sort_direction", params.sort_direction);
      }
      
      const queryString = searchParams.toString();
      const endpoint = queryString ? `/events?${queryString}` : "/events";
      
      return apiFetch<EventsResponse>(endpoint);
    },
    
    /**
     * Get specific event with associated fights
     */
    get: (id: number): Promise<Event> =>
      apiFetch<EventResponse>(`/events/${id}`).then(response => response.event),
  },

  // Fighters API  
  fighters: {
    /**
     * Get all fighters (alphabetically sorted)
     * @param params - Optional search parameters
     */
    list: (params?: FighterSearchParams): Promise<Fighter[]> => {
      const searchParams = new URLSearchParams();
      if (params?.search) {
        searchParams.append("search", params.search);
      }
      
      const queryString = searchParams.toString();
      const endpoint = queryString ? `/fighters?${queryString}` : "/fighters";
      
      return apiFetch<FightersResponse>(endpoint).then(response => response.fighters);
    },
    
    /**
     * Get specific fighter with complete fight history and statistics
     */
    get: (id: number): Promise<Fighter> =>
      apiFetch<FighterResponse>(`/fighters/${id}`).then(response => response.fighter),
      
    /**
     * Get top 3 fighters with longest current win streaks (active fighters only)
     */
    spotlight: (): Promise<FighterSpotlight[]> =>
      apiFetch<FighterSpotlightResponse>("/fighter_spotlight").then(response => response.fighters),
  },

  // Fights API
  fights: {
    /**
     * Get specific fight with complete details and statistics
     */
    get: (id: number): Promise<Fight> =>
      apiFetch<FightResponse>(`/fights/${id}`).then(response => response.fight),
  },

  // Statistical Highlights API
  statistics: {
    /**
     * Get statistical highlights for all categories
     * Returns leaders in strikes, submissions, takedowns, and knockdowns per 15 minutes
     */
    highlights: (): Promise<StatisticalHighlight[]> =>
      apiFetch<StatisticalHighlightsResponse>("/statistical_highlights")
        .then(response => response.highlights),
  },

  // Locations API
  locations: {
    /**
     * Get all unique event locations (alphabetically sorted)
     */
    list: (): Promise<string[]> =>
      apiFetch<LocationsResponse>("/locations")
        .then(response => response.locations),
  },

  // Health check
  health: {
    /**
     * Check API health status
     */
    check: (): Promise<boolean> =>
      apiFetch<void>("/up")
        .then(() => true)
        .catch(() => false),
  },
};

/**
 * Export the error class for handling in components
 */
export { ApiClientError };

/**
 * Helper function to check if an error is an API error
 */
export function isApiError(error: unknown): error is ApiClientError {
  return error instanceof ApiClientError;
}