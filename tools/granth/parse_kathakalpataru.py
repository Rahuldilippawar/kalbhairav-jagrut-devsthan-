"""Splits the OCR text of Katha-Kalpataru (purvardha, 1910) into chapters.

Input: the book-part-*.txt files published by the "OCR a scanned book"
workflow, concatenated. Output: JSON list of chapters
{id, stabak, adhyay, title, topics, pages, body, proofread} where body
uses the Guru Gyan lesson format ("## " = sub-heading).

Usage: python3 parse_kathakalpataru.py book.txt out.json
"""
import json
import os
import re
import sys

DEV = str.maketrans('०१२३४५६७८९', '0123456789')
STABAK_STARTS = {  # first line (1-based) of each stabak in the OCR text
    1: 434, 2: 3752, 3: 7162, 4: 12209, 5: 17537, 6: 23770, 7: 28629,
}
BOOK_END = 31880  # the publisher's closing summary starts after this
PAGE = re.compile(r'^===== पान (\d+) =====$')
ADHYAY = r'(?:अध्याय|अध्यय|अध्याव|अघ्याय|अन्याय|अथ्याय|अधराय|अध्यार|अध्याथ)'
# A chapter heading line: "अध्याय ८ वा." with at most a little OCR debris.
HEADING = re.compile(r'^[\s,.\'`"|~]{0,3}' + ADHYAY + r'\s*([^\s.,]{0,5})\s*(ला|रा|था|वा|बा|चा|वबा)?\s*[.,]?\s*\S{0,2}\s*$')
# Running page header: "२.२, | अध्याय ८ वा. ११९", "रा.] अध्याय ९ वा, ५१".
RUNNING = re.compile(ADHYAY + r'\s*\S{1,5}\s*(?:वा|रा|था|ला|बा|चा)?\s*[.,]?\s*[|`\'"]?\s*[\d०-९]{1,3}|\]\s*' + ADHYAY + r'|कथाक.?ल्प|^[^ ]{0,4}\s*[\]|]\s*\S*\s*$')
SUBHEAD = re.compile(r'^\s*([०-९0-9]{1,2})\s+(\S.{2,60}?)[.।]?\s*$')


def devanagari_ratio(text):
    letters = [c for c in text if not c.isspace() and c not in '.,;:-–—!?\'"()']
    if not letters:
        return 0.0
    return sum('\u0900' <= c <= '\u097f' for c in letters) / len(letters)


def tidy(text):
    """A heading or title without leading numbers and OCR debris."""
    text = re.sub(r'^[\W\d०-९_]+', '', text)
    return re.sub(r'[\s,.;:`\'"|~^*]+$', '', text).strip()


def good_title(text):
    t = tidy(text)
    return 3 < len(t) < 60 and devanagari_ratio(t) > 0.9 and not re.search(r'कथाक.?ल्प|स्त[बव]क|अध्याय', t)


def number(token):
    digits = re.sub(r'\D', '', token.translate(DEV))
    return int(digits) if digits else None


def is_running_header(line):
    s = line.strip()
    if len(s) > 55:
        return False
    return bool(RUNNING.search(s) or re.search(r'^स्त[बव]क|^[\W\d०-९]+$', s))


def clean_lines(lines):
    """Drops page markers, running headers and OCR debris."""
    out = []
    after_page = 0
    page = None
    for line in lines:
        m = PAGE.match(line)
        if m:
            page = int(m.group(1))
            after_page = 3
            out.append(('page', page))
            continue
        if after_page:
            after_page -= 1
            if not line.strip() or is_running_header(line):
                continue
            after_page = 0
        s = line.strip()
        if s and len(re.sub(r'[\W\d_]', '', s)) < 2:  # stray marks
            continue
        if s and is_running_header(s):
            continue
        out.append(('text', line.rstrip()))
    return out


def to_body(items):
    """Joins wrapped OCR lines into paragraphs; numbered sub-titles become ## headings."""
    paras, cur, pages = [], [], []
    def flush():
        if cur:
            text = ''
            for part in cur:
                if text.endswith('-'):
                    text = text[:-1] + part
                else:
                    text = (text + ' ' + part) if text else part
            paras.append(re.sub(r'\s{2,}', ' ', text).strip(' `\'"'))
            cur.clear()
    for kind, value in items:
        if kind == 'page':
            pages.append(value)
            continue
        s = value.strip()
        if not s:
            flush()
            continue
        sub = SUBHEAD.match(s)
        if sub and len(s) < 60:
            flush()
            paras.append('## ' + sub.group(2).strip(' .'))
            continue
        cur.append(s)
    flush()
    return [p for p in paras if p], pages


def main(src, dst):
    lines = open(src, encoding='utf-8').read().split('\n')
    chapters = []
    stabaks = sorted(STABAK_STARTS.items())
    for si, (stabak, start) in enumerate(stabaks):
        end = stabaks[si + 1][1] - 1 if si + 1 < len(stabaks) else BOOK_END
        # Chapter boundaries: short lines that read "अध्याय N वा." etc.
        marks = [(start - 1, 1)]
        prev = 1
        for i in range(start, end):
            m = HEADING.match(lines[i])
            if not m:
                continue
            if m.group(2) == 'ला':  # "अध्याय १ ला" – the stabak's first chapter
                marks[0] = (i, 1)
                continue
            n = number(m.group(1))
            # OCR garbles numbers ("१२१" for ११, "^"): trust only the next few.
            n = n if n is not None and prev < n <= prev + 3 else prev + 1
            marks.append((i, n))
            prev = n
        for k, (line_no, adhyay) in enumerate(marks):
            stop = marks[k + 1][0] if k + 1 < len(marks) else end
            chunk = lines[line_no + (0 if k == 0 else 1):stop]
            paras, pages = to_body(clean_lines(chunk))
            # Drop debris paragraphs and bad sub-headings.
            paras = [p for p in paras if (good_title(p[3:]) if p.startswith('## ') else
                                          (len(p) > 40 and devanagari_ratio(p) > 0.75) or good_title(p))]
            paras = [('## ' + tidy(p[3:])) if p.startswith('## ') else p for p in paras]
            topics = [p[3:] for p in paras if p.startswith('## ')]
            # Title: the chapter's own title line, else its first story.
            title = next((p for p in paras[:3] if not p.startswith('## ') and good_title(p) and len(p) < 60), None)
            if title:
                paras.remove(title)
                title = tidy(title)
            title = title or (topics[0] if topics else ('मंगलाचरण' if adhyay == 1 else f'अध्याय {adhyay}'))
            chapters.append({
                'id': f'kk-s{stabak}-a{adhyay:02d}',
                'stabak': stabak,
                'adhyay': adhyay,
                'title': title,
                'topics': topics[:12],
                'pages': [min(pages), max(pages)] if pages else [],
                'body': '\n\n'.join(paras),
                'proofread': False,
            })
    # Merged chapters (a missed heading) cover several adhyays.
    for a, b in zip(chapters, chapters[1:] + [None]):
        a['adhyayTo'] = b['adhyay'] - 1 if b and b['stabak'] == a['stabak'] and b['adhyay'] > a['adhyay'] + 1 else a['adhyay']
    chapters[:] = [c for c in chapters if len(c['body']) > 300]
    # Hand-corrected titles where OCR garbled them.
    tpath = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'titles.json')
    for c in chapters:
        c['title'] = json.load(open(tpath, encoding='utf-8')).get(c['id'], c['title'])
    # Proofread chapters (proofread/<id>.md: first line "# title", then body)
    # replace the OCR text.
    pdir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'proofread')
    by_id = {c['id']: c for c in chapters}
    for name in sorted(os.listdir(pdir)) if os.path.isdir(pdir) else []:
        cid = name[:-3]
        if not name.endswith('.md') or cid not in by_id:
            continue
        text = open(os.path.join(pdir, name), encoding='utf-8').read().strip()
        first, _, body = text.partition('\n')
        c = by_id[cid]
        c['title'] = first.lstrip('# ').strip()
        c['body'] = body.strip()
        c['topics'] = [l[3:] for l in body.split('\n') if l.startswith('## ')][:12]
        c['proofread'] = True
    json.dump(chapters, open(dst, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print(len(chapters), 'chapters')


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
