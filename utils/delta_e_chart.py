from basic_colormath.distance import get_delta_e_hex
from contextlib import closing
from jinja2 import Environment, FileSystemLoader
import os
import sqlite3


def calc_deltas(conn):
    with closing(conn.cursor()) as cur:
        cur.execute('SELECT c1.rgb, c2.rgb FROM colors c1 CROSS JOIN colors c2')
        deltas = [[get_delta_e_hex(c1, c2), c1, c2] for c1, c2 in cur]

    return deltas


def make_chart(deltas, templates_dir):
    deltas = sorted(deltas, key=lambda x: x[0])
    deltas = [[f'{d[0]:.2f}', d[1], d[2]] for d in deltas]

    env = Environment(loader=FileSystemLoader(templates_dir), autoescape=False)
    template = env.get_template('delta_e_chart_template.html')
    print(template.render(deltas=deltas))


if __name__ == '__main__':
    dir = os.path.dirname(os.path.abspath(__file__))
    with closing(sqlite3.connect(f'{dir}/../data/rb.db')) as conn:
        deltas = calc_deltas(conn)

    make_chart(deltas, dir)
