WITH metro_source AS (
    SELECT DISTINCT ON (cbsa)
        cbsa,
        cbsa_name,
        micropolitan,
        CASE lower(trim(outlying))
            WHEN 'outlying' THEN TRUE
            WHEN 'central' THEN FALSE
            ELSE NULL
        END AS is_outlying
    FROM raw_businesses
    WHERE NULLIF(trim(cbsa), '') IS NOT NULL
    ORDER BY cbsa, row_id
)
INSERT INTO metro_areas (
    cbsa,
    cbsa_name,
    micropolitan,
    is_outlying
)
SELECT
    cbsa,
    cbsa_name,
    micropolitan,
    is_outlying
FROM metro_source
ON CONFLICT (cbsa) DO UPDATE SET
    cbsa_name = EXCLUDED.cbsa_name,
    micropolitan = EXCLUDED.micropolitan,
    is_outlying = EXCLUDED.is_outlying;

INSERT INTO businesses (
    raw_row_id,
    tractid,
    year,
    source_id,
    annual_id,
    business_name,
    category
    -- org_cat
)
SELECT
    row_id,
    tractid,
    year,
    id,
    annual_id,
    business_name,
    category
    -- org_cat
FROM raw_businesses;

INSERT INTO business_contacts (
    business_id,
    phone_1,
    email,
    website,
    fax,
    full_text
)
SELECT
    b.business_id,
    r.phone_1,
    r.email,
    r.website,
    r.fax,
    r.full_text
FROM raw_businesses r
JOIN businesses b
    ON b.raw_row_id = r.row_id;

INSERT INTO business_geography (
    business_id,
    address,
    county_name,
    state,
    new_state,
    zip,
    statefp10,
    countyfp10,
    cbsa,
    match_distance,
    geoauth,
    geometry,
    geometry_location_type
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
    r.cbsa,
    r.match_distance,
    r.geoauth,

    CASE
        WHEN r.geometry IS NOT NULL AND r.geometry <> ''
        THEN ST_SetSRID(
            ST_MakePoint(
                (regexp_match(
                    r.geometry,
                    'c\(\s*([+-]?[0-9]+(?:\.[0-9]+)?)\s*,\s*([+-]?[0-9]+(?:\.[0-9]+)?)\s*\)'
                ))[1]::DOUBLE PRECISION,
                (regexp_match(
                    r.geometry,
                    'c\(\s*([+-]?[0-9]+(?:\.[0-9]+)?)\s*,\s*([+-]?[0-9]+(?:\.[0-9]+)?)\s*\)'
                ))[2]::DOUBLE PRECISION
            ),
            102003
        )
        ELSE NULL
    END AS geometry,

    r.geometry_location_type
FROM raw_businesses r
JOIN businesses b
    ON b.raw_row_id = r.row_id;

INSERT INTO business_bar_attributes (
    business_id,
    dancing_bar,
    sports_bar,
    video_bar,
    karaoke_bar,
    country_bar,
    leather_bar,
    western_bar,
    private_club,
    clothing_opt_bar
)
SELECT
    b.business_id,
    r.dancing_bar,
    r.sports_bar,
    r.video_bar,
    r.karaoke_bar,
    r.country_bar,
    r.leather_bar,
    r.western_bar,
    r.private_club,
    r.clothing_opt_bar
FROM raw_businesses r
JOIN businesses b
    ON b.raw_row_id = r.row_id;

INSERT INTO business_identity_attributes (
    business_id,
    asian,
    latine,
    black,
    poc,
    two_spirit,
    jewish,
    diverse,
    all_men,
    all_women,
    bi,
    trans,
    gbtqi_men,
    glbtqi
)
SELECT
    b.business_id,
    r.asian,
    r.latine,
    r.black,
    r.poc,
    r.two_spirit,
    r.jewish,
    r.diverse,
    r.all_men,
    r.all_women,
    r.bi,
    r.trans,
    r.gbtqi_men,
    r.glbtqi
FROM raw_businesses r
JOIN businesses b
    ON b.raw_row_id = r.row_id;

-- INSERT INTO business_classification (
--     business_id,
--     queerown,
--     queeraud,
--     core,
--     exploit,
--     entrep,
--     waffle
-- )
-- SELECT
--     b.business_id,
--     r.queerown,
--     r.queeraud,
--     r.core,
--     r.exploit,
--     r.entrep,
--     r.waffle
-- FROM raw_businesses r
-- JOIN businesses b
--     ON b.raw_row_id = r.row_id;

SELECT
    tractid,
    year,
    COUNT(*) AS source_rows
FROM raw_businesses
WHERE tractid IS NOT NULL
  AND year IS NOT NULL
GROUP BY tractid, year
HAVING COUNT(DISTINCT (
    county_fips, aland10, awater10, funcstat10, geocode_type, gisjoin,
    intptlat10, intptlon10, mtfcc10, name10, namelsad10, shape_area,
    shape_len, tractce10, cbsa
)) > 1
ORDER BY tractid, year;

INSERT INTO tract_year_context (
    tractid,
    year,
    statefp10,
    countyfp10,
    county_fips,
    aland10,
    awater10,
    funcstat10,
    geocode_type,
    gisjoin,
    intptlat10,
    intptlon10,
    mtfcc10,
    name10,
    namelsad10,
    shape_area,
    shape_len,
    tractce10,
    cbsa
    -- hinc,
    -- hu,
    -- mhmval,
    -- mrent,
    -- msa_college,
    -- msa_income,
    -- p20old,
    -- pasian,
    -- pcol,
    -- phisp,
    -- pnhblk,
    -- pnhwht,
    -- pop,
    -- pothrace,
    -- ppov,
    -- prenter,
    -- punemp
)
SELECT DISTINCT ON (tractid, year)
    tractid,
    year,
    statefp10,
    countyfp10,
    county_fips,
    aland10,
    awater10,
    funcstat10,
    geocode_type,
    gisjoin,
    intptlat10,
    intptlon10,
    mtfcc10,
    name10,
    namelsad10,
    shape_area,
    shape_len,
    tractce10,
    cbsa
    -- hinc,
    -- hu,
    -- mhmval,
    -- mrent,
    -- msa_college,
    -- msa_income,
    -- p20old,
    -- pasian,
    -- pcol,
    -- phisp,
    -- pnhblk,
    -- pnhwht,
    -- pop,
    -- pothrace,
    -- ppov,
    -- prenter,
    -- punemp
FROM raw_businesses
WHERE tractid IS NOT NULL
  AND year IS NOT NULL
ORDER BY tractid, year, row_id
ON CONFLICT (tractid, year) DO NOTHING;
