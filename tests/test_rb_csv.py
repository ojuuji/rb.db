from common import DATADIR
import csv
import pytest


class TestCsv():
    @pytest.mark.parametrize('table, headers', [
        ('colors', 'id,name,rgb,is_trans,num_parts,num_sets,y1,y2'),
        ('elements', 'element_id,part_num,color_id,design_id'),
        ('inventories', 'id,version,set_num'),
        ('inventory_minifigs', 'inventory_id,fig_num,quantity'),
        ('inventory_parts', 'inventory_id,part_num,color_id,quantity,is_spare,img_url'),
        ('inventory_sets', 'inventory_id,set_num,quantity'),
        ('minifigs', 'fig_num,name,num_parts,img_url'),
        ('part_categories', 'id,name'),
        ('part_relationships', 'rel_type,child_part_num,parent_part_num'),
        ('parts', 'part_num,name,part_cat_id,part_material'),
        ('sets', 'set_num,name,year,theme_id,num_parts,img_url'),
        ('themes', 'id,name,parent_id')
    ])
    def test_table_headers(self, table, headers):
        with open(f'{DATADIR}/{table}.csv', 'r', encoding='utf-8') as f:
            cf = csv.DictReader(f)
            assert ','.join(cf.fieldnames) == headers
