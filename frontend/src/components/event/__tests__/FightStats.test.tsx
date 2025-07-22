import React from 'react';
import { render, screen } from '@testing-library/react';
import { FightStats } from '../FightStats';
import { Fight } from '@/types/api';

describe('FightStats', () => {
  const mockFight: Fight = {
    id: 1,
    bout: 'Jon Jones vs Stipe Miocic',
    outcome: 'Jones wins by TKO',
    weight_class: 'Heavyweight',
    method: 'TKO',
    round: 3,
    time: '4:29',
    time_format: '5:00',
    referee: 'Herb Dean',
    details: null,
    fight_stats: [
      {
        id: 1,
        fight_id: 1,
        fighter_id: 1,
        round: 1,
        knockdowns: 0,
        significant_strikes: 12,
        significant_strikes_attempted: 18,
        total_strikes: 15,
        total_strikes_attempted: 22,
        head_strikes: 8,
        head_strikes_attempted: 12,
        body_strikes: 3,
        body_strikes_attempted: 4,
        leg_strikes: 1,
        leg_strikes_attempted: 2,
        distance_strikes: 10,
        distance_strikes_attempted: 15,
        clinch_strikes: 2,
        clinch_strikes_attempted: 3,
        ground_strikes: 0,
        ground_strikes_attempted: 0,
        takedowns: 1,
        takedowns_attempted: 2,
        submission_attempts: 0,
        reversals: 0,
        control_time_seconds: 45,
        fighter: {
          id: 1,
          name: 'Jon Jones',
          height_in_inches: 76,
          reach_in_inches: 84,
          birth_date: '1987-07-19'
        }
      },
      {
        id: 2,
        fight_id: 1,
        fighter_id: 2,
        round: 1,
        knockdowns: 0,
        significant_strikes: 8,
        significant_strikes_attempted: 15,
        total_strikes: 10,
        total_strikes_attempted: 18,
        head_strikes: 5,
        head_strikes_attempted: 10,
        body_strikes: 2,
        body_strikes_attempted: 3,
        leg_strikes: 1,
        leg_strikes_attempted: 2,
        distance_strikes: 7,
        distance_strikes_attempted: 13,
        clinch_strikes: 1,
        clinch_strikes_attempted: 2,
        ground_strikes: 0,
        ground_strikes_attempted: 0,
        takedowns: 0,
        takedowns_attempted: 1,
        submission_attempts: 0,
        reversals: 0,
        control_time_seconds: 30,
        fighter: {
          id: 2,
          name: 'Stipe Miocic',
          height_in_inches: 76,
          reach_in_inches: 80,
          birth_date: '1982-08-19'
        }
      }
    ]
  };

  describe('Basic Rendering', () => {
    it('displays fight statistics section', () => {
      render(<FightStats fight={mockFight} />);
      
      expect(screen.getByTestId('fight-stats')).toBeInTheDocument();
    });

    it('shows fight totals first instead of round-by-round', () => {
      render(<FightStats fight={mockFight} />);
      
      expect(screen.getByText('Fight Totals')).toBeInTheDocument();
      // Should not show individual rounds by default
      expect(screen.queryByText('Round 1')).not.toBeInTheDocument();
    });

    it('shows both fighters names in fight totals', () => {
      render(<FightStats fight={mockFight} />);
      
      expect(screen.getAllByText('Jon Jones')).toHaveLength(2); // Desktop and mobile
      expect(screen.getAllByText('Stipe Miocic')).toHaveLength(2); // Desktop and mobile
    });

    it('shows significant strikes data for both fighters', () => {
      render(<FightStats fight={mockFight} />);
      
      // Jones: 12 of 18 significant strikes (appears in both desktop and mobile)
      expect(screen.getAllByText('12/18')).toHaveLength(2);
      // Miocic: 8 of 15 significant strikes  
      expect(screen.getAllByText('8/15')).toHaveLength(2);
    });

    it('displays total strikes data for both fighters', () => {
      render(<FightStats fight={mockFight} />);
      
      // Jones: 15 of 22 total strikes (appears in both desktop and mobile)
      expect(screen.getAllByText('15/22')).toHaveLength(2);
      // Miocic: 10 of 18 total strikes
      expect(screen.getAllByText('10/18')).toHaveLength(2);
    });

    it('shows takedown statistics', () => {
      render(<FightStats fight={mockFight} />);
      
      // Should show abbreviated "Td" label (1 desktop header + 2 mobile labels for each fighter)
      expect(screen.getAllByText('Td')).toHaveLength(3); 
      
      // Check that takedown data appears (appears in both desktop and mobile)
      const takedownElements = screen.getAllByText('1/2');
      expect(takedownElements.length).toBeGreaterThan(0);
      
      const zeroTakedownElements = screen.getAllByText('0/1');
      expect(zeroTakedownElements.length).toBeGreaterThan(0);
    });

    it('displays control time for both fighters', () => {
      render(<FightStats fight={mockFight} />);
      
      // Jones: 45 seconds = 0:45 (appears in both desktop and mobile)
      expect(screen.getAllByText('0:45')).toHaveLength(2);
      // Miocic: 30 seconds = 0:30
      expect(screen.getAllByText('0:30')).toHaveLength(2);
    });
  });

  describe('Data Organization', () => {
    it('shows expandable round-by-round details for multi-round fights', () => {
      const multiRoundFight = {
        ...mockFight,
        fight_stats: [
          ...mockFight.fight_stats,
          {
            id: 3,
            fight_id: 1,
            fighter_id: 1,
            round: 2,
            knockdowns: 0,
            significant_strikes: 5,
            significant_strikes_attempted: 8,
            total_strikes: 6,
            total_strikes_attempted: 9,
            head_strikes: 4,
            head_strikes_attempted: 6,
            body_strikes: 1,
            body_strikes_attempted: 2,
            leg_strikes: 0,
            leg_strikes_attempted: 0,
            distance_strikes: 5,
            distance_strikes_attempted: 8,
            clinch_strikes: 0,
            clinch_strikes_attempted: 0,
            ground_strikes: 0,
            ground_strikes_attempted: 0,
            takedowns: 0,
            takedowns_attempted: 0,
            submission_attempts: 0,
            reversals: 0,
            control_time_seconds: 20,
            fighter: {
              id: 1,
              name: 'Jon Jones',
              height_in_inches: 76,
              reach_in_inches: 84,
              birth_date: '1987-07-19'
            }
          }
        ]
      };

      render(<FightStats fight={multiRoundFight} />);
      
      // Should show a button to view round details
      expect(screen.getByRole('button', { name: /view round details/i })).toBeInTheDocument();
      // Rounds should not be visible by default
      expect(screen.queryByText('Round 1')).not.toBeInTheDocument();
      expect(screen.queryByText('Round 2')).not.toBeInTheDocument();
    });

    it('handles fights with no statistics', () => {
      const fightWithoutStats = {
        ...mockFight,
        fight_stats: []
      };

      render(<FightStats fight={fightWithoutStats} />);
      
      expect(screen.getByText('No fight statistics available.')).toBeInTheDocument();
    });

    it('calculates totals across all rounds', () => {
      const multiRoundFight = {
        ...mockFight,
        fight_stats: [
          ...mockFight.fight_stats,
          // Add Round 2 for Jones
          {
            id: 3,
            fight_id: 1,
            fighter_id: 1,
            round: 2,
            knockdowns: 1,
            significant_strikes: 8,
            significant_strikes_attempted: 10,
            total_strikes: 9,
            total_strikes_attempted: 12,
            head_strikes: 6,
            head_strikes_attempted: 8,
            body_strikes: 2,
            body_strikes_attempted: 2,
            leg_strikes: 0,
            leg_strikes_attempted: 0,
            distance_strikes: 8,
            distance_strikes_attempted: 10,
            clinch_strikes: 0,
            clinch_strikes_attempted: 0,
            ground_strikes: 0,
            ground_strikes_attempted: 0,
            takedowns: 0,
            takedowns_attempted: 1,
            submission_attempts: 0,
            reversals: 0,
            control_time_seconds: 15,
            fighter: {
              id: 1,
              name: 'Jon Jones',
              height_in_inches: 76,
              reach_in_inches: 84,
              birth_date: '1987-07-19'
            }
          }
        ]
      };

      render(<FightStats fight={multiRoundFight} />);
      
      // Should show totals section
      expect(screen.getByText('Fight Totals')).toBeInTheDocument();
      
      // Jones totals: Round 1 (12) + Round 2 (8) = 20 sig strikes
      // Jones totals: Round 1 (18) + Round 2 (10) = 28 sig strikes attempted
      expect(screen.getAllByText('20/28')).toHaveLength(2); // Desktop and mobile
    });
  });

  describe('Statistics Categories', () => {
    it('displays abbreviated labels for better UX', () => {
      render(<FightStats fight={mockFight} />);
      
      // Labels appear multiple times (desktop header + mobile labels for each fighter)
      expect(screen.getAllByText('KD')).toHaveLength(3); // 1 desktop + 2 mobile
      expect(screen.getAllByText('Sig. str.')).toHaveLength(3);
      expect(screen.getAllByText('Sig. str. %')).toHaveLength(3);
      expect(screen.getAllByText('Total str.')).toHaveLength(3);
      expect(screen.getAllByText('Td')).toHaveLength(3);
      expect(screen.getAllByText('Td %')).toHaveLength(3);
      expect(screen.getAllByText('Sub. att')).toHaveLength(3);
      expect(screen.getAllByText('Rev.')).toHaveLength(3);
      expect(screen.getAllByText('Ctrl')).toHaveLength(3);
    });

    it('uses horizontal layout for desktop screens', () => {
      const { container } = render(<FightStats fight={mockFight} />);
      
      const statsTable = container.querySelector('[data-testid="fight-totals-table"]');
      expect(statsTable).toHaveClass('hidden', 'md:block');
    });

    it('uses vertical layout for mobile screens', () => {
      const { container } = render(<FightStats fight={mockFight} />);
      
      const mobileStats = container.querySelector('[data-testid="fight-totals-mobile"]');
      expect(mobileStats).toHaveClass('block', 'md:hidden');
    });
  });

  describe('Data Formatting', () => {
    it('formats control time from seconds to MM:SS', () => {
      render(<FightStats fight={mockFight} />);
      
      // 45 seconds should be formatted as 0:45 (desktop and mobile)
      expect(screen.getAllByText('0:45')).toHaveLength(2);
      // 30 seconds should be formatted as 0:30
      expect(screen.getAllByText('0:30')).toHaveLength(2);
    });

    it('handles zero values appropriately', () => {
      render(<FightStats fight={mockFight} />);
      
      // Both fighters have 0 knockdowns, 0 sub. att, 0 reversals (appears in desktop and mobile)
      // That's 3 zero stats per fighter × 2 fighters × 2 layouts = 12 total
      const zeroElements = screen.getAllByText('0');
      expect(zeroElements.length).toBeGreaterThanOrEqual(4);
    });

    it('displays percentage calculations for accuracy', () => {
      render(<FightStats fight={mockFight} />);
      
      // Jones significant strike accuracy: 12/18 = 66.7%
      expect(screen.getAllByText('67%')).toHaveLength(2); // Desktop and mobile
      // Miocic significant strike accuracy: 8/15 = 53.3%
      expect(screen.getAllByText('53%')).toHaveLength(2); // Desktop and mobile
    });
  });

  describe('Visual Layout', () => {
    it('applies proper table styling', () => {
      const { container } = render(<FightStats fight={mockFight} />);
      
      const table = container.querySelector('table');
      expect(table).toHaveClass('w-full');
    });

    it('uses semantic HTML structure', () => {
      const { container } = render(<FightStats fight={mockFight} />);
      
      expect(container.querySelector('table')).toBeInTheDocument();
      expect(container.querySelector('thead')).toBeInTheDocument();
      expect(container.querySelector('tbody')).toBeInTheDocument();
    });

    it('has accessible column headers', () => {
      render(<FightStats fight={mockFight} />);
      
      // Should have column headers for desktop table
      expect(screen.getByRole('columnheader', { name: /fighter/i })).toBeInTheDocument();
      expect(screen.getAllByRole('columnheader', { name: /kd/i })).toHaveLength(1);
      expect(screen.getAllByRole('columnheader')).toContainEqual(
        expect.objectContaining({ textContent: 'Sig. str.' })
      );
    });
  });
});