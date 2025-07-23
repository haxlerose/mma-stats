'use client';

import React, { useState, useEffect } from 'react';
import { useRouter, useSearchParams, usePathname } from 'next/navigation';
import { apiClient } from '@/lib/api';
import { Fighter } from '@/types/api';
import { FighterCard } from '@/components/fighter/FighterCard';

export default function FightersPage() {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  
  const [fighters, setFighters] = useState<Fighter[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  
  // Get search from URL
  const urlSearch = searchParams.get('search') || '';

  // Update URL with search parameter
  const updateURL = (search: string) => {
    const newSearchParams = new URLSearchParams(searchParams.toString());
    
    if (search) {
      newSearchParams.set('search', search);
    } else {
      newSearchParams.delete('search');
    }

    const newURL = `${pathname}?${newSearchParams.toString()}`;
    router.replace(newURL);
  };

  // Load fighters
  const loadFighters = async () => {
    setIsLoading(true);
    setError(null);
    
    try {
      const params = urlSearch ? { search: urlSearch } : undefined;
      const fightersData = await apiClient.fighters.list(params);
      setFighters(fightersData);
    } catch (err) {
      setError('Failed to load fighters. Please try again.');
      console.error('Error loading fighters:', err);
    } finally {
      setIsLoading(false);
    }
  };

  // Load fighters on mount and when search changes
  useEffect(() => {
    loadFighters();
  }, [urlSearch]);

  // Set initial search term from URL
  useEffect(() => {
    setSearchTerm(urlSearch);
  }, [urlSearch]);

  // Handle search on input change with debouncing
  useEffect(() => {
    const delayDebounceFn = setTimeout(() => {
      if (searchTerm !== urlSearch) {
        updateURL(searchTerm.trim());
      }
    }, 300); // 300ms delay

    return () => clearTimeout(delayDebounceFn);
  }, [searchTerm, urlSearch, updateURL]);

  // Handle clear search
  const handleClearSearch = () => {
    setSearchTerm('');
    updateURL('');
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Fighters</h1>
        <p className="mt-2 text-gray-600">
          Browse UFC fighters and view their complete fight history
        </p>
      </div>

      {/* Search Bar */}
      <div className="max-w-2xl">
        <div className="relative">
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Search fighters by name..."
            className="w-full px-4 py-2 pr-10 text-gray-900 placeholder-gray-500 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          />
          {searchTerm && (
            <button
              type="button"
              onClick={handleClearSearch}
              className="absolute right-2 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
              aria-label="Clear search"
            >
              <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          )}
        </div>
      </div>

      {/* Results count */}
      {!isLoading && !error && (
        <div className="text-sm text-gray-600">
          {urlSearch ? (
            <span>
              Found {fighters.length} fighter{fighters.length !== 1 ? 's' : ''} matching "{urlSearch}"
            </span>
          ) : (
            <span>
              Showing all {fighters.length} fighters
            </span>
          )}
        </div>
      )}

      {/* Loading State */}
      {isLoading && (
        <div className="text-center py-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading fighters...</p>
        </div>
      )}

      {/* Error State */}
      {error && (
        <div className="text-center py-12">
          <div className="mb-4">
            <svg className="mx-auto h-16 w-16 text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <h2 className="text-2xl font-bold text-gray-900 mb-2">Failed to Load Fighters</h2>
          <p className="text-gray-600 mb-6">{error}</p>
          <button
            onClick={loadFighters}
            className="px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
          >
            Try Again
          </button>
        </div>
      )}

      {/* Fighters Grid */}
      {!isLoading && !error && fighters.length === 0 && (
        <div className="text-center py-12">
          <p className="text-gray-600">
            {urlSearch ? 'No fighters found matching your search.' : 'No fighters available.'}
          </p>
        </div>
      )}

      {!isLoading && !error && fighters.length > 0 && (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {fighters.map((fighter) => (
            <FighterCard key={fighter.id} fighter={fighter} />
          ))}
        </div>
      )}
    </div>
  );
}