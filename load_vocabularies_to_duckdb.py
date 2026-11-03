import duckdb
from pathlib import Path

# Paths
DB_PATH = Path("data/mimic_to_omop.duckdb")
CSV_DIR = Path("data/athena_vocabulary/")

# Connect to DuckDB (creates file if it doesn't exist)
con = duckdb.connect(DB_PATH)

# Loop over all CSV files
for csv_file in CSV_DIR.glob("**/*.csv"):
    print(csv_file)
    # Remove all extensions
    table_name = csv_file.name.replace('.csv', '')
    print(f"Loading {csv_file} into table {table_name}...")
    # we set some fields to varchar to avoid ingestion issues, particularly from emar_detail
    # later ETL will fix this
    con.execute(f"CREATE SCHEMA IF NOT EXISTS athena;")
    try:
        con.execute(f"""
            CREATE TABLE IF NOT EXISTS athena.{table_name} AS
            SELECT * FROM read_csv_auto('{csv_file}');
        """)
    except duckdb.duckdb.ConversionException:
        con.execute(f"""
            CREATE TABLE IF NOT EXISTS athena.{table_name} AS
            SELECT * FROM read_csv_auto('{csv_file}', all_varchar=True);
        """)

print(f"DuckDB database at {DB_PATH} with all vocabularies loaded into 'athena' schema.")
con.execute("""
CREATE OR REPLACE TABLE athena.custom_mappings AS
SELECT * FROM read_csv_auto('data/custom_mappings/*.csv');
""")
print(f"DuckDB database at {DB_PATH} with custom_mappings loaded into 'athena' schema.")
con.close()
