import React from 'react';
import { render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MobileMenu } from '../MobileMenu';

// Mock Next.js navigation hooks
const mockPush = jest.fn();
const mockPathname = jest.fn();

jest.mock('next/navigation', () => ({
  useRouter: () => ({
    push: mockPush,
  }),
  usePathname: () => mockPathname(),
}));

// Mock createPortal
jest.mock('react-dom', () => ({
  ...jest.requireActual('react-dom'),
  createPortal: (node: React.ReactNode) => node,
}));

describe('MobileMenu', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockPathname.mockReturnValue('/');
  });

  describe('Rendering', () => {
    it('renders nothing when closed', () => {
      const { container } = render(<MobileMenu isOpen={false} onClose={jest.fn()} />);
      expect(container.firstChild).toBeNull();
    });

    it('renders mobile menu when open', () => {
      render(<MobileMenu isOpen={true} onClose={jest.fn()} />);
      
      const menu = screen.getByRole('dialog', { name: /navigation menu/i });
      expect(menu).toBeInTheDocument();
    });

    it('renders overlay backdrop', () => {
      render(<MobileMenu isOpen={true} onClose={jest.fn()} />);
      
      const overlay = screen.getByTestId('mobile-menu-overlay');
      expect(overlay).toBeInTheDocument();
      expect(overlay).toHaveClass('fixed', 'inset-0', 'bg-black', 'bg-opacity-50');
    });

    it('renders all navigation links', () => {
      render(<MobileMenu isOpen={true} onClose={jest.fn()} />);
      
      expect(screen.getByRole('link', { name: /dashboard/i })).toBeInTheDocument();
      expect(screen.getByRole('link', { name: /events/i })).toBeInTheDocument();
      expect(screen.getByRole('link', { name: /fighters/i })).toBeInTheDocument();
    });

    it('renders with correct slide-out panel styling', () => {
      render(<MobileMenu isOpen={true} onClose={jest.fn()} />);
      
      const panel = screen.getByRole('dialog');
      expect(panel).toHaveClass('fixed', 'right-0', 'w-64', 'bg-gray-900');
    });

    it('has proper navigation landmark', () => {
      render(<MobileMenu isOpen={true} onClose={jest.fn()} />);
      
      const nav = screen.getByRole('navigation', { name: /mobile navigation/i });
      expect(nav).toBeInTheDocument();
    });
  });

  describe('User Interactions', () => {
    it('calls onClose when clicking overlay', async () => {
      const mockOnClose = jest.fn();
      const user = userEvent.setup();
      
      render(<MobileMenu isOpen={true} onClose={mockOnClose} />);
      
      const overlay = screen.getByTestId('mobile-menu-overlay');
      await user.click(overlay);
      
      expect(mockOnClose).toHaveBeenCalledTimes(1);
    });

    it('calls onClose when clicking a navigation link', async () => {
      const mockOnClose = jest.fn();
      const user = userEvent.setup();
      
      render(<MobileMenu isOpen={true} onClose={mockOnClose} />);
      
      const eventsLink = screen.getByRole('link', { name: /events/i });
      await user.click(eventsLink);
      
      expect(mockOnClose).toHaveBeenCalledTimes(1);
    });

    it('does not close when clicking inside menu panel', async () => {
      const mockOnClose = jest.fn();
      const user = userEvent.setup();
      
      render(<MobileMenu isOpen={true} onClose={mockOnClose} />);
      
      const panel = screen.getByRole('dialog');
      await user.click(panel);
      
      expect(mockOnClose).not.toHaveBeenCalled();
    });

    it('closes menu when pressing Escape key', async () => {
      const mockOnClose = jest.fn();
      const user = userEvent.setup();
      
      render(<MobileMenu isOpen={true} onClose={mockOnClose} />);
      
      await user.keyboard('{Escape}');
      
      expect(mockOnClose).toHaveBeenCalledTimes(1);
    });
  });

  describe('Active Link Highlighting', () => {
    it('highlights dashboard link when on homepage', () => {
      mockPathname.mockReturnValue('/');
      render(<MobileMenu isOpen={true} onClose={jest.fn()} />);
      
      const dashboardLink = screen.getByRole('link', { name: /dashboard/i });
      const eventsLink = screen.getByRole('link', { name: /events/i });
      
      expect(dashboardLink).toHaveClass('bg-gray-800', 'text-white');
      expect(eventsLink).not.toHaveClass('bg-gray-800');
    });

    it('highlights events link when on events page', () => {
      mockPathname.mockReturnValue('/events');
      render(<MobileMenu isOpen={true} onClose={jest.fn()} />);
      
      const eventsLink = screen.getByRole('link', { name: /events/i });
      expect(eventsLink).toHaveClass('bg-gray-800', 'text-white');
    });

    it('highlights fighters link when on fighter detail page', () => {
      mockPathname.mockReturnValue('/fighters/123');
      render(<MobileMenu isOpen={true} onClose={jest.fn()} />);
      
      const fightersLink = screen.getByRole('link', { name: /fighters/i });
      expect(fightersLink).toHaveClass('bg-gray-800', 'text-white');
    });
  });

  describe('Keyboard Navigation', () => {
    it('allows tab navigation through links', async () => {
      const user = userEvent.setup();
      render(<MobileMenu isOpen={true} onClose={jest.fn()} />);
      
      // Start from first link (already focused)
      const dashboardLink = screen.getByRole('link', { name: /dashboard/i });
      dashboardLink.focus();
      
      await user.tab();
      expect(screen.getByRole('link', { name: /events/i })).toHaveFocus();
      
      await user.tab();
      expect(screen.getByRole('link', { name: /fighters/i })).toHaveFocus();
    });

    it('traps focus within menu', async () => {
      const user = userEvent.setup();
      render(<MobileMenu isOpen={true} onClose={jest.fn()} />);
      
      const firstLink = screen.getByRole('link', { name: /dashboard/i });
      const lastLink = screen.getByRole('link', { name: /fighters/i });
      
      // Focus last link
      lastLink.focus();
      
      // Tab should wrap to first link
      await user.tab();
      expect(firstLink).toHaveFocus();
      
      // Shift+Tab should wrap to last link
      await user.tab({ shift: true });
      expect(lastLink).toHaveFocus();
    });
  });

  describe('Accessibility', () => {
    it('has proper ARIA attributes', () => {
      render(<MobileMenu isOpen={true} onClose={jest.fn()} />);
      
      const dialog = screen.getByRole('dialog');
      expect(dialog).toHaveAttribute('aria-modal', 'true');
      expect(dialog).toHaveAttribute('aria-label', 'Navigation menu');
    });

    it('has proper role and semantic structure', () => {
      render(<MobileMenu isOpen={true} onClose={jest.fn()} />);
      
      const nav = screen.getByRole('navigation');
      const links = within(nav).getAllByRole('link');
      
      expect(nav).toBeInTheDocument();
      expect(links).toHaveLength(3);
    });

    it('manages focus on open', () => {
      render(<MobileMenu isOpen={true} onClose={jest.fn()} />);
      
      const firstLink = screen.getByRole('link', { name: /dashboard/i });
      expect(firstLink).toHaveFocus();
    });

    it('has touch-friendly link sizing', () => {
      render(<MobileMenu isOpen={true} onClose={jest.fn()} />);
      
      const links = screen.getAllByRole('link');
      links.forEach(link => {
        expect(link).toHaveClass('px-4', 'py-3'); // Touch-friendly padding
      });
    });
  });

  describe('Animation Classes', () => {
    it('applies entrance animation classes when open', () => {
      render(<MobileMenu isOpen={true} onClose={jest.fn()} />);
      
      const panel = screen.getByRole('dialog');
      expect(panel).toHaveClass('transform', 'transition-transform');
    });

    it('has correct z-index layering', () => {
      render(<MobileMenu isOpen={true} onClose={jest.fn()} />);
      
      const overlay = screen.getByTestId('mobile-menu-overlay');
      const panel = screen.getByRole('dialog');
      
      expect(overlay).toHaveClass('z-40');
      expect(panel).toHaveClass('z-50');
    });
  });
});