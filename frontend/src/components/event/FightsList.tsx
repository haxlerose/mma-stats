import React, { useState } from 'react';
import { Fight } from '@/types/api';
import { FightCard } from './FightCard';

interface FightsListProps {
  fights: Fight[];
}

export function FightsList({ fights }: FightsListProps) {
  const [expandedFightId, setExpandedFightId] = useState<number | null>(null);

  const handleToggle = (fightId: number) => {
    setExpandedFightId(current => current === fightId ? null : fightId);
  };

  if (!fights || fights.length === 0) {
    return (
      <div data-testid="fights-list" className="text-center py-8">
        <p className="text-gray-500">No fights available for this event.</p>
      </div>
    );
  }

  return (
    <div data-testid="fights-list" className="space-y-4">
      <h2 className="text-2xl font-bold text-white mb-6">Fight Card</h2>
      {fights.map((fight) => (
        <FightCard
          key={fight.id}
          fight={fight}
          isExpanded={expandedFightId === fight.id}
          onToggle={handleToggle}
        />
      ))}
    </div>
  );
}