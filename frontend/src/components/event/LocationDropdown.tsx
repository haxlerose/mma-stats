import React, { useState, useEffect, useRef, useMemo } from 'react';

interface LocationDropdownProps {
  locations: string[];
  selectedLocation?: string;
  onLocationSelect: (location: string | null) => void;
  isLoading?: boolean;
  error?: string;
  autoFocus?: boolean;
  onFilter?: (term: string) => void;
}

export function LocationDropdown({
  locations,
  selectedLocation,
  onLocationSelect,
  isLoading = false,
  error,
  autoFocus = false,
  onFilter
}: LocationDropdownProps) {
  const [isOpen, setIsOpen] = useState(false);
  const [searchTerm, setSearchTerm] = useState(selectedLocation || '');
  const [highlightedIndex, setHighlightedIndex] = useState(0);
  const inputRef = useRef<HTMLInputElement>(null);
  const dropdownRef = useRef<HTMLDivElement>(null);

  // Filter locations based on search term (case-insensitive)
  const filteredLocations = useMemo(() => {
    if (!searchTerm.trim()) return locations;
    
    return locations.filter(location =>
      location.toLowerCase().includes(searchTerm.toLowerCase())
    );
  }, [locations, searchTerm]);

  // Reset highlighted index when filtered results change
  useEffect(() => {
    setHighlightedIndex(0);
  }, [filteredLocations]);

  // Update search term when selected location changes
  useEffect(() => {
    setSearchTerm(selectedLocation || '');
  }, [selectedLocation]);

  // Auto focus input when requested
  useEffect(() => {
    if (autoFocus && inputRef.current) {
      inputRef.current.focus();
    }
  }, [autoFocus]);

  // Debounced filter callback
  useEffect(() => {
    if (onFilter) {
      const timer = setTimeout(() => {
        onFilter(searchTerm);
      }, 300);
      return () => clearTimeout(timer);
    }
  }, [searchTerm, onFilter]);

  // Close dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (
        dropdownRef.current &&
        !dropdownRef.current.contains(event.target as Node)
      ) {
        setIsOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleInputChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const value = event.target.value;
    setSearchTerm(value);
    setIsOpen(true);
    
    // Clear selection if user is typing something different
    if (value !== selectedLocation) {
      onLocationSelect(null);
    }
  };

  const handleInputClick = () => {
    setIsOpen(true);
  };

  const handleLocationSelect = (location: string) => {
    setSearchTerm(location);
    setIsOpen(false);
    onLocationSelect(location);
  };

  const handleClearSelection = () => {
    setSearchTerm('');
    setIsOpen(false);
    onLocationSelect(null);
    inputRef.current?.focus();
  };

  const handleKeyDown = (event: React.KeyboardEvent) => {
    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault();
        if (!isOpen) {
          setIsOpen(true);
        } else {
          setHighlightedIndex(prev => 
            prev < filteredLocations.length - 1 ? prev + 1 : 0
          );
        }
        break;
        
      case 'ArrowUp':
        event.preventDefault();
        setHighlightedIndex(prev => 
          prev > 0 ? prev - 1 : filteredLocations.length - 1
        );
        break;
        
      case 'Enter':
        event.preventDefault();
        if (isOpen && filteredLocations[highlightedIndex]) {
          handleLocationSelect(filteredLocations[highlightedIndex]);
        }
        break;
        
      case 'Escape':
        event.preventDefault();
        setIsOpen(false);
        break;
    }
  };

  const highlightMatch = (text: string, term: string) => {
    if (!term.trim()) return text;
    
    const index = text.toLowerCase().indexOf(term.toLowerCase());
    if (index === -1) return text;
    
    const before = text.slice(0, index);
    const match = text.slice(index, index + term.length);
    const after = text.slice(index + term.length);
    
    return (
      <>
        {before}
        <span className="font-bold bg-yellow-100">{match}</span>
        {after}
      </>
    );
  };

  if (isLoading) {
    return (
      <div className="relative">
        <div className="px-3 py-2 border border-gray-300 rounded-md bg-gray-50">
          Loading...
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="relative">
        <div className="px-3 py-2 border border-red-300 rounded-md bg-red-50 text-red-700">
          {error}
        </div>
      </div>
    );
  }

  return (
    <div className="relative" ref={dropdownRef}>
      <div className="relative">
        <input
          ref={inputRef}
          type="text"
          role="combobox"
          aria-expanded={isOpen}
          aria-haspopup="listbox"
          value={searchTerm}
          onChange={handleInputChange}
          onClick={handleInputClick}
          onKeyDown={handleKeyDown}
          placeholder="Search locations..."
          className="w-full px-3 py-2 pr-10 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
        />
        
        {selectedLocation && (
          <button
            onClick={handleClearSelection}
            aria-label="Clear selection"
            className="absolute right-2 top-1/2 transform -translate-y-1/2 p-1 text-gray-400 hover:text-gray-600"
          >
            ×
          </button>
        )}
      </div>

      {isOpen && (
        <div
          role="listbox"
          className="absolute z-10 w-full mt-1 bg-white border border-gray-300 rounded-md shadow-lg max-h-60 overflow-auto"
        >
          {filteredLocations.length === 0 ? (
            <div className="px-3 py-2 text-gray-500">
              No locations found
            </div>
          ) : (
            filteredLocations.map((location, index) => (
              <div
                key={location}
                role="option"
                aria-selected={index === highlightedIndex}
                onClick={() => handleLocationSelect(location)}
                className={`
                  px-3 py-2 cursor-pointer text-gray-900
                  ${index === highlightedIndex ? 'bg-blue-50 text-blue-700' : 'hover:bg-gray-50'}
                `}
              >
                {highlightMatch(location, searchTerm)}
              </div>
            ))
          )}
        </div>
      )}
    </div>
  );
}