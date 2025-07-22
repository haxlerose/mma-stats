/**
 * LocationDropdown Component Tests
 * Tests for the LocationDropdown component following TDD methodology
 */

import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import '@testing-library/jest-dom';
import { LocationDropdown } from '../LocationDropdown';

const mockLocations = [
  'Abu Dhabi, United Arab Emirates',
  'Las Vegas, Nevada',
  'London, England',
  'Manchester, England',
  'New York, New York',
  'São Paulo, Brazil'
];

describe('LocationDropdown', () => {
  const mockOnLocationSelect = jest.fn();

  beforeEach(() => {
    mockOnLocationSelect.mockClear();
  });

  // Rendering tests
  test('renders with placeholder text when no selection', () => {
    render(
      <LocationDropdown
        locations={mockLocations}
        selectedLocation={null}
        onLocationSelect={mockOnLocationSelect}
      />
    );
    
    expect(screen.getByPlaceholderText('Search locations...')).toBeInTheDocument();
  });

  test('displays selected location when provided', () => {
    render(
      <LocationDropdown
        locations={mockLocations}
        selectedLocation="Las Vegas, Nevada"
        onLocationSelect={mockOnLocationSelect}
      />
    );
    
    const input = screen.getByDisplayValue('Las Vegas, Nevada');
    expect(input).toBeInTheDocument();
  });

  test('shows loading state while fetching locations', () => {
    render(
      <LocationDropdown
        locations={[]}
        selectedLocation={null}
        onLocationSelect={mockOnLocationSelect}
        isLoading={true}
      />
    );
    
    expect(screen.getByText('Loading...')).toBeInTheDocument();
  });

  test('displays error message on fetch failure', () => {
    render(
      <LocationDropdown
        locations={[]}
        selectedLocation={null}
        onLocationSelect={mockOnLocationSelect}
        error="Failed to load locations"
      />
    );
    
    expect(screen.getByText('Failed to load locations')).toBeInTheDocument();
  });

  // User Interactions tests
  test('opens dropdown when clicked', async () => {
    const user = userEvent.setup();
    
    render(
      <LocationDropdown
        locations={mockLocations}
        selectedLocation={null}
        onLocationSelect={mockOnLocationSelect}
      />
    );
    
    const input = screen.getByRole('combobox');
    await user.click(input);
    
    // Should show all locations
    expect(screen.getByText('Las Vegas, Nevada')).toBeInTheDocument();
    expect(screen.getByText('London, England')).toBeInTheDocument();
  });

  test('filters locations as user types', async () => {
    const user = userEvent.setup();
    
    render(
      <LocationDropdown
        locations={mockLocations}
        selectedLocation={null}
        onLocationSelect={mockOnLocationSelect}
      />
    );
    
    const input = screen.getByRole('combobox');
    await user.type(input, 'Las');
    
    // Should show only Las Vegas
    expect(screen.getByText('Las Vegas, Nevada')).toBeInTheDocument();
    expect(screen.queryByText('London, England')).not.toBeInTheDocument();
  });

  test('highlights matching text in filtered results', async () => {
    const user = userEvent.setup();
    
    render(
      <LocationDropdown
        locations={mockLocations}
        selectedLocation={null}
        onLocationSelect={mockOnLocationSelect}
      />
    );
    
    const input = screen.getByRole('combobox');
    await user.type(input, 'England');
    
    // Should highlight "England" in both London and Manchester
    const highlighted = screen.getAllByText('England');
    expect(highlighted.length).toBeGreaterThan(0);
    highlighted.forEach(element => {
      expect(element).toHaveClass('font-bold'); // Highlighted text styling
    });
  });

  test('selects location when clicked from dropdown', async () => {
    const user = userEvent.setup();
    
    render(
      <LocationDropdown
        locations={mockLocations}
        selectedLocation={null}
        onLocationSelect={mockOnLocationSelect}
      />
    );
    
    const input = screen.getByRole('combobox');
    await user.click(input);
    
    const option = screen.getByText('Las Vegas, Nevada');
    await user.click(option);
    
    expect(mockOnLocationSelect).toHaveBeenCalledWith('Las Vegas, Nevada');
  });

  test('closes dropdown when location selected', async () => {
    const user = userEvent.setup();
    
    render(
      <LocationDropdown
        locations={mockLocations}
        selectedLocation={null}
        onLocationSelect={mockOnLocationSelect}
      />
    );
    
    const input = screen.getByRole('combobox');
    await user.click(input);
    
    expect(screen.getByText('Las Vegas, Nevada')).toBeInTheDocument();
    
    const option = screen.getByText('Las Vegas, Nevada');
    await user.click(option);
    
    // Dropdown should close
    await waitFor(() => {
      expect(screen.queryByText('London, England')).not.toBeInTheDocument();
    });
  });

  test('clears selection when X button clicked', async () => {
    const user = userEvent.setup();
    
    render(
      <LocationDropdown
        locations={mockLocations}
        selectedLocation="Las Vegas, Nevada"
        onLocationSelect={mockOnLocationSelect}
      />
    );
    
    const clearButton = screen.getByLabelText('Clear selection');
    await user.click(clearButton);
    
    expect(mockOnLocationSelect).toHaveBeenCalledWith(null);
  });

  test('closes dropdown when clicking outside', async () => {
    const user = userEvent.setup();
    
    render(
      <div>
        <LocationDropdown
          locations={mockLocations}
          selectedLocation={null}
          onLocationSelect={mockOnLocationSelect}
        />
        <div data-testid="outside">Outside element</div>
      </div>
    );
    
    const input = screen.getByRole('combobox');
    await user.click(input);
    
    expect(screen.getByText('Las Vegas, Nevada')).toBeInTheDocument();
    
    const outside = screen.getByTestId('outside');
    await user.click(outside);
    
    await waitFor(() => {
      expect(screen.queryByText('Las Vegas, Nevada')).not.toBeInTheDocument();
    });
  });

  // Keyboard Navigation tests
  test('opens dropdown on arrow down key', async () => {
    const user = userEvent.setup();
    
    render(
      <LocationDropdown
        locations={mockLocations}
        selectedLocation={null}
        onLocationSelect={mockOnLocationSelect}
      />
    );
    
    const input = screen.getByRole('combobox');
    input.focus();
    await user.keyboard('{ArrowDown}');
    
    expect(screen.getByText('Las Vegas, Nevada')).toBeInTheDocument();
  });

  test('navigates options with arrow keys', async () => {
    const user = userEvent.setup();
    
    render(
      <LocationDropdown
        locations={mockLocations}
        selectedLocation={null}
        onLocationSelect={mockOnLocationSelect}
      />
    );
    
    const input = screen.getByRole('combobox');
    await user.click(input);
    
    // First option should be highlighted
    const firstOption = screen.getByText(mockLocations[0]);
    expect(firstOption).toHaveClass('bg-blue-50'); // Highlighted option styling
    
    await user.keyboard('{ArrowDown}');
    
    // Second option should now be highlighted
    const secondOption = screen.getByText(mockLocations[1]);
    expect(secondOption).toHaveClass('bg-blue-50');
  });

  test('selects highlighted option on Enter', async () => {
    const user = userEvent.setup();
    
    render(
      <LocationDropdown
        locations={mockLocations}
        selectedLocation={null}
        onLocationSelect={mockOnLocationSelect}
      />
    );
    
    const input = screen.getByRole('combobox');
    await user.click(input);
    await user.keyboard('{ArrowDown}');
    await user.keyboard('{Enter}');
    
    expect(mockOnLocationSelect).toHaveBeenCalledWith(mockLocations[1]);
  });

  test('closes dropdown on Escape key', async () => {
    const user = userEvent.setup();
    
    render(
      <LocationDropdown
        locations={mockLocations}
        selectedLocation={null}
        onLocationSelect={mockOnLocationSelect}
      />
    );
    
    const input = screen.getByRole('combobox');
    await user.click(input);
    
    expect(screen.getByText('Las Vegas, Nevada')).toBeInTheDocument();
    
    await user.keyboard('{Escape}');
    
    await waitFor(() => {
      expect(screen.queryByText('Las Vegas, Nevada')).not.toBeInTheDocument();
    });
  });

  test('focuses input on component mount', () => {
    render(
      <LocationDropdown
        locations={mockLocations}
        selectedLocation={null}
        onLocationSelect={mockOnLocationSelect}
        autoFocus={true}
      />
    );
    
    const input = screen.getByRole('combobox');
    expect(input).toHaveFocus();
  });

  // Edge Cases tests
  test('handles empty locations list gracefully', () => {
    render(
      <LocationDropdown
        locations={[]}
        selectedLocation={null}
        onLocationSelect={mockOnLocationSelect}
      />
    );
    
    const input = screen.getByRole('combobox');
    fireEvent.click(input);
    
    expect(screen.getByText('No locations found')).toBeInTheDocument();
  });

  test('handles locations with special characters', async () => {
    const user = userEvent.setup();
    
    render(
      <LocationDropdown
        locations={['São Paulo, Brazil', 'Malmö, Sweden']}
        selectedLocation={null}
        onLocationSelect={mockOnLocationSelect}
      />
    );
    
    const input = screen.getByRole('combobox');
    await user.type(input, 'São');
    
    expect(screen.getByText('São Paulo, Brazil')).toBeInTheDocument();
    expect(screen.queryByText('Malmö, Sweden')).not.toBeInTheDocument();
  });

  test('debounces rapid typing events', async () => {
    const user = userEvent.setup();
    const mockFilter = jest.fn();
    
    render(
      <LocationDropdown
        locations={mockLocations}
        selectedLocation={null}
        onLocationSelect={mockOnLocationSelect}
        onFilter={mockFilter}
      />
    );
    
    const input = screen.getByRole('combobox');
    
    // Type rapidly
    await user.type(input, 'Las Vegas');
    
    // Should debounce and only call filter once after typing stops
    await waitFor(() => {
      expect(mockFilter).toHaveBeenCalledTimes(1);
    });
  });

  test('maintains case-insensitive filtering', async () => {
    const user = userEvent.setup();
    
    render(
      <LocationDropdown
        locations={mockLocations}
        selectedLocation={null}
        onLocationSelect={mockOnLocationSelect}
      />
    );
    
    const input = screen.getByRole('combobox');
    await user.type(input, 'las vegas');
    
    // Should still match "Las Vegas, Nevada" despite different case
    expect(screen.getByText('Las Vegas, Nevada')).toBeInTheDocument();
  });
});