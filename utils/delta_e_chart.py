from basic_colormath.distance import get_delta_e_hex
from contextlib import closing
from jinja2 import Environment, FileSystemLoader
import os
import sqlite3


SQL_CROSS_COLORS = """
    SELECT c1.id
         , c1.rgb
         , c2.id
         , c2.rgb
      FROM colors c1
CROSS JOIN colors c2
"""

SQL_CREATE_COLOR_DISTANCES_TABLE = """
CREATE TABLE color_distances (
    color_id1 INTEGER NOT NULL REFERENCES colors(id),
    color_id2 INTEGER NOT NULL REFERENCES colors(id),
    delta_e REAL NOT NULL
) STRICT
"""

SQL_QUERY_DELTAS = """
    SELECT printf('%.2f', delta_e)
         , c1.rgb
         , c2.rgb
      FROM color_distances
      JOIN colors c1 on c1.id = color_id1
      JOIN colors c2 on c2.id = color_id2
  ORDER BY delta_e
"""


def calc_deltas(conn):
    deltas = []
    with closing(conn.cursor()) as cur:
        for id1, rgb1, id2, rgb2 in cur.execute(SQL_CROSS_COLORS):
            deltas.append([id1, id2, get_delta_e_hex(rgb1, rgb2)])

    return deltas


def store_deltas(conn):
    with conn, closing(conn.cursor()) as cur:
        cur.execute('DROP TABLE IF EXISTS color_distances')
        cur.execute(SQL_CREATE_COLOR_DISTANCES_TABLE)

    with conn, closing(conn.cursor()) as cur:
        cur.executemany('INSERT INTO color_distances VALUES (?, ?, ?)', deltas)


def make_chart(rows, templates_dir):
    env = Environment(loader=FileSystemLoader(templates_dir), autoescape=False)
    template = env.get_template('delta_e_chart_template.html')
    print(template.render(rows=rows))


if __name__ == '__main__':
    dir = os.path.dirname(os.path.abspath(__file__))
    with closing(sqlite3.connect(f'{dir}/../data/rb.db')) as conn:
        deltas = calc_deltas(conn)
        store_deltas(conn)

        with closing(conn.cursor()) as cur:
            rows = [list(row) for row in cur.execute(SQL_QUERY_DELTAS)]
            make_chart(rows, dir)
