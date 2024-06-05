from contextlib import closing
from functools import cmp_to_key
import os
import re
import sqlite3


WORKDIR = os.path.dirname(os.path.abspath(__file__))


SQL_STATS = """
  with part_stats as (
           /* parts from sets */
    select sets.set_num set_num, sets.year year, ip.part_num part_num
      from sets
      join inventories i
        on i.set_num = sets.set_num
      join inventory_parts ip
        on ip.inventory_id = i.id
     union
           /* parts from minifigs included in the sets */
    select i_fig.set_num set_num, sets.year year, ip_fig.part_num part_num
      from sets
      join inventories i
        on i.set_num = sets.set_num
      join inventory_minifigs im
        on im.inventory_id = i.id
      join inventories i_fig
        on i_fig.set_num = im.fig_num
      join inventory_parts ip_fig
        on ip_fig.inventory_id = i_fig.id
)
select part_num, count(set_num), min(year), max(year)
  from part_stats
 group by part_num
"""

SQL_RELS_EXPAND = """
select child_part_num c, parent_part_num p
  from part_relationships
 where rel_type = "{0}"
   and (c in ({1}) or p in ({1}))
"""

SQL_RELS_LIST = """
select *
  from part_relationships
 where rel_type in ("A", "M")
"""


def find_all_rels(rel_type, con, rels):
    with closing(con.cursor()) as cur:
        old_rels = set()
        while len(old_rels) != len(rels):
            old_rels = rels
            rels = set()
            sql = SQL_RELS_EXPAND.format(rel_type, ','.join(f'"{m}"' for m in old_rels))
            for a, b in cur.execute(sql):
                rels.update([a, b])
        return rels


def try_to_int(value):
    try:
        return int(value)
    except ValueError:
        return value


def split_part_num(part_num):
    return tuple(try_to_int(x) for x in re.split(r'(\d+)', part_num))


def cmp_parts(a, b, stats, rel_type):
    has_stats_a = a in stats
    has_stats_b = b in stats
    if has_stats_a != has_stats_b:
        return -1 if has_stats_a else 1

    if has_stats_a:
        num_sets_a, min_year_a, max_year_a = stats[a]
        num_sets_b, min_year_b, max_year_b = stats[b]

        if max_year_a != max_year_b:
            return max_year_b - max_year_a

        if 'M' == rel_type and min_year_a != min_year_b:
            return min_year_b - min_year_a

        if num_sets_a != num_sets_b:
            return num_sets_b - num_sets_a

    sa = split_part_num(a)
    sb = split_part_num(b)

    return -1 if sa < sb else 1 if sa > sb else 0


def insert_rels(rels, stats, rel_type, con):
    key = cmp_to_key(lambda a, b: cmp_parts(a, b, stats, rel_type))
    resolved, *rels = sorted(list(rels), key=key)

    with con, closing(con.cursor()) as cur:
        cur.executemany('insert into part_rels_resolved values (?, ?, ?)',
                        [(rel_type, rel, resolved) for rel in rels])


def gen_part_rels_resolved(con):
    stats = {}
    resolved = {'A': set(), 'M': set()}

    with closing(con.cursor()) as cur:
        for part_num, num_sets, min_year, max_year in cur.execute(SQL_STATS):
            stats[part_num] = [num_sets, min_year, max_year]

        for rel_type, child, parent in cur.execute(SQL_RELS_LIST):
            if rel_type in resolved and child not in resolved[rel_type]:
                rels = find_all_rels(rel_type, con, {child, parent})
                resolved[rel_type].update(rels)
                insert_rels(rels, stats, rel_type, con)


if __name__ == '__main__':
    with closing(sqlite3.connect(f'{WORKDIR}/data/rb.db')) as conn:
        gen_part_rels_resolved(conn)
