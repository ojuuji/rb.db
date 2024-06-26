.output theme_chains.txt
.echo ON
.bail ON
.mode table --wrap 0

SELECT datetime(value, 'unixepoch') 'DB version'
  FROM rb_db_lov
 WHERE key = 'data_timestamp';

-- Themes along with all their ancestors composed in a chain.

CREATE TEMPORARY VIEW theme_chains
AS
  WITH RECURSIVE rec(id, last_parent_id, ids_chain, names_chain, chain_size)
    AS (SELECT id, parent_id, id, name, 1
          FROM themes
         WHERE parent_id IS NULL
         UNION
        SELECT t.id
             , rec.id
             , rec.ids_chain || ',' || t.id
             , rec.names_chain || ' → ' || t.name
             , rec.chain_size + 1
          FROM rec
          JOIN themes t
            ON t.parent_id = rec.id
       )
SELECT id, ids_chain, names_chain, chain_size
  FROM rec
 ORDER BY names_chain COLLATE NOCASE;

SELECT name, ids_chain, names_chain, chain_size FROM themes NATURAL JOIN theme_chains;
