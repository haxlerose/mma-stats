# MMA Stats API

A Ruby on Rails API application for tracking and analyzing Mixed Martial Arts (MMA) statistics, with a focus on UFC event data.

## Overview

This API-only Rails application imports and manages UFC event data, with plans to expand to fighter statistics, fight results, and predictive analytics.

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
- **Data Source**: Imported from external CSV via EventImporter

## Data Import

### EventImporter

Import UFC event data:

```ruby
importer = EventImporter.new
events = importer.import
```

The importer:
- Fetches data from UFC events CSV
- Handles duplicates gracefully
- Logs any import failures
- Returns successfully imported Event records

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