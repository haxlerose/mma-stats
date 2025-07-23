import React from 'react';
import { Fight } from '@/types/api';

interface FightResultSummaryProps {
  fight: Fight;
}

function getMethodIcon(method: string): string {
  const lowerMethod = method.toLowerCase();
  if (lowerMethod.includes('ko') || lowerMethod.includes('tko')) {
    return '🥊';
  } else if (lowerMethod.includes('submission')) {
    return '🤼';
  } else if (lowerMethod.includes('decision')) {
    return '⚖️';
  }
  return '🏁';
}

function formatMethod(method: string): string {
  // Format common abbreviations
  if (method.includes('KO/TKO')) {
    return 'Knockout / Technical Knockout';
  } else if (method.includes('SUB')) {
    return 'Submission';
  } else if (method.includes('DEC')) {
    return 'Decision';
  }
  return method;
}

export function FightResultSummary({ fight }: FightResultSummaryProps) {
  const methodIcon = getMethodIcon(fight.method);
  const formattedMethod = formatMethod(fight.method);
  const timeFormat = fight.time_format || '5:00';
  
  // Determine if fight went the distance
  const wentDistance = fight.method.toLowerCase().includes('decision');

  return (
    <div 
      data-testid="fight-result-summary"
      className="bg-white rounded-lg p-6 shadow-sm"
    >
      <h2 className="text-xl font-bold text-gray-900 mb-4">Fight Result</h2>
      
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {/* Method */}
        <div className="text-center">
          <div className="text-3xl mb-2">{methodIcon}</div>
          <div className="text-sm text-gray-700 font-medium mb-1">Method</div>
          <div className="font-semibold text-gray-900">{formattedMethod}</div>
          {fight.details && (
            <div className="text-sm text-gray-700 mt-1">({fight.details})</div>
          )}
        </div>
        
        {/* Round */}
        <div className="text-center">
          <div className="text-3xl mb-2">⏱️</div>
          <div className="text-sm text-gray-700 font-medium mb-1">Round</div>
          <div className="font-semibold text-gray-900">
            Round {fight.round}
            {wentDistance && ' (Decision)'}
          </div>
          {!wentDistance && (
            <div className="text-sm text-gray-700 mt-1">
              at {fight.time} of {timeFormat}
            </div>
          )}
        </div>
        
        {/* Referee */}
        <div className="text-center">
          <div className="text-3xl mb-2">🏁</div>
          <div className="text-sm text-gray-700 font-medium mb-1">Referee</div>
          <div className="font-semibold text-gray-900">{fight.referee}</div>
        </div>
      </div>
      
      {/* Additional Details for Decisions */}
      {wentDistance && fight.details && (
        <div className="mt-6 pt-4 border-t border-gray-200">
          <div className="text-center">
            <div className="text-sm text-gray-700 font-medium mb-1">Judges' Decision</div>
            <div className="font-semibold text-gray-900">{fight.details}</div>
          </div>
        </div>
      )}
    </div>
  );
}