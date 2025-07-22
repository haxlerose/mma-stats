import React, { useState } from 'react';
import { Fight, FightStat } from '@/types/api';

interface FightStatsProps {
  fight: Fight;
}

interface StatDisplay {
  key: string;
  label: string;
  getValue: (stat: FightStat) => string;
  getPercentage?: (stat: FightStat) => string;
}

function formatTime(seconds: number): string {
  const minutes = Math.floor(seconds / 60);
  const remainingSeconds = seconds % 60;
  return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
}

function calculatePercentage(landed: number, attempted: number): string {
  if (attempted === 0) return '0%';
  return Math.round((landed / attempted) * 100) + '%';
}

export function FightStats({ fight }: FightStatsProps) {
  const [showRoundDetails, setShowRoundDetails] = useState(false);

  if (!fight.fight_stats || fight.fight_stats.length === 0) {
    return (
      <div data-testid="fight-stats">
        <p className="text-gray-600">No fight statistics available.</p>
      </div>
    );
  }

  // Group stats by fighter and round
  const statsByFighter = fight.fight_stats.reduce((acc, stat) => {
    const fighterId = stat.fighter_id;
    if (!acc[fighterId]) {
      acc[fighterId] = {
        fighter: stat.fighter,
        rounds: {}
      };
    }
    acc[fighterId].rounds[stat.round] = stat;
    return acc;
  }, {} as Record<number, { fighter: any; rounds: Record<number, FightStat> }>);

  const fighters = Object.values(statsByFighter);
  const rounds = [...new Set(fight.fight_stats.map(stat => stat.round))].sort((a, b) => a - b);
  const hasMultipleRounds = rounds.length > 1;

  // Calculate totals for each fighter
  const calculateTotals = (rounds: Record<number, FightStat>) => {
    const stats = Object.values(rounds);
    return stats.reduce((total, stat) => ({
      knockdowns: total.knockdowns + (stat.knockdowns || 0),
      significant_strikes: total.significant_strikes + (stat.significant_strikes || 0),
      significant_strikes_attempted: total.significant_strikes_attempted + (stat.significant_strikes_attempted || 0),
      total_strikes: total.total_strikes + (stat.total_strikes || 0),
      total_strikes_attempted: total.total_strikes_attempted + (stat.total_strikes_attempted || 0),
      head_strikes: total.head_strikes + (stat.head_strikes || 0),
      head_strikes_attempted: total.head_strikes_attempted + (stat.head_strikes_attempted || 0),
      body_strikes: total.body_strikes + (stat.body_strikes || 0),
      body_strikes_attempted: total.body_strikes_attempted + (stat.body_strikes_attempted || 0),
      leg_strikes: total.leg_strikes + (stat.leg_strikes || 0),
      leg_strikes_attempted: total.leg_strikes_attempted + (stat.leg_strikes_attempted || 0),
      distance_strikes: total.distance_strikes + (stat.distance_strikes || 0),
      distance_strikes_attempted: total.distance_strikes_attempted + (stat.distance_strikes_attempted || 0),
      clinch_strikes: total.clinch_strikes + (stat.clinch_strikes || 0),
      clinch_strikes_attempted: total.clinch_strikes_attempted + (stat.clinch_strikes_attempted || 0),
      ground_strikes: total.ground_strikes + (stat.ground_strikes || 0),
      ground_strikes_attempted: total.ground_strikes_attempted + (stat.ground_strikes_attempted || 0),
      takedowns: total.takedowns + (stat.takedowns || 0),
      takedowns_attempted: total.takedowns_attempted + (stat.takedowns_attempted || 0),
      submission_attempts: total.submission_attempts + (stat.submission_attempts || 0),
      reversals: total.reversals + (stat.reversals || 0),
      control_time_seconds: total.control_time_seconds + (stat.control_time_seconds || 0),
    }), {
      knockdowns: 0,
      significant_strikes: 0,
      significant_strikes_attempted: 0,
      total_strikes: 0,
      total_strikes_attempted: 0,
      head_strikes: 0,
      head_strikes_attempted: 0,
      body_strikes: 0,
      body_strikes_attempted: 0,
      leg_strikes: 0,
      leg_strikes_attempted: 0,
      distance_strikes: 0,
      distance_strikes_attempted: 0,
      clinch_strikes: 0,
      clinch_strikes_attempted: 0,
      ground_strikes: 0,
      ground_strikes_attempted: 0,
      takedowns: 0,
      takedowns_attempted: 0,
      submission_attempts: 0,
      reversals: 0,
      control_time_seconds: 0,
    });
  };

  // Use abbreviated labels as requested
  const statDisplays: StatDisplay[] = [
    {
      key: 'knockdowns',
      label: 'KD',
      getValue: (stat) => `${stat.knockdowns || 0}`
    },
    {
      key: 'significant_strikes',
      label: 'Sig. str.',
      getValue: (stat) => `${stat.significant_strikes || 0}/${stat.significant_strikes_attempted || 0}`,
    },
    {
      key: 'significant_strikes_pct',
      label: 'Sig. str. %',
      getValue: (stat) => calculatePercentage(stat.significant_strikes || 0, stat.significant_strikes_attempted || 0)
    },
    {
      key: 'total_strikes',
      label: 'Total str.',
      getValue: (stat) => `${stat.total_strikes || 0}/${stat.total_strikes_attempted || 0}`,
    },
    {
      key: 'takedowns',
      label: 'Td',
      getValue: (stat) => `${stat.takedowns || 0}/${stat.takedowns_attempted || 0}`,
    },
    {
      key: 'takedowns_pct',
      label: 'Td %',
      getValue: (stat) => calculatePercentage(stat.takedowns || 0, stat.takedowns_attempted || 0)
    },
    {
      key: 'submission_attempts',
      label: 'Sub. att',
      getValue: (stat) => `${stat.submission_attempts || 0}`
    },
    {
      key: 'reversals',
      label: 'Rev.',
      getValue: (stat) => `${stat.reversals || 0}`
    },
    {
      key: 'control_time',
      label: 'Ctrl',
      getValue: (stat) => formatTime(stat.control_time_seconds || 0)
    }
  ];

  // Get totals for display
  const fighterTotals = fighters.map(fighter => ({
    fighter: fighter.fighter,
    totals: calculateTotals(fighter.rounds)
  }));

  const StatValue = ({ stat, display }: { stat: any; display: StatDisplay }) => (
    <div className="text-center">
      <div className="text-sm font-medium text-gray-900">{display.getValue(stat)}</div>
    </div>
  );

  return (
    <div data-testid="fight-stats" className="space-y-4">
      <h3 className="text-lg font-semibold text-gray-900">Fight Totals</h3>

      {/* Desktop Horizontal Layout */}
      <div data-testid="fight-totals-table" className="hidden md:block overflow-x-auto">
        <table className="w-full border border-gray-200 rounded-lg overflow-hidden">
          <thead>
            <tr className="bg-gray-50">
              <th className="text-left p-3 font-medium text-gray-900">Fighter</th>
              {statDisplays.map(stat => (
                <th key={stat.key} className="text-center p-2 font-medium text-gray-900 text-xs">
                  {stat.label}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {fighterTotals.map((fighterData, index) => (
              <tr key={index} className="hover:bg-gray-50">
                <td className="p-3 font-medium text-gray-900">
                  {fighterData.fighter?.name || `Fighter ${index + 1}`}
                </td>
                {statDisplays.map(display => (
                  <td key={display.key} className="p-2 text-center text-sm text-gray-700">
                    {display.getValue(fighterData.totals as any)}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Mobile Vertical Layout */}
      <div data-testid="fight-totals-mobile" className="block md:hidden space-y-4">
        {fighterTotals.map((fighterData, fighterIndex) => (
          <div key={fighterIndex} className="bg-gray-50 p-4 rounded-lg">
            <h4 className="font-semibold text-gray-900 mb-3">
              {fighterData.fighter?.name || `Fighter ${fighterIndex + 1}`}
            </h4>
            <div className="grid grid-cols-3 gap-4">
              {statDisplays.map(display => (
                <div key={display.key} className="text-center">
                  <div className="text-xs font-medium text-gray-500 mb-1">{display.label}</div>
                  <div className="text-sm font-semibold text-gray-900">
                    {display.getValue(fighterData.totals as any)}
                  </div>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>

      {/* Round Details Toggle (for multi-round fights) */}
      {hasMultipleRounds && (
        <div className="pt-4 border-t border-gray-200">
          <button
            onClick={() => setShowRoundDetails(!showRoundDetails)}
            className="flex items-center text-sm font-medium text-blue-600 hover:text-blue-700"
            aria-label="View round details"
          >
            <span>{showRoundDetails ? 'Hide' : 'View'} Round Details</span>
            <svg 
              className={`ml-2 h-4 w-4 transform transition-transform ${showRoundDetails ? 'rotate-180' : ''}`}
              fill="none" 
              stroke="currentColor" 
              viewBox="0 0 24 24"
            >
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
            </svg>
          </button>

          {showRoundDetails && (
            <div className="mt-4 space-y-6">
              {rounds.map(round => (
                <div key={round} className="space-y-2">
                  <h4 className="font-semibold text-gray-900">Round {round}</h4>
                  <div className="overflow-x-auto">
                    <table className="w-full border border-gray-200 rounded-lg overflow-hidden">
                      <thead>
                        <tr className="bg-gray-50">
                          <th className="text-left p-2 font-medium text-gray-900 text-sm">Fighter</th>
                          {statDisplays.map(stat => (
                            <th key={stat.key} className="text-center p-2 font-medium text-gray-900 text-xs">
                              {stat.label}
                            </th>
                          ))}
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-gray-100">
                        {fighters.map((fighter, index) => {
                          const roundStat = fighter.rounds[round];
                          return (
                            <tr key={index} className="hover:bg-gray-50">
                              <td className="p-2 font-medium text-gray-900 text-sm">
                                {fighter.fighter?.name || `Fighter ${index + 1}`}
                              </td>
                              {statDisplays.map(display => (
                                <td key={display.key} className="p-2 text-center text-xs text-gray-700">
                                  {roundStat ? display.getValue(roundStat) : '-'}
                                </td>
                              ))}
                            </tr>
                          );
                        })}
                      </tbody>
                    </table>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}