"""
Export the OMOP CDM tables to a standalone DuckDB file.

Copies every table in the omop_gold schema of data/mimic_to_omop.duckdb into a new
DuckDB file, under a schema named omopv5. DuckDB cannot rename a schema in place,
so the tables are created directly in omopv5.

Usage:
    uv run python export_omop_gold.py <output.duckdb>
"""

import sys
from pathlib import Path

import duckdb

# Paths and schema names
SOURCE_DB_PATH = Path("data/mimic_to_omop.duckdb")
SOURCE_SCHEMA = "omop_gold"
TARGET_SCHEMA = "omopv5"


def main():
    if len(sys.argv) != 2:
        sys.exit(f"Usage: uv run python {Path(sys.argv[0]).name} <output.duckdb>")

    target_path = Path(sys.argv[1])
    if not SOURCE_DB_PATH.exists():
        sys.exit(f"Error: source database {SOURCE_DB_PATH} does not exist.")
    if target_path.exists():
        sys.exit(f"Error: {target_path} already exists; choose a new file name.")

    print(f"Creating {target_path}...")
    target_path.parent.mkdir(parents=True, exist_ok=True)
    con = duckdb.connect(str(target_path))
    try:
        # DuckDB names the new database after the file (omopv5.duckdb -> omopv5),
        # so qualify target names with it to avoid clashing with the schema name
        target_db = con.execute("SELECT current_database()").fetchone()[0]
        target = f'"{target_db}".{TARGET_SCHEMA}'

        con.execute(f"ATTACH '{SOURCE_DB_PATH}' AS export_source (READ_ONLY);")
        # same as profiles.yml: lets DuckDB copy large tables with less memory
        con.execute("SET preserve_insertion_order = false;")
        con.execute(f"CREATE SCHEMA {target};")

        tables = [row[0] for row in con.execute(f"""
            SELECT table_name FROM duckdb_tables()
            WHERE database_name = 'export_source' AND schema_name = '{SOURCE_SCHEMA}'
            ORDER BY table_name
        """).fetchall()]

        for table_name in tables:
            con.execute(f"""
                CREATE TABLE {target}."{table_name}" AS
                SELECT * FROM export_source.{SOURCE_SCHEMA}."{table_name}";
            """)
            row_count = con.execute(f'SELECT COUNT(*) FROM {target}."{table_name}"').fetchone()[0]
            print(f"  {SOURCE_SCHEMA}.{table_name} -> {TARGET_SCHEMA}.{table_name} ({row_count:,} rows)")

        con.execute("DETACH export_source;")
        con.close()
    except BaseException:
        # don't leave a half-written export behind
        con.close()
        target_path.unlink(missing_ok=True)
        Path(f"{target_path}.wal").unlink(missing_ok=True)
        raise

    size_gb = target_path.stat().st_size / 1e9
    print(f"\nDone! Copied {len(tables)} tables into schema {TARGET_SCHEMA} of {target_path} ({size_gb:.2f} GB).")


if __name__ == "__main__":
    main()
