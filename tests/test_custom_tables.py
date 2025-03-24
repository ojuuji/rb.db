import pytest
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

SQL_RELS_EXTRA_PRINTS_EXCEPT = '''
SELECT c.part_num
  FROM (SELECT part_num
          FROM parts
         WHERE part_num GLOB '*?pr[0-9]*'
        EXCEPT
        SELECT child_part_num
          FROM part_relationships
         WHERE rel_type = 'P'
       ) c
  JOIN parts p
    ON p.part_num = substr(c.part_num, 1, instr(c.part_num, 'pr') - 1)
'''


@pytest.mark.custom_schema
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
            '64784pat0001c01',
            '64784pat0002c01',

            # None - not a pattern
            'Eyepatch'
        ]
        assert parts == expected

    def test_rels_extra_rules_prints(self, rbdb):
        rbdb.execute(SQL_RELS_EXTRA_PRINTS)
        prints_regex = re.compile(r'.+pr\d+')
        extra_prints = [part for part, in rbdb if not prints_regex.fullmatch(part)]
        extra_regex = re.compile(r'(.+)pr\d+(a|kc|c01)')  # "General rule for prints"
        nonprints = [part for part in extra_prints if not extra_regex.fullmatch(part)]
        expected = [
            # Every part_num below is a valid print if not stated otherwise. Basing on valid
            # prints the case-sensitive extra_regex rule is sufficient
            '10111c01pr0005a',
            '35499pr0032a',
            '4555c02pr0001a',
            '649pr0001HO',  # not a print
            '649pr0002HO',  # not a print
            '75113pr0001a',
            '75115pr0006a',
            '75115pr0014a',
            '75115pr0024a',
            '75121pr0001a',
            '75121pr0002a',
            '75121pr0005a',
            '93088pr0002kc',
            '93088pr0008c01',
            'dupupn0013c02pr0001a'
        ]
        expected_nonprints = [
            '649pr0001HO',
            '649pr0002HO'
        ]
        assert extra_prints == expected
        assert nonprints == expected_nonprints

    NON_PRINTS = [
        '250pr0001',
        '250pr0002',
        '251pr0001',
        '251pr0002',
        '263pr0001',
        '4jfig0003pr0001',  # it is marked as mold
        '601pr0001',
        '649pr0001HO',
        '649pr0002HO',
        '650pr0001',
        '655pr0001',
        '670pr0001',
        '671pr0001'
    ]

    def test_rels_extra_rules_print_exceptions(self, rbdb):
        parts = [part for part, in rbdb.execute(SQL_RELS_EXTRA_PRINTS_EXCEPT)]
        assert parts == TestCustomTables.NON_PRINTS

    @pytest.mark.parametrize('part_num', NON_PRINTS)
    def test_rels_extra_has_no_prints_from_exceptions(self, rbdb, part_num):
        rbdb.execute(f"SELECT count(*) FROM parts WHERE part_num = '{part_num}'")
        assert (1,) == rbdb.fetchone()

        rbdb.execute(f"SELECT count(*) FROM part_rels_extra WHERE child_part_num = '{part_num}'")
        assert (0,) == rbdb.fetchone()
