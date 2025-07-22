import React from 'react';
import { render, screen } from '@testing-library/react';
import { Breadcrumb } from '../Breadcrumb';

// Mock Next.js navigation hooks
const mockPathname = jest.fn();

jest.mock('next/navigation', () => ({
  usePathname: () => mockPathname(),
}));

describe('Breadcrumb', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Rendering', () => {
    it('renders nothing on homepage', () => {
      mockPathname.mockReturnValue('/');
      const { container } = render(<Breadcrumb />);
      
      expect(container.firstChild).toBeNull();
    });

    it('renders breadcrumb navigation landmark', () => {
      mockPathname.mockReturnValue('/events');
      render(<Breadcrumb />);
      
      const nav = screen.getByRole('navigation', { name: /breadcrumb/i });
      expect(nav).toBeInTheDocument();
    });

    it('renders proper semantic structure', () => {
      mockPathname.mockReturnValue('/events');
      render(<Breadcrumb />);
      
      const list = screen.getByRole('list');
      expect(list).toBeInTheDocument();
      expect(list).toHaveAttribute('aria-label', 'Breadcrumb');
    });

    it('renders home link in all breadcrumbs', () => {
      mockPathname.mockReturnValue('/events');
      render(<Breadcrumb />);
      
      const homeLink = screen.getByRole('link', { name: /home/i });
      expect(homeLink).toBeInTheDocument();
      expect(homeLink).toHaveAttribute('href', '/');
    });
  });

  describe('Path Generation', () => {
    it('generates breadcrumb for events list page', () => {
      mockPathname.mockReturnValue('/events');
      render(<Breadcrumb />);
      
      const items = screen.getAllByRole('listitem');
      expect(items).toHaveLength(2);
      
      expect(screen.getByRole('link', { name: /home/i })).toBeInTheDocument();
      expect(screen.getByText('Events')).toBeInTheDocument();
      
      // Current page should not be a link
      expect(screen.queryByRole('link', { name: /^events$/i })).not.toBeInTheDocument();
    });

    it('generates breadcrumb for event detail page', () => {
      mockPathname.mockReturnValue('/events/123');
      render(<Breadcrumb eventName="UFC 309: Jones vs Miocic" />);
      
      const items = screen.getAllByRole('listitem');
      expect(items).toHaveLength(3);
      
      expect(screen.getByRole('link', { name: /home/i })).toHaveAttribute('href', '/');
      expect(screen.getByRole('link', { name: /events/i })).toHaveAttribute('href', '/events');
      expect(screen.getByText('UFC 309: Jones vs Miocic')).toBeInTheDocument();
    });

    it('generates breadcrumb for fighters list page', () => {
      mockPathname.mockReturnValue('/fighters');
      render(<Breadcrumb />);
      
      const items = screen.getAllByRole('listitem');
      expect(items).toHaveLength(2);
      
      expect(screen.getByRole('link', { name: /home/i })).toBeInTheDocument();
      expect(screen.getByText('Fighters')).toBeInTheDocument();
    });

    it('generates breadcrumb for fighter detail page', () => {
      mockPathname.mockReturnValue('/fighters/456');
      render(<Breadcrumb fighterName="Jon Jones" />);
      
      const items = screen.getAllByRole('listitem');
      expect(items).toHaveLength(3);
      
      expect(screen.getByRole('link', { name: /home/i })).toHaveAttribute('href', '/');
      expect(screen.getByRole('link', { name: /fighters/i })).toHaveAttribute('href', '/fighters');
      expect(screen.getByText('Jon Jones')).toBeInTheDocument();
    });

    it('handles unknown paths gracefully', () => {
      mockPathname.mockReturnValue('/unknown/path');
      render(<Breadcrumb />);
      
      const items = screen.getAllByRole('listitem');
      expect(items).toHaveLength(3);
      
      expect(screen.getByText('Unknown')).toBeInTheDocument();
      expect(screen.getByText('Path')).toBeInTheDocument();
    });
  });

  describe('Visual Separators', () => {
    it('renders chevron separators between items', () => {
      mockPathname.mockReturnValue('/events/123');
      render(<Breadcrumb eventName="UFC 309" />);
      
      const separators = screen.getAllByText('›');
      expect(separators).toHaveLength(2); // Between Home-Events and Events-UFC 309
    });

    it('applies correct separator styling', () => {
      mockPathname.mockReturnValue('/events');
      render(<Breadcrumb />);
      
      const separator = screen.getByText('›');
      expect(separator).toHaveClass('mx-2', 'text-gray-400');
    });
  });

  describe('Mobile Responsiveness', () => {
    it('truncates long event names on mobile', () => {
      mockPathname.mockReturnValue('/events/123');
      const longName = 'UFC 309: Jones vs Miocic - Heavyweight Championship Battle at Madison Square Garden';
      
      render(<Breadcrumb eventName={longName} />);
      
      const eventItem = screen.getByText(longName);
      expect(eventItem).toHaveClass('truncate', 'max-w-[150px]', 'sm:max-w-none');
    });

    it('applies mobile-friendly text sizing', () => {
      mockPathname.mockReturnValue('/events');
      render(<Breadcrumb />);
      
      const nav = screen.getByRole('navigation');
      expect(nav).toHaveClass('text-sm');
    });
  });

  describe('Accessibility', () => {
    it('marks current page with aria-current', () => {
      mockPathname.mockReturnValue('/events');
      render(<Breadcrumb />);
      
      const currentPage = screen.getByText('Events');
      expect(currentPage).toHaveAttribute('aria-current', 'page');
    });

    it('has proper link descriptions', () => {
      mockPathname.mockReturnValue('/events/123');
      render(<Breadcrumb eventName="UFC 309" />);
      
      const homeLink = screen.getByRole('link', { name: /home/i });
      const eventsLink = screen.getByRole('link', { name: /events/i });
      
      expect(homeLink).toHaveAttribute('aria-label', 'Go to homepage');
      expect(eventsLink).toHaveAttribute('aria-label', 'Go to events list');
    });

    it('uses semantic HTML for structure', () => {
      mockPathname.mockReturnValue('/events');
      render(<Breadcrumb />);
      
      const nav = screen.getByRole('navigation');
      const list = screen.getByRole('list');
      const items = screen.getAllByRole('listitem');
      
      expect(nav).toContainElement(list);
      expect(list).toContainElement(items[0]);
    });
  });

  describe('Styling', () => {
    it('applies correct base styling', () => {
      mockPathname.mockReturnValue('/events');
      render(<Breadcrumb />);
      
      const nav = screen.getByRole('navigation');
      expect(nav).toHaveClass('text-sm', 'text-gray-600', 'mb-4');
    });

    it('styles links differently from current page', () => {
      mockPathname.mockReturnValue('/events');
      render(<Breadcrumb />);
      
      const homeLink = screen.getByRole('link', { name: /home/i });
      const currentPage = screen.getByText('Events');
      
      expect(homeLink).toHaveClass('text-blue-600', 'hover:text-blue-800');
      expect(currentPage).toHaveClass('text-gray-900', 'font-medium');
    });
  });
});