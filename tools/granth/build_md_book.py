"""Builds data/granth/<book>.json from hand-entered chapters.

data/granth/<book>/book.json  – title, subtitle, author, edition, note,
                                chapterPrefix
data/granth/<book>/aNN.md     – one adhyay: first line "# title", then the
                                text ("## " = section heading)

Usage: python3 build_md_book.py moolstambh
"""
import json
import os
import re
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'data', 'granth')


def main(book):
    folder = os.path.join(ROOT, book)
    meta = json.load(open(os.path.join(folder, 'book.json'), encoding='utf-8'))
    chapters = []
    for name in sorted(os.listdir(folder)):
        m = re.fullmatch(r'a(\d+)\.md', name)
        if not m:
            continue
        adhyay = int(m.group(1))
        first, _, body = open(os.path.join(folder, name), encoding='utf-8').read().strip().partition('\n')
        chapters.append({
            'id': f"{meta['chapterPrefix']}-a{adhyay:02d}",
            'stabak': 0,
            'adhyay': adhyay,
            'adhyayTo': adhyay,
            'title': first.lstrip('# ').strip(),
            'topics': [l[3:].strip() for l in body.split('\n') if l.startswith('## ')][:12],
            'body': body.strip(),
            'proofread': True,
        })
    out = os.path.join(ROOT, f'{book}.json')
    json.dump(chapters, open(out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print(f'{book}: {len(chapters)} adhyay')


if __name__ == '__main__':
    main(sys.argv[1])
