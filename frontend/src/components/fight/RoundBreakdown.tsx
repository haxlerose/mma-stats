import React, { useState } from 'react';
import Link from 'next/link';
import { Fight, FightStat } from '@/types/api';

interface RoundBreakdownProps {
  fight: Fight;
}

interface RoundStats {
  round: number;
  fighter1Stats: FightStat | undefined;
  fighter2Stats: FightStat | undefined;
}

function formatAccuracy(landed: number, attempted: number): string {
  if (attempted === 0) return '0%';
  return `${Math.round((landed / attempted) * 100)}%`;
}

function formatTime(seconds: number): string {
  const minutes = Math.floor(seconds / 60);
  const remainingSeconds = seconds % 60;
  return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
}

function StatRow({ 
  label, 
  fighter1Value, 
  fighter2Value,
  fighter1Total,
  fighter2Total,
  highlight = false
}: { 
  label: string; 
  fighter1Value: number | string;
  fighter2Value: number | string;
  fighter1Total?: number;
  fighter2Total?: number;
  highlight?: boolean;
}) {
  const showTotals = fighter1Total !== undefined && fighter2Total !== undefined;
  
  return (
    <div className={`grid grid-cols-3 py-2 ${highlight ? 'bg-gray-50' : ''}`}>
      <div className="text-right pr-4">
        <span className="font-medium">{fighter1Value}</span>
        {showTotals && (
          <>
            <span className="text-gray-700 text-sm">/{fighter1Total}</span>
            <span className="text-gray-700 text-sm ml-1">
              ({formatAccuracy(Number(fighter1Value), fighter1Total)})
            </span>
          </>
        )}
      </div>
      <div className="text-center text-sm text-gray-700 font-medium">
        {label}
      </div>
      <div className="text-left pl-4">
        <span className="font-medium">{fighter2Value}</span>
        {showTotals && (
          <>
            <span className="text-gray-700 text-sm">/{fighter2Total}</span>
            <span className="text-gray-700 text-sm ml-1">
              ({formatAccuracy(Number(fighter2Value), fighter2Total)})
            </span>
          </>
        )}
      </div>
    </div>
  );
}

function RoundCard({ roundStats, fighter1Name, fighter2Name, fighter1Id, fighter2Id, fighter1Slug, fighter2Slug }: {
  roundStats: RoundStats;
  fighter1Name: string;
  fighter2Name: string;
  fighter1Id: number;
  fighter2Id: number;
  fighter1Slug: string;
  fighter2Slug: string;
}) {
  const [isExpanded, setIsExpanded] = useState(false);
  const { fighter1Stats, fighter2Stats } = roundStats;
  
  if (!fighter1Stats && !fighter2Stats) return null;
  
  const f1 = fighter1Stats || {} as FightStat;
  const f2 = fighter2Stats || {} as FightStat;
  
  return (
    <div className="bg-white rounded-lg shadow-sm border border-gray-200">
      <button
        onClick={() => setIsExpanded(!isExpanded)}
        className="w-full px-6 py-4 flex items-center justify-between hover:bg-gray-50 transition-colors"
      >
        <div className="flex items-center gap-4">
          <h3 className="text-lg font-semibold text-gray-900">Round {roundStats.round}</h3>
          <div className="flex items-center gap-2 text-sm text-gray-700">
            <span className="font-medium">{f1.significant_strikes || 0}</span>
            <span>sig. strikes</span>
            <span className="text-gray-500 font-medium">vs</span>
            <span className="font-medium">{f2.significant_strikes || 0}</span>
            <span>sig. strikes</span>
          </div>
        </div>
        <svg
          className={`w-5 h-5 text-gray-500 transform transition-transform ${isExpanded ? 'rotate-180' : ''}`}
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
        </svg>
      </button>
      
      {isExpanded && (
        <div className="px-6 pb-4 border-t border-gray-200">
          <div className="mt-4">
            {/* Fighter Names */}
            <div className="grid grid-cols-3 mb-4 text-sm font-semibold">
              <div className="text-right pr-4">
                <Link 
                  href={`/fighters/${fighter1Slug}`}
                  className="text-blue-600 hover:text-blue-800 hover:underline"
                >
                  {fighter1Name}
                </Link>
              </div>
              <div></div>
              <div className="text-left pl-4">
                <Link 
                  href={`/fighters/${fighter2Slug}`}
                  className="text-red-600 hover:text-red-800 hover:underline"
                >
                  {fighter2Name}
                </Link>
              </div>
            </div>
            
            {/* Striking Stats */}
            <div className="mb-4">
              <h4 className="text-sm font-semibold text-gray-700 mb-2">Striking</h4>
              
              {(f1.knockdowns > 0 || f2.knockdowns > 0) && (
                <StatRow 
                  label="Knockdowns"
                  fighter1Value={f1.knockdowns || 0}
                  fighter2Value={f2.knockdowns || 0}
                  highlight
                />
              )}
              
              <StatRow 
                label="Significant Strikes"
                fighter1Value={f1.significant_strikes || 0}
                fighter2Value={f2.significant_strikes || 0}
                fighter1Total={f1.significant_strikes_attempted}
                fighter2Total={f2.significant_strikes_attempted}
              />
              
              <StatRow 
                label="Total Strikes"
                fighter1Value={f1.total_strikes || 0}
                fighter2Value={f2.total_strikes || 0}
                fighter1Total={f1.total_strikes_attempted}
                fighter2Total={f2.total_strikes_attempted}
              />
              
              {/* Strike Targets */}
              <div className="mt-3 pt-3 border-t border-gray-100">
                <div className="text-xs text-gray-700 font-medium mb-2 text-center">Strike Targets</div>
                <StatRow 
                  label="Head"
                  fighter1Value={f1.head_strikes || 0}
                  fighter2Value={f2.head_strikes || 0}
                  fighter1Total={f1.head_strikes_attempted}
                  fighter2Total={f2.head_strikes_attempted}
                />
                <StatRow 
                  label="Body"
                  fighter1Value={f1.body_strikes || 0}
                  fighter2Value={f2.body_strikes || 0}
                  fighter1Total={f1.body_strikes_attempted}
                  fighter2Total={f2.body_strikes_attempted}
                />
                <StatRow 
                  label="Legs"
                  fighter1Value={f1.leg_strikes || 0}
                  fighter2Value={f2.leg_strikes || 0}
                  fighter1Total={f1.leg_strikes_attempted}
                  fighter2Total={f2.leg_strikes_attempted}
                />
              </div>
              
              {/* Strike Positions */}
              <div className="mt-3 pt-3 border-t border-gray-100">
                <div className="text-xs text-gray-700 font-medium mb-2 text-center">Strike Positions</div>
                <StatRow 
                  label="Distance"
                  fighter1Value={f1.distance_strikes || 0}
                  fighter2Value={f2.distance_strikes || 0}
                  fighter1Total={f1.distance_strikes_attempted}
                  fighter2Total={f2.distance_strikes_attempted}
                />
                <StatRow 
                  label="Clinch"
                  fighter1Value={f1.clinch_strikes || 0}
                  fighter2Value={f2.clinch_strikes || 0}
                  fighter1Total={f1.clinch_strikes_attempted}
                  fighter2Total={f2.clinch_strikes_attempted}
                />
                <StatRow 
                  label="Ground"
                  fighter1Value={f1.ground_strikes || 0}
                  fighter2Value={f2.ground_strikes || 0}
                  fighter1Total={f1.ground_strikes_attempted}
                  fighter2Total={f2.ground_strikes_attempted}
                />
              </div>
            </div>
            
            {/* Grappling Stats */}
            <div className="pt-4 border-t border-gray-200">
              <h4 className="text-sm font-semibold text-gray-700 mb-2">Grappling</h4>
              
              <StatRow 
                label="Takedowns"
                fighter1Value={f1.takedowns || 0}
                fighter2Value={f2.takedowns || 0}
                fighter1Total={f1.takedowns_attempted}
                fighter2Total={f2.takedowns_attempted}
              />
              
              {(f1.submission_attempts > 0 || f2.submission_attempts > 0) && (
                <StatRow 
                  label="Submission Attempts"
                  fighter1Value={f1.submission_attempts || 0}
                  fighter2Value={f2.submission_attempts || 0}
                />
              )}
              
              {(f1.reversals > 0 || f2.reversals > 0) && (
                <StatRow 
                  label="Reversals"
                  fighter1Value={f1.reversals || 0}
                  fighter2Value={f2.reversals || 0}
                />
              )}
              
              <StatRow 
                label="Control Time"
                fighter1Value={formatTime(f1.control_time_seconds || 0)}
                fighter2Value={formatTime(f2.control_time_seconds || 0)}
              />
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export function RoundBreakdown({ fight }: RoundBreakdownProps) {
  const fighter1 = fight.fighters?.[0];
  const fighter2 = fight.fighters?.[1];
  
  if (!fighter1 || !fighter2 || !fight.fight_stats || fight.fight_stats.length === 0) {
    return (
      <div className="text-center py-8 text-gray-700">
        No round-by-round statistics available for this fight.
      </div>
    );
  }
  
  // Group stats by round
  const roundsMap = new Map<number, RoundStats>();
  
  fight.fight_stats.forEach(stat => {
    const round = stat.round;
    if (!roundsMap.has(round)) {
      roundsMap.set(round, {
        round,
        fighter1Stats: undefined,
        fighter2Stats: undefined
      });
    }
    
    const roundStats = roundsMap.get(round)!;
    if (stat.fighter_id === fighter1.id) {
      roundStats.fighter1Stats = stat;
    } else if (stat.fighter_id === fighter2.id) {
      roundStats.fighter2Stats = stat;
    }
  });
  
  // Convert to array and sort by round
  const rounds = Array.from(roundsMap.values()).sort((a, b) => a.round - b.round);
  
  return (
    <div data-testid="round-breakdown" className="space-y-4">
      {rounds.map(roundStats => (
        <RoundCard 
          key={roundStats.round}
          roundStats={roundStats}
          fighter1Name={fighter1.name}
          fighter2Name={fighter2.name}
          fighter1Id={fighter1.id}
          fighter2Id={fighter2.id}
          fighter1Slug={fighter1.slug}
          fighter2Slug={fighter2.slug}
        />
      ))}
    </div>
  );
}