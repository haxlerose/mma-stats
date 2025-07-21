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

## Database Schema

### **Database Architecture**
- **Type**: PostgreSQL with Rails 8.0.2 Solid adapters
- **Extensions**: pg_trgm (fuzzy text search), plpgsql
- **Background Processing**: Solid Queue/Cache/Cable (18 tables total)

### **Core Data Models**

#### **Event**
- **Purpose**: UFC event storage with unique constraints
- **Columns**: id, name (unique), date, location, timestamps
- **Indexes**: Unique on name, DESC on date for chronological queries
- **Relationships**: 
  - `has_many :fights` (dependent destroy)
- **Validations**: name (presence, uniqueness), date/location (presence)

#### **Fighter**
- **Purpose**: Fighter profiles with physical attributes and search optimization
- **Columns**: id, name (not null), height_in_inches, reach_in_inches, birth_date, timestamps
- **Advanced Indexing**: 
  - Standard btree on name
  - Functional index LOWER(name) for case-insensitive sorting
  - GIN trigram index for fuzzy name search
- **Relationships**: 
  - `has_many :fight_stats`
  - `has_many :fights` (through fight_stats)
- **Scopes**: alphabetical, search(query), with_fight_details
- **Search**: ILIKE pattern matching with trigram support

#### **Fight**
- **Purpose**: Individual fight records within events
- **Columns**: id, event_id (FK), bout, outcome, weight_class, method, round, time, time_format, referee, details, timestamps
- **Foreign Keys**: event_id → events.id (with constraint)
- **Relationships**: 
  - `belongs_to :event`
  - `has_many :fight_stats` (dependent destroy)
- **Scopes**: with_full_details (eager loads event and stats)
- **Methods**: fighters (unique fighters from stats)

#### **FightStat**
- **Purpose**: Comprehensive round-by-round fighting metrics per fighter
- **Core Columns**: id, fight_id (FK), fighter_id (FK), round, timestamps
- **Striking Stats**: 
  - knockdowns, significant_strikes/attempted, total_strikes/attempted
  - Target-specific: head/body/leg strikes and attempts
  - Position-specific: distance/clinch/ground strikes and attempts
- **Grappling Stats**: 
  - takedowns/attempted, submission_attempts, reversals
  - control_time_seconds (ground control duration)
- **Foreign Keys**: fight_id → fights.id, fighter_id → fighters.id (with constraints)
- **Relationships**: 
  - `belongs_to :fight`
  - `belongs_to :fighter`

### **Database Relationships**
```
Events (1) → Fights (Many) → Fight Stats (Many) ← Fighters (Many)
                                       ↓
                               Many-to-Many relationship
                               (Fighters ↔ Fights through Fight Stats)
```

### **Performance Features**
- **Strategic Indexing**: Optimized for common query patterns
- **Foreign Key Constraints**: Referential integrity enforcement
- **Cascading Deletes**: Automatic cleanup of dependent records
- **Query Optimization**: Scopes with eager loading to prevent N+1 queries
- **Full-Text Search**: PostgreSQL trigram indexing for fighter name fuzzy matching

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

### **API Architecture**
- **Versioning**: All endpoints under `/api/v1/` namespace
- **Format**: JSON responses with consistent wrapper structure
- **Authentication**: None (open API)
- **Query Optimization**: Eager loading with `includes` to prevent N+1 queries

### **Available Endpoints**

#### **Events API**
```
GET /api/v1/events
```
- **Returns**: Array of all events ordered by date (descending)
- **Response**: `{ "events": [{ "id": 1, "name": "UFC 300", "date": "2024-04-13", "location": "Las Vegas" }] }`

```
GET /api/v1/events/:id
```
- **Returns**: Event details with associated fights
- **Includes**: Fight bout details, outcomes, methods, rounds, referees

#### **Fighters API**
```
GET /api/v1/fighters
```
- **Returns**: Alphabetically sorted fighters
- **Parameters**: `search` (optional) - Case-insensitive name search using ILIKE
- **Response**: `{ "fighters": [{ "id": 1, "name": "Jon Jones", "height_in_inches": 76, "reach_in_inches": 84, "birth_date": "1987-07-19" }] }`

```
GET /api/v1/fighters/:id
```
- **Returns**: Fighter with complete fight history and statistics
- **Includes**: 
  - All fights with bout details and outcomes
  - Event information for each fight
  - Round-by-round fight statistics (strikes, takedowns, control time)

#### **Fights API**
```
GET /api/v1/fights/:id
```
- **Returns**: Complete fight details with both fighters and comprehensive statistics
- **Includes**: 
  - Event details (name, date, location)
  - All fighters with physical stats
  - Round-by-round statistics for each fighter
  - Fight outcome, method, referee information

#### **System Health**
```
GET /up
```
- **Purpose**: Health check endpoint for load balancers
- **Returns**: 200 (healthy) or 500 (unhealthy)

### **API Response Features**
- **Consistent Structure**: Root-level resource wrappers
- **Nested Data**: Related information included appropriately
- **Performance Optimized**: Strategic eager loading
- **Search Capability**: Fighter name fuzzy matching
- **Comprehensive Statistics**: Round-by-round striking and grappling metrics
- **Read-Only**: GET operations only (index and show actions)

## Deployment

The application is configured for deployment with Kamal:

```bash
bin/kamal deploy
```

## External Data Sources

- **Primary Data Source**: UFC Event Data from https://github.com/Greco1899/scrape_ufc_stats
- **Data Format**: CSV files with comprehensive fight statistics
- **Import Process**: Automated via specialized importer classes
- **Data Coverage**: Events, fighters, individual fights, round-by-round statistics

## Contributing

1. Follow TDD practices - write tests first
2. Ensure all tests pass
3. Run RuboCop and fix any violations
4. Keep commits focused and descriptive

## License

*To be determined*
