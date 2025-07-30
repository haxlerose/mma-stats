import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { useRouter, useSearchParams, usePathname } from 'next/navigation';
import TopPerformersPage from '../page';
import { apiClient } from '@/lib/api';

// Mock next/navigation
jest.mock('next/navigation', () => ({
  useRouter: jest.fn(),
  useSearchParams: jest.fn(),
  usePathname: jest.fn(),
}));

// Mock API client
jest.mock('@/lib/api', () => ({
  apiClient: {
    topPerformers: {
      list: jest.fn(),
    },
  },
}));

describe('TopPerformersPage', () => {
  const mockPush = jest.fn();
  const mockReplace = jest.fn();
  const mockRouter = { push: mockPush, replace: mockReplace };
  const mockSearchParams = new URLSearchParams();

  beforeEach(() => {
    jest.clearAllMocks();
    (useRouter as jest.Mock).mockReturnValue(mockRouter);
    (useSearchParams as jest.Mock).mockReturnValue(mockSearchParams);
    (usePathname as jest.Mock).mockReturnValue('/top-performers');
  });

  describe('Results scope', () => {
    it('defaults to total_wins category when switching to results scope', async () => {
      // Initial load with career scope
      (apiClient.topPerformers.list as jest.Mock).mockResolvedValue({
        top_performers: [],
        meta: { scope: 'career', category: 'knockdowns' },
      });

      render(<TopPerformersPage />);

      await waitFor(() => {
        expect(screen.getByText('Top Performers')).toBeInTheDocument();
      });

      // Click on Results tab
      const resultsTab = screen.getByText('Results');
      fireEvent.click(resultsTab);

      expect(mockReplace).toHaveBeenCalledWith(
        '/top-performers?scope=results&category=total_wins'
      );
    });

    it('maintains results category when already on a results category', async () => {
      // Set initial params to results scope with win_percentage
      mockSearchParams.set('scope', 'results');
      mockSearchParams.set('category', 'win_percentage');

      (apiClient.topPerformers.list as jest.Mock).mockResolvedValue({
        top_performers: [],
        meta: { scope: 'results', category: 'win_percentage' },
      });

      render(<TopPerformersPage />);

      await waitFor(() => {
        expect(screen.getByText('Top Performers')).toBeInTheDocument();
      });

      // Click on Results tab again (should maintain category)
      const resultsTab = screen.getByText('Results');
      fireEvent.click(resultsTab);

      expect(mockReplace).toHaveBeenCalledWith(
        '/top-performers?scope=results&category=win_percentage'
      );
    });

    it('switches to knockdowns when leaving results scope', async () => {
      // Set initial params to results scope
      mockSearchParams.set('scope', 'results');
      mockSearchParams.set('category', 'total_wins');

      (apiClient.topPerformers.list as jest.Mock).mockResolvedValue({
        top_performers: [],
        meta: { scope: 'results', category: 'total_wins' },
      });

      render(<TopPerformersPage />);

      await waitFor(() => {
        expect(screen.getByText('Top Performers')).toBeInTheDocument();
      });

      // Click on Career tab
      const careerTab = screen.getByText('Career');
      fireEvent.click(careerTab);

      expect(mockReplace).toHaveBeenCalledWith(
        '/top-performers?scope=career&category=knockdowns'
      );
    });

    it('displays results-specific header text', async () => {
      mockSearchParams.set('scope', 'results');
      mockSearchParams.set('category', 'win_percentage');

      (apiClient.topPerformers.list as jest.Mock).mockResolvedValue({
        top_performers: [
          {
            fighter_id: 1,
            fighter_name: 'Test Fighter',
            win_percentage: 95.0,
            total_wins: 19,
            total_losses: 1,
          },
        ],
        meta: { scope: 'results', category: 'win_percentage' },
      });

      render(<TopPerformersPage />);

      await waitFor(() => {
        expect(screen.getByText('Career win/loss records and streaks')).toBeInTheDocument();
        expect(screen.getByText('Select a results statistic to view top performers:')).toBeInTheDocument();
      });
    });

    it('loads and displays results data correctly', async () => {
      mockSearchParams.set('scope', 'results');
      mockSearchParams.set('category', 'longest_win_streak');

      const mockPerformers = [
        {
          fighter_id: 1,
          fighter_name: 'Anderson Silva',
          longest_win_streak: 16,
          total_wins: 34,
        },
        {
          fighter_id: 2,
          fighter_name: 'Jon Jones',
          longest_win_streak: 13,
          total_wins: 27,
        },
      ];

      (apiClient.topPerformers.list as jest.Mock).mockResolvedValue({
        top_performers: mockPerformers,
        meta: { scope: 'results', category: 'longest_win_streak' },
      });

      render(<TopPerformersPage />);

      await waitFor(() => {
        expect(screen.getByText('Top 2: Longest Win Streak')).toBeInTheDocument();
        expect(screen.getByText('Anderson Silva')).toBeInTheDocument();
        expect(screen.getByText('Jon Jones')).toBeInTheDocument();
      });

      // Check API was called with correct params
      expect(apiClient.topPerformers.list).toHaveBeenCalledWith({
        scope: 'results',
        category: 'longest_win_streak',
        apply_threshold: false,
      });
    });
  });
});