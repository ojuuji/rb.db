from common import DBFILE
import pytest
import sqlite3


@pytest.fixture(scope='session')
def rbdb():
    conn = sqlite3.connect(DBFILE)
    conn.execute('PRAGMA query_only = ON')
    cur = conn.cursor()

    yield cur

    cur.close()
    conn.close()
