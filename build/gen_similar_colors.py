from basic_colormath.distance import get_delta_e_hex
from contextlib import closing
from dbconn import DbConnect


SQL_CROSS_COLORS = """
    select c1.id
         , c1.rgb
         , c2.id
         , c2.rgb
      from colors c1
cross join colors c2
"""

MAX_DELTA_E = 20
UNKNOWN_COLOR_ID = -1
ANY_COLOR_ID = 9999


def gen_similar_colors(conn):
    print(":: generating similar_colors ...")

    colors = []
    with closing(conn.cursor()) as cur:
        for id1, rgb1, id2, rgb2 in cur.execute(SQL_CROSS_COLORS):
            if UNKNOWN_COLOR_ID not in [id1, id2]:
                delta_e = 0 if ANY_COLOR_ID in [id1, id2] else get_delta_e_hex(rgb1, rgb2)
                if delta_e <= MAX_DELTA_E:
                    colors.append([id1, id2])

    with conn, closing(conn.cursor()) as cur:
        cur.executemany('insert into similar_colors values (?, ?)', colors)


if __name__ == '__main__':
    with DbConnect() as conn:
        gen_similar_colors(conn)
