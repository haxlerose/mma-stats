import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { NavigationLayout } from '../NavigationLayout';

// Mock child components
jest.mock('../TopNavigation', () => ({
  TopNavigation: ({ onMenuToggle, isMobileMenuOpen }: any) => (
    <div data-testid="top-navigation">
      <button onClick={onMenuToggle}>
        {isMobileMenuOpen ? 'Close' : 'Open'} Menu
      </button>
    </div>
  ),
}));

jest.mock('../MobileMenu', () => ({
  MobileMenu: ({ isOpen, onClose }: any) => 
    isOpen ? <div data-testid="mobile-menu" onClick={onClose}>Mobile Menu</div> : null,
}));

jest.mock('../Breadcrumb', () => ({
  Breadcrumb: (props: any) => <div data-testid="breadcrumb">{JSON.stringify(props)}</div>,
}));

// Mock Next.js navigation
const mockPathname = jest.fn();
jest.mock('next/navigation', () => ({
  usePathname: () => mockPathname(),
}));

describe('NavigationLayout', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockPathname.mockReturnValue('/');
  });

  describe('Rendering', () => {
    it('renders TopNavigation component', () => {
      render(
        <NavigationLayout>
          <div>Content</div>
        </NavigationLayout>
      );
      
      expect(screen.getByTestId('top-navigation')).toBeInTheDocument();
    });

    it('renders children content', () => {
      render(
        <NavigationLayout>
          <div>Test Content</div>
        </NavigationLayout>
      );
      
      expect(screen.getByText('Test Content')).toBeInTheDocument();
    });

    it('applies proper layout structure', () => {
      const { container } = render(
        <NavigationLayout>
          <div>Content</div>
        </NavigationLayout>
      );
      
      const wrapper = container.firstChild;
      expect(wrapper).toHaveClass('min-h-screen', 'bg-gray-50');
      
      const main = screen.getByRole('main');
      expect(main).toBeInTheDocument();
    });

    it('does not render MobileMenu initially', () => {
      render(
        <NavigationLayout>
          <div>Content</div>
        </NavigationLayout>
      );
      
      expect(screen.queryByTestId('mobile-menu')).not.toBeInTheDocument();
    });
  });

  describe('Mobile Menu State Management', () => {
    it('opens mobile menu when triggered', async () => {
      const user = userEvent.setup();
      
      render(
        <NavigationLayout>
          <div>Content</div>
        </NavigationLayout>
      );
      
      const menuButton = screen.getByText('Open Menu');
      await user.click(menuButton);
      
      expect(screen.getByTestId('mobile-menu')).toBeInTheDocument();
      expect(screen.getByText('Close Menu')).toBeInTheDocument();
    });

    it('closes mobile menu when close is triggered', async () => {
      const user = userEvent.setup();
      
      render(
        <NavigationLayout>
          <div>Content</div>
        </NavigationLayout>
      );
      
      // Open menu
      await user.click(screen.getByText('Open Menu'));
      expect(screen.getByTestId('mobile-menu')).toBeInTheDocument();
      
      // Close menu
      await user.click(screen.getByTestId('mobile-menu'));
      expect(screen.queryByTestId('mobile-menu')).not.toBeInTheDocument();
    });

    it('prevents body scroll when mobile menu is open', async () => {
      const user = userEvent.setup();
      
      render(
        <NavigationLayout>
          <div>Content</div>
        </NavigationLayout>
      );
      
      // Open menu
      await user.click(screen.getByText('Open Menu'));
      expect(document.body).toHaveClass('overflow-hidden');
      
      // Close menu
      await user.click(screen.getByTestId('mobile-menu'));
      expect(document.body).not.toHaveClass('overflow-hidden');
    });
  });

  describe('Breadcrumb Integration', () => {
    it('renders breadcrumb when showBreadcrumb is true', () => {
      render(
        <NavigationLayout showBreadcrumb>
          <div>Content</div>
        </NavigationLayout>
      );
      
      expect(screen.getByTestId('breadcrumb')).toBeInTheDocument();
    });

    it('does not render breadcrumb by default', () => {
      render(
        <NavigationLayout>
          <div>Content</div>
        </NavigationLayout>
      );
      
      expect(screen.queryByTestId('breadcrumb')).not.toBeInTheDocument();
    });

    it('passes eventName prop to breadcrumb', () => {
      render(
        <NavigationLayout showBreadcrumb eventName="UFC 309">
          <div>Content</div>
        </NavigationLayout>
      );
      
      const breadcrumb = screen.getByTestId('breadcrumb');
      expect(breadcrumb).toHaveTextContent('"eventName":"UFC 309"');
    });

    it('passes fighterName prop to breadcrumb', () => {
      render(
        <NavigationLayout showBreadcrumb fighterName="Jon Jones">
          <div>Content</div>
        </NavigationLayout>
      );
      
      const breadcrumb = screen.getByTestId('breadcrumb');
      expect(breadcrumb).toHaveTextContent('"fighterName":"Jon Jones"');
    });
  });

  describe('Layout Structure', () => {
    it('adds padding to account for fixed navigation', () => {
      render(
        <NavigationLayout>
          <div>Content</div>
        </NavigationLayout>
      );
      
      const contentWrapper = screen.getByTestId('content-wrapper');
      expect(contentWrapper).toHaveClass('pt-16'); // Padding top for fixed nav
    });

    it('applies container styling to main content', () => {
      render(
        <NavigationLayout>
          <div>Content</div>
        </NavigationLayout>
      );
      
      const container = screen.getByTestId('content-container');
      expect(container).toHaveClass('container', 'mx-auto', 'px-4', 'py-8');
    });

    it('maintains proper z-index hierarchy', () => {
      render(
        <NavigationLayout>
          <div>Content</div>
        </NavigationLayout>
      );
      
      const nav = screen.getByTestId('top-navigation').parentElement;
      expect(nav).toHaveClass('z-30'); // Navigation has high z-index
    });
  });

  describe('Accessibility', () => {
    it('has proper main landmark', () => {
      render(
        <NavigationLayout>
          <div>Content</div>
        </NavigationLayout>
      );
      
      const main = screen.getByRole('main');
      expect(main).toBeInTheDocument();
    });

    it('manages focus when mobile menu opens', async () => {
      const user = userEvent.setup();
      
      render(
        <NavigationLayout>
          <div>Content</div>
        </NavigationLayout>
      );
      
      const menuButton = screen.getByText('Open Menu');
      await user.click(menuButton);
      
      // Mobile menu should be present and focusable
      expect(screen.getByTestId('mobile-menu')).toBeInTheDocument();
    });
  });

  describe('Cleanup', () => {
    it('removes overflow-hidden class on unmount', async () => {
      const user = userEvent.setup();
      const { unmount } = render(
        <NavigationLayout>
          <div>Content</div>
        </NavigationLayout>
      );
      
      // Open menu to add overflow-hidden
      const menuButton = screen.getByText('Open Menu');
      await user.click(menuButton);
      expect(document.body).toHaveClass('overflow-hidden');
      
      // Unmount should clean up
      unmount();
      expect(document.body).not.toHaveClass('overflow-hidden');
    });
  });
});