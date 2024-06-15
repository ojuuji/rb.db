from contextlib import closing
from dbconn import DbConnect, WORKDIR
import csv
import sys


def preprocess_value(key, value):
    if key.startswith('is_'):
        if value in 'tf':
            return 1 if value == 't' else 0
        raise ValueError(f"unexpected value ('{value}') for key '{key}'")

    return None if value == '' else value


def read_table(name):
    with open(f'{WORKDIR}/../data/{name}.csv', 'r', encoding='utf-8') as f:
        cf = csv.DictReader(f)
        rows = []
        for row in cf:
            rows.append({k: preprocess_value(k, v) for k, v in row.items()})

        return rows


def store_table(name, conn, rows):
    ph = ','.join([':' + key for key in rows[0].keys()])

    with conn, closing(conn.cursor()) as cursor:
        for row in rows:
            try:
                cursor.execute(f'INSERT INTO {name} VALUES({ph})', row)
            except Exception:
                print(f"error inserting row {row}", file=sys.stderr)
                raise


def import_table(name, conn):
    print(f":: importing {name} ...", flush=True)
    rows = read_table(name)
    store_table(name, conn, rows)


def import_themes(conn):
    print(":: importing themes ...", flush=True)
    rows = read_table('themes')

    # Table references itself. In order to apply foreign key constraint the
    # referenced rows must go first hence is the sorting
    sorted_rows = sorted(rows, key=lambda x: x['parent_id'] or '')
    store_table('themes', conn, sorted_rows)


def import_rb_tables(conn):
    import_themes(conn)

    tables = ['colors', 'part_categories', 'parts', 'part_relationships',
              'elements', 'minifigs', 'sets', 'inventories',
              'inventory_minifigs', 'inventory_parts', 'inventory_sets']

    for table in tables:
        import_table(table, conn)


if __name__ == '__main__':
    with DbConnect() as conn:
        import_rb_tables(conn)
