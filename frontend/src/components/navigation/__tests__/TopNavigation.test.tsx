import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { TopNavigation } from '../TopNavigation';

// Mock Next.js navigation hooks
const mockPush = jest.fn();
const mockPathname = jest.fn();

jest.mock('next/navigation', () => ({
  useRouter: () => ({
    push: mockPush,
  }),
  usePathname: () => mockPathname(),
}));

describe('TopNavigation', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockPathname.mockReturnValue('/');
  });

  describe('Rendering', () => {
    it('renders app title linking to dashboard', () => {
      render(<TopNavigation />);
      
      const logo = screen.getByRole('link', { name: /mma stats/i });
      expect(logo).toBeInTheDocument();
      expect(logo).toHaveAttribute('href', '/');
    });

    it('renders all main navigation links', () => {
      render(<TopNavigation />);
      
      expect(screen.getByRole('link', { name: /dashboard/i })).toBeInTheDocument();
      expect(screen.getByRole('link', { name: /events/i })).toBeInTheDocument();
      expect(screen.getByRole('link', { name: /fighters/i })).toBeInTheDocument();
    });

    it('renders navigation links with correct hrefs', () => {
      render(<TopNavigation />);
      
      const dashboardLink = screen.getByRole('link', { name: /dashboard/i });
      const eventsLink = screen.getByRole('link', { name: /events/i });
      const fightersLink = screen.getByRole('link', { name: /fighters/i });
      
      expect(dashboardLink).toHaveAttribute('href', '/');
      expect(eventsLink).toHaveAttribute('href', '/events');
      expect(fightersLink).toHaveAttribute('href', '/fighters');
    });

    it('renders mobile menu trigger button', () => {
      render(<TopNavigation />);
      
      const menuButton = screen.getByRole('button', { name: /menu/i });
      expect(menuButton).toBeInTheDocument();
      expect(menuButton).toHaveClass('md:hidden'); // Only visible on mobile
    });

    it('has proper nav landmark', () => {
      render(<TopNavigation />);
      
      const nav = screen.getByRole('navigation', { name: /main navigation/i });
      expect(nav).toBeInTheDocument();
    });
  });

  describe('Active Link Highlighting', () => {
    it('highlights dashboard link when on homepage', () => {
      mockPathname.mockReturnValue('/');
      render(<TopNavigation />);
      
      const dashboardLink = screen.getByRole('link', { name: /dashboard/i });
      const eventsLink = screen.getByRole('link', { name: /events/i });
      
      expect(dashboardLink).toHaveClass('text-blue-500');
      expect(eventsLink).not.toHaveClass('text-blue-500');
    });

    it('highlights events link when on events page', () => {
      mockPathname.mockReturnValue('/events');
      render(<TopNavigation />);
      
      const eventsLink = screen.getByRole('link', { name: /events/i });
      const dashboardLink = screen.getByRole('link', { name: /dashboard/i });
      
      expect(eventsLink).toHaveClass('text-blue-500');
      expect(dashboardLink).not.toHaveClass('text-blue-500');
    });

    it('highlights events link when on event detail page', () => {
      mockPathname.mockReturnValue('/events/123');
      render(<TopNavigation />);
      
      const eventsLink = screen.getByRole('link', { name: /events/i });
      expect(eventsLink).toHaveClass('text-blue-500');
    });

    it('highlights fighters link when on fighters page', () => {
      mockPathname.mockReturnValue('/fighters');
      render(<TopNavigation />);
      
      const fightersLink = screen.getByRole('link', { name: /fighters/i });
      expect(fightersLink).toHaveClass('text-blue-500');
    });

    it('highlights fighters link when on fighter detail page', () => {
      mockPathname.mockReturnValue('/fighters/456');
      render(<TopNavigation />);
      
      const fightersLink = screen.getByRole('link', { name: /fighters/i });
      expect(fightersLink).toHaveClass('text-blue-500');
    });
  });

  describe('Mobile Menu Interaction', () => {
    it('calls onMenuToggle when menu button clicked', async () => {
      const mockOnMenuToggle = jest.fn();
      const user = userEvent.setup();
      
      render(<TopNavigation onMenuToggle={mockOnMenuToggle} />);
      
      const menuButton = screen.getByRole('button', { name: /menu/i });
      await user.click(menuButton);
      
      expect(mockOnMenuToggle).toHaveBeenCalledTimes(1);
    });

    it('shows close icon when mobile menu is open', () => {
      render(<TopNavigation isMobileMenuOpen={true} />);
      
      const menuButton = screen.getByRole('button', { name: /close menu/i });
      expect(menuButton).toBeInTheDocument();
    });

    it('shows hamburger icon when mobile menu is closed', () => {
      render(<TopNavigation isMobileMenuOpen={false} />);
      
      const menuButton = screen.getByRole('button', { name: /open menu/i });
      expect(menuButton).toBeInTheDocument();
    });
  });

  describe('Keyboard Navigation', () => {
    it('allows tab navigation through links', async () => {
      const user = userEvent.setup();
      render(<TopNavigation />);
      
      // Tab through navigation
      await user.tab();
      expect(screen.getByRole('link', { name: /mma stats/i })).toHaveFocus();
      
      await user.tab();
      expect(screen.getByRole('link', { name: /dashboard/i })).toHaveFocus();
      
      await user.tab();
      expect(screen.getByRole('link', { name: /events/i })).toHaveFocus();
      
      await user.tab();
      expect(screen.getByRole('link', { name: /fighters/i })).toHaveFocus();
    });
  });

  describe('Responsive Behavior', () => {
    it('shows desktop navigation links on larger screens', () => {
      render(<TopNavigation />);
      
      const desktopNav = screen.getByTestId('desktop-nav');
      expect(desktopNav).toHaveClass('hidden', 'md:flex');
    });

    it('hides desktop navigation on mobile', () => {
      render(<TopNavigation />);
      
      const desktopNav = screen.getByTestId('desktop-nav');
      expect(desktopNav).toHaveClass('hidden', 'md:flex');
    });
  });

  describe('Accessibility', () => {
    it('has proper ARIA labels for mobile menu button', () => {
      render(<TopNavigation isMobileMenuOpen={false} />);
      
      const menuButton = screen.getByRole('button', { name: /open menu/i });
      expect(menuButton).toHaveAttribute('aria-expanded', 'false');
      expect(menuButton).toHaveAttribute('aria-controls', 'mobile-menu');
    });

    it('updates ARIA attributes when menu is open', () => {
      render(<TopNavigation isMobileMenuOpen={true} />);
      
      const menuButton = screen.getByRole('button', { name: /close menu/i });
      expect(menuButton).toHaveAttribute('aria-expanded', 'true');
    });

    it('has proper color contrast for dark theme', () => {
      render(<TopNavigation />);
      
      const nav = screen.getByRole('navigation');
      expect(nav).toHaveClass('bg-gray-900'); // Dark background
      
      // Check that inactive links have light text
      const eventsLink = screen.getByRole('link', { name: /events/i });
      const fightersLink = screen.getByRole('link', { name: /fighters/i });
      
      expect(eventsLink).toHaveClass('text-gray-300');
      expect(fightersLink).toHaveClass('text-gray-300');
    });
  });
});