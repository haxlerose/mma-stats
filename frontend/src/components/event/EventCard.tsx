import React from "react";
import Link from "next/link";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import { formatDate } from "@/lib/utils";
import { Event } from "@/types/api";

interface EventCardProps {
  event: Event;
  showFightCount?: boolean;
}

export function EventCard({ event, showFightCount = true }: EventCardProps) {
  const fightCount = event.fights?.length || 0;
  
  // Get the main event (usually the first fight in our data structure)
  const mainEvent = event.fights?.[0];

  return (
    <Card variant="hover" className="min-w-[280px] max-w-sm">
      <CardHeader>
        <CardTitle className="text-primary">{event.name}</CardTitle>
        <div className="flex flex-col text-sm text-muted">
          <span>{event.location}</span>
          <span>{formatDate(event.date)}</span>
        </div>
      </CardHeader>

      <CardContent>
        {mainEvent && (
          <div className="mb-3">
            <p className="text-sm font-medium text-foreground">
              Main Event: {mainEvent.bout}
            </p>
            <p className="text-sm text-muted">
              {mainEvent.outcome} • {mainEvent.method}
            </p>
          </div>
        )}

        {showFightCount && fightCount > 0 && (
          <p className="text-sm text-muted mb-4">
            + {fightCount - 1} more fight{fightCount !== 2 ? "s" : ""}
          </p>
        )}

        <Link href={`/events/${event.id}`}>
          <Button variant="outline" size="sm" className="w-full">
            View Event →
          </Button>
        </Link>
      </CardContent>
    </Card>
  );
}