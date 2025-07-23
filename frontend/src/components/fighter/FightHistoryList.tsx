import React, { useState, useMemo } from 'react';
import { Fighter } from '@/types/api';
import { FightHistoryCard } from './FightHistoryCard';

interface FightHistoryListProps {
  fighter: Fighter;
}

type FilterType = 'all' | 'wins' | 'losses' | 'draws';
type SortType = 'recent' | 'oldest';

export function FightHistoryList({ fighter }: FightHistoryListProps) {
  const [filter, setFilter] = useState<FilterType>('all');
  const [sortBy, setSortBy] = useState<SortType>('recent');
  const [expandedFightId, setExpandedFightId] = useState<number | null>(null);

  const filteredAndSortedFights = useMemo(() => {
    if (!fighter.fights) return [];

    // Filter fights
    let filtered = fighter.fights.filter((fight) => {
      if (filter === 'all') return true;

      const fighters = fight.bout.split(' vs. ');
      const fighter1Name = fighters[0]?.trim();
      const fighter2Name = fighters[1]?.trim();
      
      let fighterPosition: 0 | 1 | null = null;
      if (fighter1Name === fighter.name) {
        fighterPosition = 0;
      } else if (fighter2Name === fighter.name) {
        fighterPosition = 1;
      }
      
      if (fighterPosition === null) return false; // Fighter not found in bout
      
      const outcomes = fight.outcome.split('/');
      
      if (outcomes.length === 2) {
        const fighterOutcome = outcomes[fighterPosition];
        
        if (filter === 'wins') return fighterOutcome === 'W';
        if (filter === 'losses') return fighterOutcome === 'L';
        if (filter === 'draws') return fighterOutcome === 'D';
      }
      
      return false;
    });

    // Sort fights
    return [...filtered].sort((a, b) => {
      const dateA = a.event?.date || '';
      const dateB = b.event?.date || '';
      
      if (sortBy === 'recent') {
        return dateB.localeCompare(dateA); // Most recent first
      } else {
        return dateA.localeCompare(dateB); // Oldest first
      }
    });
  }, [fighter.fights, fighter.name, filter, sortBy]);

  const toggleExpanded = (fightId: number) => {
    setExpandedFightId(expandedFightId === fightId ? null : fightId);
  };

  // Count wins, losses, draws for filter buttons
  const counts = useMemo(() => {
    const result = { wins: 0, losses: 0, draws: 0 };
    
    fighter.fights?.forEach((fight) => {
      const fighters = fight.bout.split(' vs. ');
      const fighter1Name = fighters[0]?.trim();
      const fighter2Name = fighters[1]?.trim();
      
      let fighterPosition: 0 | 1 | null = null;
      if (fighter1Name === fighter.name) {
        fighterPosition = 0;
      } else if (fighter2Name === fighter.name) {
        fighterPosition = 1;
      }
      
      if (fighterPosition === null) return false; // Fighter not found in bout
      
      const outcomes = fight.outcome.split('/');
      
      if (outcomes.length === 2) {
        const fighterOutcome = outcomes[fighterPosition];
        
        if (fighterOutcome === 'W') result.wins++;
        else if (fighterOutcome === 'L') result.losses++;
        else if (fighterOutcome === 'D') result.draws++;
      }
    });
    
    return result;
  }, [fighter.fights, fighter.name]);

  return (
    <div data-testid="fight-history-list">
      {/* Filters and Sort */}
      <div className="mb-6 space-y-4">
        {/* Filter Buttons */}
        <div className="flex flex-wrap gap-2">
          <button
            onClick={() => setFilter('all')}
            className={`px-4 py-2 rounded-md font-medium transition-colors ${
              filter === 'all'
                ? 'bg-blue-600 text-white'
                : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
            }`}
          >
            All ({fighter.fights?.length || 0})
          </button>
          <button
            onClick={() => setFilter('wins')}
            className={`px-4 py-2 rounded-md font-medium transition-colors ${
              filter === 'wins'
                ? 'bg-green-600 text-white'
                : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
            }`}
          >
            Wins ({counts.wins})
          </button>
          <button
            onClick={() => setFilter('losses')}
            className={`px-4 py-2 rounded-md font-medium transition-colors ${
              filter === 'losses'
                ? 'bg-red-600 text-white'
                : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
            }`}
          >
            Losses ({counts.losses})
          </button>
          {counts.draws > 0 && (
            <button
              onClick={() => setFilter('draws')}
              className={`px-4 py-2 rounded-md font-medium transition-colors ${
                filter === 'draws'
                  ? 'bg-gray-600 text-white'
                  : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
              }`}
            >
              Draws ({counts.draws})
            </button>
          )}
        </div>

        {/* Sort Options */}
        <div className="flex items-center gap-4">
          <span className="text-sm font-semibold text-gray-800">Sort by:</span>
          <select
            value={sortBy}
            onChange={(e) => setSortBy(e.target.value as SortType)}
            className="px-3 py-1.5 border border-gray-300 rounded-md text-sm text-gray-800 bg-white font-medium focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="recent">Latest First</option>
            <option value="oldest">Oldest First</option>
          </select>
        </div>
      </div>

      {/* Fight Cards */}
      {filteredAndSortedFights.length === 0 ? (
        <div className="text-center py-8 text-gray-500">
          No fights found matching the selected filter.
        </div>
      ) : (
        <div className="space-y-4">
          {filteredAndSortedFights.map((fight) => (
            <FightHistoryCard
              key={fight.id}
              fight={fight}
              fighter={fighter}
              isExpanded={expandedFightId === fight.id}
              onToggleExpanded={() => toggleExpanded(fight.id)}
            />
          ))}
        </div>
      )}
    </div>
  );
}