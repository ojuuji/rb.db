from contextlib import closing
import colorsys
from dbconn import DbConnect

HARDCODED_ORDER = ["[Unknown]", "[No Color/Any Color]", "White", "Black"]
GRAY_THRESHOLD = 20 / 255.0


class Color:
    def __init__(self, id, name, rgb):
        self.id = id
        self.name = name
        self.r, self.g, self.b = [int(rgb[x: x + 2], 16) / 255.0 for x in [0, 2, 4]]
        self.gray_diff = max(abs(self.r - self.g), abs(self.r - self.b), abs(self.g - self.b))

    def is_grayscale(self):
        if self.name == HARDCODED_ORDER[0] or self.name == HARDCODED_ORDER[1]:
            return None
        return self.gray_diff < GRAY_THRESHOLD


def color_sort_key(color):
    if color.name in HARDCODED_ORDER:
        return (1, HARDCODED_ORDER.index(color.name))

    if color.is_grayscale():
        return (2, color.r)

    h, s, v = colorsys.rgb_to_hsv(color.r, color.g, color.b)
    return (3, h, s, v)


def gen_color_properties(conn):
    print(":: generating color_properties ...")

    colors = []
    with closing(conn.cursor()) as cur:
        for id, name, rgb in cur.execute('SELECT id, name, rgb FROM colors'):
            colors.append(Color(id, name, rgb))

    sorted_colors = sorted(colors, key=color_sort_key)
    with conn, closing(conn.cursor()) as cur:
        pos = 0
        for color in sorted_colors:
            cur.execute('INSERT INTO color_properties VALUES (?, ?, ?)',
                        (color.id, pos, color.is_grayscale()))
            pos = pos + 1


if __name__ == '__main__':
    with DbConnect() as conn:
        gen_color_properties(conn)
