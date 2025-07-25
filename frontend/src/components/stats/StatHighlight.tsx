import React, { useEffect, useState } from "react";
import Link from "next/link";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import { apiClient } from "@/lib/api";
import { StatisticalHighlight } from "@/types/api";

interface StatHighlightProps {
  icon: string;
  title: string;
  fighterName: string;
  statValue: string;
  statLabel: string;
  fighterUrl: string;
  className?: string;
}

export function StatHighlight({
  icon,
  title,
  fighterName,
  statValue,
  statLabel,
  fighterUrl,
  className,
}: StatHighlightProps) {
  return (
    <Card variant="hover" className={`min-w-[240px] max-w-xs ${className}`}>
      <CardHeader>
        <div className="flex items-center space-x-2">
          <span className="text-2xl" role="img" aria-label={title}>
            {icon}
          </span>
          <CardTitle className="text-sm uppercase tracking-wide text-muted">
            {title}
          </CardTitle>
        </div>
      </CardHeader>

      <CardContent className="text-center">
        <div className="mb-3">
          <p className="text-lg font-bold text-foreground">
            {fighterName}
          </p>
        </div>

        <div className="mb-4">
          <p className="text-3xl font-bold text-primary">
            {statValue}
          </p>
          <p className="text-sm text-muted">
            {statLabel}
          </p>
        </div>

        <Link href={fighterUrl}>
          <Button variant="outline" size="sm" className="w-full">
            View Fighter →
          </Button>
        </Link>
      </CardContent>
    </Card>
  );
}

// Helper function to format statistical values for display
function formatStatValue(value: number, category: string): string {
  if (value === 0) return "0";
  
  switch (category) {
    case "strikes_per_15min":
      return Math.round(value).toString();
    case "submission_attempts_per_15min":
    case "takedowns_per_15min":
    case "knockdowns_per_15min":
      return value.toFixed(1);
    default:
      return value.toFixed(1);
  }
}

// Helper function to get display info for each category
function getCategoryInfo(category: string) {
  switch (category) {
    case "strikes_per_15min":
      return {
        icon: "🎯",
        title: "Strike Volume",
        label: "Strikes per 15min"
      };
    case "submission_attempts_per_15min":
      return {
        icon: "🤼",
        title: "Submission Hunter",
        label: "Attempts per 15min"
      };
    case "takedowns_per_15min":
      return {
        icon: "🤸",
        title: "Takedown Master",
        label: "Takedowns per 15min"
      };
    case "knockdowns_per_15min":
      return {
        icon: "💥",
        title: "Knockout Power",
        label: "Knockdowns per 15min"
      };
    default:
      return {
        icon: "📊",
        title: "Unknown",
        label: "per 15min"
      };
  }
}

// Helper component for creating multiple stat highlights
export function StatHighlights({ 
  className 
}: { 
  className?: string 
}) {
  const [highlights, setHighlights] = useState<StatisticalHighlight[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchHighlights() {
      try {
        setIsLoading(true);
        setError(null);
        const data = await apiClient.statistics.highlights();
        setHighlights(data);
      } catch (err) {
        console.error("Failed to fetch statistical highlights:", err);
        setError("Failed to load statistical highlights");
      } finally {
        setIsLoading(false);
      }
    }

    fetchHighlights();
  }, []);

  // Loading state
  if (isLoading) {
    return (
      <div className={`grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 ${className}`}>
        {[...Array(4)].map((_, index) => (
          <Card key={index} className="min-w-[240px] max-w-xs">
            <CardHeader>
              <div className="h-6 bg-card-foreground/10 rounded animate-pulse" />
            </CardHeader>
            <CardContent className="text-center">
              <div className="mb-3">
                <div className="h-6 bg-card-foreground/10 rounded animate-pulse" />
              </div>
              <div className="mb-4">
                <div className="h-9 bg-card-foreground/10 rounded animate-pulse mb-2" />
                <div className="h-4 bg-card-foreground/10 rounded animate-pulse" />
              </div>
              <div className="h-8 bg-card-foreground/10 rounded animate-pulse" />
            </CardContent>
          </Card>
        ))}
      </div>
    );
  }

  // Error state
  if (error) {
    return (
      <div className={`text-center py-8 ${className}`}>
        <p className="text-destructive mb-4">{error}</p>
        <Button 
          variant="outline" 
          onClick={() => window.location.reload()}
        >
          Retry
        </Button>
      </div>
    );
  }

  // Empty state
  if (highlights.length === 0) {
    return (
      <div className={`text-center py-8 ${className}`}>
        <p className="text-muted">No statistical highlights available.</p>
        <p className="text-sm text-muted-foreground mt-2">
          Try importing some fight data first.
        </p>
      </div>
    );
  }

  return (
    <div className={`grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 ${className}`}>
      {highlights.map((highlight, index) => {
        const categoryInfo = getCategoryInfo(highlight.category);
        const fighterName = highlight.fighter?.name || "No Data";
        const statValue = formatStatValue(highlight.value, highlight.category);
        const fighterUrl = highlight.fighter 
          ? `/fighters/${highlight.fighter.slug}` 
          : "#";

        return (
          <StatHighlight
            key={`${highlight.category}-${index}`}
            icon={categoryInfo.icon}
            title={categoryInfo.title}
            fighterName={fighterName}
            statValue={statValue}
            statLabel={categoryInfo.label}
            fighterUrl={fighterUrl}
          />
        );
      })}
    </div>
  );
}