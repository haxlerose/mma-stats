import React from 'react';
import { Fight, Fighter } from '@/types/api';

interface TaleOfTheTapeProps {
  fight: Fight;
}

function formatHeight(inches: number | null): string {
  if (!inches) return 'N/A';
  const feet = Math.floor(inches / 12);
  const remainingInches = inches % 12;
  return `${feet}'${remainingInches}"`;
}

function calculateAge(birthDate: string | null, fightDate: string | undefined): string {
  if (!birthDate || !fightDate) return 'N/A';
  
  try {
    const birth = new Date(birthDate);
    const fight = new Date(fightDate);
    let age = fight.getFullYear() - birth.getFullYear();
    const monthDiff = fight.getMonth() - birth.getMonth();
    
    if (monthDiff < 0 || (monthDiff === 0 && fight.getDate() < birth.getDate())) {
      age--;
    }
    
    return age.toString();
  } catch {
    return 'N/A';
  }
}

function ComparisonRow({ 
  label, 
  value1, 
  value2,
  highlight1 = false,
  highlight2 = false 
}: { 
  label: string; 
  value1: string; 
  value2: string;
  highlight1?: boolean;
  highlight2?: boolean;
}) {
  return (
    <div className="grid grid-cols-3 py-3 border-b border-gray-200 last:border-b-0">
      <div className={`text-right pr-4 ${highlight1 ? 'font-semibold text-blue-600' : 'text-gray-900'}`}>
        {value1}
      </div>
      <div className="text-center text-gray-700 text-sm font-medium">
        {label}
      </div>
      <div className={`text-left pl-4 ${highlight2 ? 'font-semibold text-red-600' : 'text-gray-900'}`}>
        {value2}
      </div>
    </div>
  );
}

export function TaleOfTheTape({ fight }: TaleOfTheTapeProps) {
  const fighter1 = fight.fighters?.[0];
  const fighter2 = fight.fighters?.[1];
  
  if (!fighter1 || !fighter2) return null;
  
  const age1 = calculateAge(fighter1.birth_date, fight.event?.date);
  const age2 = calculateAge(fighter2.birth_date, fight.event?.date);
  const height1 = formatHeight(fighter1.height_in_inches);
  const height2 = formatHeight(fighter2.height_in_inches);
  const reach1 = fighter1.reach_in_inches ? `${fighter1.reach_in_inches}"` : 'N/A';
  const reach2 = fighter2.reach_in_inches ? `${fighter2.reach_in_inches}"` : 'N/A';
  
  // Determine advantages
  const heightAdvantage1 = (fighter1.height_in_inches || 0) > (fighter2.height_in_inches || 0);
  const heightAdvantage2 = (fighter2.height_in_inches || 0) > (fighter1.height_in_inches || 0);
  const reachAdvantage1 = (fighter1.reach_in_inches || 0) > (fighter2.reach_in_inches || 0);
  const reachAdvantage2 = (fighter2.reach_in_inches || 0) > (fighter1.reach_in_inches || 0);

  return (
    <div 
      data-testid="tale-of-the-tape"
      className="bg-white rounded-lg p-6 shadow-sm"
    >
      <h2 className="text-xl font-bold text-gray-900 mb-6 text-center">Tale of the Tape</h2>
      
      <div className="max-w-2xl mx-auto">
        {/* Fighter Names */}
        <div className="grid grid-cols-3 mb-6">
          <div className="text-right pr-4">
            <div className="text-lg font-bold text-blue-600">{fighter1.name}</div>
          </div>
          <div className="text-center">
            <span className="text-gray-700 font-medium">vs</span>
          </div>
          <div className="text-left pl-4">
            <div className="text-lg font-bold text-red-600">{fighter2.name}</div>
          </div>
        </div>
        
        {/* Comparisons */}
        <ComparisonRow 
          label="Age at Fight" 
          value1={age1}
          value2={age2}
        />
        <ComparisonRow 
          label="Height" 
          value1={height1}
          value2={height2}
          highlight1={heightAdvantage1}
          highlight2={heightAdvantage2}
        />
        <ComparisonRow 
          label="Reach" 
          value1={reach1}
          value2={reach2}
          highlight1={reachAdvantage1}
          highlight2={reachAdvantage2}
        />
        
        {/* Height and Reach Differences */}
        {(heightAdvantage1 || heightAdvantage2) && fighter1.height_in_inches && fighter2.height_in_inches && (
          <div className="mt-4 text-center text-sm text-gray-700 font-medium">
            Height difference: {Math.abs(fighter1.height_in_inches - fighter2.height_in_inches)}"
          </div>
        )}
        {(reachAdvantage1 || reachAdvantage2) && fighter1.reach_in_inches && fighter2.reach_in_inches && (
          <div className="text-center text-sm text-gray-700 font-medium">
            Reach difference: {Math.abs(fighter1.reach_in_inches - fighter2.reach_in_inches)}"
          </div>
        )}
      </div>
    </div>
  );
}