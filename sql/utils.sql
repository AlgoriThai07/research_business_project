SELECT
    COUNT(*) AS total_rows,
    COUNT(geometry) AS rows_with_geometry
FROM business_geography;

SELECT
    business_id,
    geometry,
    ST_AsText(geometry) AS geom_text
FROM business_geography
WHERE geometry IS NOT NULL
LIMIT 10;

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