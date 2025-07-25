import React from 'react';
import Link from 'next/link';
import { Fight, FightStat } from '@/types/api';

interface FightStatsOverviewProps {
  fight: Fight;
}

interface FighterTotals {
  name: string;
  fighterId: number;
  significantStrikes: number;
  significantStrikesAttempted: number;
  totalStrikes: number;
  totalStrikesAttempted: number;
  takedowns: number;
  takedownsAttempted: number;
  knockdowns: number;
  submissionAttempts: number;
  reversals: number;
  controlTimeSeconds: number;
  headStrikes: number;
  bodyStrikes: number;
  legStrikes: number;
}

function calculateFighterTotals(stats: FightStat[], fighterId: number, fighterName: string): FighterTotals {
  const fighterStats = stats.filter(stat => stat.fighter_id === fighterId);
  
  return fighterStats.reduce((totals, stat) => ({
    ...totals,
    significantStrikes: totals.significantStrikes + (stat.significant_strikes || 0),
    significantStrikesAttempted: totals.significantStrikesAttempted + (stat.significant_strikes_attempted || 0),
    totalStrikes: totals.totalStrikes + (stat.total_strikes || 0),
    totalStrikesAttempted: totals.totalStrikesAttempted + (stat.total_strikes_attempted || 0),
    takedowns: totals.takedowns + (stat.takedowns || 0),
    takedownsAttempted: totals.takedownsAttempted + (stat.takedowns_attempted || 0),
    knockdowns: totals.knockdowns + (stat.knockdowns || 0),
    submissionAttempts: totals.submissionAttempts + (stat.submission_attempts || 0),
    reversals: totals.reversals + (stat.reversals || 0),
    controlTimeSeconds: totals.controlTimeSeconds + (stat.control_time_seconds || 0),
    headStrikes: totals.headStrikes + (stat.head_strikes || 0),
    bodyStrikes: totals.bodyStrikes + (stat.body_strikes || 0),
    legStrikes: totals.legStrikes + (stat.leg_strikes || 0),
  }), {
    name: fighterName,
    fighterId,
    significantStrikes: 0,
    significantStrikesAttempted: 0,
    totalStrikes: 0,
    totalStrikesAttempted: 0,
    takedowns: 0,
    takedownsAttempted: 0,
    knockdowns: 0,
    submissionAttempts: 0,
    reversals: 0,
    controlTimeSeconds: 0,
    headStrikes: 0,
    bodyStrikes: 0,
    legStrikes: 0,
  });
}

function formatTime(seconds: number): string {
  const minutes = Math.floor(seconds / 60);
  const remainingSeconds = seconds % 60;
  return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
}

function formatAccuracy(landed: number, attempted: number): string {
  if (attempted === 0) return '0%';
  return `${Math.round((landed / attempted) * 100)}%`;
}

function StatComparison({ 
  label, 
  value1, 
  value2, 
  total1, 
  total2,
  showPercentage = false 
}: { 
  label: string; 
  value1: number; 
  value2: number;
  total1?: number;
  total2?: number;
  showPercentage?: boolean;
}) {
  const max = Math.max(value1, value2);
  const width1 = max > 0 ? (value1 / max) * 100 : 0;
  const width2 = max > 0 ? (value2 / max) * 100 : 0;
  
  return (
    <div className="mb-4">
      <div className="text-sm font-medium text-gray-700 mb-2 text-center">{label}</div>
      <div className="grid grid-cols-5 gap-2 items-center">
        {/* Fighter 1 Stats */}
        <div className="text-right">
          <span className="font-semibold text-gray-900">{value1}</span>
          {total1 !== undefined && (
            <span className="text-gray-700 text-sm">/{total1}</span>
          )}
          {showPercentage && total1 !== undefined && (
            <span className="text-gray-700 text-sm ml-1">
              ({formatAccuracy(value1, total1)})
            </span>
          )}
        </div>
        
        {/* Visual Bars */}
        <div className="col-span-3 relative h-8">
          {/* Fighter 1 Bar */}
          <div 
            className="absolute right-1/2 pr-1 h-full flex items-center justify-end"
            style={{ width: '50%' }}
          >
            <div 
              className="bg-blue-500 h-6 rounded-l"
              style={{ width: `${width1}%` }}
            />
          </div>
          
          {/* Fighter 2 Bar */}
          <div 
            className="absolute left-1/2 pl-1 h-full flex items-center"
            style={{ width: '50%' }}
          >
            <div 
              className="bg-red-500 h-6 rounded-r"
              style={{ width: `${width2}%` }}
            />
          </div>
          
          {/* Center line */}
          <div className="absolute left-1/2 top-0 bottom-0 w-px bg-gray-300" />
        </div>
        
        {/* Fighter 2 Stats */}
        <div className="text-left">
          <span className="font-semibold text-gray-900">{value2}</span>
          {total2 !== undefined && (
            <span className="text-gray-700 text-sm">/{total2}</span>
          )}
          {showPercentage && total2 !== undefined && (
            <span className="text-gray-700 text-sm ml-1">
              ({formatAccuracy(value2, total2)})
            </span>
          )}
        </div>
      </div>
    </div>
  );
}

export function FightStatsOverview({ fight }: FightStatsOverviewProps) {
  const fighter1 = fight.fighters?.[0];
  const fighter2 = fight.fighters?.[1];
  
  if (!fighter1 || !fighter2 || !fight.fight_stats) return null;
  
  const fighter1Totals = calculateFighterTotals(fight.fight_stats, fighter1.id, fighter1.name);
  const fighter2Totals = calculateFighterTotals(fight.fight_stats, fighter2.id, fighter2.name);

  return (
    <div 
      data-testid="fight-stats-overview"
      className="bg-white rounded-lg p-6 shadow-sm"
    >
      <h2 className="text-xl font-bold text-gray-900 mb-6 text-center">Fight Statistics</h2>
      
      {/* Fighter Names */}
      <div className="grid grid-cols-5 mb-6">
        <div className="text-right pr-2">
          <Link 
            href={`/fighters/${fighter1.slug}`}
            className="text-blue-600 font-bold hover:text-blue-800 hover:underline"
          >
            {fighter1.name}
          </Link>
        </div>
        <div className="col-span-3 text-center text-gray-700 font-medium">
          vs
        </div>
        <div className="text-left pl-2">
          <Link 
            href={`/fighters/${fighter2.slug}`}
            className="text-red-600 font-bold hover:text-red-800 hover:underline"
          >
            {fighter2.name}
          </Link>
        </div>
      </div>
      
      {/* Striking Stats */}
      <div className="mb-6">
        <h3 className="text-lg font-semibold text-gray-800 mb-4">Striking</h3>
        
        {(fighter1Totals.knockdowns > 0 || fighter2Totals.knockdowns > 0) && (
          <StatComparison 
            label="Knockdowns"
            value1={fighter1Totals.knockdowns}
            value2={fighter2Totals.knockdowns}
          />
        )}
        
        <StatComparison 
          label="Significant Strikes"
          value1={fighter1Totals.significantStrikes}
          value2={fighter2Totals.significantStrikes}
          total1={fighter1Totals.significantStrikesAttempted}
          total2={fighter2Totals.significantStrikesAttempted}
          showPercentage
        />
        
        <StatComparison 
          label="Total Strikes"
          value1={fighter1Totals.totalStrikes}
          value2={fighter2Totals.totalStrikes}
          total1={fighter1Totals.totalStrikesAttempted}
          total2={fighter2Totals.totalStrikesAttempted}
          showPercentage
        />
        
        {/* Strike Targets */}
        <div className="mt-4 pt-4 border-t border-gray-200">
          <div className="text-sm font-medium text-gray-700 mb-3 text-center">Strike Targets</div>
          <div className="grid grid-cols-3 gap-4 text-sm">
            <div>
              <StatComparison 
                label="Head"
                value1={fighter1Totals.headStrikes}
                value2={fighter2Totals.headStrikes}
              />
            </div>
            <div>
              <StatComparison 
                label="Body"
                value1={fighter1Totals.bodyStrikes}
                value2={fighter2Totals.bodyStrikes}
              />
            </div>
            <div>
              <StatComparison 
                label="Legs"
                value1={fighter1Totals.legStrikes}
                value2={fighter2Totals.legStrikes}
              />
            </div>
          </div>
        </div>
      </div>
      
      {/* Grappling Stats */}
      <div className="pt-6 border-t border-gray-200">
        <h3 className="text-lg font-semibold text-gray-800 mb-4">Grappling</h3>
        
        <StatComparison 
          label="Takedowns"
          value1={fighter1Totals.takedowns}
          value2={fighter2Totals.takedowns}
          total1={fighter1Totals.takedownsAttempted}
          total2={fighter2Totals.takedownsAttempted}
          showPercentage
        />
        
        {(fighter1Totals.submissionAttempts > 0 || fighter2Totals.submissionAttempts > 0) && (
          <StatComparison 
            label="Submission Attempts"
            value1={fighter1Totals.submissionAttempts}
            value2={fighter2Totals.submissionAttempts}
          />
        )}
        
        {(fighter1Totals.reversals > 0 || fighter2Totals.reversals > 0) && (
          <StatComparison 
            label="Reversals"
            value1={fighter1Totals.reversals}
            value2={fighter2Totals.reversals}
          />
        )}
        
        <div className="mt-4">
          <div className="text-sm font-medium text-gray-700 mb-2 text-center">Control Time</div>
          <div className="grid grid-cols-5 gap-2 items-center">
            <div className="text-right font-semibold text-gray-900">
              {formatTime(fighter1Totals.controlTimeSeconds)}
            </div>
            <div className="col-span-3 text-center text-gray-700">-</div>
            <div className="text-left font-semibold text-gray-900">
              {formatTime(fighter2Totals.controlTimeSeconds)}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}