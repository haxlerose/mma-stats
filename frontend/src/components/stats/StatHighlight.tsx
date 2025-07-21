import React from "react";
import Link from "next/link";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";

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

// Helper component for creating multiple stat highlights
export function StatHighlights({ 
  className 
}: { 
  className?: string 
}) {
  // Dummy data that looks realistic but is clearly placeholder
  const dummyStats = [
    {
      icon: "🎯",
      title: "Best Accuracy",
      fighterName: "Israel Adesanya",
      statValue: "67%",
      statLabel: "Significant Strikes",
      fighterUrl: "/fighters/1", // Will be dynamic later
    },
    {
      icon: "👊",
      title: "Most Strikes",
      fighterName: "Max Holloway", 
      statValue: "445",
      statLabel: "Total Strikes Landed",
      fighterUrl: "/fighters/2",
    },
    {
      icon: "⏱️",
      title: "Control Time",
      fighterName: "Khabib Nurmagomedov",
      statValue: "15:42",
      statLabel: "Single Fight Record",
      fighterUrl: "/fighters/3",
    },
    {
      icon: "🥊",
      title: "Takedown Rate",
      fighterName: "Daniel Cormier",
      statValue: "89%",
      statLabel: "Takedown Success",
      fighterUrl: "/fighters/4",
    },
  ];

  return (
    <div className={`grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 ${className}`}>
      {dummyStats.map((stat, index) => (
        <StatHighlight
          key={index}
          icon={stat.icon}
          title={stat.title}
          fighterName={stat.fighterName}
          statValue={stat.statValue}
          statLabel={stat.statLabel}
          fighterUrl={stat.fighterUrl}
        />
      ))}
    </div>
  );
}