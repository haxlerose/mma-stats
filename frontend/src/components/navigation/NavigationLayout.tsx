'use client';

import React, { useState, useEffect } from 'react';
import { TopNavigation } from './TopNavigation';
import { MobileMenu } from './MobileMenu';
import { Breadcrumb } from './Breadcrumb';

interface NavigationLayoutProps {
  children: React.ReactNode;
  showBreadcrumb?: boolean;
  eventName?: string;
  fighterName?: string;
}

export function NavigationLayout({ 
  children, 
  showBreadcrumb = false,
  eventName,
  fighterName
}: NavigationLayoutProps) {
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  // Handle body scroll lock when mobile menu is open
  useEffect(() => {
    if (isMobileMenuOpen) {
      document.body.classList.add('overflow-hidden');
    } else {
      document.body.classList.remove('overflow-hidden');
    }

    // Cleanup on unmount
    return () => {
      document.body.classList.remove('overflow-hidden');
    };
  }, [isMobileMenuOpen]);

  const handleMenuToggle = () => {
    setIsMobileMenuOpen(prev => !prev);
  };

  const handleMenuClose = () => {
    setIsMobileMenuOpen(false);
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Fixed Navigation */}
      <div className="fixed top-0 left-0 right-0 z-30">
        <TopNavigation 
          onMenuToggle={handleMenuToggle}
          isMobileMenuOpen={isMobileMenuOpen}
        />
      </div>

      {/* Mobile Menu */}
      <MobileMenu 
        isOpen={isMobileMenuOpen}
        onClose={handleMenuClose}
      />

      {/* Main Content */}
      <main 
        className="relative"
        role="main"
      >
        <div data-testid="content-wrapper" className="pt-16">
          <div data-testid="content-container" className="container mx-auto px-4 py-8">
            {showBreadcrumb && (
              <Breadcrumb 
                eventName={eventName}
                fighterName={fighterName}
              />
            )}
            {children}
          </div>
        </div>
      </main>
    </div>
  );
}