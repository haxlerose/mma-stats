import React from 'react';
import { render, screen } from '@testing-library/react';
import { PerformerCard } from '../PerformerCard';
import { TopPerformer } from '@/types/api';

// Mock Next.js Link component
jest.mock('next/link', () => {
  return {
    __esModule: true,
    default: ({ children, href }: { children: React.ReactNode; href: string }) => (
      <a href={href}>{children}</a>
    ),
  };
});

describe('PerformerCard', () => {
  const basePerformer: TopPerformer = {
    fighter_id: 123,
    fighter_name: 'John Doe',
    fight_id: 456,
  };

  describe('Career scope', () => {
    it('displays total statistics for career scope', () => {
      const performer = {
        ...basePerformer,
        total_knockdowns: 15,
      };

      render(
        <PerformerCard
          performer={performer}
          rank={1}
          scope="career"
          category="knockdowns"
        />
      );

      expect(screen.getByText('15')).toBeInTheDocument();
    });

    it('formats control time correctly for career scope', () => {
      const performer = {
        ...basePerformer,
        total_control_time_seconds: 725, // 12:05
      };

      render(
        <PerformerCard
          performer={performer}
          rank={2}
          scope="career"
          category="control_time_seconds"
        />
      );

      expect(screen.getByText('12:05')).toBeInTheDocument();
    });
  });

  describe('Fight scope', () => {
    it('displays maximum statistics for fight scope', () => {
      const performer = {
        ...basePerformer,
        max_significant_strikes: 150,
        event_name: 'UFC 300',
        opponent_name: 'Jane Smith',
      };

      render(
        <PerformerCard
          performer={performer}
          rank={3}
          scope="fight"
          category="significant_strikes"
        />
      );

      expect(screen.getByText('150')).toBeInTheDocument();
      expect(screen.getByText('vs.')).toBeInTheDocument();
      expect(screen.getByText('Jane Smith')).toBeInTheDocument();
      expect(screen.getByText('UFC 300')).toBeInTheDocument();
    });
  });

  describe('Round scope', () => {
    it('displays round information', () => {
      const performer = {
        ...basePerformer,
        max_total_strikes: 50,
        event_name: 'UFC 299',
        opponent_name: 'Bob Johnson',
        round: 3,
      };

      render(
        <PerformerCard
          performer={performer}
          rank={4}
          scope="round"
          category="total_strikes"
        />
      );

      expect(screen.getByText('50')).toBeInTheDocument();
      expect(screen.getByText('Round 3')).toBeInTheDocument();
      expect(screen.getByText('Bob Johnson')).toBeInTheDocument();
    });
  });

  describe('Per minute scope', () => {
    it('displays rate statistics with two decimal places', () => {
      const performer = {
        ...basePerformer,
        takedowns_per_15_minutes: 2.567,
        fight_duration_minutes: 45.5,
        total_takedowns: 15,
      };

      render(
        <PerformerCard
          performer={performer}
          rank={5}
          scope="per_minute"
          category="takedowns"
        />
      );

      expect(screen.getByText('2.57 per 15 min')).toBeInTheDocument();
      expect(screen.getByText('Fight time:')).toBeInTheDocument();
      expect(screen.getByText('45.5 minutes')).toBeInTheDocument();
      expect(screen.getByText('Total:')).toBeInTheDocument();
      expect(screen.getByText('15')).toBeInTheDocument();
    });
  });

  describe('Rank styling', () => {
    it('applies gold styling for rank 1', () => {
      render(
        <PerformerCard
          performer={basePerformer}
          rank={1}
          scope="career"
          category="knockdowns"
        />
      );

      // Find the rank element and check its container
      const rankElement = screen.getByText('1');
      const rankContainer = rankElement.closest('div.rounded-full');
      expect(rankContainer).toHaveClass('bg-gradient-to-r', 'from-yellow-400', 'to-amber-500');
    });

    it('applies silver styling for rank 2', () => {
      render(
        <PerformerCard
          performer={basePerformer}
          rank={2}
          scope="career"
          category="knockdowns"
        />
      );

      // Find the rank element and check its container
      const rankElement = screen.getByText('2');
      const rankContainer = rankElement.closest('div.rounded-full');
      expect(rankContainer).toHaveClass('bg-gradient-to-r', 'from-gray-300', 'to-gray-400');
    });

    it('applies bronze styling for rank 3', () => {
      render(
        <PerformerCard
          performer={basePerformer}
          rank={3}
          scope="career"
          category="knockdowns"
        />
      );

      // Find the rank element and check its container
      const rankElement = screen.getByText('3');
      const rankContainer = rankElement.closest('div.rounded-full');
      expect(rankContainer).toHaveClass('bg-gradient-to-r', 'from-orange-400', 'to-orange-500');
    });

    it('applies default styling for rank 4+', () => {
      render(
        <PerformerCard
          performer={basePerformer}
          rank={4}
          scope="career"
          category="knockdowns"
        />
      );

      // Find the rank element and check its container
      const rankElement = screen.getByText('4');
      const rankContainer = rankElement.closest('div.rounded-full');
      expect(rankContainer).toHaveClass('bg-gray-100', 'text-gray-700');
    });
  });

  it('creates correct fighter link', () => {
    render(
      <PerformerCard
        performer={basePerformer}
        rank={1}
        scope="career"
        category="knockdowns"
      />
    );

    const fighterLink = screen.getByText('John Doe').closest('a');
    expect(fighterLink).toHaveAttribute('href', '/fighters/123');
  });

  describe('Accuracy scope', () => {
    it('displays accuracy percentage with one decimal place', () => {
      const performer = {
        ...basePerformer,
        accuracy_percentage: 75.567,
        value: 75.567,
        total_significant_strikes: 150,
        total_significant_strikes_attempted: 200,
        total_fights: 10,
      };

      render(
        <PerformerCard
          performer={performer}
          rank={1}
          scope="accuracy"
          category="significant_strike_accuracy"
        />
      );

      expect(screen.getByText('75.6%')).toBeInTheDocument();
      expect(screen.getByText('Landed:')).toBeInTheDocument();
      expect(screen.getByText('150')).toBeInTheDocument();
      expect(screen.getByText('Attempted:')).toBeInTheDocument();
      expect(screen.getByText('200')).toBeInTheDocument();
      expect(screen.getByText('Fight count:')).toBeInTheDocument();
      expect(screen.getByText('10')).toBeInTheDocument();
    });

    it('handles missing accuracy fields gracefully', () => {
      const performer = {
        ...basePerformer,
        value: 68.9,
      };

      render(
        <PerformerCard
          performer={performer}
          rank={2}
          scope="accuracy"
          category="significant_strike_accuracy"
        />
      );

      expect(screen.getByText('68.9%')).toBeInTheDocument();
      // Check for all three "0" values
      const zeroElements = screen.getAllByText('0');
      expect(zeroElements).toHaveLength(3); // Landed, Attempted, Fight count
    });
  });

  describe('Results scope', () => {
    it('displays total wins correctly', () => {
      const performer = {
        ...basePerformer,
        total_wins: 25,
        win_percentage: 83.3,
      };

      render(
        <PerformerCard
          performer={performer}
          rank={1}
          scope="results"
          category="total_wins"
        />
      );

      expect(screen.getByText('25')).toBeInTheDocument();
      expect(screen.getByText('Win rate:')).toBeInTheDocument();
      expect(screen.getByText('83.3%')).toBeInTheDocument();
    });

    it('displays total losses correctly', () => {
      const performer = {
        ...basePerformer,
        total_losses: 5,
        win_percentage: 83.3,
      };

      render(
        <PerformerCard
          performer={performer}
          rank={2}
          scope="results"
          category="total_losses"
        />
      );

      expect(screen.getByText('5')).toBeInTheDocument();
      expect(screen.getByText('Win rate:')).toBeInTheDocument();
      expect(screen.getByText('83.3%')).toBeInTheDocument();
    });

    it('displays win percentage with context', () => {
      const performer = {
        ...basePerformer,
        win_percentage: 91.7,
        total_wins: 22,
        total_losses: 2,
      };

      render(
        <PerformerCard
          performer={performer}
          rank={1}
          scope="results"
          category="win_percentage"
        />
      );

      expect(screen.getByText('91.7%')).toBeInTheDocument();
      expect(screen.getByText('Wins:')).toBeInTheDocument();
      expect(screen.getByText('22')).toBeInTheDocument();
      expect(screen.getByText('Losses:')).toBeInTheDocument();
      expect(screen.getByText('2')).toBeInTheDocument();
      expect(screen.getByText('Total fights:')).toBeInTheDocument();
      expect(screen.getByText('24')).toBeInTheDocument();
    });

    it('displays longest win streak with career wins', () => {
      const performer = {
        ...basePerformer,
        longest_win_streak: 15,
        total_wins: 30,
      };

      render(
        <PerformerCard
          performer={performer}
          rank={3}
          scope="results"
          category="longest_win_streak"
        />
      );

      expect(screen.getByText('15')).toBeInTheDocument();
      expect(screen.getByText('Career wins:')).toBeInTheDocument();
      expect(screen.getByText('30')).toBeInTheDocument();
    });

    it('handles missing results data gracefully', () => {
      const performer = {
        ...basePerformer,
      };

      render(
        <PerformerCard
          performer={performer}
          rank={4}
          scope="results"
          category="win_percentage"
        />
      );

      expect(screen.getByText('0%')).toBeInTheDocument();
      expect(screen.getByText('Total fights:')).toBeInTheDocument();
      // Check for all zero values
      const zeroElements = screen.getAllByText('0');
      expect(zeroElements.length).toBeGreaterThan(0);
    });
  });
});