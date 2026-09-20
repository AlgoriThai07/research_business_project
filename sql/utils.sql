-- Create a view for business geography in WGS84 (EPSG:4326)
DROP VIEW IF EXISTS business_geography_wgs84;

CREATE VIEW business_geography_wgs84 AS
SELECT
    geography_id,
    business_id,
    address,
    state,
    zip,
    geometry_location_type,
    ST_Transform(geometry, 4326)::geometry(Point, 4326) AS geometry
FROM business_geography
WHERE geometry IS NOT NULL;

-- Check the data quality of the business_geography table
SELECT
    COUNT(*) AS total_rows,
    COUNT(geometry) AS rows_with_geometry
FROM business_geography;

-- Check the first 10 rows of business_geography with geometry
SELECT
    business_id,
    geometry,
    ST_AsText(geometry) AS geom_text
FROM business_geography
WHERE geometry IS NOT NULL
LIMIT 10;

-- Check the SRID of the geometry column in business_geography
SELECT DISTINCT ST_SRID(geometry)
FROM business_geography
WHERE geometry IS NOT NULL;

ANALYZE business_geography;

SELECT
    business_id,
    state,
    ST_X(ST_Transform(geometry, 4326)) AS longitude,
    ST_Y(ST_Transform(geometry, 4326)) AS latitude
FROM business_geography
WHERE geometry IS NOT NULL
LIMIT 20;

-- CBSA data quality check: Check for CBSA duplicates in raw_businesses table
SELECT
    cbsa,
    COUNT(*) AS source_rows
FROM raw_businesses
WHERE NULLIF(trim(cbsa), '') IS NOT NULL
GROUP BY cbsa
HAVING COUNT(DISTINCT (cbsa_name, micropolitan, lower(trim(outlying)))) > 1
ORDER BY cbsa;