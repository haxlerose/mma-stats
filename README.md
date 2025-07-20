# MMA Stats API

A Ruby on Rails API application for collecting and storing comprehensive Mixed Martial Arts (MMA) statistics from UFC events, fights, and fighters.

## Overview

This API-only Rails application imports and stores comprehensive UFC data including events, fighters, individual fights, and detailed round-by-round fight statistics from external CSV sources.

## Requirements

- Ruby 3.4.5
- Rails 8.0.2
- PostgreSQL
- Redis (for Solid Queue/Cache/Cable)

## Setup

1. Clone the repository
2. Install dependencies:
   ```bash
   bin/setup
   ```

## Development

### Running the Application

```bash
bin/rails server
```

The API will be available at `http://localhost:3000`

### Database

```bash
bin/rails db:create    # Create database
bin/rails db:migrate   # Run migrations
bin/rails db:seed      # Load seed data (if any)
```

### Console

```bash
bin/rails console      # Rails console
bin/rails dbconsole    # Database console
```

## Testing

This project follows Test-Driven Development (TDD) practices.

```bash
bin/rails test                              # Run all tests
bin/rails test test/models/event_test.rb   # Run specific test file
```

## Code Quality

All code must pass RuboCop checks:

```bash
bin/rubocop            # Check code style
bin/rubocop -a         # Auto-correct issues
bin/brakeman           # Security analysis
```

## Data Models

### Event
- **Attributes**: name (unique), date, location
- **Purpose**: Represents UFC events
- **Associations**: has_many :fights

### Fighter
- **Attributes**: name, height_in_inches, reach_in_inches, birth_date
- **Purpose**: Represents individual MMA fighters
- **Associations**: has_many :fight_stats

### Fight
- **Attributes**: bout, outcome, weight_class, method, round, time, referee, details
- **Purpose**: Individual fights within UFC events
- **Associations**: belongs_to :event, has_many :fight_stats

### FightStat
- **Attributes**: Comprehensive striking and grappling statistics per round
- **Purpose**: Detailed round-by-round performance metrics
- **Associations**: belongs_to :fight, belongs_to :fighter

## Data Import

The application includes 4 specialized importer classes that follow consistent patterns:

### EventImporter
```ruby
importer = EventImporter.new
events = importer.import
```

### FighterImporter
```ruby
importer = FighterImporter.new
fighters = importer.import
```

### FightImporter
```ruby
importer = FightImporter.new
fights = importer.import
```

### FightStatImporter
```ruby
importer = FightStatImporter.new
stats = importer.import
```

**Import Features:**
- Fetches data from external UFC statistics CSV files
- Handles duplicates gracefully with find_or_initialize_by
- Performance optimization with caching strategies
- Comprehensive error handling and logging
- Returns arrays of successfully imported records

**Import Dependencies:** Events → Fighters (independent) → Fights → Fight Stats

## API Endpoints

*Note: API endpoints are under development*

## Deployment

The application is configured for deployment with Kamal:

```bash
bin/kamal deploy
```

## External Data Sources

- UFC Event Data: https://github.com/Greco1899/scrape_ufc_stats

## Contributing

1. Follow TDD practices - write tests first
2. Ensure all tests pass
3. Run RuboCop and fix any violations
4. Keep commits focused and descriptive

## License

*To be determined*
