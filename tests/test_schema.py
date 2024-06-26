from contextlib import closing
import os
import pytest
import sqlite3

SCHEMADIR = os.path.normpath(f'{os.path.dirname(os.path.abspath(__file__))}/../schema')


@pytest.fixture
def conn():
    conn = sqlite3.connect(':memory:')
    conn.execute('PRAGMA foreign_keys = ON')

    yield conn

    conn.close()


class TestSchema():
    def executescript(self, conn, name):
        with open(f'{SCHEMADIR}/{name}.sql', 'r') as file:
            script = '\n'.join([line for line in file.readlines() if not line.startswith('.')])
            conn.executescript(script)

    def test_rb_drop_leaves_nothing(self, conn):
        self.executescript(conn, 'rb_tables')
        self.executescript(conn, 'rb_indexes')
        self.executescript(conn, 'rb_drop')

        with closing(conn.cursor()) as cur:
            assert (0,) == cur.execute('SELECT count(*) FROM sqlite_master').fetchone()

    @pytest.mark.custom_schema
    def test_custom_drop_leaves_nothing_custom(self, conn):
        self.executescript(conn, 'rb_tables')
        self.executescript(conn, 'rb_indexes')

        with closing(conn.cursor()) as cur:
            before, = cur.execute('SELECT count(*) FROM sqlite_master').fetchone()

        self.executescript(conn, 'custom_tables')
        self.executescript(conn, 'custom_indexes')
        self.executescript(conn, 'custom_drop')

        with closing(conn.cursor()) as cur:
            after, = cur.execute('SELECT count(*) FROM sqlite_master').fetchone()

        assert before == after

    @pytest.mark.custom_schema
    def test_rb_and_custom_drop_leave_nothing(self, conn):
        self.executescript(conn, 'rb_tables')
        self.executescript(conn, 'rb_indexes')
        self.executescript(conn, 'custom_tables')
        self.executescript(conn, 'custom_indexes')
        self.executescript(conn, 'custom_drop')
        self.executescript(conn, 'rb_drop')

        with closing(conn.cursor()) as cur:
            assert (0,) == cur.execute('SELECT count(*) FROM sqlite_master').fetchone()
