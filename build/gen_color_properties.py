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
        self.graydiff = max(abs(self.r - self.g), abs(self.r - self.b), abs(self.g - self.b))

    def is_grayscale(self):
        if self.name == HARDCODED_ORDER[0] or self.name == HARDCODED_ORDER[1]:
            return None
        return self.graydiff < GRAY_THRESHOLD

    def __lt__(self, other):
        if self.name == other.name:
            return False

        for color in Color.HARDCODED_ORDER:
            if self.name == color:
                return True
            if other.name == color:
                return False

        lgs = self.is_grayscale()
        rgs = other.is_grayscale()
        if lgs or rgs:
            return self.r < other.r if lgs and rgs else lgs

        lh, ls, lv = colorsys.rgb_to_hsv(self.r, self.g, self.b)
        rh, rs, rv = colorsys.rgb_to_hsv(other.r, other.g, other.b)

        return lh < rh if lh != rh else ls < rs if ls != rs else lv < rv


def gen_color_properties(conn):
    print(":: generating color_properties ...")

    colors = []
    with closing(conn.cursor()) as cur:
        for id, name, rgb in cur.execute('SELECT id, name, rgb FROM colors'):
            colors.append(Color(id, name, rgb))

    sorted_colors = sorted(colors)
    with conn, closing(conn.cursor()) as cur:
        pos = 0
        for color in sorted_colors:
            cur.execute('INSERT INTO color_properties VALUES (?, ?, ?)',
                        (color.id, pos, color.is_grayscale()))
            pos = pos + 1


if __name__ == '__main__':
    with DbConnect() as conn:
        gen_color_properties(conn)
