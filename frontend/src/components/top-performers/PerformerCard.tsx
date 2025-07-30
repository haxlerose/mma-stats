'use client';

import React from 'react';
import Link from 'next/link';
import { TopPerformer, TopPerformerScope, TopPerformerCategory } from '@/types/api';

interface PerformerCardProps {
  performer: TopPerformer;
  rank: number;
  scope: TopPerformerScope;
  category: TopPerformerCategory;
}

export function PerformerCard({ performer, rank, scope, category }: PerformerCardProps) {
  // Helper to format control time from seconds to MM:SS
  const formatControlTime = (seconds: number): string => {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
  };

  // Helper to get the value based on scope and category
  const getValue = (): string => {
    if (scope === 'accuracy') {
      const value = performer.accuracy_percentage ?? performer.value;
      return typeof value === 'number' ? `${value.toFixed(1)}%` : '0%';
    } else if (scope === 'results') {
      if (category === 'total_wins') {
        return performer.total_wins?.toString() || '0';
      } else if (category === 'total_losses') {
        return performer.total_losses?.toString() || '0';
      } else if (category === 'win_percentage') {
        const percentage = performer.win_percentage;
        return typeof percentage === 'number' ? `${percentage.toFixed(1)}%` : '0%';
      } else if (category === 'longest_win_streak') {
        return performer.longest_win_streak?.toString() || '0';
      }
      return '0';
    } else if (scope === 'career') {
      const value = performer[`total_${category}` as keyof TopPerformer];
      if (category === 'control_time_seconds' && typeof value === 'number') {
        return formatControlTime(value);
      }
      return value?.toString() || '0';
    } else if (scope === 'fight' || scope === 'round') {
      const value = performer[`max_${category}` as keyof TopPerformer];
      if (category === 'control_time_seconds' && typeof value === 'number') {
        return formatControlTime(value);
      }
      return value?.toString() || '0';
    } else if (scope === 'per_minute') {
      const value = performer[`${category}_per_15_minutes` as keyof TopPerformer];
      if (category === 'control_time_seconds' && typeof value === 'number') {
        return formatControlTime(Math.round(value));
      }
      return typeof value === 'number' ? value.toFixed(2) : '0';
    }
    return '0';
  };

  // Helper to get label suffix based on scope
  const getLabelSuffix = (): string => {
    if (scope === 'per_minute') return ' per 15 min';
    if (category === 'control_time_seconds') return '';
    return '';
  };

  // Helper to get rank styling
  const getRankClasses = (): string => {
    switch (rank) {
      case 1:
        return 'bg-gradient-to-r from-yellow-400 to-amber-500 text-white';
      case 2:
        return 'bg-gradient-to-r from-gray-300 to-gray-400 text-white';
      case 3:
        return 'bg-gradient-to-r from-orange-400 to-orange-500 text-white';
      default:
        return 'bg-gray-100 text-gray-700';
    }
  };

  // Helper to get card border styling
  const getCardClasses = (): string => {
    switch (rank) {
      case 1:
        return 'border-yellow-400 shadow-lg';
      case 2:
        return 'border-gray-400 shadow-md';
      case 3:
        return 'border-orange-400 shadow-md';
      default:
        return 'border-gray-200';
    }
  };

  return (
    <div 
      className={`
        bg-white rounded-lg border-2 p-4 transition-transform hover:scale-105
        ${getCardClasses()}
      `}
    >
      <div className="flex items-start justify-between mb-3">
        <div className="flex items-center space-x-3">
          <div 
            className={`
              w-10 h-10 rounded-full flex items-center justify-center font-bold text-lg
              ${getRankClasses()}
            `}
          >
            {rank}
          </div>
          <div>
            <Link
              href={`/fighters/${performer.fighter_id}`}
              className="text-lg font-semibold text-gray-900 hover:text-blue-600 transition-colors"
            >
              {performer.fighter_name}
            </Link>
          </div>
        </div>
      </div>

      <div className="text-center py-3">
        <div className="text-3xl font-bold text-gray-900">
          {getValue()}{getLabelSuffix()}
        </div>
      </div>

      {/* Additional context based on scope */}
      {(scope === 'fight' || scope === 'round') && performer.event_name && (
        <div className="mt-3 pt-3 border-t border-gray-100 text-sm text-gray-600">
          <div className="space-y-1">
            {performer.opponent_name && (
              <p>
                <span className="font-medium">vs.</span> {performer.opponent_name}
              </p>
            )}
            <p className="truncate" title={performer.event_name}>
              {performer.event_name}
            </p>
            {scope === 'round' && performer.round && (
              <p className="font-medium">Round {performer.round}</p>
            )}
          </div>
        </div>
      )}

      {/* Per minute context */}
      {scope === 'per_minute' && performer.fight_duration_minutes && (
        <div className="mt-3 pt-3 border-t border-gray-100 text-sm text-gray-600">
          <p>
            <span className="font-medium">Fight time:</span> {performer.fight_duration_minutes.toFixed(1)} minutes
          </p>
          {performer[`total_${category}` as keyof TopPerformer] && (
            <p>
              <span className="font-medium">Total:</span> {
                category === 'control_time_seconds' && typeof performer[`total_${category}` as keyof TopPerformer] === 'number'
                  ? formatControlTime(performer[`total_${category}` as keyof TopPerformer] as number)
                  : performer[`total_${category}` as keyof TopPerformer]
              }
            </p>
          )}
        </div>
      )}

      {/* Accuracy context */}
      {scope === 'accuracy' && (
        <div className="mt-3 pt-3 border-t border-gray-100 text-sm text-gray-600">
          <div className="space-y-1">
            <p>
              <span className="font-medium">Landed:</span> {
                (() => {
                  // Map accuracy category to corresponding landed stat
                  const landedStatMap: Record<string, keyof TopPerformer> = {
                    'significant_strike_accuracy': 'total_significant_strikes',
                    'total_strike_accuracy': 'total_total_strikes',
                    'head_strike_accuracy': 'total_head_strikes',
                    'body_strike_accuracy': 'total_body_strikes',
                    'leg_strike_accuracy': 'total_leg_strikes',
                    'distance_strike_accuracy': 'total_distance_strikes',
                    'clinch_strike_accuracy': 'total_clinch_strikes',
                    'ground_strike_accuracy': 'total_ground_strikes',
                    'takedown_accuracy': 'total_takedowns',
                  };
                  const landedKey = landedStatMap[category];
                  return landedKey ? (performer[landedKey] || 0) : 0;
                })()
              }
            </p>
            <p>
              <span className="font-medium">Attempted:</span> {
                (() => {
                  // Map accuracy category to corresponding attempted stat
                  const attemptedStatMap: Record<string, keyof TopPerformer> = {
                    'significant_strike_accuracy': 'total_significant_strikes_attempted',
                    'total_strike_accuracy': 'total_total_strikes_attempted',
                    'head_strike_accuracy': 'total_head_strikes_attempted',
                    'body_strike_accuracy': 'total_body_strikes_attempted',
                    'leg_strike_accuracy': 'total_leg_strikes_attempted',
                    'distance_strike_accuracy': 'total_distance_strikes_attempted',
                    'clinch_strike_accuracy': 'total_clinch_strikes_attempted',
                    'ground_strike_accuracy': 'total_ground_strikes_attempted',
                    'takedown_accuracy': 'total_takedowns_attempted',
                  };
                  const attemptedKey = attemptedStatMap[category];
                  return attemptedKey ? (performer[attemptedKey] || 0) : 0;
                })()
              }
            </p>
            <p>
              <span className="font-medium">Fight count:</span> {performer.total_fights || 0}
            </p>
          </div>
        </div>
      )}

      {/* Results context */}
      {scope === 'results' && (
        <div className="mt-3 pt-3 border-t border-gray-100 text-sm text-gray-600">
          <div className="space-y-1">
            {category === 'win_percentage' && (
              <>
                <p>
                  <span className="font-medium">Wins:</span> {performer.total_wins || 0}
                </p>
                <p>
                  <span className="font-medium">Losses:</span> {performer.total_losses || 0}
                </p>
                <p>
                  <span className="font-medium">Total fights:</span> {(performer.total_wins || 0) + (performer.total_losses || 0)}
                </p>
              </>
            )}
            {category === 'longest_win_streak' && performer.total_wins !== undefined && (
              <p>
                <span className="font-medium">Career wins:</span> {performer.total_wins}
              </p>
            )}
            {(category === 'total_wins' || category === 'total_losses') && (
              <p>
                <span className="font-medium">Win rate:</span> {
                  performer.win_percentage !== undefined 
                    ? `${performer.win_percentage.toFixed(1)}%` 
                    : 'N/A'
                }
              </p>
            )}
          </div>
        </div>
      )}
    </div>
  );
}