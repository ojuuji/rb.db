import os
import sqlite3


WORKDIR = os.path.dirname(os.path.abspath(__file__))


class DbConnect():
    def __enter__(self):
        self.conn = sqlite3.connect(f'{WORKDIR}/../data/rb.db')
        self.conn.execute('PRAGMA foreign_keys = ON')

        return self.conn

    def __exit__(self, exc_type, exc_value, traceback):
        self.conn.execute('PRAGMA optimize')
        self.conn.close()
