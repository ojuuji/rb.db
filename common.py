import os
import sqlite3


WORKDIR = os.path.dirname(os.path.abspath(__file__))


def db_connect():
    conn = sqlite3.connect(f'{WORKDIR}/data/rb.db')
    conn.execute('PRAGMA foreign_keys = ON')

    return conn
