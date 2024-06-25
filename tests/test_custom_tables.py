import re

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

SQL_RELS_EXTRA_MINIFIGS = '''
SELECT DISTINCT substr(part_num, 1, 4)
  FROM parts
 WHERE part_num GLOB '97[03][a-z]*'
 ORDER BY 1
'''

SQL_RELS_EXTRA_PATTERNS = '''
SELECT iif(glob('*pr[0-9][0-9][0-9][0-9]', part_num),
           substr(part_num, 1, length(part_num) - 6),
           part_num)
  FROM parts WHERE part_num LIKE '%_pat_%'
EXCEPT
SELECT child_part_num
  FROM part_relationships
 WHERE rel_type = 'T'
'''

SQL_RELS_EXTRA_PRINTS = '''
SELECT part_num
  FROM parts
 WHERE part_num LIKE '%_pr_%'
EXCEPT
SELECT child_part_num
  FROM part_relationships
 WHERE rel_type = 'P'
'''


class TestCustomTables():
    def test_rels_uniqueness(self, rbdb):
        rbdb.execute(f'SELECT count(*) FROM ({SQL_RELS_UNION})')
        all, = rbdb.fetchone()

        rbdb.execute(f'SELECT count(*) FROM (SELECT DISTINCT * FROM ({SQL_RELS_UNION}))')
        distinct, = rbdb.fetchone()

        assert all == distinct

    def test_rels_extra_rules_minifigs(self, rbdb):
        parts = [part for part, in rbdb.execute(SQL_RELS_EXTRA_MINIFIGS)]
        expected = [
            # T,970[cdl].+,970c00
            '970c',
            '970d',
            '970l',
            # A,970e.+,970c00
            '970e',
            # None - long legs and nothing same (unlike 973b below)
            '970f',
            # T,973[c-h].+,973c00
            '973c',
            '973d',
            '973e',
            '973f',
            '973g',
            '973h',
            # A,973b.+,973c00 - same body but long arms so alternate
            '973b',
            # None - single body part without arms
            '973p'
        ]
        assert parts == sorted(expected)

    def test_rels_extra_rules_patterns(self, rbdb):
        rbdb.execute(SQL_RELS_EXTRA_PATTERNS)
        regex = re.compile(r'.+pat\d+(pr\d+)?')
        parts = [part for part, in rbdb if not regex.fullmatch(part)]
        expected = [
            # T,(.+)pats?\d+(c01)?,$1
            '16709pats01',
            '16709pats02',
            '16709pats12',
            '16709pats14',
            '16709pats22',
            '16709pats27',
            '16709pats37',
            '16709pats41',
            '64784pat01c01',
            '64784pat02c01',

            # None - not a pattern
            'Eyepatch'
        ]
        assert parts == expected

    def test_rels_extra_rules_prints(self, rbdb):
        rbdb.execute(SQL_RELS_EXTRA_PRINTS)
        regex = re.compile(r'.+pr\d+')
        parts = [part for part, in rbdb if not regex.fullmatch(part)]
        expected = [
            # Every part_num below is a valid print if not stated otherwise. Basing on valid
            # prints this rel is sufficient (case-sensitive): P,(.+)pr\d+[a-z]*,$1
            '35499pr0032a',
            '4555c02pr0001a',
            '649pr0001HO',  # not a print
            '649pr0002HO',  # not a print
            '75115pr0006a',
            '75115pr0014a',
            '75115pr0024a',
            '75121pr0001a',
            '75121pr0002a',
            '75121pr0005a',
            '93088pr0002kc',
            'dupupn0013c02pr0001a'
        ]
        assert parts == expected
