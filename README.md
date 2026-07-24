# Research Business Database Project

This project builds a PostgreSQL database for storing, cleaning, and organizing a historical business dataset. The original dataset is imported from a CSV file into a raw staging table, then cleaned and transformed into smaller relational tables for easier querying and analysis.

The project focuses on businesses, their locations, contact information, geocoding data, demographic context, and classification variables related to ownership, audience, and business type.

## Project Overview

The main goal of this project is to convert a wide CSV dataset into a structured relational database.

The workflow is:

1. Load the original CSV file into Python using pandas.
2. Rename unclear or inconsistent column names.
3. Combine duplicate or equivalent variables into cleaner columns.
4. Import the cleaned data into a PostgreSQL raw table.
5. Use SQL to split the raw table into smaller normalized tables.
6. Convert raw geometry text into PostGIS geometry objects for spatial analysis.

## Tech Stack

- Python
- pandas
- SQLAlchemy
- psycopg2
- PostgreSQL
- PostGIS
- CSV data loading
- Relational database design

## Project Structure

```text
research_business_db/
├── data/
│   └── small_set_for_thai.csv
├── scripts/
│   └── load_raw_businesses.py
├── sql/
│   ├── schema.sql
│   ├── create_subtables.sql
│   └── populate_subtables.sql
└── README.md
```

## Database Name

```text
research_business_db
```

## Raw Data Table

The main raw import table is `raw_businesses`.

This table stores cleaned but still mostly raw data from the CSV. It keeps one row per business-year observation.

### Example Schema

```sql
CREATE TABLE raw_businesses (
    row_id SERIAL PRIMARY KEY,
    original_index INTEGER,
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
    phone_2 VARCHAR(20),
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
    geometry TEXT,
    geometry_location_type VARCHAR(100),
    statefp10 VARCHAR(2),
    countyfp10 VARCHAR(3),
    queerown INTEGER,
    queeraud INTEGER,
    core INTEGER,
    exploit INTEGER,
    entrep INTEGER,
    waffle INTEGER,
    cbsa VARCHAR(10),
    cbsa_name VARCHAR(255),
    hinc DOUBLE PRECISION,
    hu INTEGER,
    mhmval DOUBLE PRECISION,
    mrent DOUBLE PRECISION,
    msa_college DOUBLE PRECISION,
    msa_income DOUBLE PRECISION,
    p20old DOUBLE PRECISION,
    pasian DOUBLE PRECISION,
    pcol DOUBLE PRECISION,
    phisp DOUBLE PRECISION,
    pnhblk DOUBLE PRECISION,
    pnhwht DOUBLE PRECISION,
    pop INTEGER,
    pothrace DOUBLE PRECISION,
    ppov DOUBLE PRECISION,
    prenter DOUBLE PRECISION,
    punemp DOUBLE PRECISION,
    org_cat VARCHAR(255)
);
```

## Why Use a Raw Table?

The `raw_businesses` table acts as a staging table.

It keeps the imported dataset close to its original form while applying basic cleaning, such as:

- Renaming unclear columns
- Standardizing column names
- Combining duplicate variables
- Preserving the original CSV row index
- Keeping raw geometry as text before converting it into PostGIS geometry

This makes the project safer because the original loaded data remains available even after creating smaller cleaned tables.

## Loading Data

The script `load_raw_businesses.py` loads the CSV file into PostgreSQL.

Main steps:

1. Read the CSV file.
2. Rename columns.
3. Combine equivalent variables.
4. Keep only selected columns.
5. Replace missing values with `NULL`.
6. Delete old rows from `raw_businesses`.
7. Append the cleaned dataframe into PostgreSQL.

Example command:

```bash
python scripts/load_raw_businesses.py
```

## Column Cleaning

Some columns in the original dataset represent the same concept. These are combined into one cleaner column before loading into the database.

Example:

```python
df_clean = combine_columns(df_clean, "two_spirit", ["symbol_34", "_TWO_SPIRIT_"])
```

This creates one cleaned column: `two_spirit`.

The helper function uses the first non-null value from the source columns.

```python
def combine_columns(df, new_col, source_cols):
    existing_cols = [col for col in source_cols if col in df.columns]

    if not existing_cols:
        print(f"Warning: no source columns found for {new_col}: {source_cols}")
        df[new_col] = None
        return df

    df[new_col] = df[existing_cols].bfill(axis=1).iloc[:, 0]
    return df
```

## Important Cleaned Variables

| Clean Column       | Original Source Columns       |
| ------------------ | ----------------------------- |
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
| `queerown`         | `gayown`                      |
| `queeraud`         | `gayaud`                      |

## Suggested Smaller Tables

After loading data into `raw_businesses`, the dataset can be split into smaller relational tables.

Recommended tables:

- `businesses`
- `business_contacts`
- `business_geography`
- `business_bar_attributes`
- `business_identity_attributes`
- `business_classification`
- `metro_areas`
- `census_context`

## 1. Businesses Table

Stores the main business identity information.

```sql
CREATE TABLE businesses (
    business_id SERIAL PRIMARY KEY,
    raw_row_id INTEGER UNIQUE REFERENCES raw_businesses(row_id),
    original_index INTEGER,
    tractid VARCHAR(50),
    year INTEGER,
    source_id VARCHAR(255),
    annual_id VARCHAR(255) UNIQUE,
    business_name VARCHAR(255),
    category VARCHAR(255),
    org_cat VARCHAR(255)
);
```

## 2. Business Contacts Table

Stores contact information.

```sql
CREATE TABLE business_contacts (
    contact_id SERIAL PRIMARY KEY,
    business_id INTEGER UNIQUE REFERENCES businesses(business_id),
    phone_1 VARCHAR(20),
    phone_2 VARCHAR(20),
    email VARCHAR(100),
    website VARCHAR(255),
    fax VARCHAR(20),
    full_text TEXT
);
```

## 3. Business Geography Table

Stores address, FIPS, CBSA, geocoding, and spatial information.

```sql
CREATE TABLE business_geography (
    geography_id SERIAL PRIMARY KEY,
    business_id INTEGER UNIQUE REFERENCES businesses(business_id),
    address VARCHAR(255),
    county_name VARCHAR(50),
    state VARCHAR(30),
    new_state VARCHAR(2),
    zip VARCHAR(10),
    statefp10 VARCHAR(2),
    countyfp10 VARCHAR(3),
    cbsa VARCHAR(10),
    match_distance DOUBLE PRECISION,
    geoauth VARCHAR(50),
    geometry geometry(Point, 102003),
    geometry_location_type VARCHAR(100)
);
```

## Geometry Handling

In the CSV, geometry appears as text in this format:

```text
c(-2266671.75280056, 253561.466568569)
```

This is an R-style coordinate vector, not a PostGIS geometry object.

The coordinates are in the USA_Contiguous_Albers_Equal_Area_Conic projection.

For the raw table, geometry is stored as text:

```sql
geometry TEXT
```

When populating `business_geography`, it should be converted into a PostGIS point:

```sql
ST_SetSRID(
    ST_MakePoint(x, y),
    102003
)
```

Example conversion:

```sql
CASE
    WHEN r.geometry IS NOT NULL AND r.geometry <> ''
    THEN ST_SetSRID(
        ST_MakePoint(
            split_part(
                replace(replace(replace(r.geometry, 'c(', ''), ')', ''), ' ', ''),
                ',',
                1
            )::DOUBLE PRECISION,
            split_part(
                replace(replace(replace(r.geometry, 'c(', ''), ')', ''), ' ', ''),
                ',',
                2
            )::DOUBLE PRECISION
        ),
        102003
    )
    ELSE NULL
END AS geometry
```

    `102003` refers to USA_Contiguous_Albers_Equal_Area_Conic (ESRI:102003), which is used for contiguous U.S. Albers projected coordinates.

## 4. Business Bar Attributes Table

Stores venue-type indicator variables.

```sql
CREATE TABLE business_bar_attributes (
    business_id INTEGER PRIMARY KEY REFERENCES businesses(business_id),
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
```

## 5. Business Identity Attributes Table

Stores audience and identity-related indicator variables.

```sql
CREATE TABLE business_identity_attributes (
    business_id INTEGER PRIMARY KEY REFERENCES businesses(business_id),
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
```

## 6. Business Classification Table

Stores business classification variables.

```sql
CREATE TABLE business_classification (
    business_id INTEGER PRIMARY KEY REFERENCES businesses(business_id),
    queerown INTEGER,
    queeraud INTEGER,
    core INTEGER,
    exploit INTEGER,
    entrep INTEGER,
    waffle INTEGER
);
```

## 7. Metro Areas Table

Stores CBSA information.

```sql
CREATE TABLE metro_areas (
    cbsa VARCHAR(10) PRIMARY KEY,
    cbsa_name VARCHAR(255)
);
```

## 8. Census Context Table

Stores tract-level demographic and socioeconomic variables.

```sql
CREATE TABLE census_context (
    census_context_id SERIAL PRIMARY KEY,
    tractid VARCHAR(50),
    year INTEGER,
    hinc DOUBLE PRECISION,
    hu INTEGER,
    mhmval DOUBLE PRECISION,
    mrent DOUBLE PRECISION,
    msa_college DOUBLE PRECISION,
    msa_income DOUBLE PRECISION,
    p20old DOUBLE PRECISION,
    pasian DOUBLE PRECISION,
    pcol DOUBLE PRECISION,
    phisp DOUBLE PRECISION,
    pnhblk DOUBLE PRECISION,
    pnhwht DOUBLE PRECISION,
    pop INTEGER,
    pothrace DOUBLE PRECISION,
    ppov DOUBLE PRECISION,
    prenter DOUBLE PRECISION,
    punemp DOUBLE PRECISION,
    UNIQUE (tractid, year)
);
```

## Data Type Decisions

| Data Type          | Used For                                                        |
| ------------------ | --------------------------------------------------------------- |
| `INTEGER`          | Counts, flags, binary variables, years                          |
| `DOUBLE PRECISION` | Percentages, distances, income, rent, continuous numeric values |
| `VARCHAR`          | Codes, names, categories, IDs                                   |
| `TEXT`             | Long text fields and raw geometry before conversion             |
| `GEOMETRY`         | Cleaned spatial data in PostGIS                                 |

Important design choices:

- FIPS, ZIP, tract, and CBSA codes are stored as `VARCHAR`, not numbers.
- Raw geometry is stored as `TEXT`.
- Cleaned geometry is stored as `geometry(Point, 102003)`.
- `row_id` is the internal database primary key.
- `original_index` preserves the original CSV row number.

## Running the Project

### 1. Start PostgreSQL

Make sure PostgreSQL is running locally.

### 2. Create the database

```sql
CREATE DATABASE research_business_db;
```

### 3. Enable PostGIS

Connect to the database, then run:

```sql
CREATE EXTENSION IF NOT EXISTS postgis;
```

### 4. Create the raw table

Run:

```bash
psql -U postgres -d research_business_db -f sql/schema.sql
```

### 5. Load the CSV

Run:

```bash
python scripts/load_raw_businesses.py
```

### 6. Create smaller tables

Run:

```bash
psql -U postgres -d research_business_db -f sql/create_subtables.sql
```

### 7. Populate smaller tables

Run:

```bash
psql -U postgres -d research_business_db -f sql/populate_subtables.sql
```

## Example Queries

View the first few loaded businesses:

```sql
SELECT
    row_id,
    business_name,
    category,
    city,
    state,
    year
FROM raw_businesses
LIMIT 10;
```

Find businesses classified as queer-owned:

```sql
SELECT
    business_name,
    year,
    state,
    queerown
FROM raw_businesses
WHERE queerown = 1;
```

Find businesses by CBSA:

```sql
SELECT
    business_name,
    cbsa,
    cbsa_name
FROM raw_businesses
WHERE cbsa IS NOT NULL;
```

Find businesses with geography converted to longitude and latitude:

```sql
SELECT
    b.business_name,
    ST_X(ST_Transform(g.geometry, 4326)) AS longitude,
    ST_Y(ST_Transform(g.geometry, 4326)) AS latitude
FROM businesses b
JOIN business_geography g
    ON b.business_id = g.business_id
WHERE g.geometry IS NOT NULL;
```

## Current Progress

Completed:

- Created PostgreSQL database
- Designed raw table schema
- Built Python loading script
- Cleaned and renamed important variables
- Combined duplicate source columns into cleaner variables
- Imported CSV data into `raw_businesses`
- Planned smaller relational tables
- Designed geometry conversion from text to PostGIS geometry

Next steps:

- Finalize `create_subtables.sql`
- Finalize `populate_subtables.sql`
- Test geometry conversion
- Add indexes for frequently queried columns
- Write analysis queries for business distribution, classification, and geography

## Future Improvements

Possible improvements:

- Add indexes on `annual_id`, `tractid`, `year`, `cbsa`, and geometry.
- Use PostGIS spatial indexes for faster geographic queries.
- Create views for common analysis queries.
- Validate binary flag columns to ensure they only contain `0`, `1`, or `NULL`.
- Add automated tests for the loading script.
- Add a data dictionary based on the variable codebook.
- Create visualizations using Python or GIS tools.

## Notes

This project is designed to practice the full data engineering workflow:

```text
CSV → Python cleaning → PostgreSQL raw table → normalized relational tables → spatial analysis
```

The raw table should preserve the imported data as much as possible, while the smaller subtables should represent the cleaner analytical database structure.
#   r e s e a r c h _ b u s i n e s s _ p r o j e c t  
 