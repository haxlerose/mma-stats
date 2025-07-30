# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.
ALWAYS use the appropriate subagent for the task at hand.

## Repository Overview

Full-stack MMA statistics application with Rails API backend and Next.js frontend for comprehensive UFC data visualization.

**Backend Stack:**
- Ruby 3.4.5 with Rails 8.0.2 (API-only)
- PostgreSQL with Solid Queue/Cache/Cable
- Faraday for HTTP requests, VCR for test recording

**Frontend Stack:**
- Next.js 15.4.2 with App Router
- React 19.1.0 with TypeScript
- Tailwind CSS v4 for styling
- Jest + React Testing Library

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

# Frontend (in frontend directory)
npm install                 # Install dependencies
npm run dev                 # Start dev server (port 3001)
npm run build              # Build for production
npm test                   # Run tests
npm run lint               # ESLint check
```

## Project Architecture

### Backend (Rails API)
- API-only mode with JSON responses
- CORS enabled for frontend at localhost:3001
- RESTful endpoints under /api/v1 namespace

### Frontend (Next.js)
- `/frontend` directory with App Router structure
- Pages: Dashboard, Events, Fighters, Fight details
- Reusable components in `/components`
- API client at `/lib/api.ts` for backend communication
- TypeScript interfaces in `/types/api.ts`

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
- IMPORTANT! ALWAYS use the appropriate subagent for the job

### Git Messages
- **GIT COMMIT MESSAGES SHOULD ONLY CONTAIN CODE CHANGE DESCRIPTIONS**
- **YOU MUST NOT mention "Claude" in commit messages**

### Code Quality
- Follow SOLID, OOP, and Ruby on Rails best practices for Ruby code
- Keep controller and model files skinny following Single Responsibility Principle
- Frontend components should be designed to be reusable
- Use TypeScript strict mode with proper type definitions
- Implement proper error boundaries and loading states
- Keep components focused - single responsibility principle
- Extract business logic into custom hooks when appropriate
- Avoid prop drilling - use component composition
- Follow RESTful conventions for API endpoints

## Testing (TDD MANDATORY)

### ⚠️ CRITICAL REQUIREMENT
**ALL PRODUCTION CODE MUST FOLLOW Test-Driven Development (TDD)**
- **Red**: Write failing test describing desired behavior before writing code
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
- **Faraday** for HTTP requests, **VCR** for test recording

### Domain Models & Data Import

**Core Entities:** Event/Fighter/Fight/FightStat with comprehensive validations and associations
**4 Importers:** CSV fetching from https://github.com/Greco1899/scrape_ufc_stats with caching optimization
**Dependencies:** Events → Fighters (independent) → Fights → Fight Stats

## API Endpoints (Read-Only)

**Versioned Structure:** All endpoints under `/api/v1/`

**Available Endpoints:**
- `GET /api/v1/events` - List events (date ordered) + `GET /api/v1/events/:id` - Event with fights
- `GET /api/v1/fighters` - List fighters (searchable) + `GET /api/v1/fighters/:id` - Fighter with full history
- `GET /api/v1/fights/:id` - Complete fight details with statistics

**Features:** Custom JSON serialization, eager loading optimization, fighter name search, comprehensive round-by-round statistics, no authentication (open API)

## Frontend Pages & Components

**Main Pages:**
- `/` - Dashboard with recent events, fighter spotlight, stats
- `/events` - Paginated event list with location filtering
- `/events/[id]` - Event details with fight card
- `/fighters` - Fighter search with debounced input
- `/fighters/[id]` - Fighter profile with stats and history
- `/fights/[id]` - Fight details with round-by-round breakdown

**Key Features:**
- Responsive design with Tailwind CSS
- Loading states and error handling
- Debounced search functionality
- Fight statistics visualization
- Avatar circles with fighter initials

## Important Notes

- **IMPORTANT! YOU MUST ALWAYS USE TDD AS EXPLAINED EARLIER**
- ALWAYS use the subagent that is right for the job
- Frontend runs on port 3001, backend on 3000
- Use TypeScript for all frontend code
- Follow existing component patterns
- Maintain consistent styling with Tailwind
