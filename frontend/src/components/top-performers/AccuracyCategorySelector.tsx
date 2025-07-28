'use client';

import React, { useState, useRef, useEffect } from 'react';
import { TopPerformerCategory } from '@/types/api';

interface AccuracyCategorySelectorProps {
  activeCategory: TopPerformerCategory;
  onCategoryChange: (category: TopPerformerCategory) => void;
}

interface AccuracyCategory {
  value: TopPerformerCategory;
  label: string;
  description: string;
}

const accuracyCategories: AccuracyCategory[] = [
  { 
    value: 'significant_strike_accuracy', 
    label: 'Significant Strikes',
    description: 'Percentage of significant strikes that land (min. activity required)'
  },
  { 
    value: 'total_strike_accuracy', 
    label: 'Total Strikes',
    description: 'Percentage of all strikes that land (min. activity required)'
  },
  { 
    value: 'head_strike_accuracy', 
    label: 'Head Strikes',
    description: 'Percentage of head strikes that land (min. activity required)'
  },
  { 
    value: 'body_strike_accuracy', 
    label: 'Body Strikes',
    description: 'Percentage of body strikes that land (min. activity required)'
  },
  { 
    value: 'leg_strike_accuracy', 
    label: 'Leg Strikes',
    description: 'Percentage of leg strikes that land (min. activity required)'
  },
  { 
    value: 'distance_strike_accuracy', 
    label: 'Distance Strikes',
    description: 'Percentage of strikes from distance that land (min. activity required)'
  },
  { 
    value: 'clinch_strike_accuracy', 
    label: 'Clinch Strikes',
    description: 'Percentage of strikes in the clinch that land (min. activity required)'
  },
  { 
    value: 'ground_strike_accuracy', 
    label: 'Ground Strikes',
    description: 'Percentage of ground strikes that land (min. activity required)'
  },
  { 
    value: 'takedown_accuracy', 
    label: 'Takedowns',
    description: 'Percentage of takedown attempts that succeed (min. activity required)'
  },
];

export function AccuracyCategorySelector({ activeCategory, onCategoryChange }: AccuracyCategorySelectorProps) {
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

  // Find active category
  const activeAccuracyCategory = accuracyCategories.find(cat => cat.value === activeCategory) || accuracyCategories[0];

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
        className="w-full md:w-80 px-4 py-2 text-left bg-card text-card-foreground border border-border rounded-md shadow-sm hover:bg-accent hover:text-accent-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:border-transparent transition-colors"
        aria-haspopup="listbox"
        aria-expanded={isOpen}
      >
        <span className="flex items-center justify-between">
          <span>
            <span className="font-medium">{activeAccuracyCategory.label} Accuracy</span>
            <span className="text-sm text-muted-foreground ml-2">
              {activeAccuracyCategory.description}
            </span>
          </span>
          <svg
            className={`ml-2 h-5 w-5 text-muted-foreground transition-transform flex-shrink-0 ${isOpen ? 'rotate-180' : ''}`}
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
          className="absolute z-10 mt-1 w-full bg-card rounded-md shadow-lg border border-border"
          role="listbox"
        >
          <div className="max-h-96 overflow-auto py-1">
            {accuracyCategories.map((category) => (
              <button
                key={category.value}
                onClick={() => {
                  onCategoryChange(category.value);
                  setIsOpen(false);
                }}
                className={`
                  w-full px-4 py-3 text-left hover:bg-accent hover:text-accent-foreground focus:bg-accent focus:text-accent-foreground focus:outline-none transition-colors
                  ${activeCategory === category.value
                    ? 'bg-primary/10 text-primary'
                    : 'text-card-foreground'
                  }
                `}
                role="option"
                aria-selected={activeCategory === category.value}
              >
                <div className="font-medium">{category.label} Accuracy</div>
                <div className="text-sm text-muted-foreground mt-0.5">
                  {category.description}
                </div>
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}