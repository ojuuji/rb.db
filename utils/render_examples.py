import glob
from jinja2 import Environment, FileSystemLoader
import os

DESC_PREFIX = '-- '
OUT_PREFIX = '.output '


def collect_examples(dir):
    examples = []

    for path in glob.glob(f'{dir}/*.sql'):
        desc = []
        sql = os.path.basename(path)
        out = ext = None

        with open(path, 'r') as file:
            for line in file:
                if line.startswith(DESC_PREFIX):
                    desc.append(line.rstrip()[len(DESC_PREFIX):])
                if line.startswith(OUT_PREFIX):
                    out = line.rstrip()[len(OUT_PREFIX):]
                    ext = os.path.splitext(out)[1].lstrip('.')

        fulldesc = ' '.join(desc) if len(desc) else os.path.splitext(sql)[0]
        examples.append({'desc': fulldesc, 'sql': sql, 'out': out, 'ext': ext})

    return examples


def render_examples(examples, templates_dir):
    examples = sorted(examples, key=lambda x: x['sql'])

    env = Environment(loader=FileSystemLoader(templates_dir), autoescape=False)
    template = env.get_template('examples_template.md')
    print(template.render(examples=examples))


if __name__ == '__main__':
    dir = os.path.dirname(os.path.abspath(__file__))
    examples = collect_examples(f'{dir}/../docs/examples')
    render_examples(examples, dir)
