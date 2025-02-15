import pytest

SQL_MINIFIGS_CONTENT = '''
SELECT count(*)
  FROM minifigs m
  JOIN inventories i
    ON m.fig_num = i.set_num
  JOIN %s x
    ON x.inventory_id = i.id
'''

SQL_MAX_THEMES_CHAIN_SIZE = '''
  WITH RECURSIVE rec(id, parent_id, chain_size)
    AS (SELECT id, parent_id, 1
          FROM themes
         UNION
        SELECT t.id, t.parent_id, rec.chain_size + 1
          FROM rec
          JOIN themes t
            ON t.id = rec.parent_id
       )
SELECT max(chain_size)
  FROM rec
'''

SQL_NO_UNIQUE_RELS = '''
SELECT *
  FROM part_relationships
 GROUP BY rel_type, ?
HAVING count(*) = 1
'''


class TestRbTables():
    def test_minifigs_have_standard_parts(self, rbdb):
        assert (0,) != rbdb.execute(SQL_MINIFIGS_CONTENT % 'inventory_parts').fetchone()

    def test_minifigs_do_not_have_minifigs(self, rbdb):
        assert (0,) == rbdb.execute(SQL_MINIFIGS_CONTENT % 'inventory_minifigs').fetchone()

    def test_minifigs_do_not_have_sets(self, rbdb):
        assert (0,) == rbdb.execute(SQL_MINIFIGS_CONTENT % 'inventory_sets').fetchone()

    def test_minifigs_do_not_have_spare_parts(self, rbdb):
        sql = SQL_MINIFIGS_CONTENT % 'inventory_parts' + ' where is_spare'
        assert (0,) == rbdb.execute(sql).fetchone()

    # Check to ensure the docs relevance (they are mentioned in docs)
    @pytest.mark.parametrize('part_num', ['75c23.75', '134916-740'])
    def test_parts_with_nonstandard_names_still_exist(self, rbdb, part_num):
        rbdb.execute(f"SELECT count(*) FROM parts WHERE part_num = '{part_num}'")
        assert (1,) == rbdb.fetchone()

    def test_max_themes_chain_size(self, rbdb):
        assert (3,) == rbdb.execute(SQL_MAX_THEMES_CHAIN_SIZE).fetchone()

    def test_no_unique_child_rels(self, rbdb):
        assert [] == rbdb.execute(SQL_NO_UNIQUE_RELS, ['child_part_num']).fetchall()

    def test_no_unique_parent_rels(self, rbdb):
        assert [] == rbdb.execute(SQL_NO_UNIQUE_RELS, ['parent_part_num']).fetchall()
