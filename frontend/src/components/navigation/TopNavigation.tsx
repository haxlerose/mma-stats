'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';

interface TopNavigationProps {
  onMenuToggle?: () => void;
  isMobileMenuOpen?: boolean;
}

interface NavLink {
  label: string;
  href: string;
  isActive: (pathname: string) => boolean;
}

const navLinks: NavLink[] = [
  {
    label: 'Dashboard',
    href: '/',
    isActive: (pathname) => pathname === '/',
  },
  {
    label: 'Events',
    href: '/events',
    isActive: (pathname) => pathname.startsWith('/events'),
  },
  {
    label: 'Fighters',
    href: '/fighters',
    isActive: (pathname) => pathname.startsWith('/fighters'),
  },
  {
    label: 'Top Performers',
    href: '/top-performers',
    isActive: (pathname) => pathname.startsWith('/top-performers'),
  },
];

export function TopNavigation({ 
  onMenuToggle,
  isMobileMenuOpen = false 
}: TopNavigationProps) {
  const pathname = usePathname();

  return (
    <nav 
      className="bg-gray-900 text-gray-300 shadow-lg"
      aria-label="Main navigation"
    >
      <div className="container mx-auto px-4">
        <div className="flex items-center justify-between h-16">
          {/* Logo/App Title */}
          <div className="flex-shrink-0">
            <Link 
              href="/"
              className="text-xl font-bold text-white hover:text-gray-200 transition-colors"
            >
              MMA Stats
            </Link>
          </div>

          {/* Desktop Navigation */}
          <div 
            className="hidden md:flex md:items-center md:space-x-8"
            data-testid="desktop-nav"
          >
            {navLinks.map(link => {
              const isActive = link.isActive(pathname);
              return (
                <Link
                  key={link.href}
                  href={link.href}
                  className={`
                    px-3 py-2 text-sm font-medium transition-colors
                    ${isActive 
                      ? 'text-blue-500' 
                      : 'text-gray-300 hover:text-white'
                    }
                  `}
                >
                  {link.label}
                </Link>
              );
            })}
          </div>

          {/* Mobile Menu Button */}
          <button
            onClick={onMenuToggle}
            className="md:hidden inline-flex items-center justify-center p-2 rounded-md text-gray-400 hover:text-white hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-white"
            aria-expanded={isMobileMenuOpen}
            aria-controls="mobile-menu"
            aria-label={isMobileMenuOpen ? 'Close menu' : 'Open menu'}
          >
            {isMobileMenuOpen ? (
              // Close icon (X)
              <svg 
                className="block h-6 w-6" 
                fill="none" 
                viewBox="0 0 24 24" 
                stroke="currentColor"
              >
                <path 
                  strokeLinecap="round" 
                  strokeLinejoin="round" 
                  strokeWidth={2} 
                  d="M6 18L18 6M6 6l12 12" 
                />
              </svg>
            ) : (
              // Hamburger icon
              <svg 
                className="block h-6 w-6" 
                fill="none" 
                viewBox="0 0 24 24" 
                stroke="currentColor"
              >
                <path 
                  strokeLinecap="round" 
                  strokeLinejoin="round" 
                  strokeWidth={2} 
                  d="M4 6h16M4 12h16M4 18h16" 
                />
              </svg>
            )}
          </button>
        </div>
      </div>
    </nav>
  );
}