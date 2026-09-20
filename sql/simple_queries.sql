-- 1. All bars in Chicago in 2011.
-- There is no city column in the current schema, so Chicago is matched in the
-- stored address. Replace this with an exact city predicate if one is added.
SELECT
    b.business_id,
    b.business_name,
    b.category,
    b.year,
    g.address,
    g.new_state AS state,
    g.zip
FROM businesses AS b
JOIN business_geography AS g ON g.business_id = b.business_id
WHERE b.year = 2011
  AND g.new_state = 'IL'
  AND g.address ILIKE '%Chicago%'
  AND b.category ILIKE '%bar%'
ORDER BY b.business_name, b.business_id;

-- 2. Counts of organizations by state.
-- COUNT(DISTINCT ...) keeps the result correct if the join relationships change.
SELECT
    COALESCE(g.new_state, g.state, 'Unknown') AS state,
    COUNT(DISTINCT b.business_id) AS organization_count
FROM businesses AS b
LEFT JOIN business_geography AS g ON g.business_id = b.business_id
GROUP BY COALESCE(g.new_state, g.state, 'Unknown')
ORDER BY organization_count DESC, state;

-- 3. Count of organizations marked as serving "All Men" in New York City.
-- As above, NYC is matched from address because there is no city column.
SELECT
    COUNT(DISTINCT b.business_id) AS all_men_organizations_in_new_york_city
FROM businesses AS b
JOIN business_geography AS g ON g.business_id = b.business_id
JOIN business_identity_attributes AS i ON i.business_id = b.business_id
WHERE g.new_state = 'NY'
  AND g.address ILIKE '%New York%'
  AND i.all_men = 1;