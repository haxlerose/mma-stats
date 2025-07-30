import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { CategorySelector } from '../CategorySelector';
import { TopPerformerCategory, TopPerformerScope } from '@/types/api';

describe('CategorySelector', () => {
  const mockOnCategoryChange = jest.fn();

  beforeEach(() => {
    mockOnCategoryChange.mockClear();
  });

  it('renders with the active category displayed', () => {
    render(
      <CategorySelector 
        activeCategory="knockdowns" 
        onCategoryChange={mockOnCategoryChange} 
      />
    );

    expect(screen.getByText('Knockdowns')).toBeInTheDocument();
  });

  it('opens dropdown when clicked', () => {
    render(
      <CategorySelector 
        activeCategory="takedowns" 
        onCategoryChange={mockOnCategoryChange} 
      />
    );

    const button = screen.getByRole('button');
    fireEvent.click(button);

    // Check for category groups
    expect(screen.getByText('Striking')).toBeInTheDocument();
    expect(screen.getByText('Grappling')).toBeInTheDocument();
    expect(screen.getByText('Control')).toBeInTheDocument();
  });

  it('calls onCategoryChange when a category is selected', () => {
    render(
      <CategorySelector 
        activeCategory="knockdowns" 
        onCategoryChange={mockOnCategoryChange} 
      />
    );

    const button = screen.getByRole('button');
    fireEvent.click(button);

    const significantStrikesOption = screen.getByText('Significant Strikes');
    fireEvent.click(significantStrikesOption);

    expect(mockOnCategoryChange).toHaveBeenCalledWith('significant_strikes');
    expect(mockOnCategoryChange).toHaveBeenCalledTimes(1);
  });

  it('closes dropdown after selection', async () => {
    render(
      <CategorySelector 
        activeCategory="knockdowns" 
        onCategoryChange={mockOnCategoryChange} 
      />
    );

    const button = screen.getByRole('button');
    fireEvent.click(button);

    const takedownsOption = screen.getByText('Takedowns');
    fireEvent.click(takedownsOption);

    await waitFor(() => {
      expect(screen.queryByText('Grappling')).not.toBeInTheDocument();
    });
  });

  it('highlights the active category in the dropdown', () => {
    render(
      <CategorySelector 
        activeCategory="submission_attempts" 
        onCategoryChange={mockOnCategoryChange} 
      />
    );

    const button = screen.getByRole('button');
    fireEvent.click(button);

    // Find the option in the dropdown, not the button text
    const activeOption = screen.getByRole('option', { name: 'Submission Attempts', selected: true });
    expect(activeOption).toHaveClass('bg-primary/10', 'text-primary', 'font-medium');
  });

  it('closes dropdown when clicking outside', async () => {
    render(
      <div>
        <CategorySelector 
          activeCategory="knockdowns" 
          onCategoryChange={mockOnCategoryChange} 
        />
        <div data-testid="outside">Outside element</div>
      </div>
    );

    const button = screen.getByRole('button');
    fireEvent.click(button);

    expect(screen.getByText('Striking')).toBeInTheDocument();

    const outsideElement = screen.getByTestId('outside');
    fireEvent.mouseDown(outsideElement);

    await waitFor(() => {
      expect(screen.queryByText('Striking')).not.toBeInTheDocument();
    });
  });

  it('closes dropdown when Escape key is pressed', async () => {
    render(
      <CategorySelector 
        activeCategory="knockdowns" 
        onCategoryChange={mockOnCategoryChange} 
      />
    );

    const button = screen.getByRole('button');
    fireEvent.click(button);

    expect(screen.getByText('Striking')).toBeInTheDocument();

    fireEvent.keyDown(button, { key: 'Escape' });

    await waitFor(() => {
      expect(screen.queryByText('Striking')).not.toBeInTheDocument();
    });
  });

  it('renders all category groups and options', () => {
    render(
      <CategorySelector 
        activeCategory="knockdowns" 
        onCategoryChange={mockOnCategoryChange} 
      />
    );

    const button = screen.getByRole('button');
    fireEvent.click(button);

    // Check striking categories - use role queries to avoid ambiguity
    expect(screen.getByRole('option', { name: 'Knockdowns' })).toBeInTheDocument();
    expect(screen.getByRole('option', { name: 'Significant Strikes' })).toBeInTheDocument();
    expect(screen.getByRole('option', { name: 'Total Strikes' })).toBeInTheDocument();

    // Check grappling categories
    expect(screen.getByRole('option', { name: 'Takedowns' })).toBeInTheDocument();
    expect(screen.getByRole('option', { name: 'Submission Attempts' })).toBeInTheDocument();
    expect(screen.getByRole('option', { name: 'Reversals' })).toBeInTheDocument();

    // Check control category
    expect(screen.getByRole('option', { name: 'Control Time' })).toBeInTheDocument();
  });

  it('does not render selector for accuracy scope', () => {
    const { container } = render(
      <CategorySelector 
        activeCategory="significant_strike_accuracy" 
        onCategoryChange={mockOnCategoryChange}
        scope="accuracy"
      />
    );

    expect(container.firstChild).toBeNull();
  });

  it('renders results categories when scope is results', () => {
    render(
      <CategorySelector 
        activeCategory="total_wins" 
        onCategoryChange={mockOnCategoryChange}
        scope="results"
      />
    );

    const button = screen.getByRole('button');
    expect(screen.getByText('Total Wins')).toBeInTheDocument();
    
    fireEvent.click(button);
    
    // Check for results category group
    expect(screen.getByText('Win/Loss Records')).toBeInTheDocument();
    
    // Check for results category options
    expect(screen.getByRole('option', { name: 'Total Wins' })).toBeInTheDocument();
    expect(screen.getByRole('option', { name: 'Total Losses' })).toBeInTheDocument();
    expect(screen.getByRole('option', { name: 'Win Percentage' })).toBeInTheDocument();
    expect(screen.getByRole('option', { name: 'Longest Win Streak' })).toBeInTheDocument();
    
    // Should not show other categories
    expect(screen.queryByText('Striking')).not.toBeInTheDocument();
    expect(screen.queryByText('Grappling')).not.toBeInTheDocument();
  });

  it('renders normal selector without accuracy or results scope', () => {
    render(
      <CategorySelector 
        activeCategory="knockdowns" 
        onCategoryChange={mockOnCategoryChange}
        scope="career"
      />
    );

    const button = screen.getByRole('button');
    expect(button).not.toBeDisabled();
    expect(screen.getByText('Knockdowns')).toBeInTheDocument();
  });
});