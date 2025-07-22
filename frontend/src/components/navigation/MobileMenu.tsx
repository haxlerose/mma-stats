'use client';

import React, { useEffect, useRef } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { createPortal } from 'react-dom';

interface MobileMenuProps {
  isOpen: boolean;
  onClose: () => void;
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
];

export function MobileMenu({ isOpen, onClose }: MobileMenuProps) {
  const pathname = usePathname();
  const firstLinkRef = useRef<HTMLAnchorElement>(null);
  const lastLinkRef = useRef<HTMLAnchorElement>(null);

  // Focus management
  useEffect(() => {
    if (isOpen && firstLinkRef.current) {
      firstLinkRef.current.focus();
    }
  }, [isOpen]);

  // Handle Escape key
  useEffect(() => {
    if (!isOpen) return;

    const handleEscape = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        onClose();
      }
    };

    document.addEventListener('keydown', handleEscape);
    return () => document.removeEventListener('keydown', handleEscape);
  }, [isOpen, onClose]);

  // Handle focus trap
  const handleKeyDown = (event: React.KeyboardEvent) => {
    if (event.key === 'Tab') {
      if (event.shiftKey && document.activeElement === firstLinkRef.current) {
        event.preventDefault();
        lastLinkRef.current?.focus();
      } else if (!event.shiftKey && document.activeElement === lastLinkRef.current) {
        event.preventDefault();
        firstLinkRef.current?.focus();
      }
    }
  };

  if (!isOpen) return null;

  const menuContent = (
    <>
      {/* Overlay */}
      <div
        className="fixed inset-0 bg-black bg-opacity-50 z-40"
        onClick={onClose}
        data-testid="mobile-menu-overlay"
      />

      {/* Menu Panel */}
      <div
        role="dialog"
        aria-modal="true"
        aria-label="Navigation menu"
        className="fixed top-0 right-0 bottom-0 w-64 bg-gray-900 shadow-xl z-50 transform transition-transform duration-300 ease-out"
        onKeyDown={handleKeyDown}
      >
        <nav
          className="h-full pt-16 pb-6"
          aria-label="Mobile navigation"
        >
          <div className="px-2 space-y-1">
            {navLinks.map((link, index) => {
              const isActive = link.isActive(pathname);
              const isFirst = index === 0;
              const isLast = index === navLinks.length - 1;

              return (
                <Link
                  key={link.href}
                  href={link.href}
                  ref={isFirst ? firstLinkRef : isLast ? lastLinkRef : null}
                  onClick={onClose}
                  className={`
                    block px-4 py-3 rounded-md text-base font-medium transition-colors
                    ${isActive 
                      ? 'bg-gray-800 text-white' 
                      : 'text-gray-300 hover:bg-gray-700 hover:text-white'
                    }
                  `}
                >
                  {link.label}
                </Link>
              );
            })}
          </div>
        </nav>
      </div>
    </>
  );

  // Use portal to render at document root
  if (typeof window !== 'undefined') {
    return createPortal(menuContent, document.body);
  }

  return menuContent;
}