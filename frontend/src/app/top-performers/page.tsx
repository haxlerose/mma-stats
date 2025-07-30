'use client';

import React, { useState, useEffect } from 'react';
import { useRouter, useSearchParams, usePathname } from 'next/navigation';
import { apiClient } from '@/lib/api';
import { 
  TopPerformer, 
  TopPerformerScope, 
  TopPerformerCategory,
  TopPerformersResponse 
} from '@/types/api';
import { ScopeTabs } from '@/components/top-performers/ScopeTabs';
import { CategorySelector } from '@/components/top-performers/CategorySelector';
import { AccuracyCategorySelector } from '@/components/top-performers/AccuracyCategorySelector';
import { PerformerCard } from '@/components/top-performers/PerformerCard';
import { PerformerCardSkeletonList } from '@/components/top-performers/PerformerCardSkeleton';

export default function TopPerformersPage() {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();

  // State
  const [topPerformers, setTopPerformers] = useState<TopPerformer[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [minimumThreshold, setMinimumThreshold] = useState<number | null>(null);
  const [isFiltered, setIsFiltered] = useState(false);

  // Get scope and category from URL, with defaults
  const urlScope = (searchParams.get('scope') || 'career') as TopPerformerScope;
  const urlCategory = (searchParams.get('category') || 'knockdowns') as TopPerformerCategory;

  // Update URL with new parameters
  const updateURL = (params: { scope?: TopPerformerScope; category?: TopPerformerCategory }) => {
    const newSearchParams = new URLSearchParams(searchParams.toString());

    if (params.scope !== undefined) {
      newSearchParams.set('scope', params.scope);
    }

    if (params.category !== undefined) {
      newSearchParams.set('category', params.category);
    }

    const newURL = `${pathname}?${newSearchParams.toString()}`;
    router.replace(newURL);
  };

  // Load top performers
  const loadTopPerformers = async (scope: TopPerformerScope, category: TopPerformerCategory) => {
    setIsLoading(true);
    setError(null);
    setMinimumThreshold(null);
    setIsFiltered(false);

    try {
      // Apply threshold filtering for accuracy scope
      const applyThreshold = scope === 'accuracy';
      const response = await apiClient.topPerformers.list({ 
        scope, 
        category,
        apply_threshold: applyThreshold
      });
      
      setTopPerformers(response.top_performers);
      
      // Set threshold info for accuracy scope
      if (scope === 'accuracy' && response.minimum_thresholds) {
        const thresholdKey = category as keyof typeof response.minimum_thresholds;
        const threshold = response.minimum_thresholds[thresholdKey];
        if (threshold !== undefined) {
          setMinimumThreshold(threshold);
          // If we got less than 10 results, filtering was applied
          setIsFiltered(response.top_performers.length < 10);
        }
      }
    } catch (err) {
      setError('Failed to load top performers. Please try again.');
      console.error('Error loading top performers:', err);
      console.error('Request params:', { scope, category });
    } finally {
      setIsLoading(false);
    }
  };

  // Load data when scope or category changes
  useEffect(() => {
    loadTopPerformers(urlScope, urlCategory);
  }, [urlScope, urlCategory]);

  // Handle scope change
  const handleScopeChange = (scope: TopPerformerScope) => {
    // When switching to accuracy scope, default to significant_strike_accuracy if not already on an accuracy category
    if (scope === 'accuracy') {
      const isCurrentlyAccuracyCategory = urlCategory.includes('_accuracy');
      const newCategory = isCurrentlyAccuracyCategory ? urlCategory : 'significant_strike_accuracy';
      updateURL({ scope, category: newCategory });
    } else if (scope === 'results') {
      // When switching to results scope, default to total_wins if not already on a results category
      const isCurrentlyResultsCategory = ['total_wins', 'total_losses', 'win_percentage', 'longest_win_streak'].includes(urlCategory);
      const newCategory = isCurrentlyResultsCategory ? urlCategory : 'total_wins';
      updateURL({ scope, category: newCategory });
    } else {
      // When leaving accuracy or results scope, switch to a non-accuracy/non-results category
      const isSpecialCategory = urlCategory.includes('_accuracy') || 
        ['total_wins', 'total_losses', 'win_percentage', 'longest_win_streak'].includes(urlCategory);
      const newCategory = isSpecialCategory ? 'knockdowns' : urlCategory;
      updateURL({ scope, category: newCategory });
    }
  };

  // Handle category change
  const handleCategoryChange = (category: TopPerformerCategory) => {
    updateURL({ category });
  };

  // Helper to format category name for display
  const formatCategoryName = (category: TopPerformerCategory): string => {
    // Special formatting for accuracy categories
    if (category.endsWith('_accuracy')) {
      const parts = category.replace('_accuracy', '').split('_');
      return parts.map(word => word.charAt(0).toUpperCase() + word.slice(1)).join(' ') + ' Accuracy';
    }
    return category
      .split('_')
      .map(word => word.charAt(0).toUpperCase() + word.slice(1))
      .join(' ');
  };

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Top Performers</h1>
        <p className="mt-2 text-gray-600">
          Discover the best performers in UFC history across various statistics
        </p>
      </div>

      {/* Controls */}
      <div className="space-y-4">
        <ScopeTabs 
          activeScope={urlScope} 
          onScopeChange={handleScopeChange} 
        />
        
        {urlScope === 'accuracy' ? (
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between space-y-2 sm:space-y-0">
            <div className="text-sm text-gray-600">
              Select an accuracy statistic to view top performers:
            </div>
            <AccuracyCategorySelector 
              activeCategory={urlCategory} 
              onCategoryChange={handleCategoryChange}
            />
          </div>
        ) : urlScope === 'results' ? (
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between space-y-2 sm:space-y-0">
            <div className="text-sm text-gray-600">
              Select a results statistic to view top performers:
            </div>
            <CategorySelector 
              activeCategory={urlCategory} 
              onCategoryChange={handleCategoryChange}
              scope={urlScope}
            />
          </div>
        ) : (
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between space-y-2 sm:space-y-0">
            <div className="text-sm text-gray-600">
              Select a statistic to view top performers:
            </div>
            <CategorySelector 
              activeCategory={urlCategory} 
              onCategoryChange={handleCategoryChange}
              scope={urlScope}
            />
          </div>
        )}
      </div>

      {/* Results Header */}
      {!isLoading && !error && topPerformers.length > 0 && (
        <div className="text-center py-4">
          <h2 className="text-2xl font-semibold text-gray-900">
            Top {topPerformers.length}: {formatCategoryName(urlCategory)}
          </h2>
          <p className="text-sm text-gray-600 mt-1">
            {urlScope === 'career' && 'Total career statistics'}
            {urlScope === 'fight' && 'Best single fight performance'}
            {urlScope === 'round' && 'Best single round performance'}
            {urlScope === 'per_minute' && 'Average per 15 minutes of fight time'}
            {urlScope === 'accuracy' && `Highest ${formatCategoryName(urlCategory).toLowerCase()} percentage`}
            {urlScope === 'results' && 'Career win/loss records and streaks'}
          </p>
        </div>
      )}

      {/* Minimum Threshold Information */}
      {!isLoading && !error && urlScope === 'accuracy' && minimumThreshold !== null && (
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
          <div className="flex items-start">
            <svg
              className="flex-shrink-0 h-5 w-5 text-blue-400 mr-2 mt-0.5"
              fill="currentColor"
              viewBox="0 0 20 20"
            >
              <path
                fillRule="evenodd"
                d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z"
                clipRule="evenodd"
              />
            </svg>
            <div className="text-sm text-blue-800">
              <p className="font-medium mb-1">Minimum Activity Requirement</p>
              <p>
                Fighters must attempt at least {minimumThreshold.toFixed(1)} {
                  urlCategory.replace('_accuracy', '').replace(/_/g, ' ')
                } per minute to qualify for this ranking.
              </p>
              {isFiltered && (
                <p className="mt-2">
                  Some fighters with high accuracy percentages were excluded due to insufficient activity.
                </p>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Loading State */}
      {isLoading && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <PerformerCardSkeletonList count={10} />
        </div>
      )}

      {/* Error State */}
      {error && (
        <div className="text-center py-12">
          <div className="mb-4">
            <svg 
              className="mx-auto h-16 w-16 text-red-400" 
              fill="none" 
              viewBox="0 0 24 24" 
              stroke="currentColor"
            >
              <path 
                strokeLinecap="round" 
                strokeLinejoin="round" 
                strokeWidth={1} 
                d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" 
              />
            </svg>
          </div>
          <h2 className="text-2xl font-bold text-gray-900 mb-2">
            Failed to Load Top Performers
          </h2>
          <p className="text-gray-600 mb-6">{error}</p>
          <button
            onClick={() => loadTopPerformers(urlScope, urlCategory)}
            className="px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
          >
            Try Again
          </button>
        </div>
      )}

      {/* Results Grid */}
      {!isLoading && !error && topPerformers.length > 0 && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {topPerformers.map((performer, index) => (
            <PerformerCard
              key={`${performer.fighter_id}-${index}`}
              performer={performer}
              rank={index + 1}
              scope={urlScope}
              category={urlCategory}
            />
          ))}
        </div>
      )}

      {/* Empty State */}
      {!isLoading && !error && topPerformers.length === 0 && (
        <div className="text-center py-12">
          <p className="text-gray-600">
            No data available for the selected category and scope.
          </p>
        </div>
      )}
    </div>
  );
}