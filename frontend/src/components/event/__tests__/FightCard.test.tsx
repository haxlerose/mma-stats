import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { FightCard } from '../FightCard';
import { Fight } from '@/types/api';

// Mock FightStats component
jest.mock('../FightStats', () => ({
  FightStats: ({ fight }: { fight: Fight }) => (
    <div data-testid="fight-stats">
      Stats for {fight.bout}
    </div>
  ),
}));

describe('FightCard', () => {
  const mockFight: Fight = {
    id: 1,
    bout: 'Jon Jones vs. Stipe Miocic',
    outcome: 'Jones wins',
    weight_class: 'Heavyweight',
    method: 'TKO',
    round: 3,
    time: '4:29',
    time_format: '5:00',
    referee: 'Herb Dean',
    details: null,
    fight_stats: []
  };

  const defaultProps = {
    fight: mockFight,
    isExpanded: false,
    onToggle: jest.fn(),
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Basic Rendering', () => {
    it('displays fighter matchup clearly', () => {
      render(<FightCard {...defaultProps} />);
      
      // Fighters are now displayed separately with WIN/LOSS indicators
      expect(screen.getByText('Jon Jones')).toBeInTheDocument();
      expect(screen.getByText('Stipe Miocic')).toBeInTheDocument();
      expect(screen.getByText('VS')).toBeInTheDocument();
    });

    it('shows weight class information', () => {
      render(<FightCard {...defaultProps} />);
      
      expect(screen.getByText(/Heavyweight/)).toBeInTheDocument();
    });

    it('displays fight method and finish details', () => {
      render(<FightCard {...defaultProps} />);
      
      expect(screen.getByText(/TKO/)).toBeInTheDocument();
      expect(screen.getByText(/Round 3 • 4:29/)).toBeInTheDocument();
    });

    it('shows referee information', () => {
      render(<FightCard {...defaultProps} />);
      
      expect(screen.getByText(/Herb Dean/)).toBeInTheDocument();
    });

    it('applies proper card styling', () => {
      const { container } = render(<FightCard {...defaultProps} />);
      
      const card = container.querySelector('[data-testid="fight-card"]');
      expect(card).toHaveClass('bg-white', 'rounded-lg', 'shadow-sm', 'border');
    });
  });

  describe('Winner Indication', () => {
    it('highlights winner with visual styling when outcome includes "wins"', () => {
      const fightWithWinner = {
        ...mockFight,
        outcome: 'Jones wins by TKO'
      };
      
      render(<FightCard {...defaultProps} fight={fightWithWinner} />);
      
      expect(screen.getByTestId('winner-badge')).toBeInTheDocument();
      expect(screen.getByText('Jon Jones')).toBeInTheDocument();
    });

    it('shows winner indicator icon', () => {
      const fightWithWinner = {
        ...mockFight,
        outcome: 'Jones wins'
      };
      
      render(<FightCard {...defaultProps} fight={fightWithWinner} />);
      
      expect(screen.getByText('WIN')).toBeInTheDocument();
    });

    it('handles outcome without clear winner', () => {
      const drawFight = {
        ...mockFight,
        outcome: 'Draw'
      };
      
      render(<FightCard {...defaultProps} fight={drawFight} />);
      
      expect(screen.getByText('Draw')).toBeInTheDocument();
      expect(screen.queryByText('WIN')).not.toBeInTheDocument();
    });

    it('extracts winner name correctly from different outcome formats', () => {
      const testCases = [
        { outcome: 'Jones wins by TKO', expectedWinner: 'Jon Jones' },
        { outcome: 'Miocic defeats Jones', expectedWinner: 'Stipe Miocic' },
        { outcome: 'Jones victory', expectedWinner: 'Jon Jones' },
        { outcome: 'W/L', expectedWinner: 'Jon Jones' }, // First fighter wins in W/L format
        { outcome: 'L/W', expectedWinner: 'Stipe Miocic' }, // Second fighter wins in L/W format
        { outcome: 'No Contest', expectedWinner: null }
      ];

      testCases.forEach(({ outcome, expectedWinner }, index) => {
        const { unmount } = render(<FightCard {...defaultProps} fight={{ ...mockFight, outcome }} />);
        
        if (expectedWinner) {
          expect(screen.getByText('WIN')).toBeInTheDocument();
          expect(screen.getByText(expectedWinner)).toBeInTheDocument();
        } else {
          expect(screen.queryByText('WIN')).not.toBeInTheDocument();
        }
        
        unmount(); // Clean up for next iteration
      });
    });

    it('shows clear winner and loser labels for each fighter', () => {
      const fightWithClearWinLoss = {
        ...mockFight,
        outcome: 'Jones wins by TKO'
      };
      
      render(<FightCard {...defaultProps} fight={fightWithClearWinLoss} />);
      
      // Should show "WIN" for the winner
      expect(screen.getByTestId('winner-badge')).toBeInTheDocument();
      expect(screen.getByText('WIN')).toBeInTheDocument();
      
      // Should show "LOSS" for the loser  
      expect(screen.getByTestId('loser-badge')).toBeInTheDocument();
      expect(screen.getByText('LOSS')).toBeInTheDocument();
    });

    it('displays winner with green styling', () => {
      const fightWithWinner = {
        ...mockFight,
        outcome: 'Jones wins by submission'
      };
      
      render(<FightCard {...defaultProps} fight={fightWithWinner} />);
      
      const winnerBadge = screen.getByTestId('winner-badge');
      expect(winnerBadge).toHaveClass('bg-green-100', 'text-green-800', 'border-green-300');
    });

    it('displays loser with red styling', () => {
      const fightWithWinner = {
        ...mockFight,
        outcome: 'Jones wins by decision'
      };
      
      render(<FightCard {...defaultProps} fight={fightWithWinner} />);
      
      const loserBadge = screen.getByTestId('loser-badge');
      expect(loserBadge).toHaveClass('bg-red-100', 'text-red-800', 'border-red-300');
    });

    it('shows both fighters with result indicators in bout display', () => {
      const fightWithResult = {
        ...mockFight,
        bout: 'Jon Jones vs. Stipe Miocic',
        outcome: 'Jon Jones wins by TKO'
      };
      
      render(<FightCard {...defaultProps} fight={fightWithResult} />);
      
      // Should show fighters split with win/loss indicators
      expect(screen.getByTestId('fight-matchup')).toBeInTheDocument();
      expect(screen.getByText('Jon Jones')).toBeInTheDocument();
      expect(screen.getByText('Stipe Miocic')).toBeInTheDocument();
      expect(screen.getByText('WIN')).toBeInTheDocument();
      expect(screen.getByText('LOSS')).toBeInTheDocument();
    });
  });

  describe('Accordion Functionality', () => {
    it('starts in collapsed state by default', () => {
      render(<FightCard {...defaultProps} />);
      
      expect(screen.queryByTestId('fight-stats')).not.toBeInTheDocument();
      expect(screen.getByLabelText(/expand fight details/i)).toBeInTheDocument();
    });

    it('shows expand indicator when collapsed', () => {
      render(<FightCard {...defaultProps} />);
      
      const expandButton = screen.getByRole('button');
      expect(expandButton).toHaveAttribute('aria-expanded', 'false');
      expect(screen.getByText('▼')).toBeInTheDocument();
    });

    it('shows collapse indicator when expanded', () => {
      render(<FightCard {...defaultProps} isExpanded={true} />);
      
      const collapseButton = screen.getByRole('button');
      expect(collapseButton).toHaveAttribute('aria-expanded', 'true');
      expect(screen.getByText('▲')).toBeInTheDocument();
    });

    it('displays fight stats when expanded', () => {
      render(<FightCard {...defaultProps} isExpanded={true} />);
      
      expect(screen.getByTestId('fight-stats')).toBeInTheDocument();
      expect(screen.getByText('Stats for Jon Jones vs. Stipe Miocic')).toBeInTheDocument();
    });

    it('calls onToggle when clicked', async () => {
      const user = userEvent.setup();
      const mockOnToggle = jest.fn();
      
      render(<FightCard {...defaultProps} onToggle={mockOnToggle} />);
      
      await user.click(screen.getByRole('button'));
      
      expect(mockOnToggle).toHaveBeenCalledWith(1);
    });

    it('handles keyboard interaction (Enter key)', () => {
      const mockOnToggle = jest.fn();
      
      render(<FightCard {...defaultProps} onToggle={mockOnToggle} />);
      
      const button = screen.getByRole('button');
      fireEvent.keyDown(button, { key: 'Enter', code: 'Enter' });
      
      expect(mockOnToggle).toHaveBeenCalledWith(1);
    });

    it('handles keyboard interaction (Space key)', () => {
      const mockOnToggle = jest.fn();
      
      render(<FightCard {...defaultProps} onToggle={mockOnToggle} />);
      
      const button = screen.getByRole('button');
      fireEvent.keyDown(button, { key: ' ', code: 'Space' });
      
      expect(mockOnToggle).toHaveBeenCalledWith(1);
    });
  });

  describe('Edge Cases and Data Handling', () => {
    it('handles missing bout information', () => {
      const fightWithoutBout = {
        ...mockFight,
        bout: ''
      };
      
      render(<FightCard {...defaultProps} fight={fightWithoutBout} />);
      
      expect(screen.getByText('Fight details unavailable')).toBeInTheDocument();
    });

    it('handles missing method information', () => {
      const fightWithoutMethod = {
        ...mockFight,
        method: ''
      };
      
      render(<FightCard {...defaultProps} fight={fightWithoutMethod} />);
      
      expect(screen.getByText(/Method TBD/)).toBeInTheDocument();
    });

    it('handles missing round/time information', () => {
      const fightWithoutRoundTime = {
        ...mockFight,
        round: null as any,
        time: ''
      };
      
      render(<FightCard {...defaultProps} fight={fightWithoutRoundTime} />);
      
      expect(screen.getByText(/Time\/Round TBD/)).toBeInTheDocument();
    });

    it('handles missing referee information', () => {
      const fightWithoutReferee = {
        ...mockFight,
        referee: ''
      };
      
      render(<FightCard {...defaultProps} fight={fightWithoutReferee} />);
      
      expect(screen.getByText(/Referee TBD/)).toBeInTheDocument();
    });

    it('handles very long fighter names', () => {
      const fightWithLongNames = {
        ...mockFight,
        bout: 'Jon "Bones" Jones The Light Heavyweight Champion vs. Stipe "The Firefighter from Cleveland" Miocic'
      };
      
      render(<FightCard {...defaultProps} fight={fightWithLongNames} />);
      
      expect(screen.getByText(fightWithLongNames.bout)).toBeInTheDocument();
    });
  });

  describe('Accessibility', () => {
    it('has proper ARIA attributes for accordion', () => {
      render(<FightCard {...defaultProps} />);
      
      const button = screen.getByRole('button');
      expect(button).toHaveAttribute('aria-expanded', 'false');
      expect(button).toHaveAttribute('aria-controls');
      expect(button).toHaveAttribute('aria-label');
    });

    it('updates ARIA attributes when expanded', () => {
      render(<FightCard {...defaultProps} isExpanded={true} />);
      
      const button = screen.getByRole('button');
      expect(button).toHaveAttribute('aria-expanded', 'true');
    });

    it('has proper tabindex for keyboard navigation', () => {
      render(<FightCard {...defaultProps} />);
      
      const button = screen.getByRole('button');
      expect(button).toHaveAttribute('tabindex', '0');
    });

    it('has semantic HTML structure', () => {
      const { container } = render(<FightCard {...defaultProps} />);
      
      const article = container.querySelector('article');
      expect(article).toBeInTheDocument();
    });
  });

  describe('Visual Design', () => {
    it('applies hover effects on interactive elements', () => {
      const { container } = render(<FightCard {...defaultProps} />);
      
      const button = screen.getByRole('button');
      expect(button.parentElement).toHaveClass('hover:shadow-md');
    });

    it('shows winner styling appropriately', () => {
      const fightWithClearWinner = {
        ...mockFight,
        outcome: 'Jones wins by submission'
      };
      
      render(<FightCard {...defaultProps} fight={fightWithClearWinner} />);
      
      const winnerBadge = screen.getByTestId('winner-badge');
      expect(winnerBadge).toHaveClass('bg-green-100', 'text-green-800', 'border-green-300');
    });

    it('uses consistent spacing and typography', () => {
      const { container } = render(<FightCard {...defaultProps} />);
      
      const fightInfo = container.querySelector('[data-testid="fight-info"]');
      expect(fightInfo).toHaveClass('space-y-3');
    });
  });
});