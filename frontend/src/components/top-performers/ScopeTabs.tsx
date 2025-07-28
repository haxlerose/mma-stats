'use client';

import React from 'react';
import { TopPerformerScope } from '@/types/api';

interface ScopeTabsProps {
  activeScope: TopPerformerScope;
  onScopeChange: (scope: TopPerformerScope) => void;
}

interface ScopeTab {
  value: TopPerformerScope;
  label: string;
  description: string;
}

const scopeTabs: ScopeTab[] = [
  {
    value: 'career',
    label: 'Career',
    description: 'Total career statistics',
  },
  {
    value: 'fight',
    label: 'Fight',
    description: 'Best single fight performance',
  },
  {
    value: 'round',
    label: 'Round',
    description: 'Best single round performance',
  },
  {
    value: 'per_minute',
    label: 'Per 15 min',
    description: 'Rate per 15 minutes',
  },
  {
    value: 'accuracy',
    label: 'Accuracy',
    description: 'Strike accuracy percentage',
  },
];

export function ScopeTabs({ activeScope, onScopeChange }: ScopeTabsProps) {
  return (
    <div className="w-full">
      <nav 
        className="flex space-x-1 rounded-lg bg-gray-100 p-1"
        aria-label="Scope tabs"
      >
        {scopeTabs.map((tab) => (
          <button
            key={tab.value}
            onClick={() => onScopeChange(tab.value)}
            className={`
              flex-1 rounded-md px-3 py-2 text-sm font-medium transition-colors
              ${activeScope === tab.value
                ? 'bg-white text-gray-900 shadow-sm'
                : 'text-gray-500 hover:text-gray-700'
              }
            `}
            aria-current={activeScope === tab.value ? 'page' : undefined}
            title={tab.description}
          >
            {tab.label}
          </button>
        ))}
      </nav>
    </div>
  );
}