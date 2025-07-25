import React from 'react';
import Link from 'next/link';
import { Fight } from '@/types/api';

interface FightHeaderProps {
  fight: Fight;
}

function getWinnerAndLoser(fight: Fight): { 
  winner: { name: string; id: number; slug: string } | null; 
  loser: { name: string; id: number; slug: string } | null; 
  isDraw: boolean;
  isNoContest: boolean;
} {
  const fighters = fight.bout.split(' vs. ');
  const fighter1Name = fighters[0]?.trim();
  const fighter2Name = fighters[1]?.trim();
  
  const fighter1 = fight.fighters?.find(f => f.name === fighter1Name);
  const fighter2 = fight.fighters?.find(f => f.name === fighter2Name);
  
  const outcomes = fight.outcome.split('/');
  
  if (outcomes.length === 2) {
    if (outcomes[0] === 'W' && outcomes[1] === 'L') {
      return { 
        winner: fighter1 ? { name: fighter1.name, id: fighter1.id, slug: fighter1.slug } : null, 
        loser: fighter2 ? { name: fighter2.name, id: fighter2.id, slug: fighter2.slug } : null,
        isDraw: false,
        isNoContest: false
      };
    } else if (outcomes[0] === 'L' && outcomes[1] === 'W') {
      return { 
        winner: fighter2 ? { name: fighter2.name, id: fighter2.id, slug: fighter2.slug } : null, 
        loser: fighter1 ? { name: fighter1.name, id: fighter1.id, slug: fighter1.slug } : null,
        isDraw: false,
        isNoContest: false
      };
    } else if (outcomes[0] === 'D' && outcomes[1] === 'D') {
      return { 
        winner: null, 
        loser: null,
        isDraw: true,
        isNoContest: false
      };
    } else if (outcomes[0] === 'NC' && outcomes[1] === 'NC') {
      return { 
        winner: null, 
        loser: null,
        isDraw: false,
        isNoContest: true
      };
    }
  }
  
  return { winner: null, loser: null, isDraw: false, isNoContest: false };
}

export function FightHeader({ fight }: FightHeaderProps) {
  const { winner, loser, isDraw, isNoContest } = getWinnerAndLoser(fight);
  const fighter1 = fight.fighters?.[0];
  const fighter2 = fight.fighters?.[1];
  
  if (!fighter1 || !fighter2) return null;

  return (
    <header 
      data-testid="fight-header"
      className="bg-white rounded-lg p-6 shadow-sm"
    >
      <div className="text-center">
        {/* Fight Title */}
        <div className="flex items-center justify-center gap-4 mb-4">
          <div className="flex-1 text-right">
            <Link 
              href={`/fighters/${fighter1.slug}`}
              className={`text-2xl font-bold hover:text-blue-600 transition-colors ${
                winner?.id === fighter1.id ? 'text-green-600' : 
                loser?.id === fighter1.id ? 'text-red-600' : 
                'text-gray-900'
              }`}
            >
              {fighter1.name}
            </Link>
            {winner?.id === fighter1.id && (
              <div className="mt-1">
                <span className="text-green-600 text-sm font-semibold">WINNER</span>
                <span className="ml-1">👑</span>
              </div>
            )}
          </div>
          
          <div className="px-4">
            <span className="text-gray-700 text-xl font-medium">vs</span>
          </div>
          
          <div className="flex-1 text-left">
            <Link 
              href={`/fighters/${fighter2.slug}`}
              className={`text-2xl font-bold hover:text-blue-600 transition-colors ${
                winner?.id === fighter2.id ? 'text-green-600' : 
                loser?.id === fighter2.id ? 'text-red-600' : 
                'text-gray-900'
              }`}
            >
              {fighter2.name}
            </Link>
            {winner?.id === fighter2.id && (
              <div className="mt-1">
                <span className="ml-1">👑</span>
                <span className="text-green-600 text-sm font-semibold">WINNER</span>
              </div>
            )}
          </div>
        </div>
        
        {/* Draw or No Contest */}
        {isDraw && (
          <div className="text-gray-600 font-semibold">
            DRAW
          </div>
        )}
        {isNoContest && (
          <div className="text-yellow-600 font-semibold">
            NO CONTEST
          </div>
        )}
        
        {/* Event Info */}
        <div className="mt-4 text-gray-700">
          <Link 
            href={`/events/${fight.event?.id}`}
            className="hover:text-blue-600 transition-colors"
          >
            {fight.event?.name}
          </Link>
          <span className="mx-2">•</span>
          <span>{fight.event?.date ? new Date(fight.event.date).toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'long',
            day: 'numeric',
            timeZone: 'UTC'
          }) : ''}</span>
        </div>
        
        <div className="mt-2 text-gray-700">
          <span className="font-medium">{fight.weight_class}</span>
        </div>
      </div>
    </header>
  );
}