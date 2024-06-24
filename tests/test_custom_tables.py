SQL_RELS_UNION = '''
SELECT *
  FROM part_relationships
 WHERE rel_type NOT IN ('A', 'M')
 UNION ALL
SELECT *
  FROM part_rels_resolved
 WHERE rel_type IN ('A', 'M')
 UNION ALL
SELECT *
  FROM part_rels_extra
'''


class TestCustomTables():
    def test_rels_uniqueness(self, rbdb):
        rbdb.execute(f'SELECT count(*) FROM ({SQL_RELS_UNION})')
        all, = rbdb.fetchone()

        rbdb.execute(f'SELECT count(*) FROM (SELECT DISTINCT * FROM ({SQL_RELS_UNION}))')
        distinct, = rbdb.fetchone()

        assert all == distinct
