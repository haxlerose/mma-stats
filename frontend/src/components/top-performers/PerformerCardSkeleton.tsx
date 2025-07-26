'use client';

import React from 'react';

export function PerformerCardSkeleton() {
  return (
    <div className="bg-white rounded-lg border-2 border-gray-200 p-4 animate-pulse">
      <div className="flex items-start justify-between mb-3">
        <div className="flex items-center space-x-3">
          <div className="w-10 h-10 rounded-full bg-gray-200"></div>
          <div className="h-6 w-32 bg-gray-200 rounded"></div>
        </div>
      </div>

      <div className="text-center py-3">
        <div className="h-8 w-24 bg-gray-200 rounded mx-auto"></div>
      </div>

      <div className="mt-3 pt-3 border-t border-gray-100">
        <div className="space-y-2">
          <div className="h-4 w-3/4 bg-gray-200 rounded"></div>
          <div className="h-4 w-1/2 bg-gray-200 rounded"></div>
        </div>
      </div>
    </div>
  );
}

interface PerformerCardSkeletonListProps {
  count?: number;
}

export function PerformerCardSkeletonList({ count = 10 }: PerformerCardSkeletonListProps) {
  return (
    <>
      {Array.from({ length: count }).map((_, index) => (
        <PerformerCardSkeleton key={index} />
      ))}
    </>
  );
}