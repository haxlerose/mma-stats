import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { useRouter } from 'next/navigation';
import EventDetailPage from '../page';
import { apiClient } from '@/lib/api';
import { Event, Fight } from '@/types/api';

// Mock Next.js navigation
jest.mock('next/navigation', () => ({
  useRouter: jest.fn(),
  useParams: () => ({ id: '123' }),
}));

// Mock API client
jest.mock('@/lib/api');
const mockApiClient = apiClient as jest.Mocked<typeof apiClient>;

// Mock child components
jest.mock('@/components/event/EventHeader', () => ({
  EventHeader: ({ event }: { event: Event }) => (
    <div data-testid="event-header">{event.name}</div>
  ),
}));

jest.mock('@/components/event/FightsList', () => ({
  FightsList: ({ fights }: { fights: Fight[] }) => (
    <div data-testid="fights-list">
      {fights.map(fight => (
        <div key={fight.id} data-testid="fight-item">
          {fight.bout}
        </div>
      ))}
    </div>
  ),
}));

describe('EventDetailPage', () => {
  const mockRouter = {
    push: jest.fn(),
    replace: jest.fn(),
    back: jest.fn(),
  };

  const mockEvent: Event = {
    id: 123,
    name: 'UFC 309: Jones vs Miocic',
    date: '2024-11-16',
    location: 'Las Vegas, Nevada',
    fight_count: 2,
    fights: [
      {
        id: 1,
        bout: 'Jon Jones vs Stipe Miocic',
        outcome: 'Jones wins',
        weight_class: 'Heavyweight',
        method: 'TKO',
        round: 3,
        time: '4:29',
        time_format: '5:00',
        referee: 'Herb Dean',
        details: null,
        fight_stats: []
      },
      {
        id: 2,
        bout: 'Charles Oliveira vs Michael Chandler',
        outcome: 'Oliveira wins',
        weight_class: 'Lightweight', 
        method: 'Submission',
        round: 1,
        time: '3:31',
        time_format: '5:00',
        referee: 'Marc Goddard',
        details: null,
        fight_stats: []
      }
    ]
  };

  beforeEach(() => {
    jest.clearAllMocks();
    (useRouter as jest.Mock).mockReturnValue(mockRouter);
  });

  describe('Data Fetching', () => {
    it('fetches event data on mount using correct API endpoint', async () => {
      mockApiClient.events.get.mockResolvedValue(mockEvent);
      
      render(<EventDetailPage />);
      
      await waitFor(() => {
        expect(mockApiClient.events.get).toHaveBeenCalledWith(123);
      });
    });

    it('displays loading state while fetching', () => {
      mockApiClient.events.get.mockImplementation(() => new Promise(() => {}));
      
      render(<EventDetailPage />);
      
      expect(screen.getByText(/loading/i)).toBeInTheDocument();
      expect(screen.getByTestId('loading-spinner')).toBeInTheDocument();
    });

    it('renders event data when loaded successfully', async () => {
      mockApiClient.events.get.mockResolvedValue(mockEvent);
      
      render(<EventDetailPage />);
      
      await waitFor(() => {
        expect(screen.getByTestId('event-header')).toHaveTextContent('UFC 309: Jones vs Miocic');
        expect(screen.getByTestId('fights-list')).toBeInTheDocument();
      });
    });

    it('passes event data to EventHeader component', async () => {
      mockApiClient.events.get.mockResolvedValue(mockEvent);
      
      render(<EventDetailPage />);
      
      await waitFor(() => {
        const eventHeader = screen.getByTestId('event-header');
        expect(eventHeader).toHaveTextContent('UFC 309: Jones vs Miocic');
      });
    });

    it('passes fights data to FightsList component', async () => {
      mockApiClient.events.get.mockResolvedValue(mockEvent);
      
      render(<EventDetailPage />);
      
      await waitFor(() => {
        expect(screen.getByText('Jon Jones vs Stipe Miocic')).toBeInTheDocument();
        expect(screen.getByText('Charles Oliveira vs Michael Chandler')).toBeInTheDocument();
      });
    });
  });

  describe('Error Handling', () => {
    it('handles 404 errors for non-existent events', async () => {
      const error = new Error('API request failed: 404 Not Found');
      error.name = 'ApiClientError';
      (error as any).status = 404;
      
      mockApiClient.events.get.mockRejectedValue(error);
      
      render(<EventDetailPage />);
      
      await waitFor(() => {
        expect(screen.getByText(/event not found/i)).toBeInTheDocument();
        expect(screen.getByText(/the event you're looking for doesn't exist/i)).toBeInTheDocument();
      });
    });

    it('handles network errors gracefully', async () => {
      const networkError = new Error('Network error: Failed to fetch');
      networkError.name = 'ApiClientError';
      (networkError as any).status = 0;
      
      mockApiClient.events.get.mockRejectedValue(networkError);
      
      render(<EventDetailPage />);
      
      await waitFor(() => {
        expect(screen.getByText(/failed to load event/i)).toBeInTheDocument();
        expect(screen.getByRole('button', { name: /try again/i })).toBeInTheDocument();
      });
    });

    it('handles server errors with retry functionality', async () => {
      const serverError = new Error('API request failed: 500 Internal Server Error');
      serverError.name = 'ApiClientError';
      (serverError as any).status = 500;
      
      mockApiClient.events.get.mockRejectedValue(serverError);
      
      render(<EventDetailPage />);
      
      await waitFor(() => {
        expect(screen.getByText(/something went wrong/i)).toBeInTheDocument();
        expect(screen.getByRole('button', { name: /try again/i })).toBeInTheDocument();
      });
    });

    it('retries fetching when try again button is clicked', async () => {
      const user = userEvent.setup();
      const networkError = new Error('Network error');
      networkError.name = 'ApiClientError';
      (networkError as any).status = 0;
      
      mockApiClient.events.get
        .mockRejectedValueOnce(networkError)
        .mockResolvedValue(mockEvent);
      
      render(<EventDetailPage />);
      
      await waitFor(() => {
        expect(screen.getByRole('button', { name: /try again/i })).toBeInTheDocument();
      });
      
      await user.click(screen.getByRole('button', { name: /try again/i }));
      
      await waitFor(() => {
        expect(mockApiClient.events.get).toHaveBeenCalledTimes(2);
        expect(screen.getByTestId('event-header')).toBeInTheDocument();
      });
    });
  });

  describe('Breadcrumb Integration', () => {
    it('uses NavigationLayout with breadcrumb and event name', async () => {
      mockApiClient.events.get.mockResolvedValue(mockEvent);
      
      const { container } = render(<EventDetailPage />);
      
      await waitFor(() => {
        // Check that the page is wrapped with appropriate layout
        expect(container.querySelector('[data-testid="event-detail-page"]')).toBeInTheDocument();
      });
    });

    it('shows loading breadcrumb before event loads', () => {
      mockApiClient.events.get.mockImplementation(() => new Promise(() => {}));
      
      render(<EventDetailPage />);
      
      // Should show generic breadcrumb while loading
      expect(screen.getByTestId('loading-spinner')).toBeInTheDocument();
    });
  });

  describe('Edge Cases', () => {
    it('handles events with no fights', async () => {
      const eventWithNoFights: Event = {
        ...mockEvent,
        fights: []
      };
      
      mockApiClient.events.get.mockResolvedValue(eventWithNoFights);
      
      render(<EventDetailPage />);
      
      await waitFor(() => {
        expect(screen.getByTestId('event-header')).toBeInTheDocument();
        expect(screen.getByTestId('fights-list')).toBeInTheDocument();
        expect(screen.queryByTestId('fight-item')).not.toBeInTheDocument();
      });
    });

    it('handles events with undefined fights array', async () => {
      const eventWithUndefinedFights: Event = {
        ...mockEvent,
        fights: undefined as any
      };
      
      mockApiClient.events.get.mockResolvedValue(eventWithUndefinedFights);
      
      render(<EventDetailPage />);
      
      await waitFor(() => {
        expect(screen.getByTestId('event-header')).toBeInTheDocument();
        expect(screen.getByTestId('fights-list')).toBeInTheDocument();
      });
    });
  });

  describe('Layout and Styling', () => {
    it('applies proper page layout classes', async () => {
      mockApiClient.events.get.mockResolvedValue(mockEvent);
      
      const { container } = render(<EventDetailPage />);
      
      await waitFor(() => {
        const page = container.querySelector('[data-testid="event-detail-page"]');
        expect(page).toHaveClass('space-y-8');
      });
    });

    it('displays proper loading skeleton structure', () => {
      mockApiClient.events.get.mockImplementation(() => new Promise(() => {}));
      
      render(<EventDetailPage />);
      
      expect(screen.getByTestId('event-header-skeleton')).toBeInTheDocument();
      expect(screen.getByTestId('fights-list-skeleton')).toBeInTheDocument();
    });
  });
});