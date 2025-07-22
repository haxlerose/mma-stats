/**
 * SortToggle Component Tests
 * Tests for the SortToggle component following TDD methodology
 */

import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import '@testing-library/jest-dom';
import { SortToggle } from '../SortToggle';

describe('SortToggle', () => {
  const mockOnToggle = jest.fn();

  beforeEach(() => {
    mockOnToggle.mockClear();
  });

  test('displays "Newest First" for desc direction', () => {
    render(<SortToggle direction="desc" onToggle={mockOnToggle} />);
    
    expect(screen.getByText('Newest First')).toBeInTheDocument();
  });

  test('displays "Oldest First" for asc direction', () => {
    render(<SortToggle direction="asc" onToggle={mockOnToggle} />);
    
    expect(screen.getByText('Oldest First')).toBeInTheDocument();
  });

  test('shows down arrow icon for desc direction', () => {
    render(<SortToggle direction="desc" onToggle={mockOnToggle} />);
    
    const button = screen.getByRole('button');
    expect(button).toHaveTextContent('↓'); // Down arrow for newest first
  });

  test('shows up arrow icon for asc direction', () => {
    render(<SortToggle direction="asc" onToggle={mockOnToggle} />);
    
    const button = screen.getByRole('button');
    expect(button).toHaveTextContent('↑'); // Up arrow for oldest first  
  });

  test('calls onToggle with opposite direction when clicked', () => {
    render(<SortToggle direction="desc" onToggle={mockOnToggle} />);
    
    const button = screen.getByRole('button');
    fireEvent.click(button);
    
    expect(mockOnToggle).toHaveBeenCalledWith('asc');
  });

  test('calls onToggle with desc when current is asc', () => {
    render(<SortToggle direction="asc" onToggle={mockOnToggle} />);
    
    const button = screen.getByRole('button');
    fireEvent.click(button);
    
    expect(mockOnToggle).toHaveBeenCalledWith('desc');
  });

  test('has proper ARIA labels for accessibility', () => {
    render(<SortToggle direction="desc" onToggle={mockOnToggle} />);
    
    const button = screen.getByRole('button');
    expect(button).toHaveAttribute('aria-label', expect.stringContaining('sort'));
  });

  test('applies correct CSS classes for desc state', () => {
    render(<SortToggle direction="desc" onToggle={mockOnToggle} />);
    
    const button = screen.getByRole('button');
    expect(button).toHaveClass('bg-blue-50', 'text-blue-700'); // Active state styling
  });

  test('applies correct CSS classes for asc state', () => {
    render(<SortToggle direction="asc" onToggle={mockOnToggle} />);
    
    const button = screen.getByRole('button');
    expect(button).toHaveClass('bg-blue-50', 'text-blue-700'); // Active state styling
  });

  test('animates transition between states', () => {
    const { rerender } = render(<SortToggle direction="desc" onToggle={mockOnToggle} />);
    
    const button = screen.getByRole('button');
    expect(button).toHaveClass('transition-colors'); // Should have transition classes
    
    rerender(<SortToggle direction="asc" onToggle={mockOnToggle} />);
    
    // Icon should change smoothly
    expect(button).toHaveTextContent('↑');
  });

  test('handles keyboard navigation', () => {
    render(<SortToggle direction="desc" onToggle={mockOnToggle} />);
    
    const button = screen.getByRole('button');
    
    // Should be focusable
    button.focus();
    expect(button).toHaveFocus();
    
    // Should respond to Enter key
    fireEvent.keyDown(button, { key: 'Enter' });
    expect(mockOnToggle).toHaveBeenCalledWith('asc');
  });

  test('handles space bar activation', () => {
    render(<SortToggle direction="desc" onToggle={mockOnToggle} />);
    
    const button = screen.getByRole('button');
    fireEvent.keyDown(button, { key: ' ' });
    
    expect(mockOnToggle).toHaveBeenCalledWith('asc');
  });

  test('displays tooltip or helper text', () => {
    render(<SortToggle direction="desc" onToggle={mockOnToggle} />);
    
    const button = screen.getByRole('button');
    expect(button).toHaveAttribute('title', expect.stringContaining('sort'));
  });

  test('maintains state consistency', () => {
    const { rerender } = render(<SortToggle direction="desc" onToggle={mockOnToggle} />);
    
    expect(screen.getByText('Newest First')).toBeInTheDocument();
    expect(screen.getByText('↓')).toBeInTheDocument();
    
    rerender(<SortToggle direction="asc" onToggle={mockOnToggle} />);
    
    expect(screen.getByText('Oldest First')).toBeInTheDocument();
    expect(screen.getByText('↑')).toBeInTheDocument();
  });

  test('applies hover effects', () => {
    render(<SortToggle direction="desc" onToggle={mockOnToggle} />);
    
    const button = screen.getByRole('button');
    expect(button).toHaveClass('hover:bg-blue-100'); // Hover effect
  });
});