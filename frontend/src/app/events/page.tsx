'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { useRouter, useSearchParams, usePathname } from 'next/navigation';
import { apiClient } from '@/lib/api';
import { Event, EventsSearchParams, EventsResponse } from '@/types/api';
import { EventCard } from '@/components/event/EventCard';
import { SortToggle } from '@/components/event/SortToggle';
import { LocationDropdown } from '@/components/event/LocationDropdown';

export default function EventsPage() {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  
  const [events, setEvents] = useState<Event[]>([]);
  const [locations, setLocations] = useState<string[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [locationsLoading, setLocationsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [locationsError, setLocationsError] = useState<string | null>(null);
  const [pagination, setPagination] = useState({
    current_page: 1,
    total_pages: 1,
    total_count: 0,
    per_page: 20
  });

  // Get current filter state from URL
  const selectedLocation = searchParams.get('location');
  const sortDirection = (searchParams.get('sort_direction') as 'asc' | 'desc') || 'desc';
  const currentPage = parseInt(searchParams.get('page') || '1');

  // Update URL with new parameters
  const updateURL = useCallback((params: Record<string, string | null>) => {
    const newSearchParams = new URLSearchParams(searchParams.toString());
    
    Object.entries(params).forEach(([key, value]) => {
      if (value === null) {
        newSearchParams.delete(key);
      } else {
        newSearchParams.set(key, value);
      }
    });

    const newURL = `${pathname}?${newSearchParams.toString()}`;
    router.replace(newURL);
  }, [pathname, router, searchParams]);

  // Load events based on current filters
  const loadEvents = useCallback(async () => {
    setIsLoading(true);
    setError(null);

    try {
      const params: EventsSearchParams = {};
      
      if (selectedLocation) params.location = selectedLocation;
      if (sortDirection !== 'desc') params.sort_direction = sortDirection;
      if (currentPage > 1) params.page = currentPage;

      const response: EventsResponse = await apiClient.events.list(params);
      
      setEvents(response.events);
      if (response.meta) {
        setPagination(response.meta);
      }
    } catch (err) {
      setError('Failed to load events. Please try again.');
      console.error('Error loading events:', err);
    } finally {
      setIsLoading(false);
    }
  }, [selectedLocation, sortDirection, currentPage]);

  // Load locations for dropdown
  const loadLocations = useCallback(async () => {
    setLocationsLoading(true);
    setLocationsError(null);

    try {
      const locationsData = await apiClient.events.locations();
      setLocations(locationsData);
    } catch (err) {
      setLocationsError('Failed to load locations');
      console.error('Error loading locations:', err);
    } finally {
      setLocationsLoading(false);
    }
  }, []);

  // Load events when filters change
  useEffect(() => {
    loadEvents();
  }, [loadEvents]);

  // Load locations on mount
  useEffect(() => {
    loadLocations();
  }, [loadLocations]);

  // Handle location selection
  const handleLocationSelect = (location: string | null) => {
    updateURL({
      location,
      page: '1' // Reset to page 1 when filters change
    });
  };

  // Handle sort direction change
  const handleSortToggle = (direction: 'asc' | 'desc') => {
    updateURL({
      sort_direction: direction === 'desc' ? null : direction, // Default is desc
      page: '1' // Reset to page 1 when filters change
    });
  };

  // Handle pagination
  const handlePageChange = (page: number) => {
    updateURL({
      page: page.toString()
    });
  };

  if (error) {
    return (
      <div className="text-center">
        <h1 className="text-3xl font-bold text-gray-900 mb-4">UFC Events</h1>
        <div className="bg-red-50 border border-red-200 rounded-md p-4 max-w-md mx-auto">
          <p className="text-red-700">{error}</p>
          <button
            onClick={loadEvents}
            className="mt-2 px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700"
          >
            Try Again
          </button>
        </div>
      </div>
    );
  }

  return (
    <div>
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">UFC Events</h1>
        <p className="text-gray-700 font-medium">
          {pagination.total_count} events total
        </p>
      </div>

      {/* Filters */}
      <div className="mb-8 flex flex-col sm:flex-row gap-4 items-start sm:items-center">
        <div className="flex-1 max-w-md">
          <label className="block text-sm font-semibold text-gray-800 mb-2">
            Location
          </label>
          <LocationDropdown
            locations={locations}
            {...(selectedLocation && { selectedLocation })}
            onLocationSelect={handleLocationSelect}
            isLoading={locationsLoading}
            {...(locationsError && { error: locationsError })}
          />
        </div>
        
        <div>
          <label className="block text-sm font-semibold text-gray-800 mb-2">
            Sort
          </label>
          <SortToggle
            direction={sortDirection}
            onToggle={handleSortToggle}
          />
        </div>
      </div>

      {/* Loading State */}
      {isLoading ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {Array.from({ length: 6 }, (_, i) => (
            <div key={i} className="bg-gray-100 rounded-lg p-4 animate-pulse">
              <div className="text-center text-gray-500">Loading events...</div>
            </div>
          ))}
        </div>
      ) : (
        <>
          {/* Events Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
            {events.map((event) => (
              <EventCard key={event.id} event={event} />
            ))}
          </div>

          {/* Empty State */}
          {events.length === 0 && (
            <div className="text-center py-12">
              <p className="text-gray-500 text-lg">
                No events found{selectedLocation && ` in ${selectedLocation}`}.
              </p>
            </div>
          )}

          {/* Pagination */}
          {pagination.total_pages > 1 && (
            <div className="flex justify-center items-center gap-4 mt-8">
              <button
                onClick={() => handlePageChange(currentPage - 1)}
                disabled={currentPage <= 1}
                className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Previous
              </button>
              
              <span className="text-sm text-gray-700">
                Page {pagination.current_page} of {pagination.total_pages}
              </span>
              
              <button
                onClick={() => handlePageChange(currentPage + 1)}
                disabled={currentPage >= pagination.total_pages}
                className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Next
              </button>
            </div>
          )}
        </>
      )}
    </div>
  );
}