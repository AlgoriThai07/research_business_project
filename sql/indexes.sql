CREATE INDEX IF NOT EXISTS idx_raw_businesses_tract_year
ON raw_businesses(tractid, year);

CREATE INDEX IF NOT EXISTS idx_raw_businesses_state
ON raw_businesses(state);

CREATE INDEX IF NOT EXISTS idx_raw_businesses_business_name
ON raw_businesses(business_name);

CREATE INDEX IF NOT EXISTS idx_businesses_tract_year
ON businesses(tractid, year);

CREATE INDEX IF NOT EXISTS idx_businesses_business_name
ON businesses(business_name);

CREATE INDEX IF NOT EXISTS idx_businesses_category
ON businesses(category);

CREATE INDEX IF NOT EXISTS idx_business_geography_state
ON business_geography(state);

CREATE INDEX IF NOT EXISTS idx_business_geography_new_state
ON business_geography(new_state);

CREATE INDEX IF NOT EXISTS idx_business_geography_county_name
ON business_geography(county_name);

CREATE INDEX IF NOT EXISTS idx_business_geography_zip
ON business_geography(zip);

CREATE INDEX IF NOT EXISTS idx_business_geography_cbsa
ON business_geography(cbsa);

CREATE INDEX IF NOT EXISTS idx_tract_year_context_cbsa
ON tract_year_context(cbsa);

CREATE INDEX IF NOT EXISTS idx_business_classification_core
ON business_classification(core);

CREATE INDEX IF NOT EXISTS idx_business_classification_queerown
ON business_classification(queerown);

CREATE INDEX IF NOT EXISTS idx_business_classification_queeraud
ON business_classification(queeraud);

CREATE INDEX IF NOT EXISTS idx_business_geography_geometry
ON business_geography
USING GIST (geometry);