/**
 * EventsPage Integration Tests
 * Tests for the EventsPage following TDD methodology
 */

import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import '@testing-library/jest-dom';
import EventsPage from '../page';
import { apiClient } from '@/lib/api';

// Mock the API client
jest.mock('@/lib/api');
const mockApiClient = apiClient as jest.Mocked<typeof apiClient>;

// Mock Next.js router
const mockPush = jest.fn();
const mockReplace = jest.fn();
jest.mock('next/navigation', () => ({
  useRouter: () => ({
    push: mockPush,
    replace: mockReplace
  }),
  useSearchParams: () => new URLSearchParams(),
  usePathname: () => '/events'
}));

const mockEventsResponse = {
  events: [
    {
      id: 1,
      name: 'UFC 309: Jones vs Miocic',
      date: '2024-11-16',
      location: 'Las Vegas, Nevada',
      fight_count: 13
    },
    {
      id: 2,
      name: 'UFC 308: Topuria vs Holloway',
      date: '2024-10-26',
      location: 'Abu Dhabi, United Arab Emirates',
      fight_count: 12
    }
  ],
  meta: {
    current_page: 1,
    total_pages: 1,
    total_count: 2,
    per_page: 20
  }
};

const mockLocations = [
  'Abu Dhabi, United Arab Emirates',
  'Las Vegas, Nevada',
  'London, England'
];

describe('EventsPage', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockApiClient.events.list.mockResolvedValue(mockEventsResponse);
    mockApiClient.events.locations.mockResolvedValue(mockLocations);
  });

  // Initial State tests
  test('loads events on component mount', async () => {
    render(<EventsPage />);
    
    await waitFor(() => {
      expect(mockApiClient.events.list).toHaveBeenCalledWith(undefined);
    });
  });

  test('displays loading state initially', () => {
    render(<EventsPage />);
    
    expect(screen.getByText('Loading events...')).toBeInTheDocument();
  });

  test('shows event cards after successful load', async () => {
    render(<EventsPage />);
    
    await waitFor(() => {
      expect(screen.getByText('UFC 309: Jones vs Miocic')).toBeInTheDocument();
      expect(screen.getByText('UFC 308: Topuria vs Holloway')).toBeInTheDocument();
    });
  });

  test('displays error message on load failure', async () => {
    mockApiClient.events.list.mockRejectedValue(new Error('API Error'));
    
    render(<EventsPage />);
    
    await waitFor(() => {
      expect(screen.getByText(/Failed to load events/)).toBeInTheDocument();
    });
  });

  // Location Filtering tests
  test('filters events when location selected from dropdown', async () => {
    const user = userEvent.setup();
    
    render(<EventsPage />);
    
    // Wait for initial load
    await waitFor(() => {
      expect(screen.getByText('UFC 309: Jones vs Miocic')).toBeInTheDocument();
    });
    
    // Open location dropdown
    const locationInput = screen.getByPlaceholderText('Search locations...');
    await user.click(locationInput);
    
    // Select Las Vegas
    const vegasOption = screen.getByText('Las Vegas, Nevada');
    await user.click(vegasOption);
    
    // Should call API with location filter
    await waitFor(() => {
      expect(mockApiClient.events.list).toHaveBeenCalledWith({
        location: 'Las Vegas, Nevada'
      });
    });
  });

  test('updates URL when location filter applied', async () => {
    const user = userEvent.setup();
    
    render(<EventsPage />);
    
    await waitFor(() => {
      expect(screen.getByText('UFC 309: Jones vs Miocic')).toBeInTheDocument();
    });
    
    const locationInput = screen.getByPlaceholderText('Search locations...');
    await user.click(locationInput);
    
    const vegasOption = screen.getByText('Las Vegas, Nevada');
    await user.click(vegasOption);
    
    expect(mockReplace).toHaveBeenCalledWith(
      expect.stringContaining('location=Las%20Vegas%2C%20Nevada')
    );
  });

  test('clears events filter when location cleared', async () => {
    const user = userEvent.setup();
    
    render(<EventsPage />);
    
    await waitFor(() => {
      expect(screen.getByText('UFC 309: Jones vs Miocic')).toBeInTheDocument();
    });
    
    // Select a location first
    const locationInput = screen.getByPlaceholderText('Search locations...');
    await user.click(locationInput);
    const vegasOption = screen.getByText('Las Vegas, Nevada');
    await user.click(vegasOption);
    
    // Clear the selection
    const clearButton = screen.getByLabelText('Clear selection');
    await user.click(clearButton);
    
    // Should call API without location filter
    await waitFor(() => {
      expect(mockApiClient.events.list).toHaveBeenCalledWith({});
    });
  });

  test('maintains location filter on page refresh', async () => {
    // Mock URL search params with location
    jest.mocked(require('next/navigation').useSearchParams).mockReturnValue(
      new URLSearchParams('location=Las Vegas, Nevada')
    );
    
    render(<EventsPage />);
    
    await waitFor(() => {
      expect(mockApiClient.events.list).toHaveBeenCalledWith({
        location: 'Las Vegas, Nevada'
      });
    });
  });

  // Sorting tests
  test('re-sorts events when sort toggle clicked', async () => {
    const user = userEvent.setup();
    
    render(<EventsPage />);
    
    await waitFor(() => {
      expect(screen.getByText('UFC 309: Jones vs Miocic')).toBeInTheDocument();
    });
    
    // Click sort toggle (should be "Newest First" by default)
    const sortButton = screen.getByText('Newest First');
    await user.click(sortButton);
    
    // Should now show "Oldest First" and call API with asc direction
    await waitFor(() => {
      expect(mockApiClient.events.list).toHaveBeenCalledWith({
        sort_direction: 'asc'
      });
    });
  });

  test('updates URL when sort direction changed', async () => {
    const user = userEvent.setup();
    
    render(<EventsPage />);
    
    await waitFor(() => {
      expect(screen.getByText('Newest First')).toBeInTheDocument();
    });
    
    const sortButton = screen.getByText('Newest First');
    await user.click(sortButton);
    
    expect(mockReplace).toHaveBeenCalledWith(
      expect.stringContaining('sort_direction=asc')
    );
  });

  test('maintains sort direction on page refresh', async () => {
    // Mock URL search params with sort direction
    jest.mocked(require('next/navigation').useSearchParams).mockReturnValue(
      new URLSearchParams('sort_direction=asc')
    );
    
    render(<EventsPage />);
    
    await waitFor(() => {
      expect(mockApiClient.events.list).toHaveBeenCalledWith({
        sort_direction: 'asc'
      });
    });
    
    // Should show "Oldest First" button
    expect(screen.getByText('Oldest First')).toBeInTheDocument();
  });

  // Pagination tests
  test('loads next page when pagination clicked', async () => {
    const user = userEvent.setup();
    
    // Mock response with multiple pages
    mockApiClient.events.list.mockResolvedValue({
      ...mockEventsResponse,
      meta: {
        current_page: 1,
        total_pages: 3,
        total_count: 60,
        per_page: 20
      }
    });
    
    render(<EventsPage />);
    
    await waitFor(() => {
      expect(screen.getByText('UFC 309: Jones vs Miocic')).toBeInTheDocument();
    });
    
    // Click next page
    const nextButton = screen.getByText('Next');
    await user.click(nextButton);
    
    await waitFor(() => {
      expect(mockApiClient.events.list).toHaveBeenCalledWith({
        page: 2
      });
    });
  });

  test('updates URL with page parameter', async () => {
    const user = userEvent.setup();
    
    mockApiClient.events.list.mockResolvedValue({
      ...mockEventsResponse,
      meta: {
        current_page: 1,
        total_pages: 3,
        total_count: 60,
        per_page: 20
      }
    });
    
    render(<EventsPage />);
    
    await waitFor(() => {
      expect(screen.getByText('Next')).toBeInTheDocument();
    });
    
    const nextButton = screen.getByText('Next');
    await user.click(nextButton);
    
    expect(mockReplace).toHaveBeenCalledWith(
      expect.stringContaining('page=2')
    );
  });

  test('resets to page 1 when filters change', async () => {
    const user = userEvent.setup();
    
    // Start on page 2
    jest.mocked(require('next/navigation').useSearchParams).mockReturnValue(
      new URLSearchParams('page=2')
    );
    
    render(<EventsPage />);
    
    await waitFor(() => {
      expect(screen.getByText('UFC 309: Jones vs Miocic')).toBeInTheDocument();
    });
    
    // Change location filter
    const locationInput = screen.getByPlaceholderText('Search locations...');
    await user.click(locationInput);
    const vegasOption = screen.getByText('Las Vegas, Nevada');
    await user.click(vegasOption);
    
    // Should reset to page 1
    await waitFor(() => {
      expect(mockApiClient.events.list).toHaveBeenCalledWith({
        location: 'Las Vegas, Nevada',
        page: 1
      });
    });
  });

  test('disables prev/next buttons appropriately', async () => {
    // Mock single page response
    mockApiClient.events.list.mockResolvedValue({
      ...mockEventsResponse,
      meta: {
        current_page: 1,
        total_pages: 1,
        total_count: 2,
        per_page: 20
      }
    });
    
    render(<EventsPage />);
    
    await waitFor(() => {
      expect(screen.getByText('UFC 309: Jones vs Miocic')).toBeInTheDocument();
    });
    
    // Both prev and next should be disabled on single page
    const prevButton = screen.getByText('Previous');
    const nextButton = screen.getByText('Next');
    
    expect(prevButton).toBeDisabled();
    expect(nextButton).toBeDisabled();
  });

  // Combined Behaviors tests
  test('applies both location filter and sort together', async () => {
    const user = userEvent.setup();
    
    render(<EventsPage />);
    
    await waitFor(() => {
      expect(screen.getByText('UFC 309: Jones vs Miocic')).toBeInTheDocument();
    });
    
    // Apply location filter
    const locationInput = screen.getByPlaceholderText('Search locations...');
    await user.click(locationInput);
    const vegasOption = screen.getByText('Las Vegas, Nevada');
    await user.click(vegasOption);
    
    // Apply sort
    const sortButton = screen.getByText('Newest First');
    await user.click(sortButton);
    
    await waitFor(() => {
      expect(mockApiClient.events.list).toHaveBeenCalledWith({
        location: 'Las Vegas, Nevada',
        sort_direction: 'asc'
      });
    });
  });

  test('maintains all filters during pagination', async () => {
    const user = userEvent.setup();
    
    mockApiClient.events.list.mockResolvedValue({
      ...mockEventsResponse,
      meta: {
        current_page: 1,
        total_pages: 2,
        total_count: 40,
        per_page: 20
      }
    });
    
    render(<EventsPage />);
    
    await waitFor(() => {
      expect(screen.getByText('UFC 309: Jones vs Miocic')).toBeInTheDocument();
    });
    
    // Apply filters
    const locationInput = screen.getByPlaceholderText('Search locations...');
    await user.click(locationInput);
    const vegasOption = screen.getByText('Las Vegas, Nevada');
    await user.click(vegasOption);
    
    const sortButton = screen.getByText('Newest First');
    await user.click(sortButton);
    
    // Navigate to next page
    const nextButton = screen.getByText('Next');
    await user.click(nextButton);
    
    await waitFor(() => {
      expect(mockApiClient.events.list).toHaveBeenCalledWith({
        location: 'Las Vegas, Nevada',
        sort_direction: 'asc',
        page: 2
      });
    });
  });

  test('restores state from URL parameters on load', async () => {
    // Mock URL with all parameters
    jest.mocked(require('next/navigation').useSearchParams).mockReturnValue(
      new URLSearchParams('location=Las Vegas, Nevada&sort_direction=asc&page=2')
    );
    
    render(<EventsPage />);
    
    await waitFor(() => {
      expect(mockApiClient.events.list).toHaveBeenCalledWith({
        location: 'Las Vegas, Nevada',
        sort_direction: 'asc',
        page: 2
      });
    });
    
    // UI should reflect the state
    expect(screen.getByDisplayValue('Las Vegas, Nevada')).toBeInTheDocument();
    expect(screen.getByText('Oldest First')).toBeInTheDocument();
  });

  // Performance tests
  test('shows skeleton loading states', () => {
    render(<EventsPage />);
    
    // Should show multiple skeleton cards while loading
    const skeletons = screen.getAllByText('Loading events...');
    expect(skeletons.length).toBeGreaterThan(0);
  });
});