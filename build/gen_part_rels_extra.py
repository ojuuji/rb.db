from contextlib import closing
from dbconn import DbConnect
import os
import re


def process_part(part, rules, cur):
    extra = []

    for rel_type, regex, repl in rules:
        new_part = regex.sub(repl, part)
        if new_part != part:
            table = 'part_rels_resolved' if rel_type in 'AM' else 'part_relationships'
            cur.execute(f"SELECT * FROM {table} WHERE child_part_num = '{part}' " +
                        "AND parent_part_num = '{new_part}' AND rel_type = '{rel_type}'")
            if cur.fetchone() is None:
                extra.append((rel_type, part, new_part))
                extra.extend(process_part(new_part, rules, cur))

            break

    return extra


def gen_part_rels_extra(conn):
    print(":: generating part_rels_extra ...")

    ws = re.compile(r'^#.*|^\s*$')
    rules_path = os.path.dirname(os.path.abspath(__file__)) + '/part_rels_extra_rules.txt'
    rules = []
    with open(rules_path, 'r') as rules_file:
        for rule_line in rules_file:
            rule_line = rule_line.rstrip()
            if not ws.fullmatch(rule_line):
                pieces = rule_line.split(rule_line[1])
                if len(pieces) != 3:
                    raise ValueError(f"invalid rule: '{rule_line}'")
                rel_type, pattern, repl = pieces
                rules.append([rel_type, re.compile(f'^{pattern}$'), repl])

    extra = []
    with closing(conn.cursor()) as cur:
        all_parts = [part for part, in cur.execute('SELECT part_num from parts')]
        for part in all_parts:
            extra.extend(process_part(part, rules, cur))

    with conn, closing(conn.cursor()) as cur:
        cur.executemany('INSERT INTO part_rels_extra VALUES (?, ?, ?)', extra)


if __name__ == '__main__':
    with DbConnect() as conn:
        gen_part_rels_extra(conn)
