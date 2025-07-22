import React from 'react';
import { render, screen } from '@testing-library/react';
import { EventHeader } from '../EventHeader';
import { Event } from '@/types/api';

describe('EventHeader', () => {
  const mockEvent: Event = {
    id: 123,
    name: 'UFC 309: Jones vs Miocic',
    date: '2024-11-16',
    location: 'Las Vegas, Nevada',
    fight_count: 12,
    fights: []
  };

  describe('Basic Rendering', () => {
    it('renders event name prominently', () => {
      render(<EventHeader event={mockEvent} />);
      
      const eventName = screen.getByRole('heading', { level: 1 });
      expect(eventName).toHaveTextContent('UFC 309: Jones vs Miocic');
      expect(eventName).toHaveClass('text-3xl', 'font-bold');
    });

    it('displays formatted date correctly', () => {
      render(<EventHeader event={mockEvent} />);
      
      expect(screen.getByText('November 16, 2024')).toBeInTheDocument();
    });

    it('shows location information with icon', () => {
      render(<EventHeader event={mockEvent} />);
      
      expect(screen.getByText('Las Vegas, Nevada')).toBeInTheDocument();
      expect(screen.getByText('📍')).toBeInTheDocument();
    });

    it('displays total fight count', () => {
      render(<EventHeader event={mockEvent} />);
      
      expect(screen.getByText('12 fights')).toBeInTheDocument();
    });

    it('applies proper styling classes', () => {
      const { container } = render(<EventHeader event={mockEvent} />);
      
      const header = container.querySelector('[data-testid="event-header"]');
      expect(header).toHaveClass('bg-white', 'rounded-lg', 'p-6', 'shadow-sm');
    });
  });

  describe('Date Formatting', () => {
    it('formats different date formats correctly', () => {
      const eventWithDifferentDate = {
        ...mockEvent,
        date: '2023-12-31'
      };
      
      render(<EventHeader event={eventWithDifferentDate} />);
      
      expect(screen.getByText('December 31, 2023')).toBeInTheDocument();
    });

    it('handles invalid date formats gracefully', () => {
      const eventWithInvalidDate = {
        ...mockEvent,
        date: 'invalid-date'
      };
      
      render(<EventHeader event={eventWithInvalidDate} />);
      
      expect(screen.getByText('invalid-date')).toBeInTheDocument();
    });

    it('handles missing date', () => {
      const eventWithoutDate = {
        ...mockEvent,
        date: ''
      };
      
      render(<EventHeader event={eventWithoutDate} />);
      
      expect(screen.getByText('Date TBD')).toBeInTheDocument();
    });
  });

  describe('Fight Count Display', () => {
    it('displays singular "fight" for count of 1', () => {
      const eventWithOneFight = {
        ...mockEvent,
        fight_count: 1
      };
      
      render(<EventHeader event={eventWithOneFight} />);
      
      expect(screen.getByText('1 fight')).toBeInTheDocument();
    });

    it('displays plural "fights" for count of 0', () => {
      const eventWithNoFights = {
        ...mockEvent,
        fight_count: 0
      };
      
      render(<EventHeader event={eventWithNoFights} />);
      
      expect(screen.getByText('0 fights')).toBeInTheDocument();
    });

    it('displays plural "fights" for multiple fights', () => {
      const eventWithMultipleFights = {
        ...mockEvent,
        fight_count: 15
      };
      
      render(<EventHeader event={eventWithMultipleFights} />);
      
      expect(screen.getByText('15 fights')).toBeInTheDocument();
    });

    it('handles undefined fight_count', () => {
      const eventWithUndefinedCount = {
        ...mockEvent,
        fight_count: undefined as any
      };
      
      render(<EventHeader event={eventWithUndefinedCount} />);
      
      expect(screen.getByText('0 fights')).toBeInTheDocument();
    });
  });

  describe('Edge Cases and Data Handling', () => {
    it('handles very long event names', () => {
      const eventWithLongName = {
        ...mockEvent,
        name: 'UFC 309: Jon "Bones" Jones vs Stipe "The Firefighter" Miocic for the Undisputed Heavyweight Championship of the World'
      };
      
      render(<EventHeader event={eventWithLongName} />);
      
      const eventName = screen.getByRole('heading', { level: 1 });
      expect(eventName).toHaveTextContent(eventWithLongName.name);
      expect(eventName).toHaveClass('break-words');
    });

    it('handles very long location names', () => {
      const eventWithLongLocation = {
        ...mockEvent,
        location: 'T-Mobile Arena, Las Vegas, Nevada, United States of America'
      };
      
      render(<EventHeader event={eventWithLongLocation} />);
      
      expect(screen.getByText(eventWithLongLocation.location)).toBeInTheDocument();
    });

    it('handles missing location', () => {
      const eventWithoutLocation = {
        ...mockEvent,
        location: ''
      };
      
      render(<EventHeader event={eventWithoutLocation} />);
      
      expect(screen.getByText('Location TBD')).toBeInTheDocument();
    });

    it('handles null values gracefully', () => {
      const eventWithNullValues = {
        ...mockEvent,
        name: null as any,
        location: null as any,
        date: null as any
      };
      
      render(<EventHeader event={eventWithNullValues} />);
      
      expect(screen.getByText('Event Name TBD')).toBeInTheDocument();
      expect(screen.getByText('Location TBD')).toBeInTheDocument();
      expect(screen.getByText('Date TBD')).toBeInTheDocument();
    });
  });

  describe('Accessibility', () => {
    it('has proper heading hierarchy', () => {
      render(<EventHeader event={mockEvent} />);
      
      const heading = screen.getByRole('heading', { level: 1 });
      expect(heading).toBeInTheDocument();
    });

    it('uses semantic HTML structure', () => {
      const { container } = render(<EventHeader event={mockEvent} />);
      
      const header = container.querySelector('header');
      expect(header).toBeInTheDocument();
    });

    it('has proper ARIA labels for icons', () => {
      render(<EventHeader event={mockEvent} />);
      
      const locationIcon = screen.getByLabelText(/location/i);
      expect(locationIcon).toBeInTheDocument();
    });
  });

  describe('Visual Layout', () => {
    it('applies consistent spacing between elements', () => {
      const { container } = render(<EventHeader event={mockEvent} />);
      
      const header = container.querySelector('[data-testid="event-header"]');
      expect(header).toHaveClass('space-y-4');
    });

    it('uses appropriate text colors', () => {
      render(<EventHeader event={mockEvent} />);
      
      const eventName = screen.getByRole('heading');
      expect(eventName).toHaveClass('text-gray-900');
    });

    it('applies proper responsive design classes', () => {
      const { container } = render(<EventHeader event={mockEvent} />);
      
      const eventName = screen.getByRole('heading');
      expect(eventName).toHaveClass('sm:text-4xl');
    });
  });
});