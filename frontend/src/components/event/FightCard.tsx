import React from 'react';
import Link from 'next/link';
import { Fight } from '@/types/api';
import { FightStats } from './FightStats';

interface FightCardProps {
  fight: Fight;
  isExpanded: boolean;
  onToggle: (fightId: number) => void;
}

function extractWinner(outcome: string, bout: string): string | null {
  if (!outcome || !bout) return null;
  
  const fighters = bout.split(' vs. ').map(name => name.trim());
  if (fighters.length !== 2) return null;
  
  // Handle W/L format (first fighter wins/loses)
  if (outcome === 'W/L') {
    return fighters[0]; // First fighter wins
  } else if (outcome === 'L/W') {
    return fighters[1]; // Second fighter wins
  }
  
  // Handle text-based outcomes for backwards compatibility with tests
  const lowerOutcome = outcome.toLowerCase();
  
  // Check for common win patterns
  for (const fighter of fighters) {
    const lowerFighter = fighter.toLowerCase();
    
    // Check full name patterns first
    if (
      lowerOutcome.includes(`${lowerFighter} wins`) ||
      lowerOutcome.includes(`${lowerFighter} defeats`) ||
      lowerOutcome.includes(`${lowerFighter} victory`) ||
      lowerOutcome.startsWith(`${lowerFighter} wins`) ||
      (lowerOutcome.startsWith(lowerFighter) && lowerOutcome.includes('wins'))
    ) {
      return fighter;
    }
    
    // Check for last name only patterns (e.g., "Jones wins" for "Jon Jones")
    const lastNameParts = fighter.split(' ');
    if (lastNameParts.length > 1) {
      const lastName = lastNameParts[lastNameParts.length - 1].toLowerCase();
      if (
        lowerOutcome.includes(`${lastName} wins`) ||
        lowerOutcome.includes(`${lastName} defeats`) ||
        lowerOutcome.includes(`${lastName} victory`) ||
        lowerOutcome.startsWith(`${lastName} wins`) ||
        (lowerOutcome.startsWith(lastName) && lowerOutcome.includes('wins'))
      ) {
        return fighter;
      }
    }
  }
  
  return null;
}

function splitFighters(bout: string): { fighter1: string; fighter2: string } | null {
  if (!bout || !bout.includes(' vs. ')) {
    return null;
  }
  
  const fighters = bout.split(' vs. ').map(name => name.trim());
  if (fighters.length !== 2) {
    return null;
  }
  
  return {
    fighter1: fighters[0],
    fighter2: fighters[1]
  };
}

export function FightCard({ fight, isExpanded, onToggle }: FightCardProps) {
  const bout = fight.bout || 'Fight details unavailable';
  const method = fight.method || 'Method TBD';
  const referee = fight.referee || 'Referee TBD';
  const winner = extractWinner(fight.outcome, fight.bout);
  const fighters = splitFighters(fight.bout);
  
  const roundTimeDisplay = fight.round && fight.time 
    ? `Round ${fight.round} • ${fight.time}`
    : 'Time/Round TBD';

  const handleClick = () => {
    onToggle(fight.id);
  };

  const handleKeyDown = (event: React.KeyboardEvent) => {
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault();
      onToggle(fight.id);
    }
  };

  // Determine winner and loser for clear display
  const hasWinner = winner && fighters;
  const winnerName = hasWinner ? winner : null;
  const loserName = hasWinner && fighters 
    ? (winner === fighters.fighter1 ? fighters.fighter2 : fighters.fighter1)
    : null;

  return (
    <article 
      data-testid="fight-card"
      className="bg-white rounded-lg shadow-sm border transition-shadow duration-200 hover:shadow-md"
    >
      <button
        className="w-full p-4 text-left focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-inset rounded-lg"
        onClick={handleClick}
        onKeyDown={handleKeyDown}
        aria-expanded={isExpanded}
        aria-controls={`fight-stats-${fight.id}`}
        aria-label={isExpanded ? 'Collapse fight details' : 'Expand fight details'}
        tabIndex={0}
      >
        <div className="flex items-center justify-between">
          <div data-testid="fight-info" className="flex-1 space-y-3">
            {/* Fight Matchup with Win/Loss Indicators */}
            {hasWinner && fighters ? (
              <div data-testid="fight-matchup" className="space-y-3">
                <h3 className="text-lg font-semibold text-gray-900">
                  {fight.weight_class} • {method} • {roundTimeDisplay}
                </h3>
                
                <div className="flex items-center justify-between">
                  {/* Winner */}
                  <div className="flex items-center gap-3">
                    <div 
                      data-testid="winner-badge"
                      className="px-3 py-1 bg-green-100 text-green-800 border border-green-300 rounded-md font-bold text-sm"
                    >
                      WIN
                    </div>
                    <span className="text-lg font-semibold text-gray-900">{winnerName}</span>
                  </div>
                  
                  {/* VS */}
                  <div className="text-gray-400 font-medium">VS</div>
                  
                  {/* Loser */}
                  <div className="flex items-center gap-3">
                    <span className="text-lg font-semibold text-gray-900">{loserName}</span>
                    <div 
                      data-testid="loser-badge"
                      className="px-3 py-1 bg-red-100 text-red-800 border border-red-300 rounded-md font-bold text-sm"
                    >
                      LOSS
                    </div>
                  </div>
                </div>
              </div>
            ) : (
              /* Fallback for fights without clear winner or invalid format */
              <div className="space-y-2">
                <div className="flex items-center gap-2">
                  {fight.outcome && (
                    <div className="px-2 py-1 bg-gray-50 border border-gray-200 rounded text-gray-700 text-sm">
                      <span className="font-medium">{fight.outcome}</span>
                    </div>
                  )}
                  <h3 className="text-lg font-semibold text-gray-900 break-words">
                    {bout}
                  </h3>
                </div>
                
                <div className="flex flex-wrap gap-4 text-sm text-gray-600">
                  <span className="font-medium">{fight.weight_class}</span>
                  <span>•</span>
                  <span>{method}</span>
                  <span>•</span>
                  <span>{roundTimeDisplay}</span>
                </div>
              </div>
            )}

            {/* Referee */}
            <div className="text-sm text-gray-500">
              Referee: {referee}
            </div>
          </div>

          {/* Accordion Indicator */}
          <div className="ml-4 text-gray-400">
            <span className="text-lg">
              {isExpanded ? '▲' : '▼'}
            </span>
          </div>
        </div>
      </button>

      {/* Expanded Fight Stats */}
      {isExpanded && (
        <div 
          id={`fight-stats-${fight.id}`}
          className="border-t border-gray-100 p-4"
        >
          <FightStats fight={fight} />
          
          {/* Link to Fight Details */}
          <div className="mt-4">
            <Link 
              href={`/fights/${fight.id}`}
              className="text-blue-600 hover:text-blue-800 text-sm font-medium"
            >
              View Full Fight Details →
            </Link>
          </div>
        </div>
      )}
    </article>
  );
}