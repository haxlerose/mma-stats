'use client';

import React, { useState, useEffect } from 'react';
import { useParams } from 'next/navigation';
import { apiClient, ApiClientError } from '@/lib/api';
import { Event } from '@/types/api';
import { EventHeader } from '@/components/event/EventHeader';
import { FightsList } from '@/components/event/FightsList';

export default function EventDetailPage() {
  const params = useParams();
  const eventId = parseInt(params.id as string);
  
  const [event, setEvent] = useState<Event | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<{ type: 'not-found' | 'network' | 'server'; message: string } | null>(null);

  const fetchEvent = async () => {
    setIsLoading(true);
    setError(null);
    
    try {
      const eventData = await apiClient.events.get(eventId);
      setEvent(eventData);
    } catch (err) {
      if (err instanceof ApiClientError || (err as any)?.name === 'ApiClientError') {
        const apiError = err as any;
        if (apiError.status === 404) {
          setError({
            type: 'not-found',
            message: 'Event not found. The event you\'re looking for doesn\'t exist.'
          });
        } else if (apiError.status === 0) {
          setError({
            type: 'network',
            message: 'Failed to load event. Please check your connection and try again.'
          });
        } else {
          setError({
            type: 'server',
            message: 'Something went wrong while loading the event. Please try again.'
          });
        }
      } else {
        setError({
          type: 'server',
          message: 'Something went wrong while loading the event. Please try again.'
        });
      }
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    if (eventId) {
      fetchEvent();
    }
  }, [eventId]);

  const handleRetry = () => {
    fetchEvent();
  };

  if (isLoading) {
    return (
      <div className="space-y-8">
        <div data-testid="loading-spinner" className="text-center py-8">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading event details...</p>
        </div>
        
        {/* Loading Skeletons */}
        <div data-testid="event-header-skeleton" className="space-y-4">
          <div className="h-8 bg-gray-200 rounded animate-pulse"></div>
          <div className="h-4 bg-gray-200 rounded animate-pulse w-1/2"></div>
          <div className="h-4 bg-gray-200 rounded animate-pulse w-1/3"></div>
        </div>
        
        <div data-testid="fights-list-skeleton" className="space-y-4">
          {[...Array(3)].map((_, i) => (
            <div key={i} className="h-20 bg-gray-200 rounded animate-pulse"></div>
          ))}
        </div>
      </div>
    );
  }

  if (error?.type === 'not-found') {
    return (
      <div className="text-center py-12">
        <div className="mb-4">
          <svg className="mx-auto h-16 w-16 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1} d="M9.172 16.172a4 4 0 015.656 0M9 12h6m-6-4h6m2 5.291A7.962 7.962 0 0112 15c-2.34 0-4.47-.881-6.08-2.33" />
          </svg>
        </div>
        <h2 className="text-2xl font-bold text-gray-900 mb-2">Event Not Found</h2>
        <p className="text-gray-600 mb-6">The event you're looking for doesn't exist or may have been removed.</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="text-center py-12">
        <div className="mb-4">
          <svg className="mx-auto h-16 w-16 text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>
        <h2 className="text-2xl font-bold text-gray-900 mb-2">
          {error.type === 'network' ? 'Failed to Load Event' : 'Something Went Wrong'}
        </h2>
        <p className="text-gray-600 mb-6">{error.message}</p>
        <button
          onClick={handleRetry}
          className="px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
        >
          Try Again
        </button>
      </div>
    );
  }

  if (!event) {
    return null;
  }

  return (
    <div data-testid="event-detail-page" className="space-y-8">
      <EventHeader event={event} />
      <FightsList fights={event.fights || []} />
    </div>
  );
}