import React from 'react';
import { Fighter } from '@/types/api';

interface FighterAttributesProps {
  fighter: Fighter;
}

function formatHeight(inches: number | null): string {
  if (!inches) return 'N/A';
  const feet = Math.floor(inches / 12);
  const remainingInches = inches % 12;
  return `${feet}'${remainingInches}"`;
}

function calculateAge(birthDate: string | null): string {
  if (!birthDate) return 'N/A';
  
  try {
    const birth = new Date(birthDate);
    const today = new Date();
    let age = today.getFullYear() - birth.getFullYear();
    const monthDiff = today.getMonth() - birth.getMonth();
    
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birth.getDate())) {
      age--;
    }
    
    return age.toString();
  } catch {
    return 'N/A';
  }
}

function formatBirthDate(birthDate: string | null): string {
  if (!birthDate) return 'N/A';
  
  try {
    const date = new Date(birthDate);
    return new Intl.DateTimeFormat('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      timeZone: 'UTC'
    }).format(date);
  } catch {
    return 'N/A';
  }
}

export function FighterAttributes({ fighter }: FighterAttributesProps) {
  const age = calculateAge(fighter.birth_date);
  const birthDateFormatted = formatBirthDate(fighter.birth_date);
  
  const attributes = [
    {
      label: 'Height',
      value: formatHeight(fighter.height_in_inches),
      icon: '📏',
    },
    {
      label: 'Reach',
      value: fighter.reach_in_inches ? `${fighter.reach_in_inches}"` : 'N/A',
      icon: '🤸',
    },
    {
      label: 'Age',
      value: age,
      subValue: birthDateFormatted !== 'N/A' ? `Born ${birthDateFormatted}` : undefined,
      icon: '🎂',
    },
  ];

  return (
    <div 
      data-testid="fighter-attributes"
      className="bg-white rounded-lg p-6 shadow-sm"
    >
      <h2 className="text-xl font-bold text-gray-900 mb-4">Physical Attributes</h2>
      
      <div className="space-y-4">
        {attributes.map((attr) => (
          <div key={attr.label} className="flex items-start">
            <span className="mr-3 text-xl" aria-label={attr.label}>
              {attr.icon}
            </span>
            <div className="flex-1">
              <div className="flex items-center justify-between">
                <span className="text-gray-600 font-medium">{attr.label}</span>
                <span className="text-gray-900 font-semibold text-lg">
                  {attr.value}
                </span>
              </div>
              {attr.subValue && (
                <div className="text-sm text-gray-500 mt-1">
                  {attr.subValue}
                </div>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}