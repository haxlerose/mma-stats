import React from 'react';
import Link from 'next/link';
import { Fighter, FightWithStats } from '@/types/api';

interface FightHistoryCardProps {
  fight: FightWithStats;
  fighter: Fighter;
  isExpanded: boolean;
  onToggleExpanded: () => void;
}

function formatDate(dateString: string): string {
  if (!dateString) return 'Date TBD';
  
  try {
    const date = new Date(dateString);
    return new Intl.DateTimeFormat('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      timeZone: 'UTC'
    }).format(date);
  } catch {
    return dateString;
  }
}

function getFightResult(fight: FightWithStats, fighterName: string): {
  result: 'W' | 'L' | 'D' | 'NC';
  opponent: string;
  resultClass: string;
  resultText: string;
} {
  const fighters = fight.bout.split(' vs. ');
  const fighter1Name = fighters[0]?.trim();
  const fighter2Name = fighters[1]?.trim();
  
  let fighterPosition: 0 | 1 | null = null;
  let opponent = '';
  
  if (fighter1Name === fighterName) {
    fighterPosition = 0;
    opponent = fighter2Name || '';
  } else if (fighter2Name === fighterName) {
    fighterPosition = 1;
    opponent = fighter1Name || '';
  }
  
  if (fighterPosition === null) {
    return {
      result: 'NC',
      opponent: fighters[1] || fighters[0] || 'Unknown',
      resultClass: 'bg-gray-100 text-gray-800',
      resultText: 'NC'
    };
  }
  
  const outcomes = fight.outcome.split('/');
  
  if (outcomes.length === 2) {
    const fighterOutcome = outcomes[fighterPosition];
    
    if (fighterOutcome === 'W') {
      return {
        result: 'W',
        opponent,
        resultClass: 'bg-green-100 text-green-800',
        resultText: 'WIN'
      };
    } else if (fighterOutcome === 'L') {
      return {
        result: 'L',
        opponent,
        resultClass: 'bg-red-100 text-red-800',
        resultText: 'LOSS'
      };
    } else if (fighterOutcome === 'D') {
      return {
        result: 'D',
        opponent,
        resultClass: 'bg-gray-100 text-gray-800',
        resultText: 'DRAW'
      };
    } else if (fighterOutcome === 'NC') {
      return {
        result: 'NC',
        opponent,
        resultClass: 'bg-yellow-100 text-yellow-800',
        resultText: 'NC'
      };
    }
  }
  
  return {
    result: 'NC',
    opponent,
    resultClass: 'bg-gray-100 text-gray-800',
    resultText: 'NC'
  };
}

export function FightHistoryCard({ fight, fighter, isExpanded, onToggleExpanded }: FightHistoryCardProps) {
  const { opponent, resultClass, resultText } = getFightResult(fight, fighter.name);
  // When viewing from a fighter's page, all fight_stats are for that fighter
  const fighterStats = fight.fight_stats || [];
  // Opponent stats are not included in the fighter endpoint
  const opponentStats: any[] = [];

  // Calculate totals for the fight
  const totalStrikes = fighterStats.reduce((sum, stat) => sum + (stat.total_strikes || 0), 0);
  const totalStrikesAttempted = fighterStats.reduce((sum, stat) => sum + (stat.total_strikes_attempted || 0), 0);
  const totalTakedowns = fighterStats.reduce((sum, stat) => sum + (stat.takedowns || 0), 0);
  const totalTakedownsAttempted = fighterStats.reduce((sum, stat) => sum + (stat.takedowns_attempted || 0), 0);
  
  // Additional totals for expanded view
  const totalSignificantStrikes = fighterStats.reduce((sum, stat) => sum + (stat.significant_strikes || 0), 0);
  const totalSignificantStrikesAttempted = fighterStats.reduce((sum, stat) => sum + (stat.significant_strikes_attempted || 0), 0);
  const totalKnockdowns = fighterStats.reduce((sum, stat) => sum + (stat.knockdowns || 0), 0);
  const totalHeadStrikes = fighterStats.reduce((sum, stat) => sum + (stat.head_strikes || 0), 0);
  const totalHeadStrikesAttempted = fighterStats.reduce((sum, stat) => sum + (stat.head_strikes_attempted || 0), 0);
  const totalBodyStrikes = fighterStats.reduce((sum, stat) => sum + (stat.body_strikes || 0), 0);
  const totalBodyStrikesAttempted = fighterStats.reduce((sum, stat) => sum + (stat.body_strikes_attempted || 0), 0);
  const totalLegStrikes = fighterStats.reduce((sum, stat) => sum + (stat.leg_strikes || 0), 0);
  const totalLegStrikesAttempted = fighterStats.reduce((sum, stat) => sum + (stat.leg_strikes_attempted || 0), 0);
  const totalSubmissionAttempts = fighterStats.reduce((sum, stat) => sum + (stat.submission_attempts || 0), 0);
  const totalReversals = fighterStats.reduce((sum, stat) => sum + (stat.reversals || 0), 0);
  const totalControlTime = fighterStats.reduce((sum, stat) => sum + (stat.control_time_seconds || 0), 0);

  return (
    <div className="bg-white rounded-lg shadow-sm overflow-hidden">
      {/* Main Fight Info */}
      <div 
        className="p-4 cursor-pointer hover:bg-gray-50 transition-colors"
        onClick={onToggleExpanded}
      >
        <div className="flex items-center justify-between">
          <div className="flex-1">
            <div className="flex items-center gap-4 mb-2">
              <span className={`px-3 py-1 rounded-full text-sm font-bold ${resultClass}`}>
                {resultText}
              </span>
              <span className="text-lg font-semibold text-gray-900">
                vs {opponent}
              </span>
            </div>
            
            <div className="flex flex-wrap items-center gap-4 text-sm text-gray-600">
              <span>{fight.event?.name}</span>
              <span>•</span>
              <span>{formatDate(fight.event?.date || '')}</span>
              <span>•</span>
              <span>{fight.weight_class}</span>
            </div>
            
            <div className="mt-2 text-sm">
              <span className="font-medium text-gray-700">
                {fight.method} - Round {fight.round}, {fight.time}
              </span>
            </div>
          </div>
          
          <div className="ml-4">
            <svg 
              className={`w-5 h-5 text-gray-400 transition-transform ${isExpanded ? 'rotate-180' : ''}`}
              fill="none" 
              viewBox="0 0 24 24" 
              stroke="currentColor"
            >
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
            </svg>
          </div>
        </div>
        
        {/* Quick Stats Summary */}
        <div className="mt-3 flex gap-6 text-sm text-gray-600">
          <span>
            Strikes: {totalStrikes}/{totalStrikesAttempted} 
            ({totalStrikesAttempted > 0 ? `${((totalStrikes / totalStrikesAttempted) * 100).toFixed(0)}%` : '0%'})
          </span>
          <span>
            Takedowns: {totalTakedowns}/{totalTakedownsAttempted}
            ({totalTakedownsAttempted > 0 ? `${((totalTakedowns / totalTakedownsAttempted) * 100).toFixed(0)}%` : '0%'})
          </span>
        </div>
      </div>
      
      {/* Expanded Details */}
      {isExpanded && (
        <div className="border-t border-gray-200 p-4 bg-gray-50">
          {fighterStats.length === 0 ? (
            <p className="text-gray-500 text-sm">No detailed statistics available for this fight.</p>
          ) : (
            <>
              {/* Fight Totals */}
              <div className="mb-6">
                <h4 className="font-semibold text-gray-900 mb-3">Fight Totals</h4>
                <div className="bg-white rounded p-4">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {/* Total Striking Stats */}
                    <div>
                      <p className="font-medium text-gray-700 mb-2">Striking</p>
                      <div className="space-y-1 text-sm text-gray-600">
                        <div>Significant Strikes: {totalSignificantStrikes}/{totalSignificantStrikesAttempted} ({totalSignificantStrikesAttempted > 0 ? `${Math.round((totalSignificantStrikes / totalSignificantStrikesAttempted) * 100)}%` : '0%'})</div>
                        <div>Total Strikes: {totalStrikes}/{totalStrikesAttempted} ({totalStrikesAttempted > 0 ? `${Math.round((totalStrikes / totalStrikesAttempted) * 100)}%` : '0%'})</div>
                        {totalKnockdowns > 0 && (
                          <div className="text-red-600 font-medium">Knockdowns: {totalKnockdowns}</div>
                        )}
                        {/* Strike Targets Totals */}
                        <div className="mt-2 pl-2 border-l-2 border-gray-200">
                          <p className="text-xs font-medium text-gray-700 mb-1">By Target:</p>
                          <div className="space-y-0.5 text-xs">
                            <div>Head: {totalHeadStrikes}/{totalHeadStrikesAttempted}</div>
                            <div>Body: {totalBodyStrikes}/{totalBodyStrikesAttempted}</div>
                            <div>Legs: {totalLegStrikes}/{totalLegStrikesAttempted}</div>
                          </div>
                        </div>
                      </div>
                    </div>
                    
                    {/* Total Grappling Stats */}
                    <div>
                      <p className="font-medium text-gray-700 mb-2">Grappling</p>
                      <div className="space-y-1 text-sm text-gray-600">
                        <div>Takedowns: {totalTakedowns}/{totalTakedownsAttempted} ({totalTakedownsAttempted > 0 ? `${Math.round((totalTakedowns / totalTakedownsAttempted) * 100)}%` : '0%'})</div>
                        <div>Submission Attempts: {totalSubmissionAttempts}</div>
                        <div>Reversals: {totalReversals}</div>
                        {totalControlTime > 0 && (
                          <div>Control Time: {Math.floor(totalControlTime / 60)}:{(totalControlTime % 60).toString().padStart(2, '0')}</div>
                        )}
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Round by Round */}
              <h4 className="font-semibold text-gray-900 mb-3">Round-by-Round Breakdown</h4>
              <div className="space-y-4">
              {fighterStats.map((roundStat, index) => {
                const opponentRoundStat = opponentStats.find(s => s.round === roundStat.round);
                
                return (
                  <div key={index} className="bg-white rounded p-3">
                    <h5 className="font-medium text-gray-800 mb-2">Round {roundStat.round}</h5>
                    
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                      {/* Striking Stats */}
                      <div>
                        <p className="font-medium text-gray-700 mb-2">Striking</p>
                        <div className="space-y-1 text-gray-600">
                          <div>Significant Strikes: {roundStat.significant_strikes}/{roundStat.significant_strikes_attempted} ({roundStat.significant_strikes_attempted > 0 ? `${Math.round((roundStat.significant_strikes / roundStat.significant_strikes_attempted) * 100)}%` : '0%'})</div>
                          <div>Total Strikes: {roundStat.total_strikes}/{roundStat.total_strikes_attempted} ({roundStat.total_strikes_attempted > 0 ? `${Math.round((roundStat.total_strikes / roundStat.total_strikes_attempted) * 100)}%` : '0%'})</div>
                          {roundStat.knockdowns > 0 && (
                            <div className="text-red-600 font-medium">Knockdowns: {roundStat.knockdowns}</div>
                          )}
                          {/* Strike Targets */}
                          {(roundStat.head_strikes || roundStat.body_strikes || roundStat.leg_strikes) && (
                            <div className="mt-2 pl-2 border-l-2 border-gray-200">
                              <p className="text-xs font-medium text-gray-700 mb-1">By Target:</p>
                              <div className="space-y-0.5 text-xs">
                                <div>Head: {roundStat.head_strikes || 0}/{roundStat.head_strikes_attempted || 0}</div>
                                <div>Body: {roundStat.body_strikes || 0}/{roundStat.body_strikes_attempted || 0}</div>
                                <div>Legs: {roundStat.leg_strikes || 0}/{roundStat.leg_strikes_attempted || 0}</div>
                              </div>
                            </div>
                          )}
                        </div>
                      </div>
                      
                      {/* Grappling Stats */}
                      <div>
                        <p className="font-medium text-gray-700 mb-2">Grappling</p>
                        <div className="space-y-1 text-gray-600">
                          <div>Takedowns: {roundStat.takedowns}/{roundStat.takedowns_attempted} ({roundStat.takedowns_attempted > 0 ? `${Math.round((roundStat.takedowns / roundStat.takedowns_attempted) * 100)}%` : '0%'})</div>
                          <div>Submission Attempts: {roundStat.submission_attempts}</div>
                          <div>Reversals: {roundStat.reversals}</div>
                          {roundStat.control_time_seconds > 0 && (
                            <div>Control Time: {Math.floor(roundStat.control_time_seconds / 60)}:{(roundStat.control_time_seconds % 60).toString().padStart(2, '0')}</div>
                          )}
                        </div>
                      </div>
                    </div>
                  </div>
                );
              })}
              </div>
            </>
          )}
          
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
    </div>
  );
}