"""Writes a parsed granth (see parse_kathakalpataru.py) to Firestore.

  granth/<book>          – book details + chapter list (no text), one read
  granth_text/<chapter>  – one chapter's text

Usage: PROJECT=<id> TOKEN=$(gcloud auth print-access-token) \
       python3 import_firestore.py data/granth/kathakalpataru.json
"""
import json
import os
import sys
import urllib.request

BOOKS = {}
BOOKS['kathakalpataru'] = {
    'title': 'कथाकल्पतरू',
    'subtitle': 'पूर्वार्ध – स्तबक १ ते ७',
    'author': 'कवी श्रीकृष्ण व मधुकर',
    'edition': 'सरळ गोष्टींच्या रूपाने सुलभ मराठी भाषांतर – दामोदर सावळाराम आणि मंडळी, मुंबई, इ.स. १९१०',
    'note': 'मजकूर १९१० च्या छापील प्रतीवरून संगणकाने वाचला (OCR) आहे; "शुद्ध" खूण नसलेल्या अध्यायांत काही अक्षरचुका असू शकतात.',
}


def value(v):
    if v is None:
        return {'nullValue': None}
    if isinstance(v, bool):
        return {'booleanValue': v}
    if isinstance(v, int):
        return {'integerValue': str(v)}
    if isinstance(v, str):
        return {'stringValue': v}
    if isinstance(v, list):
        return {'arrayValue': {'values': [value(x) for x in v]}}
    if isinstance(v, dict):
        return {'mapValue': {'fields': {k: value(x) for k, x in v.items()}}}
    raise TypeError(type(v))


def commit(project, token, writes):
    base = f'projects/{project}/databases/(default)/documents'
    body = json.dumps({'writes': [
        {'update': {'name': f'{base}/{path}', 'fields': {k: value(x) for k, x in data.items()}}}
        for path, data in writes
    ]}).encode()
    req = urllib.request.Request(
        f'https://firestore.googleapis.com/v1/{base}:commit', data=body, method='POST',
        headers={'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'})
    urllib.request.urlopen(req).read()


def book_meta(path):
    """Details of the book in <path>: built in, or <book>/book.json next to it."""
    book = os.path.splitext(os.path.basename(path))[0]
    meta_file = os.path.join(os.path.dirname(path), book, 'book.json')
    meta = dict(BOOKS.get(book, {}))
    if os.path.exists(meta_file):
        meta.update(json.load(open(meta_file, encoding='utf-8')))
    return book, {k: v for k, v in meta.items() if k in ('title', 'subtitle', 'author', 'edition', 'note') and v}


def main(path):
    project, token = os.environ['PROJECT'], os.environ['TOKEN']
    chapters = json.load(open(path, encoding='utf-8'))
    book, meta = book_meta(path)
    index = {**meta, 'chapters': [
        {k: c[k] for k in ('id', 'stabak', 'adhyay', 'adhyayTo', 'title', 'topics', 'proofread')} for c in chapters
    ]}
    writes = [(f'granth/{book}', index)] + [
        (f'granth_text/{c["id"]}', {'book': book, 'stabak': c['stabak'], 'adhyay': c['adhyay'],
                                   'adhyayTo': c['adhyayTo'], 'title': c['title'], 'body': c['body'],
                                   'proofread': c['proofread']})
        for c in chapters
    ]
    for i in range(0, len(writes), 10):
        commit(project, token, writes[i:i + 10])
    print(f'{len(chapters)} chapters written ({sum(c["proofread"] for c in chapters)} proofread)')


if __name__ == '__main__':
    for p in sys.argv[1:]:
        main(p)
