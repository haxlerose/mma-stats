'use client';

import React, { useState, useRef, useEffect } from 'react';
import { TopPerformerCategory, TopPerformerScope } from '@/types/api';

interface CategorySelectorProps {
  activeCategory: TopPerformerCategory;
  onCategoryChange: (category: TopPerformerCategory) => void;
  scope?: TopPerformerScope;
}

interface CategoryGroup {
  label: string;
  categories: Array<{
    value: TopPerformerCategory;
    label: string;
  }>;
}

const categoryGroups: CategoryGroup[] = [
  {
    label: 'Striking',
    categories: [
      { value: 'knockdowns', label: 'Knockdowns' },
      { value: 'significant_strikes', label: 'Significant Strikes' },
      { value: 'significant_strikes_attempted', label: 'Sig. Strikes Attempted' },
      { value: 'total_strikes', label: 'Total Strikes' },
      { value: 'total_strikes_attempted', label: 'Total Strikes Attempted' },
    ],
  },
  {
    label: 'Target Strikes',
    categories: [
      { value: 'head_strikes', label: 'Head Strikes' },
      { value: 'head_strikes_attempted', label: 'Head Strikes Attempted' },
      { value: 'body_strikes', label: 'Body Strikes' },
      { value: 'body_strikes_attempted', label: 'Body Strikes Attempted' },
      { value: 'leg_strikes', label: 'Leg Strikes' },
      { value: 'leg_strikes_attempted', label: 'Leg Strikes Attempted' },
    ],
  },
  {
    label: 'Position Strikes',
    categories: [
      { value: 'distance_strikes', label: 'Distance Strikes' },
      { value: 'distance_strikes_attempted', label: 'Distance Strikes Attempted' },
      { value: 'clinch_strikes', label: 'Clinch Strikes' },
      { value: 'clinch_strikes_attempted', label: 'Clinch Strikes Attempted' },
      { value: 'ground_strikes', label: 'Ground Strikes' },
      { value: 'ground_strikes_attempted', label: 'Ground Strikes Attempted' },
    ],
  },
  {
    label: 'Grappling',
    categories: [
      { value: 'takedowns', label: 'Takedowns' },
      { value: 'takedowns_attempted', label: 'Takedowns Attempted' },
      { value: 'submission_attempts', label: 'Submission Attempts' },
      { value: 'reversals', label: 'Reversals' },
    ],
  },
  {
    label: 'Control',
    categories: [
      { value: 'control_time_seconds', label: 'Control Time' },
    ],
  },
];

export function CategorySelector({ activeCategory, onCategoryChange, scope }: CategorySelectorProps) {
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);

  // Close dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // Special handling for accuracy scope
  if (scope === 'accuracy') {
    return (
      <div className="relative" ref={dropdownRef}>
        <button
          type="button"
          disabled
          className="w-full md:w-64 px-4 py-2 text-left bg-card text-card-foreground border border-border rounded-md shadow-sm opacity-75 cursor-not-allowed"
        >
          <span className="flex items-center justify-between">
            <span className="truncate">Significant Strike Accuracy</span>
          </span>
        </button>
      </div>
    );
  }

  // Find active category label
  const activeCategoryLabel = categoryGroups
    .flatMap(group => group.categories)
    .find(cat => cat.value === activeCategory)?.label || activeCategory;

  // Handle keyboard navigation
  const handleKeyDown = (event: React.KeyboardEvent) => {
    if (event.key === 'Escape') {
      setIsOpen(false);
    }
  };

  return (
    <div className="relative" ref={dropdownRef}>
      <button
        type="button"
        onClick={() => setIsOpen(!isOpen)}
        onKeyDown={handleKeyDown}
        className="w-full md:w-64 px-4 py-2 text-left bg-card text-card-foreground border border-border rounded-md shadow-sm hover:bg-accent hover:text-accent-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:border-transparent transition-colors"
        aria-haspopup="listbox"
        aria-expanded={isOpen}
      >
        <span className="flex items-center justify-between">
          <span className="truncate">{activeCategoryLabel}</span>
          <svg
            className={`ml-2 h-5 w-5 text-muted-foreground transition-transform ${isOpen ? 'rotate-180' : ''}`}
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M19 9l-7 7-7-7"
            />
          </svg>
        </span>
      </button>

      {isOpen && (
        <div
          className="absolute z-10 mt-1 w-full md:w-64 bg-card rounded-md shadow-lg border border-border"
          role="listbox"
        >
          <div className="max-h-96 overflow-auto py-1">
            {categoryGroups.map((group) => (
              <div key={group.label}>
                <div className="px-3 py-2 text-xs font-semibold text-muted-foreground uppercase tracking-wider">
                  {group.label}
                </div>
                {group.categories.map((category) => (
                  <button
                    key={category.value}
                    onClick={() => {
                      onCategoryChange(category.value);
                      setIsOpen(false);
                    }}
                    className={`
                      w-full px-4 py-2 text-left text-sm hover:bg-accent hover:text-accent-foreground focus:bg-accent focus:text-accent-foreground focus:outline-none transition-colors
                      ${activeCategory === category.value
                        ? 'bg-primary/10 text-primary font-medium'
                        : 'text-card-foreground'
                      }
                    `}
                    role="option"
                    aria-selected={activeCategory === category.value}
                  >
                    {category.label}
                  </button>
                ))}
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}