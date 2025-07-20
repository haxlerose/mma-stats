# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Ruby on Rails 8.0.2 API-only application for MMA (Mixed Martial Arts) statistics tracking and analysis. The project is in early development stages with infrastructure set up but no domain models implemented yet.

**Technology Stack:**
- Ruby 3.4.5 with Rails 8.0.2 (API-only mode)
- PostgreSQL database
- Faraday for external HTTP requests
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
**Development:** Single PostgreSQL database `mma_stats_development`

### Code Organization Patterns
- **Controllers**: Place API endpoints in `app/controllers/api/v1/`
- **Jobs**: Background processing in `app/jobs/` for data syncing
- **Models**: All business logic using namespacing for organization

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

## Important Notes

- **ALWAYS USE TDD AS EXPLAINED EARLIER**
- This is an API-only application - no views or assets pipeline
- Use JSON serialization for all API responses
- Consider implementing API versioning from the start (v1, v2, etc.)
- Solid Queue is used for background jobs
- Multi-database production setup requires careful migration targeting
- Do not mention "Claude" at all in commit messages
