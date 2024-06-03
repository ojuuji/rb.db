from contextlib import closing
import csv
import os
import sqlite3
import sys


WORKDIR = os.path.dirname(os.path.abspath(__file__))


def read_table(name):
    with open(f'{WORKDIR}/data/{name}.csv', 'r', encoding='utf-8') as f:
        cf = csv.DictReader(f)
        rows = [[None if v == '' else v for v in row.values()] for row in cf]

        return cf.fieldnames, rows


def store_table(name, conn, fieldnames, rows):
    ph = ','.join([':' + key for key in fieldnames])

    with closing(conn.cursor()) as cursor:
        for row in rows:
            try:
                cursor.execute(f'insert into {name} values({ph})', row)
            except Exception:
                print(f"error inserting row {row}", file=sys.stderr)
                raise
        conn.commit()


def import_table(name, conn):
    fieldnames, rows = read_table(name)
    store_table(name, conn, fieldnames, rows)


def import_themes(conn):
    # Table references itself. In order to apply foreign key constraint the
    # referenced rows must go first hence is the sorting
    print(":: importing themes ...", flush=True)

    fieldnames, rows = read_table('themes')
    sorted_rows = sorted(rows, key=lambda x: x[2] or '')
    store_table('themes', conn, fieldnames, sorted_rows)


def import_all_tables(conn):
    import_themes(conn)

    tables = ['colors', 'part_categories', 'parts', 'part_relationships',
              'elements', 'minifigs', 'sets', 'inventories',
              'inventory_minifigs', 'inventory_parts', 'inventory_sets']

    for table in tables:
        print(f":: importing {table} ...", flush=True)
        import_table(table, conn)


if __name__ == '__main__':
    with closing(sqlite3.connect(f'{WORKDIR}/data/rb.db')) as conn:
        conn.execute('PRAGMA foreign_keys = ON')
        import_all_tables(conn)
