/**
 * API Client Tests
 * Tests for the Events API functionality following TDD methodology
 */

import { apiClient, ApiClientError } from '../api';
import { EventsResponse, EventsSearchParams } from '@/types/api';

// Mock fetch globally
global.fetch = jest.fn();

const mockFetch = fetch as jest.MockedFunction<typeof fetch>;

describe('Events API', () => {
  beforeEach(() => {
    mockFetch.mockClear();
  });

  describe('events.list', () => {
    test('calls correct endpoint with default parameters', async () => {
      const mockResponse: EventsResponse = {
        events: [
          {
            id: 1,
            name: 'UFC 309',
            date: '2024-11-16',
            location: 'Las Vegas, Nevada',
            fight_count: 13
          }
        ],
        meta: {
          current_page: 1,
          total_pages: 1,
          total_count: 1,
          per_page: 20
        }
      };

      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockResponse,
      } as Response);

      const result = await apiClient.events.list();

      expect(mockFetch).toHaveBeenCalledWith(
        'http://localhost:3000/api/v1/events',
        {
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        }
      );
      expect(result).toEqual(mockResponse);
    });

    test('includes location parameter when provided', async () => {
      const mockResponse: EventsResponse = {
        events: [],
        meta: {
          current_page: 1,
          total_pages: 0,
          total_count: 0,
          per_page: 20
        }
      };

      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockResponse,
      } as Response);

      const params: EventsSearchParams = {
        location: 'Las Vegas, Nevada'
      };

      await apiClient.events.list(params);

      expect(mockFetch).toHaveBeenCalledWith(
        'http://localhost:3000/api/v1/events?location=Las%20Vegas%2C%20Nevada',
        expect.any(Object)
      );
    });

    test('includes sort_direction parameter', async () => {
      const mockResponse: EventsResponse = {
        events: [],
        meta: {
          current_page: 1,
          total_pages: 0,
          total_count: 0,
          per_page: 20
        }
      };

      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockResponse,
      } as Response);

      const params: EventsSearchParams = {
        sort_direction: 'asc'
      };

      await apiClient.events.list(params);

      expect(mockFetch).toHaveBeenCalledWith(
        'http://localhost:3000/api/v1/events?sort_direction=asc',
        expect.any(Object)
      );
    });

    test('includes pagination parameters', async () => {
      const mockResponse: EventsResponse = {
        events: [],
        meta: {
          current_page: 2,
          total_pages: 5,
          total_count: 100,
          per_page: 20
        }
      };

      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockResponse,
      } as Response);

      const params: EventsSearchParams = {
        page: 2,
        per_page: 20
      };

      await apiClient.events.list(params);

      expect(mockFetch).toHaveBeenCalledWith(
        'http://localhost:3000/api/v1/events?page=2&per_page=20',
        expect.any(Object)
      );
    });

    test('includes all parameters when provided', async () => {
      const mockResponse: EventsResponse = {
        events: [],
        meta: {
          current_page: 1,
          total_pages: 1,
          total_count: 2,
          per_page: 10
        }
      };

      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockResponse,
      } as Response);

      const params: EventsSearchParams = {
        page: 1,
        per_page: 10,
        location: 'Las Vegas, Nevada',
        sort_direction: 'desc'
      };

      await apiClient.events.list(params);

      expect(mockFetch).toHaveBeenCalledWith(
        'http://localhost:3000/api/v1/events?page=1&per_page=10&location=Las%20Vegas%2C%20Nevada&sort_direction=desc',
        expect.any(Object)
      );
    });

    test('handles API errors gracefully', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 500,
        statusText: 'Internal Server Error',
      } as Response);

      await expect(apiClient.events.list()).rejects.toThrow(ApiClientError);
      await expect(apiClient.events.list()).rejects.toThrow('API request failed: 500 Internal Server Error');
    });

    test('returns proper TypeScript types', async () => {
      const mockResponse: EventsResponse = {
        events: [
          {
            id: 1,
            name: 'UFC 309',
            date: '2024-11-16',
            location: 'Las Vegas, Nevada',
            fight_count: 13
          }
        ],
        meta: {
          current_page: 1,
          total_pages: 1,
          total_count: 1,
          per_page: 20
        }
      };

      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockResponse,
      } as Response);

      const result = await apiClient.events.list();

      // TypeScript should infer these types correctly
      expect(typeof result.events[0].id).toBe('number');
      expect(typeof result.events[0].name).toBe('string');
      expect(typeof result.events[0].date).toBe('string');
      expect(typeof result.events[0].location).toBe('string');
      expect(typeof result.events[0].fight_count).toBe('number');
      expect(typeof result.meta?.current_page).toBe('number');
    });
  });


  describe('network error handling', () => {
    test('handles network errors', async () => {
      mockFetch.mockRejectedValueOnce(new Error('Network error'));

      await expect(apiClient.events.list()).rejects.toThrow(ApiClientError);
      await expect(apiClient.events.list()).rejects.toThrow('Network error: Network error');
    });

    test('handles JSON parsing errors', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => {
          throw new Error('Invalid JSON');
        },
      } as Response);

      await expect(apiClient.events.list()).rejects.toThrow(ApiClientError);
      await expect(apiClient.events.list()).rejects.toThrow('Network error: Invalid JSON');
    });
  });
});

describe('Locations API', () => {
  beforeEach(() => {
    mockFetch.mockClear();
  });

  describe('locations.list', () => {
    test('calls locations endpoint', async () => {
      const mockResponse = {
        locations: ['Las Vegas, Nevada', 'New York, New York']
      };

      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockResponse,
      } as Response);

      const result = await apiClient.locations.list();

      expect(mockFetch).toHaveBeenCalledWith(
        'http://localhost:3000/api/v1/locations',
        {
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        }
      );
      expect(result).toEqual(['Las Vegas, Nevada', 'New York, New York']);
    });

    test('handles empty response', async () => {
      const mockResponse = {
        locations: []
      };

      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => mockResponse,
      } as Response);

      const result = await apiClient.locations.list();

      expect(result).toEqual([]);
    });

    test('handles API errors', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 404,
        statusText: 'Not Found',
      } as Response);

      await expect(apiClient.locations.list()).rejects.toThrow(ApiClientError);
      await expect(apiClient.locations.list()).rejects.toThrow('API request failed: 404 Not Found');
    });
  });
});