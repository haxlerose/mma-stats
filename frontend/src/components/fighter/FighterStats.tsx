import React from 'react';
import { Fighter } from '@/types/api';

interface FighterStatsProps {
  fighter: Fighter;
}

interface CareerStats {
  // Striking
  totalStrikesLanded: number;
  totalStrikesAttempted: number;
  significantStrikesLanded: number;
  significantStrikesAttempted: number;
  knockdowns: number;
  
  // Target breakdown
  headStrikesLanded: number;
  headStrikesAttempted: number;
  bodyStrikesLanded: number;
  bodyStrikesAttempted: number;
  legStrikesLanded: number;
  legStrikesAttempted: number;
  
  // Grappling
  takedownsLanded: number;
  takedownsAttempted: number;
  submissionAttempts: number;
  reversals: number;
  controlTimeSeconds: number;
  
  // Fights
  totalFights: number;
  totalRounds: number;
}

function calculateCareerStats(fighter: Fighter): CareerStats {
  const stats: CareerStats = {
    totalStrikesLanded: 0,
    totalStrikesAttempted: 0,
    significantStrikesLanded: 0,
    significantStrikesAttempted: 0,
    knockdowns: 0,
    headStrikesLanded: 0,
    headStrikesAttempted: 0,
    bodyStrikesLanded: 0,
    bodyStrikesAttempted: 0,
    legStrikesLanded: 0,
    legStrikesAttempted: 0,
    takedownsLanded: 0,
    takedownsAttempted: 0,
    submissionAttempts: 0,
    reversals: 0,
    controlTimeSeconds: 0,
    totalFights: 0,
    totalRounds: 0,
  };

  if (!fighter.fights) return stats;

  fighter.fights.forEach((fight) => {
    stats.totalFights++;
    
    // All fight_stats from the fighter endpoint are for this fighter
    const fighterStats = fight.fight_stats || [];
    
    fighterStats.forEach((roundStats) => {
      stats.totalRounds++;
      
      // Striking
      stats.totalStrikesLanded += roundStats.total_strikes || 0;
      stats.totalStrikesAttempted += roundStats.total_strikes_attempted || 0;
      stats.significantStrikesLanded += roundStats.significant_strikes || 0;
      stats.significantStrikesAttempted += roundStats.significant_strikes_attempted || 0;
      stats.knockdowns += roundStats.knockdowns || 0;
      
      // Target breakdown
      stats.headStrikesLanded += roundStats.head_strikes || 0;
      stats.headStrikesAttempted += roundStats.head_strikes_attempted || 0;
      stats.bodyStrikesLanded += roundStats.body_strikes || 0;
      stats.bodyStrikesAttempted += roundStats.body_strikes_attempted || 0;
      stats.legStrikesLanded += roundStats.leg_strikes || 0;
      stats.legStrikesAttempted += roundStats.leg_strikes_attempted || 0;
      
      // Grappling
      stats.takedownsLanded += roundStats.takedowns || 0;
      stats.takedownsAttempted += roundStats.takedowns_attempted || 0;
      stats.submissionAttempts += roundStats.submission_attempts || 0;
      stats.reversals += roundStats.reversals || 0;
      stats.controlTimeSeconds += roundStats.control_time_seconds || 0;
    });
  });

  return stats;
}

function formatAccuracy(landed: number, attempted: number): string {
  if (attempted === 0) return '0%';
  return `${((landed / attempted) * 100).toFixed(0)}%`;
}

function formatTime(seconds: number): string {
  const minutes = Math.floor(seconds / 60);
  const remainingSeconds = seconds % 60;
  return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
}

export function FighterStats({ fighter }: FighterStatsProps) {
  const stats = calculateCareerStats(fighter);
  
  const strikingAccuracy = formatAccuracy(stats.totalStrikesLanded, stats.totalStrikesAttempted);
  const significantAccuracy = formatAccuracy(stats.significantStrikesLanded, stats.significantStrikesAttempted);
  const takedownAccuracy = formatAccuracy(stats.takedownsLanded, stats.takedownsAttempted);
  
  const strikesPerRound = stats.totalRounds > 0 
    ? (stats.totalStrikesLanded / stats.totalRounds).toFixed(1)
    : '0.0';
  const significantPerRound = stats.totalRounds > 0 
    ? (stats.significantStrikesLanded / stats.totalRounds).toFixed(1)
    : '0.0';

  return (
    <div 
      data-testid="fighter-stats"
      className="bg-white rounded-lg p-6 shadow-sm"
    >
      <h2 className="text-xl font-bold text-gray-900 mb-6">Career Statistics</h2>
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
        {/* Striking Statistics */}
        <div>
          <h3 className="text-lg font-semibold text-gray-800 mb-4 flex items-center">
            <span className="mr-2">👊</span>
            Striking
          </h3>
          
          <div className="space-y-3">
            <div className="flex justify-between items-center">
              <span className="text-gray-700">Total Strikes</span>
              <span className="font-medium text-gray-900">
                {stats.totalStrikesLanded}/{stats.totalStrikesAttempted} ({strikingAccuracy})
              </span>
            </div>
            
            <div className="flex justify-between items-center">
              <span className="text-gray-700 font-medium">Significant Strikes</span>
              <span className="font-semibold text-gray-900">
                {stats.significantStrikesLanded}/{stats.significantStrikesAttempted} ({significantAccuracy})
              </span>
            </div>
            
            <div className="flex justify-between items-center">
              <span className="text-gray-700 font-medium">Strikes per Round</span>
              <span className="font-semibold text-gray-900">{strikesPerRound}</span>
            </div>
            
            <div className="flex justify-between items-center">
              <span className="text-gray-700 font-medium">Sig. Strikes per Round</span>
              <span className="font-semibold text-gray-900">{significantPerRound}</span>
            </div>
            
            <div className="flex justify-between items-center">
              <span className="text-gray-700 font-medium">Knockdowns</span>
              <span className="font-semibold text-gray-900">{stats.knockdowns}</span>
            </div>
            
            {/* Strike Target Breakdown */}
            <div className="mt-4 pt-4 border-t border-gray-200">
              <p className="text-sm font-medium text-gray-700 mb-2">Strike Targets</p>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between">
                  <span className="text-gray-700 font-medium">Head</span>
                  <span className="font-medium text-gray-800">{stats.headStrikesLanded}/{stats.headStrikesAttempted} ({formatAccuracy(stats.headStrikesLanded, stats.headStrikesAttempted)})</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-700 font-medium">Body</span>
                  <span className="font-medium text-gray-800">{stats.bodyStrikesLanded}/{stats.bodyStrikesAttempted} ({formatAccuracy(stats.bodyStrikesLanded, stats.bodyStrikesAttempted)})</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-700 font-medium">Legs</span>
                  <span className="font-medium text-gray-800">{stats.legStrikesLanded}/{stats.legStrikesAttempted} ({formatAccuracy(stats.legStrikesLanded, stats.legStrikesAttempted)})</span>
                </div>
              </div>
            </div>
          </div>
        </div>
        
        {/* Grappling Statistics */}
        <div>
          <h3 className="text-lg font-semibold text-gray-800 mb-4 flex items-center">
            <span className="mr-2">🤼</span>
            Grappling
          </h3>
          
          <div className="space-y-3">
            <div className="flex justify-between items-center">
              <span className="text-gray-700 font-medium">Takedowns</span>
              <span className="font-semibold text-gray-900">
                {stats.takedownsLanded}/{stats.takedownsAttempted} ({takedownAccuracy})
              </span>
            </div>
            
            <div className="flex justify-between items-center">
              <span className="text-gray-700 font-medium">Takedowns per Fight</span>
              <span className="font-semibold text-gray-900">
                {stats.totalFights > 0 ? (stats.takedownsLanded / stats.totalFights).toFixed(1) : '0.0'}
              </span>
            </div>
            
            <div className="flex justify-between items-center">
              <span className="text-gray-700 font-medium">Submission Attempts</span>
              <span className="font-semibold text-gray-900">{stats.submissionAttempts}</span>
            </div>
            
            <div className="flex justify-between items-center">
              <span className="text-gray-700 font-medium">Reversals</span>
              <span className="font-semibold text-gray-900">{stats.reversals}</span>
            </div>
            
            <div className="flex justify-between items-center">
              <span className="text-gray-700 font-medium">Total Control Time</span>
              <span className="font-semibold text-gray-900">{formatTime(stats.controlTimeSeconds)}</span>
            </div>
            
            <div className="flex justify-between items-center">
              <span className="text-gray-700 font-medium">Avg Control per Fight</span>
              <span className="font-semibold text-gray-900">
                {stats.totalFights > 0 ? formatTime(Math.round(stats.controlTimeSeconds / stats.totalFights)) : '0:00'}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}