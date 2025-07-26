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

    try {
      const response = await apiClient.topPerformers.list({ scope, category });
      setTopPerformers(response.top_performers);
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
    updateURL({ scope });
  };

  // Handle category change
  const handleCategoryChange = (category: TopPerformerCategory) => {
    updateURL({ category });
  };

  // Helper to format category name for display
  const formatCategoryName = (category: TopPerformerCategory): string => {
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
        
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between space-y-2 sm:space-y-0">
          <div className="text-sm text-gray-600">
            Select a statistic to view top performers:
          </div>
          <CategorySelector 
            activeCategory={urlCategory} 
            onCategoryChange={handleCategoryChange} 
          />
        </div>
      </div>

      {/* Results Header */}
      {!isLoading && !error && topPerformers.length > 0 && (
        <div className="text-center py-4">
          <h2 className="text-2xl font-semibold text-gray-900">
            Top 10: {formatCategoryName(urlCategory)}
          </h2>
          <p className="text-sm text-gray-600 mt-1">
            {urlScope === 'career' && 'Total career statistics'}
            {urlScope === 'fight' && 'Best single fight performance'}
            {urlScope === 'round' && 'Best single round performance'}
            {urlScope === 'per_minute' && 'Average per 15 minutes of fight time'}
          </p>
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