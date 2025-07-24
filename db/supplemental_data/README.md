# Supplemental Data Directory

This directory contains CSV files for data that's missing from the primary data source.

## How it works

1. The importers automatically check this directory for supplemental CSV files
2. Data from these files is merged with the primary source data
3. Duplicate prevention still works - existing records won't be recreated

## Files

- `events.csv` - Missing UFC events
- `fighters.csv` - Missing fighter profiles  
- `fights.csv` - Missing fight results
- `fight_stats.csv` - Missing fight statistics

## Adding missing data

1. Find the missing data on the UFC website
2. Add rows to the appropriate CSV file following the same format
3. Run `bin/rails db:seed` to import the new data

## Example events.csv entry

```csv
EVENT,URL,DATE,LOCATION
"UFC Fight Night: Tuivasa vs. Tybura",https://www.ufc.com/event/ufc-fight-night-march-16-2024,"March 16, 2024","Las Vegas, NV"
```

Note: The URL field is optional and not used by the importer.