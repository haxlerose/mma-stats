/**
 * EventCard Component Tests
 * Tests for the EventCard component following TDD methodology
 */

import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { EventCard } from '../EventCard';
import { Event } from '@/types/api';

describe('EventCard', () => {
  const mockEvent: Event = {
    id: 1,
    name: 'UFC 309: Jones vs Miocic',
    date: '2024-11-16',
    location: 'Las Vegas, Nevada',
    fight_count: 13
  };

  test('displays event name prominently', () => {
    render(<EventCard event={mockEvent} />);
    
    const eventName = screen.getByText('UFC 309: Jones vs Miocic');
    expect(eventName).toBeInTheDocument();
    expect(eventName).toHaveClass('text-lg', 'font-bold'); // Should be prominent
  });

  test('formats date in readable format', () => {
    render(<EventCard event={mockEvent} />);
    
    // Should format 2024-11-16 to a readable format like "Nov 16, 2024"
    const dateElement = screen.getByText(/Nov 16, 2024/i);
    expect(dateElement).toBeInTheDocument();
  });

  test('displays location with icon', () => {
    render(<EventCard event={mockEvent} />);
    
    const locationText = screen.getByText('Las Vegas, Nevada');
    expect(locationText).toBeInTheDocument();
    
    // Should have a location icon (📍 or similar)
    const locationContainer = locationText.closest('div');
    expect(locationContainer).toHaveTextContent('📍');
  });

  test('shows fight count', () => {
    render(<EventCard event={mockEvent} />);
    
    const fightCount = screen.getByText(/13 fights/i);
    expect(fightCount).toBeInTheDocument();
  });

  test('links to event detail page', () => {
    render(<EventCard event={mockEvent} />);
    
    const link = screen.getByRole('link');
    expect(link).toHaveAttribute('href', '/events/1');
  });

  test('handles missing optional fields gracefully', () => {
    const eventWithoutFightCount: Event = {
      id: 2,
      name: 'UFC 308: Topuria vs Holloway',
      date: '2024-10-26',
      location: 'Abu Dhabi, United Arab Emirates'
      // fight_count is optional and not provided
    };

    render(<EventCard event={eventWithoutFightCount} />);
    
    // Should still render without crashing
    expect(screen.getByText('UFC 308: Topuria vs Holloway')).toBeInTheDocument();
    expect(screen.getByText('Abu Dhabi, United Arab Emirates')).toBeInTheDocument();
    
    // Should show 0 fights or hide fight count section
    const fightText = screen.queryByText(/fights/i);
    if (fightText) {
      expect(fightText).toHaveTextContent('0 fights');
    }
  });

  test('applies hover effects on interaction', () => {
    render(<EventCard event={mockEvent} />);
    
    const card = screen.getByRole('link');
    expect(card).toHaveClass('hover:shadow-lg'); // Should have hover effect
  });

  test('has semantic HTML structure', () => {
    render(<EventCard event={mockEvent} />);
    
    // Should be wrapped in an article for semantic meaning
    const article = screen.getByRole('article');
    expect(article).toBeInTheDocument();
    
    // Should have a link for navigation
    const link = screen.getByRole('link');
    expect(link).toBeInTheDocument();
  });

  test('provides proper accessibility attributes', () => {
    render(<EventCard event={mockEvent} />);
    
    const link = screen.getByRole('link');
    expect(link).toHaveAttribute('aria-label', expect.stringContaining('UFC 309'));
  });

  test('handles very long event names', () => {
    const eventWithLongName: Event = {
      id: 3,
      name: 'UFC 300: Very Long Event Name That Should Be Properly Handled And Not Break The Layout When Displayed In The Card Component',
      date: '2024-04-13',
      location: 'Las Vegas, Nevada',
      fight_count: 15
    };

    render(<EventCard event={eventWithLongName} />);
    
    const eventName = screen.getByText(eventWithLongName.name);
    expect(eventName).toBeInTheDocument();
    // Should have text truncation or wrapping classes
    expect(eventName).toHaveClass('truncate', 'text-wrap');
  });

  test('displays upcoming events differently from past events', () => {
    const futureEvent: Event = {
      id: 4,
      name: 'UFC 310: Future Event',
      date: '2025-12-31',
      location: 'New York, New York',
      fight_count: 12
    };

    render(<EventCard event={futureEvent} />);
    
    // Should have visual indicator for future events
    const card = screen.getByRole('article');
    expect(card).toHaveClass('border-blue-200'); // Different styling for future events
  });
});