import geopandas as gpd
from sqlalchemy import create_engine

engine = create_engine(
    "postgresql+psycopg2://postgres:thai0703@localhost:5432/research_business_db"
)

sql = """
SELECT
    geography_id,
    business_id,
    address,
    ST_Transform(geometry, 4326) AS geometry
FROM business_geography
WHERE geometry IS NOT NULL;
"""

gdf = gpd.read_postgis(sql, engine, geom_col="geometry")

print(gdf.head())
print(gdf.crs)

gdf.to_file("business_points.geojson", driver="GeoJSON")