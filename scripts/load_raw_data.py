import os
from pathlib import Path
from dotenv import load_dotenv
import pandas as pd
from sqlalchemy import create_engine, text

# Load environment variables from .env file
load_dotenv()

# Retrieve database credentials from environment
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME")

# Path setup
BASE_DIR = Path(__file__).resolve().parent.parent
CSV_PATH = BASE_DIR / "data" / "small_set_for_thai.csv"

engine = create_engine(
    f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)


def get_table_columns(engine, table_name):
    query = text("""
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = :table_name
        ORDER BY ordinal_position
    """)

    with engine.connect() as conn:
        rows = conn.execute(query, {"table_name": table_name}).fetchall()

    return [row[0] for row in rows]


RAW_BUSINESSES_COLUMN_TYPES = {
    "original_index": "INTEGER",
    "tractid": "TEXT",
    "year": "INTEGER",
    "id": "TEXT",
    "annual_id": "TEXT",
    "business_name": "TEXT",
    "category": "TEXT",
    "dancing_bar": "INTEGER",
    "sports_bar": "INTEGER",
    "video_bar": "INTEGER",
    "karaoke_bar": "INTEGER",
    "country_bar": "INTEGER",
    "leather_bar": "INTEGER",
    "western_bar": "INTEGER",
    "private_club": "INTEGER",
    "clothing_opt_bar": "INTEGER",
    "asian": "INTEGER",
    "latine": "INTEGER",
    "black": "INTEGER",
    "poc": "INTEGER",
    "two_spirit": "INTEGER",
    "jewish": "INTEGER",
    "diverse": "INTEGER",
    "phone_1": "TEXT",
    "phone_2": "TEXT",
    "address": "TEXT",
    "county_name": "TEXT",
    "state": "TEXT",
    "new_state": "TEXT",
    "zip": "TEXT",
    "email": "TEXT",
    "website": "TEXT",
    "fax": "TEXT",
    "full_text": "TEXT",
    "all_men": "INTEGER",
    "all_women": "INTEGER",
    "bi": "INTEGER",
    "trans": "INTEGER",
    "gbtqi_men": "INTEGER",
    "glbtqi": "INTEGER",
    "match_distance": "DOUBLE PRECISION",
    "geoauth": "TEXT",
    "geometry": "TEXT",
    "geometry_location_type": "TEXT",
    "statefp10": "TEXT",
    "countyfp10": "TEXT",
    "queerown": "INTEGER",
    "queeraud": "INTEGER",
    "core": "INTEGER",
    "exploit": "INTEGER",
    "entrep": "INTEGER",
    "waffle": "INTEGER",
    "cbsa": "TEXT",
    "cbsa_name": "TEXT",
    "hinc": "DOUBLE PRECISION",
    "hu": "INTEGER",
    "mhmval": "DOUBLE PRECISION",
    "mrent": "DOUBLE PRECISION",
    "msa_college": "DOUBLE PRECISION",
    "msa_income": "DOUBLE PRECISION",
    "p20old": "DOUBLE PRECISION",
    "pasian": "DOUBLE PRECISION",
    "pcol": "DOUBLE PRECISION",
    "phisp": "DOUBLE PRECISION",
    "pnhblk": "DOUBLE PRECISION",
    "pnhwht": "DOUBLE PRECISION",
    "pop": "INTEGER",
    "pothrace": "DOUBLE PRECISION",
    "ppov": "DOUBLE PRECISION",
    "prenter": "DOUBLE PRECISION",
    "punemp": "DOUBLE PRECISION",
    "org_cat": "TEXT",
}


def ensure_raw_businesses_table(engine):
    current_columns = get_table_columns(engine, "raw_businesses")

    if not current_columns:
        column_definitions = ["row_id SERIAL PRIMARY KEY"]
        for column_name, sql_type in RAW_BUSINESSES_COLUMN_TYPES.items():
            column_definitions.append(f"{column_name} {sql_type}")
        column_definitions.append("UNIQUE (annual_id)")

        create_table_sql = "CREATE TABLE raw_businesses (\n    " + ",\n    ".join(column_definitions) + "\n)"

        with engine.begin() as conn:
            conn.execute(text(create_table_sql))
        return

    missing_columns = [
        column_name
        for column_name in RAW_BUSINESSES_COLUMN_TYPES
        if column_name not in current_columns
    ]

    if not missing_columns:
        return

    with engine.begin() as conn:
        for column_name in missing_columns:
            conn.execute(
                text(
                    f"ALTER TABLE raw_businesses ADD COLUMN IF NOT EXISTS {column_name} {RAW_BUSINESSES_COLUMN_TYPES[column_name]}"
                )
            )

df = pd.read_csv(CSV_PATH)

print("Original CSV shape:", df.shape)
print("Original CSV columns:", list(df.columns))

df_clean = df.rename(columns={
    "Unnamed: 0": "original_index",
    "ID": "id",
    "Business_name": "business_name",
    "STATEFP10": "statefp10",
    "COUNTYFP10": "countyfp10",
    "NEW_CATEGORY_1": "category",
    "NEW_COUNTY": "county_name",
    "State": "state",
    "NEW_STATE": "new_state",
    "ZIP": "zip",
    "FIPS": "fips",
    "Area": "area",
    "Email": "email",
    "www": "website",
    "Fax": "fax",
    "Text": "full_text",
    "gayown": "queerown",
    "gayaud": "queeraud",
    "symbol_35": "jewish"
})

def combine_columns(df, new_col, source_cols):
    """
    Combine multiple source columns into one cleaned column.
    Uses the first non-null value from left to right.
    """
    existing_cols = [col for col in source_cols if col in df.columns]

    if not existing_cols:
        print(f"Warning: no source columns found for {new_col}: {source_cols}")
        df[new_col] = None
        return df

    df[new_col] = df[existing_cols].bfill(axis=1).iloc[:, 0]
    return df

df_clean = combine_columns(df_clean, "dancing_bar", ["symbol_14", "_DANCING_"])
df_clean = combine_columns(df_clean, "sports_bar", ["symbol_15", "_SPORT_BAR_"])
df_clean = combine_columns(df_clean, "video_bar", ["symbol_16", "_VIDEO_BAR_"])
df_clean = combine_columns(df_clean, "karaoke_bar", ["symbol_17", "_KARAOKE_"])
df_clean = combine_columns(df_clean, "country_bar", ["symbol_18", "_COUNTRY_"])
df_clean = combine_columns(df_clean, "leather_bar", ["symbol_19", "_LEATHER_"])
df_clean = combine_columns(df_clean, "western_bar", ["symbol_20", "_WESTERN_"])
df_clean = combine_columns(df_clean, "private_club", ["symbol_21", "_PRIV_CLUB_"])
df_clean = combine_columns(df_clean, "clothing_opt_bar", ["symbol_22", "_CLOTH_OPT_"])

df_clean = combine_columns(df_clean, "asian", ["symbol_30", "_ASIAN_"])
df_clean = combine_columns(df_clean, "latine", ["symbol_31", "_LATIN_"])
df_clean = combine_columns(df_clean, "black", ["symbol_32", "_AFRICAN_"])
df_clean = combine_columns(df_clean, "poc", ["symbol_33", "_PEOPLE_COLOR_"])
df_clean = combine_columns(df_clean, "two_spirit", ["symbol_34", "_TWO_SPIRIT_"])
df_clean = combine_columns(df_clean, "diverse", ["symbol_36", "_DIVERSE_"])

df_clean = combine_columns(df_clean, "bi", ["BI", "_BISE1UAL_P_", "_BISE1UAL_W_"])
df_clean = combine_columns(df_clean, "trans", ["trans", "_TRANSSE1UAL_"])
df_clean = combine_columns(df_clean, "gbtqi_men", ["GBTQI_MEN", "_GBTQI_M_1"])
df_clean = combine_columns(df_clean, "glbtqi", ["GLBTQI", "_GLBTQI_P_1"])
df_clean = combine_columns(df_clean, "all_men", ["ALL_MEN", "_ALL_M_"])
df_clean = combine_columns(df_clean, "all_women", ["ALL_WOMEN", "_ALL_W_"])

expected_columns = [
    "original_index",
    "tractid",
    "year",
    "id",
    "annual_id",
    "business_name",
    "category",
    "dancing_bar",
    "sports_bar",
    "video_bar",
    "karaoke_bar",
    "country_bar",
    "leather_bar",
    "western_bar",
    "private_club",
    "clothing_opt_bar",
    "asian",
    "latine",
    "black",
    "poc",
    "two_spirit",
    "jewish",
    "diverse",
    "phone_1",
    "phone_2",
    "address",
    "county_name",
    "state",
    "new_state",
    "zip",
    "email",
    "website",
    "fax",
    "full_text",
    "all_men",
    "all_women",
    "bi",
    "trans",
    "gbtqi_men",
    "glbtqi",
    "match_distance",
    "geoauth",
    "geometry",
    "geometry_location_type",
    "statefp10",
    "countyfp10",
    "queerown",
    "queeraud",
    "core",
    "exploit",
    "entrep",
    "waffle",
    "cbsa",
    "cbsa_name",
    "hinc",
    "hu",
    "mhmval",
    "mrent",
    "msa_college",
    "msa_income",
    "p20old",
    "pasian",
    "pcol",
    "phisp",
    "pnhblk",
    "pnhwht",
    "pop",
    "pothrace",
    "ppov",
    "prenter",
    "punemp",
    "org_cat",
]

ensure_raw_businesses_table(engine)

columns_to_keep = [
    "original_index",
    "tractid",
    "year",
    "id",
    "annual_id",

    "business_name",
    "category",

    "dancing_bar",
    "sports_bar",
    "video_bar",
    "karaoke_bar",
    "country_bar",
    "leather_bar",
    "western_bar",
    "private_club",
    "clothing_opt_bar",

    "asian",
    "latine",
    "black",
    "poc",
    "two_spirit",
    "jewish",
    "diverse",

    "phone_1",
    "phone_2",
    "address",
    "county_name",
    "state",
    "new_state",
    "zip",
    "email",
    "website",
    "fax",
    "full_text",

    "all_men",
    "all_women",
    "bi",
    "trans",
    "gbtqi_men",
    "glbtqi",
    # "lbtqi_w",

    "match_distance",
    "geoauth",
    "geometry",
    "geometry_location_type",
    "statefp10",
    "countyfp10",

    "queerown",
    "queeraud",
    "core",
    "exploit",
    "entrep",
    "waffle",

    "cbsa",
    "cbsa_name",

    "hinc",
    "hu",
    "mhmval",
    "mrent",
    "msa_college",
    "msa_income",
    "p20old",
    "pasian",
    "pcol",
    "phisp",
    "pnhblk",
    "pnhwht",
    "pop",
    "pothrace",
    "ppov",
    "prenter",
    "punemp",

    "org_cat"
]

missing_columns = [col for col in columns_to_keep if col not in df_clean.columns]

if missing_columns:
    raise ValueError(f"Missing columns after rename: {missing_columns}")

df_clean = df_clean[columns_to_keep]

# Convert NaN values into None, which PostgreSQL stores as NULL
df_clean = df_clean.where(pd.notnull(df_clean), None)

print("Cleaned dataframe shape:", df_clean.shape)

with engine.begin() as conn:
    conn.execute(text("DELETE FROM raw_businesses;"))

df_clean.to_sql(
    "raw_businesses",
    engine,
    if_exists="append",
    index=False
)

print(f"Loaded {len(df_clean)} rows into raw_businesses.")