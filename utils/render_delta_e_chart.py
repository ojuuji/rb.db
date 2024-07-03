from basic_colormath import get_delta_e_hex, hex_to_rgb, rgb_to_hsl
from contextlib import closing
from functools import cmp_to_key
from jinja2 import Environment, FileSystemLoader
import os
import sqlite3

SQL_CROSS_COLORS = '''
    SELECT c1.id, c1.rgb
         , c2.id, c2.rgb
      FROM colors c1
CROSS JOIN colors c2
     WHERE c1.id NOT IN (-1, 9999)
       AND c2.id NOT IN (-1, 9999)
       AND c1.id < c2.id
'''

SQL_COLORS = '''
SELECT id, name, rgb
  FROM colors
 WHERE id NOT IN (-1, 9999)
'''

SQL_DB_VERSION = '''
SELECT datetime(value, 'unixepoch')
  FROM rb_db_lov
 WHERE key = 'data_timestamp'
'''


def is_dark(rgb):
    hsl = rgb_to_hsl(hex_to_rgb(rgb))
    return 1 if hsl[2] < 56 else 0


def gen_data(conn):
    with closing(conn.cursor()) as cur:
        cur.execute(SQL_CROSS_COLORS)
        deltas = [[get_delta_e_hex(c1, c2), id1, id2] for id1, c1, id2, c2 in cur]
        colors = [[id, [name, rgb, is_dark(rgb)]] for id, name, rgb in cur.execute(SQL_COLORS)]
        db_version, = cur.execute(SQL_DB_VERSION).fetchone()

        return deltas, colors, db_version


def cmp_colors(a, b, colors):
    ta = int(a[0] * 100), colors[a[1]][0], colors[a[2]][0]
    tb = int(b[0] * 100), colors[b[1]][0], colors[b[2]][0]

    return -1 if ta < tb else 1 if ta > tb else 0


def make_chart(deltas, colors, db_version, templates_dir):
    colors_dict = dict(colors)
    deltas = sorted(deltas, key=cmp_to_key(lambda a, b: cmp_colors(a, b, colors_dict)))
    deltas = [[f'{d[0]:.2f}', d[1], d[2]] for d in deltas]

    env = Environment(loader=FileSystemLoader(templates_dir), autoescape=False)
    template = env.get_template('delta_e_chart_template.html')
    print(template.render(deltas=deltas, colors=colors, db_version=db_version))


if __name__ == '__main__':
    dir = os.path.dirname(os.path.abspath(__file__))
    with closing(sqlite3.connect(f'{dir}/../data/rb.db')) as conn:
        deltas, colors, db_version = gen_data(conn)

    make_chart(deltas, colors, db_version, dir)
