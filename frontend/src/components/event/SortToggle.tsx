import React from 'react';

interface SortToggleProps {
  direction: 'asc' | 'desc';
  onToggle: (direction: 'asc' | 'desc') => void;
}

export function SortToggle({ direction, onToggle }: SortToggleProps) {
  const isDesc = direction === 'desc';
  const label = isDesc ? 'Newest First' : 'Oldest First';
  const icon = isDesc ? '↓' : '↑';
  const oppositeDirection = isDesc ? 'asc' : 'desc';
  
  const handleClick = () => {
    onToggle(oppositeDirection);
  };
  
  const handleKeyDown = (event: React.KeyboardEvent) => {
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault();
      onToggle(oppositeDirection);
    }
  };

  return (
    <button
      onClick={handleClick}
      onKeyDown={handleKeyDown}
      className="
        inline-flex items-center gap-2 px-3 py-2 text-sm font-medium
        bg-blue-50 text-blue-700 border border-blue-200 rounded-md
        hover:bg-blue-100 focus:outline-none focus:ring-2 focus:ring-blue-500
        transition-colors duration-200
      "
      aria-label={`Sort events by date: currently ${label.toLowerCase()}, click to change`}
      title={`Sort events by date: currently ${label.toLowerCase()}`}
      type="button"
    >
      <span>{label}</span>
      <span className="text-lg">{icon}</span>
    </button>
  );
}