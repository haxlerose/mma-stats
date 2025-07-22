import React from 'react';
import { Event } from '@/types/api';

interface EventHeaderProps {
  event: Event;
}

function formatDate(dateString: string): string {
  if (!dateString) return 'Date TBD';
  
  try {
    // Parse as local date to avoid timezone issues
    const [year, month, day] = dateString.split('-').map(Number);
    const date = new Date(year, month - 1, day); // month is 0-indexed
    
    // Check if date is valid
    if (isNaN(date.getTime())) {
      return dateString; // Return original string if invalid
    }
    
    return new Intl.DateTimeFormat('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      timeZone: 'UTC' // Use UTC to be consistent
    }).format(date);
  } catch {
    return dateString; // Return original string if parsing fails
  }
}

export function EventHeader({ event }: EventHeaderProps) {
  const eventName = event.name || 'Event Name TBD';
  const location = event.location || 'Location TBD';
  const fightCount = event.fight_count ?? 0;
  const fightText = fightCount === 1 ? 'fight' : 'fights';

  return (
    <header 
      data-testid="event-header"
      className="bg-white rounded-lg p-6 shadow-sm space-y-4"
    >
      {/* Event Name */}
      <h1 className="text-3xl sm:text-4xl font-bold text-gray-900 break-words">
        {eventName}
      </h1>

      {/* Event Details */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:gap-6 gap-2">
        {/* Date */}
        <div className="flex items-center text-gray-600">
          <span className="mr-2" aria-label="Date">📅</span>
          <span>{formatDate(event.date)}</span>
        </div>

        {/* Location */}
        <div className="flex items-center text-gray-600">
          <span className="mr-2" aria-label="Location">📍</span>
          <span>{location}</span>
        </div>

        {/* Fight Count */}
        <div className="flex items-center text-gray-600">
          <span className="mr-2" aria-label="Fight count">🥊</span>
          <span>{fightCount} {fightText}</span>
        </div>
      </div>
    </header>
  );
}