import React from 'react';
import { Fighter } from '@/types/api';

interface FighterHeaderProps {
  fighter: Fighter;
}

function calculateRecord(fighter: Fighter): { wins: number; losses: number; draws: number } {
  if (!fighter.fights || fighter.fights.length === 0) {
    return { wins: 0, losses: 0, draws: 0 };
  }

  const record = { wins: 0, losses: 0, draws: 0 };

  fighter.fights.forEach((fight) => {
    // Determine if fighter was fighter 1 or fighter 2 based on position in bout string
    const fighters = fight.bout.split(' vs. ');
    const fighter1Name = fighters[0]?.trim();
    const fighter2Name = fighters[1]?.trim();
    
    let fighterPosition: 0 | 1 | null = null;
    if (fighter1Name === fighter.name) {
      fighterPosition = 0;
    } else if (fighter2Name === fighter.name) {
      fighterPosition = 1;
    }
    
    if (fighterPosition === null) return; // Fighter not found in bout

    // Parse outcome (e.g., "W/L" means fighter 1 won, fighter 2 lost)
    const outcomes = fight.outcome.split('/');
    if (outcomes.length === 2) {
      const fighterOutcome = outcomes[fighterPosition];
      
      if (fighterOutcome === 'W') {
        record.wins++;
      } else if (fighterOutcome === 'L') {
        record.losses++;
      } else if (fighterOutcome === 'D') {
        record.draws++;
      }
    }
  });

  return record;
}

function getCurrentStreak(fighter: Fighter): { type: 'W' | 'L' | 'D' | null; count: number } {
  if (!fighter.fights || fighter.fights.length === 0) {
    return { type: null, count: 0 };
  }

  // Sort fights by date (most recent first)
  const sortedFights = [...fighter.fights].sort((a, b) => {
    const dateA = a.event?.date || '';
    const dateB = b.event?.date || '';
    return dateB.localeCompare(dateA);
  });

  let streakType: 'W' | 'L' | 'D' | null = null;
  let streakCount = 0;

  for (const fight of sortedFights) {
    const fighters = fight.bout.split(' vs. ');
    const fighter1Name = fighters[0]?.trim();
    const fighter2Name = fighters[1]?.trim();
    
    let fighterPosition: 0 | 1 | null = null;
    if (fighter1Name === fighter.name) {
      fighterPosition = 0;
    } else if (fighter2Name === fighter.name) {
      fighterPosition = 1;
    }
    
    if (fighterPosition === null) continue; // Fighter not found in bout
    
    const outcomes = fight.outcome.split('/');
    
    if (outcomes.length === 2) {
      const fighterOutcome = outcomes[fighterPosition] as 'W' | 'L' | 'D';
      
      if (streakType === null) {
        streakType = fighterOutcome;
        streakCount = 1;
      } else if (fighterOutcome === streakType) {
        streakCount++;
      } else {
        break;
      }
    }
  }

  return { type: streakType, count: streakCount };
}

export function FighterHeader({ fighter }: FighterHeaderProps) {
  const record = calculateRecord(fighter);
  const streak = getCurrentStreak(fighter);
  const winPercentage = record.wins + record.losses > 0 
    ? ((record.wins / (record.wins + record.losses)) * 100).toFixed(1)
    : '0.0';

  return (
    <header 
      data-testid="fighter-header"
      className="bg-white rounded-lg p-6 shadow-sm space-y-4"
    >
      {/* Fighter Name */}
      <h1 className="text-3xl sm:text-4xl font-bold text-gray-900 break-words">
        {fighter.name}
      </h1>

      {/* Record and Stats */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:gap-8 gap-4">
        {/* Win-Loss Record */}
        <div className="flex items-center gap-4">
          <span className="text-2xl font-semibold text-gray-800">
            {record.wins}-{record.losses}
            {record.draws > 0 && `-${record.draws}`}
          </span>
          <span className="text-sm text-gray-600">
            ({winPercentage}% Win Rate)
          </span>
        </div>

        {/* Current Streak */}
        {streak.type && streak.count > 0 && (
          <div className="flex items-center gap-2">
            <span className={`text-lg font-medium ${
              streak.type === 'W' ? 'text-green-600' : 
              streak.type === 'L' ? 'text-red-600' : 
              'text-gray-600'
            }`}>
              {streak.count} Fight {streak.type === 'W' ? 'Win' : streak.type === 'L' ? 'Loss' : 'Draw'} Streak
            </span>
          </div>
        )}
      </div>

      {/* Total Fights */}
      <div className="text-gray-600">
        <span className="mr-2">🥊</span>
        <span>{fighter.fights?.length || 0} UFC Fights</span>
      </div>
    </header>
  );
}