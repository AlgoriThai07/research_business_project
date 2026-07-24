-- -- Only needed if you are using GEOMETRY
-- CREATE EXTENSION IF NOT EXISTS postgis;

DROP TABLE IF EXISTS raw_businesses CASCADE;

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
    lbtqi_w INTEGER,
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

DROP TABLE IF EXISTS business_year_records CASCADE;
DROP TABLE IF EXISTS business_contacts CASCADE;
DROP TABLE IF EXISTS business_geography CASCADE;
DROP TABLE IF EXISTS business_bar_attributes CASCADE;
DROP TABLE IF EXISTS business_identity_attributes CASCADE;
DROP TABLE IF EXISTS business_classification CASCADE;
DROP TABLE IF EXISTS tract_year_context CASCADE;
DROP TABLE IF EXISTS businesses CASCADE;
DROP TABLE IF EXISTS metro_areas CASCADE;


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

CREATE TABLE metro_areas (
    cbsa VARCHAR(10) PRIMARY KEY,
    cbsa_name VARCHAR(255)
);

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
    cbsa VARCHAR(10) REFERENCES metro_areas(cbsa),

    match_distance DOUBLE PRECISION,
    geoauth VARCHAR(50),
    geometry GEOMETRY(POINT, 102003),
    geometry_location_type VARCHAR(100)
);

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
    glbtqi INTEGER,
    lbtqi_w INTEGER
);

CREATE TABLE business_classification (
    business_id INTEGER PRIMARY KEY REFERENCES businesses(business_id),

    queerown INTEGER,
    queeraud INTEGER,
    core INTEGER,
    exploit INTEGER,
    entrep INTEGER,
    waffle INTEGER
);

CREATE TABLE tract_year_context (
    tract_year_id SERIAL PRIMARY KEY,

    tractid VARCHAR(50) NOT NULL,
    year INTEGER NOT NULL,

    statefp10 VARCHAR(2),
    countyfp10 VARCHAR(3),
    cbsa VARCHAR(10) REFERENCES metro_areas(cbsa),

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

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

SELECT *
FROM raw_businesses;
