import React from "react";
import Link from "next/link";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import { formatHeight, formatReach } from "@/lib/utils";
import { Fighter } from "@/types/api";

interface FighterCardProps {
  fighter: Fighter;
  highlightStat?: {
    label: string;
    value: string;
  };
}

export function FighterCard({ fighter, highlightStat }: FighterCardProps) {
  // Calculate record from fight history if available
  const wins = fighter.fights?.filter(fight => 
    fight.outcome?.toLowerCase().includes('win')
  ).length || 0;
  
  const losses = fighter.fights?.filter(fight => 
    fight.outcome?.toLowerCase().includes('loss')
  ).length || 0;

  // Get most recent fight
  const recentFight = fighter.fights?.[0];

  // Get fighter initials
  const getInitials = (name: string) => {
    const names = name.trim().split(' ');
    if (names.length === 1) {
      return names[0]?.substring(0, 2).toUpperCase() || '';
    }
    return ((names[0]?.charAt(0) || '') + (names[names.length - 1]?.charAt(0) || '')).toUpperCase();
  };

  return (
    <Card variant="hover" className="min-w-[280px] max-w-sm">
      <CardHeader>
        {/* Fighter Photo Placeholder */}
        <div className="w-16 h-16 bg-gray-200 rounded-full mx-auto mb-3 flex items-center justify-center">
          <span className="text-xl font-bold text-gray-700">
            {getInitials(fighter.name)}
          </span>
        </div>
        
        <CardTitle className="text-center">{fighter.name}</CardTitle>
        
        {/* Physical Stats */}
        <div className="flex justify-center space-x-4 text-sm text-gray-600">
          {fighter.height_in_inches && (
            <span>H: {formatHeight(fighter.height_in_inches)}</span>
          )}
          {fighter.reach_in_inches && (
            <span>R: {formatReach(fighter.reach_in_inches)}</span>
          )}
        </div>
      </CardHeader>

      <CardContent className="text-center">
        {/* Fight Record */}
        {(wins > 0 || losses > 0) && (
          <div className="mb-3">
            <p className="text-lg font-bold text-gray-900">
              Record: {wins}-{losses}-0
            </p>
          </div>
        )}

        {/* Recent Fight */}
        {recentFight && (
          <div className="mb-3">
            <p className="text-sm font-medium text-gray-900">
              Last: {recentFight.outcome}
            </p>
            <p className="text-sm text-gray-600">
              vs {recentFight.bout?.includes('vs') 
                ? recentFight.bout.split('vs')[1]?.trim() 
                : 'Opponent'
              }
            </p>
          </div>
        )}

        {/* Highlight Stat */}
        {highlightStat && (
          <div className="mb-4 p-2 bg-card border border-border rounded">
            <p className="text-xs text-gray-600 uppercase tracking-wide">
              {highlightStat.label}
            </p>
            <p className="text-lg font-bold text-green-600">
              {highlightStat.value}
            </p>
          </div>
        )}

        <Link href={`/fighters/${fighter.slug}`}>
          <Button variant="outline" size="sm" className="w-full">
            View Profile →
          </Button>
        </Link>
      </CardContent>
    </Card>
  );
}