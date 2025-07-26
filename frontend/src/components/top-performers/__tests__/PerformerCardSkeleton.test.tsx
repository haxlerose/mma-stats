import React from 'react';
import { render, screen } from '@testing-library/react';
import { PerformerCardSkeleton, PerformerCardSkeletonList } from '../PerformerCardSkeleton';

describe('PerformerCardSkeleton', () => {
  it('renders skeleton card with animation', () => {
    const { container } = render(<PerformerCardSkeleton />);
    
    const skeletonCard = container.firstChild;
    expect(skeletonCard).toHaveClass('animate-pulse');
  });

  it('renders correct skeleton structure', () => {
    const { container } = render(<PerformerCardSkeleton />);
    
    // Check for rank placeholder
    const rankPlaceholder = container.querySelector('.w-10.h-10.rounded-full.bg-gray-200');
    expect(rankPlaceholder).toBeInTheDocument();
    
    // Check for name placeholder
    const namePlaceholder = container.querySelector('.h-6.w-32.bg-gray-200.rounded');
    expect(namePlaceholder).toBeInTheDocument();
    
    // Check for value placeholder
    const valuePlaceholder = container.querySelector('.h-8.w-24.bg-gray-200.rounded');
    expect(valuePlaceholder).toBeInTheDocument();
  });
});

describe('PerformerCardSkeletonList', () => {
  it('renders default count of 10 skeleton cards', () => {
    const { container } = render(<PerformerCardSkeletonList />);
    
    const skeletonCards = container.querySelectorAll('.animate-pulse');
    expect(skeletonCards).toHaveLength(10);
  });

  it('renders custom count of skeleton cards', () => {
    const { container } = render(<PerformerCardSkeletonList count={5} />);
    
    const skeletonCards = container.querySelectorAll('.animate-pulse');
    expect(skeletonCards).toHaveLength(5);
  });

  it('renders 0 skeleton cards when count is 0', () => {
    const { container } = render(<PerformerCardSkeletonList count={0} />);
    
    const skeletonCards = container.querySelectorAll('.animate-pulse');
    expect(skeletonCards).toHaveLength(0);
  });
});