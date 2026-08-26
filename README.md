# Research Business Database Project

A PostgreSQL and PostGIS data pipeline designed to ingest, clean, and organize a historical business dataset. This project processes wide, unnormalized CSV data via Python, loads it into a PostgreSQL staging table, and executes relational modeling and spatial transformations to prepare the data for downstream analysis.

---

## 💡 System Architecture & Data Flow

```text
┌─────────────────┐       ┌────────────────────────┐       ┌─────────────────────────┐       ┌───────────────────────────┐
│                 │       │                        │       │                         │       │   Normalized Relational   │
│  CSV Source     │ ───►  │  Python (pandas)       │ ───►  │  PostgreSQL             │ ───►  │   Schema                  │
│  Data           │       │  Cleaning & Parsing    │       │  Staging (raw_businesses)│       │   + PostGIS Geometries    │
└─────────────────┘       └────────────────────────┘       └─────────────────────────┘       └───────────────────────────┘
```

1. **Ingest & Clean (Python):** Load CSV data, standardize column headers, combine overlapping attributes, and impute missing values.
2. **Stage (PostgreSQL):** Persist observation-level records into a wide `raw_businesses` staging table to retain raw provenance.
3. **Normalize (SQL):** Split wide staging records into third-normal-form (3NF) relational sub-tables using SQL transactional logic.
4. **Spatial Transform (PostGIS):** Parse string-formatted projected coordinates into native PostGIS geometry points (`ESRI:102003`).

---

## 🛠 Tech Stack

- **Language:** Python 3.x
- **Data Processing:** pandas, SQLAlchemy, psycopg2
- **Database:** PostgreSQL 14+ with PostGIS Extension
- **Spatial Projection:** USA Contiguous Albers Equal Area Conic (`ESRI:102003` / WGS84 `EPSG:4326`)

---

## 📁 Project Structure

```text
research_business_db/
├── data/
│   └── small_set_for_thai.csv        # Source raw CSV dataset
├── scripts/
│   └── load_raw_businesses.py        # ETL script for parsing and staging CSV data
├── sql/
│   ├── schema.sql                    # Schema definition for staging table (`raw_businesses`)
│   ├── create_subtables.sql          # DDL for normalized relational tables
│   └── populate_subtables.sql        # DML scripts to transform staging data into normalized tables
└── README.md                         # Project documentation
```

---

## 🛢️ Staging Layer (`raw_businesses`)

The `raw_businesses` table stores preprocessed, wide-format records directly imported from Python. Preserving this staging layer ensures auditability, allowing for iterative schema redesigns without requiring re-parsing of the raw CSV file.

### Staging Schema Definition

```sql
CREATE TABLE raw_businesses (
    row_id SERIAL PRIMARY KEY,
    tractid VARCHAR(50),
    year INTEGER,
    id VARCHAR(255),
    annual_id VARCHAR(255) UNIQUE,
    business_name VARCHAR(255),
    category VARCHAR(255),
    dancing_bar INTEGER,
    sports_bar INTEGER,
    video_bar INTEGER,
    karaoke_bar INTEGER,
    country_bar INTEGER,
    leather_bar INTEGER,
    western_bar INTEGER,
    private_club INTEGER,
    clothing_opt_bar INTEGER,
    asian INTEGER,
    latine INTEGER,
    black INTEGER,
    poc INTEGER,
    two_spirit INTEGER,
    jewish INTEGER,
    diverse INTEGER,
    phone_1 VARCHAR(20),
    address VARCHAR(255),
    county_name VARCHAR(50),
    state VARCHAR(30),
    new_state VARCHAR(2),
    zip VARCHAR(10),
    email VARCHAR(100),
    website VARCHAR(255),
    fax VARCHAR(20),
    full_text TEXT,
    all_men INTEGER,
    all_women INTEGER,
    bi INTEGER,
    trans INTEGER,
    gbtqi_men INTEGER,
    glbtqi INTEGER,
    match_distance DOUBLE PRECISION,
    geoauth VARCHAR(50),
    geometry TEXT,                      -- Stored as string prior to PostGIS parsing
    geometry_location_type VARCHAR(100),
    statefp10 VARCHAR(2),
    countyfp10 VARCHAR(3),
    -- cbsa VARCHAR(10),
    -- cbsa_name VARCHAR(255)
);
```

---

## 🧹 Data Ingestion & Preprocessing

The Python script `scripts/load_raw_businesses.py` handles column coalescing prior to database insertion. Legacy or redundant columns are consolidated into single unified variables using `bfill` (backward fill) logic across rows.

### Column Mapping Matrix

| Cleaned Variable   | Source Columns Consolidated   |
| :----------------- | :---------------------------- |
| `dancing_bar`      | `symbol_14`, `_DANCING_`      |
| `sports_bar`       | `symbol_15`, `_SPORT_BAR_`    |
| `video_bar`        | `symbol_16`, `_VIDEO_BAR_`    |
| `karaoke_bar`      | `symbol_17`, `_KARAOKE_`      |
| `country_bar`      | `symbol_18`, `_COUNTRY_`      |
| `leather_bar`      | `symbol_19`, `_LEATHER_`      |
| `western_bar`      | `symbol_20`, `_WESTERN_`      |
| `private_club`     | `symbol_21`, `_PRIV_CLUB_`    |
| `clothing_opt_bar` | `symbol_22`, `_CLOTH_OPT_`    |
| `asian`            | `symbol_30`, `_ASIAN_`        |
| `latine`           | `symbol_31`, `_LATIN_`        |
| `black`            | `symbol_32`, `_AFRICAN_`      |
| `poc`              | `symbol_33`, `_PEOPLE_COLOR_` |
| `two_spirit`       | `symbol_34`, `_TWO_SPIRIT_`   |
| `diverse`          | `symbol_36`, `_DIVERSE_`      |

### Python Consolidation Logic

```python
def combine_columns(df: pd.DataFrame, new_col: str, source_cols: list) -> pd.DataFrame:
    """Coalesces multiple source columns into a single target column using the first non-null value."""
    existing_cols = [col for col in source_cols if col in df.columns]

    if not existing_cols:
        print(f"Warning: No source columns found for {new_col}: {source_cols}")
        df[new_col] = None
        return df

    df[new_col] = df[existing_cols].bfill(axis=1).iloc[:, 0]
    return df
```

---

## 📐 Relational Target Schema

After staging, data is split into domain-specific tables to eliminate redundancy and improve query performance.

```text
                  ┌──────────────────────┐
                  │      businesses      │ (Core Entity)
                  └──────────┬───────────┘
                             │
     ┌───────────────────────┼───────────────────────┬──────────────────────┐
     │ 1:1                   │ 1:1                   │ 1:1                  │ 1:1
┌────┴────────────┐  ┌───────┴──────────┐  ┌─────────┴─────────┐  ┌─────────┴─────────┐
│business_contacts│  │business_geography│  │business_bar_attrs │  │business_ident_attr│
└─────────────────┘  └──────────────────┘  └───────────────────┘  └───────────────────┘
```

### Table Definitions

```sql
-- 1. Core Businesses Entity
CREATE TABLE businesses (
    business_id SERIAL PRIMARY KEY,
    raw_row_id INTEGER UNIQUE REFERENCES raw_businesses(row_id),
    tractid VARCHAR(50),
    year INTEGER,
    source_id VARCHAR(255),
    annual_id VARCHAR(255),
    business_name VARCHAR(255),
    category VARCHAR(255)
);

-- 2. Business Contacts
CREATE TABLE business_contacts (
    contact_id SERIAL PRIMARY KEY,
    business_id INTEGER UNIQUE REFERENCES businesses(business_id) ON DELETE CASCADE,
    phone_1 VARCHAR(20),
    email VARCHAR(100),
    website VARCHAR(255),
    fax VARCHAR(20),
    full_text TEXT
);

-- 3. Business Spatial & Geographic Attributes
CREATE TABLE business_geography (
    geography_id SERIAL PRIMARY KEY,
    business_id INTEGER UNIQUE REFERENCES businesses(business_id) ON DELETE CASCADE,
    address VARCHAR(255),
    county_name VARCHAR(50),
    state VARCHAR(30),
    new_state VARCHAR(2),
    zip VARCHAR(10),
    statefp10 VARCHAR(2),
    countyfp10 VARCHAR(3),
    -- cbsa VARCHAR(10),
    match_distance DOUBLE PRECISION,
    geoauth VARCHAR(50),
    geometry geometry(Point, 102003),
    geometry_location_type VARCHAR(100)
);

-- 4. Bar Attributes
CREATE TABLE business_bar_attributes (
    business_id INTEGER PRIMARY KEY REFERENCES businesses(business_id) ON DELETE CASCADE,
    dancing_bar INTEGER,
    sports_bar INTEGER,
    video_bar INTEGER,
    karaoke_bar INTEGER,
    country_bar INTEGER,
    leather_bar INTEGER,
    western_bar INTEGER,
    private_club INTEGER,
    clothing_opt_bar INTEGER
);

-- 5. Identity & Audience Attributes
CREATE TABLE business_identity_attributes (
    business_id INTEGER PRIMARY KEY REFERENCES businesses(business_id) ON DELETE CASCADE,
    asian INTEGER,
    latine INTEGER,
    black INTEGER,
    poc INTEGER,
    two_spirit INTEGER,
    jewish INTEGER,
    diverse INTEGER,
    all_men INTEGER,
    all_women INTEGER,
    bi INTEGER,
    trans INTEGER,
    gbtqi_men INTEGER,
    glbtqi INTEGER
);

-- 6. Metropolitan Statistical Areas (Lookup)
-- CREATE TABLE metro_areas (
--     cbsa VARCHAR(10) PRIMARY KEY,
--     cbsa_name VARCHAR(255)
-- );

-- 7. Census Tract Contextual Demographics
CREATE TABLE tract_year_context (
    tract_year_id SERIAL PRIMARY KEY,
    tractid VARCHAR(50),
    year INTEGER,
    statefp10 VARCHAR(2),
    countyfp10 VARCHAR(3),
    UNIQUE (tractid, year)
);
```

---

## 🗺️ Spatial Coordinate Parsing (PostGIS)

The source CSV provides projected coordinates formatted as R vector strings: `c(-2266671.7528, 253561.4665)`.

During population of the `business_geography` table, these strings are parsed into PostGIS point geometries registered under the **USA Contiguous Albers Equal Area Conic** spatial reference system (`ESRI:102003`).

### SQL Spatial Transformation Query

```sql
INSERT INTO business_geography (
    business_id, address, county_name, state, new_state, zip,
    statefp10, countyfp10, match_distance, geoauth,
    geometry_location_type, geometry
)
SELECT
    b.business_id,
    r.address,
    r.county_name,
    r.state,
    r.new_state,
    r.zip,
    r.statefp10,
    r.countyfp10,
    r.match_distance,
    r.geoauth,
    r.geometry_location_type,
    CASE
        WHEN r.geometry IS NOT NULL AND r.geometry <> '' AND r.geometry LIKE 'c(%'
        THEN ST_SetSRID(
            ST_MakePoint(
                split_part(replace(replace(replace(r.geometry, 'c(', ''), ')', ''), ' ', ''), ',', 1)::DOUBLE PRECISION,
                split_part(replace(replace(replace(r.geometry, 'c(', ''), ')', ''), ' ', ''), ',', 2)::DOUBLE PRECISION
            ),
            102003
        )
        ELSE NULL
    END AS geometry
FROM raw_businesses r
JOIN businesses b ON r.row_id = b.raw_row_id;
```

---

## 🚀 Execution Guide

### Prerequisites

- PostgreSQL with PostGIS installed locally or accessible via network.
- Python 3.8+ with `pandas`, `sqlalchemy`, and `psycopg2`.

### Step-by-Step Setup

```bash
# 1. Initialize PostgreSQL Database
psql -U postgres -c "CREATE DATABASE research_business_db;"

# 2. Enable PostGIS Extension
psql -U postgres -d research_business_db -c "CREATE EXTENSION IF NOT EXISTS postgis;"

# 3. Create Raw Staging Schema
psql -U postgres -d research_business_db -f sql/schema.sql

# 4. Ingest Raw CSV Data
python scripts/load_raw_data.py

# 5. Transform and Populate Sub-tables
psql -U postgres -d research_business_db -f sql/populate_clean_tables.sql

# 6. Create Indexes for Tables
psql -U postgres -d research_business_db -f sql/indexes.sql
```

---

## 🔍 Analytical Query Examples

### Geographic Coordinate Conversion (Albers → WGS84 Lat/Long)

Re-projects internal projected meters to standard GPS coordinates (WGS84 / EPSG:4326) for web mapping or GIS exports.

```sql
SELECT
    b.business_name,
    g.state,
    ST_X(ST_Transform(g.geometry, 4326)) AS longitude,
    ST_Y(ST_Transform(g.geometry, 4326)) AS latitude
FROM businesses b
JOIN business_geography g ON b.business_id = g.business_id
WHERE g.geometry IS NOT NULL
LIMIT 10;
```
