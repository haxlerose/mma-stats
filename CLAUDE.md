# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Ruby on Rails 8.0.2 API-only application for MMA (Mixed Martial Arts) statistics data collection and storage. The application imports comprehensive UFC data including events, fighters, fights, and detailed fight statistics from external CSV sources.

**Technology Stack:**
- Ruby 3.4.5 with Rails 8.0.2 (API-only mode)
- PostgreSQL database
- Faraday for external HTTP requests
- VCR for recording/replaying HTTP interactions in tests
- Solid Queue/Cache/Cable (Rails 8 native adapters)

## Essential Commands

```bash
# Initial setup
bin/setup                    # Install dependencies, create database, start server

# Development
bin/rails server            # Start development server
bin/rails console           # Interactive Rails console
bin/rails dbconsole         # Database console

# Database
bin/rails db:create         # Create databases
bin/rails db:migrate        # Run pending migrations
bin/rails db:prepare        # Create and migrate in one command
bin/rails db:seed           # Load seed data

# Testing
bin/rails test              # Run all tests
bin/rails test test/models/fighter_test.rb  # Run specific test file

# Code Quality
bin/rubocop                 # Ruby linting (80 char limit, double quotes)
bin/brakeman                # Security scanning

# Deployment
bin/kamal deploy            # Deploy using Kamal
```

## Project Architecture

### API-Only Configuration
- No views or frontend components
- JSON API responses only
- CORS configuration needed for frontend clients

### Database Structure
**Database Type:** PostgreSQL with Rails 8.0.2 Solid adapters
**Schema Version:** 2025_07_21_123911
**Extensions:** pg_trgm (trigram search), plpgsql

#### **Core Application Tables**

**Events Table:**
- **Purpose:** UFC event storage
- **Columns:** id, name (unique), date, location, timestamps
- **Indexes:** Unique index on name, date DESC for chronological ordering
- **Associations:** has_many :fights (dependent: :destroy)
- **Validations:** name (presence, uniqueness), date/location (presence)

**Fighters Table:**
- **Purpose:** Fighter profiles with physical attributes
- **Columns:** id, name (not null), height_in_inches, reach_in_inches, birth_date, timestamps
- **Indexes:** 
  - Standard btree on name
  - Functional index on LOWER(name) for case-insensitive sorting
  - GIN trigram index for fuzzy text search
- **Associations:** has_many :fight_stats, has_many :fights (through :fight_stats)
- **Scopes:** alphabetical, search(query), with_fight_details
- **Validations:** name (presence)

**Fights Table:**
- **Purpose:** Individual fights within events
- **Columns:** id, event_id (FK), bout, outcome, weight_class, method, round, time, time_format, referee, details, timestamps
- **Foreign Keys:** event_id → events.id (with constraint)
- **Indexes:** Foreign key index on event_id
- **Associations:** belongs_to :event, has_many :fight_stats (dependent: :destroy)
- **Scopes:** with_full_details (includes event and fight_stats)
- **Validations:** bout, outcome, weight_class (presence)

**Fight Stats Table:**
- **Purpose:** Detailed round-by-round fighting statistics per fighter
- **Columns:** 
  - **Core:** id, fight_id (FK), fighter_id (FK), round, timestamps
  - **Striking:** knockdowns, significant_strikes/attempted, total_strikes/attempted
  - **Target-Specific:** head/body/leg strikes and attempts
  - **Position-Specific:** distance/clinch/ground strikes and attempts
  - **Grappling:** takedowns/attempted, submission_attempts, reversals, control_time_seconds
- **Foreign Keys:** fight_id → fights.id, fighter_id → fighters.id (with constraints)
- **Indexes:** Foreign key indexes on fight_id and fighter_id
- **Associations:** belongs_to :fight, belongs_to :fighter
- **Validations:** round (presence)

#### **Rails 8 Solid Adapters (Background System)**

**Solid Queue (12 tables):**
- Background job processing replacing Redis/Sidekiq
- Tables: jobs, executions (ready/scheduled/claimed/failed/blocked), processes, pauses, recurring_tasks, semaphores
- Database-backed queuing with state management

**Solid Cache (1 table):**
- `solid_cache_entries` with binary key/value storage
- Hash-based indexing for fast cache lookups
- Database-backed caching replacing Redis

**Solid Cable (1 table):**
- `solid_cable_messages` for real-time messaging
- Channel-based message routing with hash indexes

#### **Database Performance Features**
- **PostgreSQL Extensions:** pg_trgm for fuzzy search, plpgsql
- **Strategic Indexing:** Optimized for query patterns
- **Foreign Key Constraints:** Referential integrity enforcement
- **Cascading Deletes:** Automatic cleanup of dependent records
- **Query Optimization:** Scopes with includes for N+1 prevention

### Code Organization Patterns
- **Controllers**: Place API endpoints in `app/controllers/api/v1/`
- **Jobs**: Background processing in `app/jobs/` for data syncing
- **Models**: All business logic using namespacing for organization
- **Importers**: Data import classes (e.g., EventImporter) for external data sources

## Development Standards

## Testing (TDD MANDATORY)

### ⚠️ CRITICAL REQUIREMENT
**ALL PRODUCTION CODE MUST FOLLOW Test-Driven Development (TDD)**
- **Red**: Write failing test describing desired behavior
- **Green**: Write minimum code to make test pass
- **Refactor**: Improve code using SOLID principles while keeping tests green

### Testing Approach
- Framework: Minitest (Rails default)
- Parallel testing enabled for speed
- Test files mirror app structure exactly
- Run specific test files during development, not full suite

### Code Style (RuboCop enforced)
- 80 character line limit
- Double quotes for strings
- Extensive line-breaking for readability
- Rails and Performance cops enabled
- **ZERO RUBOCOP VIOLATIONS ALLOWED** - All code must pass RuboCop checks
- **ALL TESTS MUST PASS** - No failing tests in the test suite

### External Data Integration
- Faraday gem available for HTTP requests
- VCR for recording HTTP interactions in test environment
- UFC event data source: https://github.com/Greco1899/scrape_ufc_stats

### Current Domain Models

**Event**
- Represents a UFC event
- Attributes: name (unique), date, location
- Associations: has_many :fights
- Imported via EventImporter from CSV data

**Fighter**
- Represents individual MMA fighters
- Attributes: name, height_in_inches, reach_in_inches, birth_date
- Associations: has_many :fight_stats
- Imported via FighterImporter with physical stats parsing

**Fight**
- Represents individual fights within events
- Attributes: bout, outcome, weight_class, method, round, time, referee, details
- Associations: belongs_to :event, has_many :fight_stats
- Imported via FightImporter with event lookup caching

**FightStat**
- Detailed round-by-round fighting statistics
- Comprehensive striking/grappling metrics per fighter per round
- Associations: belongs_to :fight, belongs_to :fighter
- Imported via FightStatImporter with triple-cache optimization

### Data Import System
All importers follow consistent patterns:
- CSV data fetching from GitHub repository
- Error handling with detailed logging
- Performance optimization with caching strategies
- Graceful duplicate handling with find_or_initialize_by

**Import Dependencies:** Events → Fighters (independent) → Fights → Fight Stats

## API Endpoints

### **Versioned API Structure**
All endpoints follow `/api/v1/` pattern for future API iterations.

#### **Events API**
- **GET `/api/v1/events`**
  - Returns: Array of events ordered by date (descending)
  - Data: `{ events: [{ id, name, date, location }] }`

- **GET `/api/v1/events/:id`**
  - Returns: Event details with associated fights
  - Data: Event object with nested fights array including bout details, outcomes, methods, etc.

#### **Fighters API**
- **GET `/api/v1/fighters`**
  - Returns: Alphabetically sorted fighters
  - Parameters: `search` (optional) - Case-insensitive name search
  - Data: `{ fighters: [{ id, name, height_in_inches, reach_in_inches, birth_date }] }`

- **GET `/api/v1/fighters/:id`**
  - Returns: Fighter with complete fight history and statistics
  - Data: Fighter object with nested fights array, each including:
    - Fight details (bout, outcome, method, round, time, referee)
    - Event details (name, date)
    - Round-by-round fight_stats (strikes, takedowns, control time, etc.)

#### **Fights API**
- **GET `/api/v1/fights/:id`**
  - Returns: Complete fight details with both fighters and all statistics
  - Data: Fight object with nested:
    - Event details
    - Fighters array with physical stats
    - Fight_stats array with comprehensive round-by-round metrics

#### **Health Check**
- **GET `/up`** - Rails health check endpoint (200/500 status)

### **API Features**
- **Read-only endpoints** - Only GET operations (index, show)
- **Custom JSON serialization** - Uses as_json with field filtering
- **Query optimization** - Eager loading with includes to prevent N+1 queries
- **Search functionality** - Fighter name search with ILIKE pattern matching
- **No authentication** - Open API currently
- **Comprehensive statistics** - Round-by-round striking/grappling metrics

### **Response Format**
- Root level resource wrapper (e.g., `{ events: [...] }`, `{ fighter: {...} }`)
- Nested related data appropriately
- Consistent field naming and structure across endpoints

## Important Notes

- **IMPORTANT! YOU MUST ALWAYS USE TDD AS EXPLAINED EARLIER**
- **GIT COMMIT MESSAGES SHOULD ONLY INCLUDE DESCRIPTIONS OF CODE CHANGES**
- **YOU MUST NOT mention "Claude" or anything similar at all in commit messages**
- This is an API-only application - no views or assets pipeline
- Currently focused on data collection and storage, not prediction modeling
- Use JSON serialization for all API responses
- API versioning implemented (v1) for future iterations
- Solid Queue is used for background jobs
- Multi-database production setup requires careful migration targeting
