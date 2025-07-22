import React from "react";
import Link from "next/link";
import { formatDate } from "@/lib/utils";
import { Event } from "@/types/api";

interface EventCardProps {
  event: Event;
}

export function EventCard({ event }: EventCardProps) {
  const fightCount = event.fight_count ?? 0;
  const eventDate = new Date(event.date);
  const now = new Date();
  const isUpcoming = eventDate > now;
  
  const formattedDate = formatDate(event.date);

  return (
    <article className={`
      border rounded-lg p-4 bg-white shadow-sm transition-shadow duration-200 hover:shadow-lg
      ${isUpcoming ? 'border-blue-200' : 'border-gray-200'}
    `}>
      <Link 
        href={`/events/${event.id}`}
        aria-label={`View details for ${event.name}`}
        className="block"
      >
        <div className="space-y-3">
          {/* Event Name */}
          <h3 className="text-lg font-bold text-gray-900 truncate text-wrap">
            {event.name}
          </h3>
          
          {/* Date */}
          <div className="text-sm text-gray-600">
            {formattedDate}
          </div>
          
          {/* Location with Icon */}
          <div className="flex items-center text-sm text-gray-600">
            <span className="mr-1">📍</span>
            <span>{event.location}</span>
          </div>
          
          {/* Fight Count */}
          <div className="text-sm text-gray-500">
            {fightCount} fights
          </div>
        </div>
      </Link>
    </article>
  );
}