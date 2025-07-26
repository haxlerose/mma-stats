import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import { ScopeTabs } from '../ScopeTabs';
import { TopPerformerScope } from '@/types/api';

describe('ScopeTabs', () => {
  const mockOnScopeChange = jest.fn();

  beforeEach(() => {
    mockOnScopeChange.mockClear();
  });

  it('renders all scope tabs', () => {
    render(
      <ScopeTabs 
        activeScope="career" 
        onScopeChange={mockOnScopeChange} 
      />
    );

    expect(screen.getByText('Career')).toBeInTheDocument();
    expect(screen.getByText('Fight')).toBeInTheDocument();
    expect(screen.getByText('Round')).toBeInTheDocument();
    expect(screen.getByText('Per 15 min')).toBeInTheDocument();
  });

  it('highlights the active tab', () => {
    render(
      <ScopeTabs 
        activeScope="fight" 
        onScopeChange={mockOnScopeChange} 
      />
    );

    const fightTab = screen.getByText('Fight').closest('button');
    const careerTab = screen.getByText('Career').closest('button');

    expect(fightTab).toHaveClass('bg-white', 'text-gray-900');
    expect(careerTab).not.toHaveClass('bg-white');
  });

  it('calls onScopeChange when a tab is clicked', () => {
    render(
      <ScopeTabs 
        activeScope="career" 
        onScopeChange={mockOnScopeChange} 
      />
    );

    const roundTab = screen.getByText('Round');
    fireEvent.click(roundTab);

    expect(mockOnScopeChange).toHaveBeenCalledWith('round');
    expect(mockOnScopeChange).toHaveBeenCalledTimes(1);
  });

  it('shows appropriate descriptions in title attributes', () => {
    render(
      <ScopeTabs 
        activeScope="career" 
        onScopeChange={mockOnScopeChange} 
      />
    );

    expect(screen.getByText('Career').closest('button')).toHaveAttribute(
      'title',
      'Total career statistics'
    );
    expect(screen.getByText('Fight').closest('button')).toHaveAttribute(
      'title',
      'Best single fight performance'
    );
    expect(screen.getByText('Round').closest('button')).toHaveAttribute(
      'title',
      'Best single round performance'
    );
    expect(screen.getByText('Per 15 min').closest('button')).toHaveAttribute(
      'title',
      'Rate per 15 minutes'
    );
  });

  it('sets aria-current on active tab', () => {
    render(
      <ScopeTabs 
        activeScope="per_minute" 
        onScopeChange={mockOnScopeChange} 
      />
    );

    const activeTab = screen.getByText('Per 15 min').closest('button');
    const inactiveTab = screen.getByText('Career').closest('button');

    expect(activeTab).toHaveAttribute('aria-current', 'page');
    expect(inactiveTab).not.toHaveAttribute('aria-current');
  });
});