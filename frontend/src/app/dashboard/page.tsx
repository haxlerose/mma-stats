"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import { Button } from "@/components/ui/Button";
import { Section, SectionHeader, SectionTitle, SectionSubtitle } from "@/components/ui/Section";
import { EventCard } from "@/components/event/EventCard";
import { FighterCard } from "@/components/fighter/FighterCard";
import { StatHighlights } from "@/components/stats/StatHighlight";
import { apiClient } from "@/lib/api";
import { Event, FighterSpotlight } from "@/types/api";

export default function DashboardPage() {
  const [recentEvents, setRecentEvents] = useState<Event[]>([]);
  const [featuredFighters, setFeaturedFighters] = useState<FighterSpotlight[]>([]);
  const [isLoadingEvents, setIsLoadingEvents] = useState(true);
  const [isLoadingFighters, setIsLoadingFighters] = useState(true);

  // Fetch data on component mount
  useEffect(() => {
    async function fetchData() {
      try {
        // Fetch recent events and fighter spotlight concurrently
        const [eventsResponse, spotlightFighters] = await Promise.all([
          apiClient.events.list(),
          apiClient.fighters.spotlight()
        ]);
        
        // Get the 8 most recent events for desktop (API returns them date ordered)
        setRecentEvents(eventsResponse.events.slice(0, 8));
        setFeaturedFighters(spotlightFighters);
      } catch (error) {
        console.error("Failed to fetch data:", error);
      } finally {
        setIsLoadingEvents(false);
        setIsLoadingFighters(false);
      }
    }

    fetchData();
  }, []);


  return (
    <>
      {/* Hero Section */}
      <Section className="bg-gradient-to-b from-card to-background border-b border-border -mt-8">
        <div className="container mx-auto px-4 text-center pt-8">
          <h1 className="text-4xl md:text-5xl font-bold text-foreground mb-4">
            Latest MMA Fight Statistics
          </h1>
          <p className="text-lg text-muted mb-8 max-w-2xl mx-auto">
            Comprehensive UFC data with round-by-round insights and fighter analytics
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link href="/events">
              <Button size="lg" className="w-full sm:w-auto">
                Browse All Events
              </Button>
            </Link>
            <Link href="/fighters">
              <Button variant="outline" size="lg" className="w-full sm:w-auto">
                Search Fighters
              </Button>
            </Link>
          </div>
        </div>
      </Section>

      {/* Main Content */}
      <div className="container mx-auto px-4">
        {/* Recent Events and Fighter Spotlight */}
        <div className="grid lg:grid-cols-3 gap-8">
          {/* Recent Events - Takes up 2/3 on desktop */}
          <div className="lg:col-span-2">
            <Section>
              <SectionHeader>
                <SectionTitle>Recent Events</SectionTitle>
                <SectionSubtitle>
                  Latest UFC events with fight results and statistics
                </SectionSubtitle>
              </SectionHeader>

              {isLoadingEvents ? (
                <div className="grid sm:grid-cols-2 gap-4">
                  {[...Array(8)].map((_, i) => (
                    <div
                      key={i}
                      className="h-48 bg-card border border-border rounded-lg animate-pulse"
                    />
                  ))}
                </div>
              ) : (
                <div className="grid sm:grid-cols-2 gap-4">
                  {recentEvents.map((event, index) => (
                    <div key={event.id} className={index >= 4 ? "hidden lg:block" : ""}>
                      <EventCard event={event} />
                    </div>
                  ))}
                </div>
              )}

              {!isLoadingEvents && recentEvents.length === 0 && (
                <div className="text-center py-8 text-muted">
                  <p>No recent events found.</p>
                  <p className="text-sm mt-2">
                    Try importing some event data first.
                  </p>
                </div>
              )}

              {/* View All Events Link */}
              {!isLoadingEvents && recentEvents.length > 0 && (
                <div className="mt-6 text-center">
                  <Link href="/events">
                    <Button variant="outline" size="sm">
                      View All Events →
                    </Button>
                  </Link>
                </div>
              )}
            </Section>
          </div>

          {/* Fighter Spotlight - Takes up 1/3 on desktop */}
          <div className="lg:col-span-1">
            <Section>
              <SectionHeader>
                <SectionTitle>Fighter Spotlight</SectionTitle>
                <SectionSubtitle>
                  Featured fighters with standout performances
                </SectionSubtitle>
              </SectionHeader>

              {isLoadingFighters ? (
                <div className="space-y-4">
                  {[...Array(3)].map((_, i) => (
                    <div
                      key={i}
                      className="h-64 bg-card border border-border rounded-lg animate-pulse"
                    />
                  ))}
                </div>
              ) : (
                <div className="space-y-4">
                  {featuredFighters.map((fighter) => (
                    <FighterCard
                      key={fighter.id}
                      fighter={fighter}
                      highlightStat={{
                        label: "Win Streak",
                        value: `${fighter.current_win_streak} fight${
                          fighter.current_win_streak !== 1 ? "s" : ""
                        }`
                      }}
                    />
                  ))}
                </div>
              )}

              {!isLoadingFighters && featuredFighters.length === 0 && (
                <div className="text-center py-8 text-muted">
                  <p>No active fighters found.</p>
                  <p className="text-sm mt-2">
                    Try importing some fight data first.
                  </p>
                </div>
              )}
            </Section>
          </div>
        </div>

        {/* Stats Highlights */}
        <Section className="border-t border-border bg-card/30">
          <SectionHeader className="text-center">
            <SectionTitle>Statistical Highlights</SectionTitle>
            <SectionSubtitle>
              Outstanding performances and record holders
            </SectionSubtitle>
          </SectionHeader>

          <div className="flex justify-center">
            <StatHighlights />
          </div>
        </Section>
      </div>
    </>
  );
}