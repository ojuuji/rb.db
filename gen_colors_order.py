from common import db_connect
from contextlib import closing
import colorsys


class Color:
    HARDCODED_ORDER = ["[Unknown]", "[No Color/Any Color]", "White", "Black"]
    GRAY_THRESHOLD = 20 / 255.0

    def __init__(self, id, name, rgb):
        self.id = id
        self.name = name
        self.r, self.g, self.b = [int(rgb[x: x + 2], 16) / 255.0 for x in [0, 2, 4]]

    def __lt__(self, other):
        if self.name == other.name:
            return False

        for color in Color.HARDCODED_ORDER:
            if self.name == color:
                return True
            if other.name == color:
                return False

        ldiff = max(abs(self.r - self.g), abs(self.r - self.b), abs(self.g - self.b))
        rdiff = max(abs(other.r - other.g), abs(other.r - other.b), abs(other.g - other.b))

        if ldiff < Color.GRAY_THRESHOLD and rdiff < Color.GRAY_THRESHOLD:
            return self.r < other.r
        if ldiff < Color.GRAY_THRESHOLD or rdiff < Color.GRAY_THRESHOLD:
            return rdiff >= Color.GRAY_THRESHOLD

        lh, ls, lv = colorsys.rgb_to_hsv(self.r, self.g, self.b)
        rh, rs, rv = colorsys.rgb_to_hsv(other.r, other.g, other.b)

        return lh < rh if lh != rh else ls < rs if ls != rs else lv < rv


def gen_colors_order(conn):
    print(":: generating colors_order ...")

    colors = []
    with closing(conn.cursor()) as cur:
        for id, name, rgb in cur.execute('select id, name, rgb from colors'):
            colors.append(Color(id, name, rgb))

    sorted_colors = sorted(colors)
    with conn, closing(conn.cursor()) as cur:
        pos = 0
        for color in sorted_colors:
            cur.execute('insert into colors_order values (?, ?)', (pos, color.id))
            pos = pos + 1


if __name__ == '__main__':
    with closing(db_connect()) as conn:
        gen_colors_order(conn)
