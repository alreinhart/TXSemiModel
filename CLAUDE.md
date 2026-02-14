# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

R-based web scraping framework for collecting semiconductor job postings from company career pages. Targets Texas-area semiconductor companies (Applied Materials, NXP, TI, Samsung, SkyWater, Tokyo Electron). Uses SQLite for storage, with quarterly automated runs via GitHub Actions.

## Running the Scraper

```bash
# All companies
Rscript semiconductor_jobs_scraper/scrapers/main.R all

# Single company
Rscript semiconductor_jobs_scraper/scrapers/main.R "Applied Materials"
```

From R/RStudio (working directory must be `semiconductor_jobs_scraper/`):
```r
source("scrapers/main.R")
scrape_company("Applied Materials")   # single company
scrape_all_companies()                # all companies
```

## Installing Dependencies

```r
install.packages(c("rvest", "httr", "jsonlite", "DBI", "RSQLite",
                    "dplyr", "lubridate", "readr", "purrr", "stringr",
                    "glue", "xml2", "here"))
```

## Architecture

All scraper code lives under `semiconductor_jobs_scraper/`.

**Execution flow:** `main.R` orchestrates everything — initializes the SQLite DB, loads companies from `config/companies.csv`, dispatches to platform-specific scrapers based on each company's `platform` field, saves results, and exports CSVs.

**Platform scrapers** are routed by the `platform` column in `companies.csv`:
- `workday` → `scrapers/workday_scraper.R` (production-ready, handles pagination)
- `oracle` → `scrapers/oracle_scraper.R` (template, not fully tested)
- `custom` → not yet implemented (Samsung, SkyWater, Tokyo Electron)

**Key files:**
- `config/scraper_config.R` — all tunable parameters: rate limits, timeouts, CSS selectors, user-agent
- `config/db_schema.sql` — SQLite schema with 3 tables (`companies`, `jobs`, `scrape_runs`) and 2 views
- `scrapers/utils.R` — shared utilities: logging, HTTP fetch with retry/backoff, robots.txt checking, date parsing, text sanitization
- `scrapers/main.R` — orchestration, DB init, upsert logic, CSV export

**Data outputs:**
- SQLite DB: `data/semiconductor_jobs.db`
- CSV exports: `data/exports/jobs_<company>_YYYYMMDD.csv`
- Logs: `logs/scrape_YYYYMMDD.log`

## Database

Jobs are deduplicated by `job_url` uniqueness constraint. The `save_jobs_to_db()` function in `main.R` implements upsert logic. Two convenience views exist: `vw_jobs_full` (jobs joined with company names) and `vw_scrape_stats` (scraping run statistics).

## Adding a New Company

1. Add a row to `config/companies.csv` with the company name, careers URL, and platform type
2. If the platform type already has a scraper (workday/oracle), it works automatically
3. For a new platform, create a new scraper file following the pattern in `workday_scraper.R` and add routing in `scrape_company()` in `main.R`

## Rate Limiting & Ethics

The scraper respects robots.txt (checked via `check_robots_txt()` in utils.R) and enforces configurable delays between requests (default 3s) and between companies (default 10s). These are set in `config/scraper_config.R`.

## CI/CD

GitHub Actions workflow at `semiconductor_jobs_scraper/.github/workflows/quarterly_scrape.yml` runs quarterly (Jan/Apr/Jul/Oct 1st at 2AM UTC). Supports manual dispatch with company selection. Auto-commits results and creates quarterly releases.
