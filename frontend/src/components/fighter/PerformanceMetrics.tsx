import React from 'react';
import { Fighter } from '@/types/api';

interface PerformanceMetricsProps {
  fighter: Fighter;
}

interface FinishStats {
  koTko: number;
  submission: number;
  decision: number;
  total: number;
}

function calculateFinishStats(fighter: Fighter): FinishStats {
  const stats: FinishStats = {
    koTko: 0,
    submission: 0,
    decision: 0,
    total: 0
  };

  if (!fighter.fights) return stats;

  fighter.fights.forEach((fight) => {
    // Determine if fighter won
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
    
    const outcomes = fight.outcome.split('/');
    
    if (outcomes.length === 2) {
      const fighterOutcome = outcomes[fighterPosition];
      
      if (fighterOutcome === 'W') {
        stats.total++;
        
        const method = fight.method.toLowerCase();
        if (method.includes('ko') || method.includes('tko')) {
          stats.koTko++;
        } else if (method.includes('submission')) {
          stats.submission++;
        } else if (method.includes('decision')) {
          stats.decision++;
        }
      }
    }
  });

  return stats;
}

function calculateAverageFightTime(fighter: Fighter): string {
  if (!fighter.fights || fighter.fights.length === 0) return 'N/A';

  let totalSeconds = 0;
  let validFights = 0;

  fighter.fights.forEach((fight) => {
    if (fight.round && fight.time) {
      // Parse time (format: "M:SS")
      const [minutes, seconds] = fight.time.split(':').map(Number);
      if (!isNaN(minutes) && !isNaN(seconds)) {
        // Calculate total seconds: completed rounds + time in final round
        const completedRounds = fight.round - 1;
        const secondsFromCompletedRounds = completedRounds * 5 * 60; // 5 minutes per round
        const secondsInFinalRound = minutes * 60 + seconds;
        totalSeconds += secondsFromCompletedRounds + secondsInFinalRound;
        validFights++;
      }
    }
  });

  if (validFights === 0) return 'N/A';

  const avgSeconds = totalSeconds / validFights;
  const avgMinutes = Math.floor(avgSeconds / 60);
  const remainingSeconds = Math.round(avgSeconds % 60);
  
  return `${avgMinutes}:${remainingSeconds.toString().padStart(2, '0')}`;
}

function calculateRoundsPerFight(fighter: Fighter): string {
  if (!fighter.fights || fighter.fights.length === 0) return 'N/A';

  const totalRounds = fighter.fights.reduce((sum, fight) => {
    return sum + (fight.round || 0);
  }, 0);

  const avgRounds = totalRounds / fighter.fights.length;
  return avgRounds.toFixed(1);
}

export function PerformanceMetrics({ fighter }: PerformanceMetricsProps) {
  const finishStats = calculateFinishStats(fighter);
  const avgFightTime = calculateAverageFightTime(fighter);
  const avgRounds = calculateRoundsPerFight(fighter);
  const finishRate = finishStats.total > 0 
    ? ((finishStats.koTko + finishStats.submission) / finishStats.total * 100).toFixed(0)
    : '0';

  const metrics = [
    {
      label: 'Finish Rate',
      value: `${finishRate}%`,
      subLabel: `${finishStats.koTko + finishStats.submission} of ${finishStats.total} wins`,
      color: 'text-green-600',
    },
    {
      label: 'Avg Fight Time',
      value: avgFightTime,
      subLabel: `${avgRounds} rounds average`,
      color: 'text-blue-600',
    },
    {
      label: 'Win Methods',
      value: `${finishStats.koTko} KO/TKO`,
      subLabel: `${finishStats.submission} SUB, ${finishStats.decision} DEC`,
      color: 'text-purple-600',
    },
  ];

  return (
    <div 
      data-testid="performance-metrics"
      className="bg-white rounded-lg p-6 shadow-sm"
    >
      <h2 className="text-xl font-bold text-gray-900 mb-4">Performance Metrics</h2>
      
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
        {metrics.map((metric) => (
          <div key={metric.label} className="text-center">
            <div className={`text-2xl font-bold ${metric.color}`}>
              {metric.value}
            </div>
            <div className="text-sm font-medium text-gray-700 mt-1">
              {metric.label}
            </div>
            <div className="text-xs text-gray-500 mt-1">
              {metric.subLabel}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}