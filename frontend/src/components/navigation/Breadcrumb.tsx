'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';

interface BreadcrumbProps {
  eventName?: string;
  fighterName?: string;
}

interface BreadcrumbItem {
  label: string;
  href?: string;
  ariaCurrent?: 'page';
}

export function Breadcrumb({ eventName, fighterName }: BreadcrumbProps) {
  const pathname = usePathname();

  // Don't show breadcrumb on homepage
  if (pathname === '/') {
    return null;
  }

  // Generate breadcrumb items based on current path
  const items: BreadcrumbItem[] = [
    { label: 'Home', href: '/' },
  ];

  const pathSegments = pathname.split('/').filter(Boolean);

  // Build breadcrumb based on path
  if (pathSegments[0] === 'events') {
    items.push({ 
      label: 'Events', 
      href: pathSegments.length > 1 ? '/events' : undefined,
      ariaCurrent: pathSegments.length === 1 ? 'page' : undefined
    });

    if (pathSegments[1] && eventName) {
      items.push({ 
        label: eventName, 
        ariaCurrent: 'page' 
      });
    }
  } else if (pathSegments[0] === 'fighters') {
    items.push({ 
      label: 'Fighters', 
      href: pathSegments.length > 1 ? '/fighters' : undefined,
      ariaCurrent: pathSegments.length === 1 ? 'page' : undefined
    });

    if (pathSegments[1] && fighterName) {
      items.push({ 
        label: fighterName, 
        ariaCurrent: 'page' 
      });
    }
  } else {
    // Handle unknown paths
    pathSegments.forEach((segment, index) => {
      const label = segment.charAt(0).toUpperCase() + segment.slice(1);
      const isLast = index === pathSegments.length - 1;
      
      items.push({
        label,
        href: isLast ? undefined : `/${pathSegments.slice(0, index + 1).join('/')}`,
        ariaCurrent: isLast ? 'page' : undefined
      });
    });
  }

  return (
    <nav aria-label="Breadcrumb" className="text-sm text-gray-600 mb-4">
      <ol className="flex items-center" aria-label="Breadcrumb">
        {items.map((item, index) => (
          <li key={index} className="flex items-center">
            {index > 0 && (
              <span className="mx-2 text-gray-400" aria-hidden="true">
                ›
              </span>
            )}
            
            {item.href ? (
              <Link
                href={item.href}
                className="text-blue-600 hover:text-blue-800 hover:underline"
                aria-label={
                  item.label === 'Home' 
                    ? 'Go to homepage' 
                    : `Go to ${item.label.toLowerCase()} list`
                }
              >
                {item.label}
              </Link>
            ) : (
              <span 
                className={`
                  text-gray-900 font-medium
                  ${item.label.length > 30 ? 'truncate max-w-[150px] sm:max-w-none inline-block' : ''}
                `}
                aria-current={item.ariaCurrent}
              >
                {item.label}
              </span>
            )}
          </li>
        ))}
      </ol>
    </nav>
  );
}