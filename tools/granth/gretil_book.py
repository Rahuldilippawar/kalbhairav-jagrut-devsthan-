"""Builds Guru Gyan granths from GRETIL plain-text e-texts (IAST).

GRETIL – Göttingen Register of Electronic Texts in Indian Languages,
licence CC BY-NC-SA 4.0. The texts are transliterated to Devanagari and
split into parts (स्कंध / अंश / भाग …) and chapters using GRETIL's own verse
references (e.g. "// bhp_01.01.005 //", "/ap_1.001ab/", "1.1.3: sutra").

Usage: python3 gretil_book.py <plaintext dir> <out dir> [book id …]
Writes <out dir>/<id>.json and <out dir>/<id>/book.json for import_firestore.py.
"""
import json
import os
import re
import sys

from indic_transliteration import sanscript

LICENCE = 'मूळ संस्कृत e-text: GRETIL (Göttingen Register of Electronic Texts in Indian Languages), CC BY-NC-SA 4.0.'

# id: title, files (part number per file, or None = taken from the
# references), labels, note on completeness.
PURANAS = {
    'bhagavata': dict(title='श्रीमद्भागवत महापुराण', files=[('sa_bhAgavatapurANa.txt', None)],
                      part='स्कंध', chapter='अध्याय', order=40, complete=True),
    'vishnu': dict(title='श्रीविष्णु महापुराण', files=[('sa_viSNupurANa.txt', None)],
                   part='अंश', chapter='अध्याय', order=41, complete=True),
    'brahma': dict(title='ब्रह्म महापुराण', files=[('sa_brahmapurANa-1-246.txt', 0)],
                   chapter='अध्याय', order=42, complete=True),
    'agni': dict(title='अग्नि महापुराण', files=[('sa_agnipurANa.txt', 0)], chapter='अध्याय', order=43, complete=True),
    'garuda': dict(title='गरुड महापुराण', files=[('sa_garuDapurANa.txt', None)],
                   part='खंड', chapter='अध्याय', order=44, complete=True),
    'linga': dict(title='लिंग महापुराण', files=[('sa_liGgapurANa1-108.txt', None), ('sa_liGgapurANa2,1-55.txt', None)],
                  part='भाग', chapter='अध्याय', order=45, complete=True),
    'kurma': dict(title='कूर्म महापुराण', files=[('sa_kUrmapurANa.txt', None)],
                  part='भाग', chapter='अध्याय', order=46, complete=True),
    'narada': dict(title='नारद महापुराण', files=[('sa_nAradapurANa.txt', None)],
                   part='भाग', chapter='अध्याय', order=47, complete=True),
    'brahmanda': dict(title='ब्रह्मांड महापुराण', files=[('sa_brahmANDapurANa.txt', None)],
                      part='भाग', chapter='अध्याय', order=48, complete=True),
    'vamana': dict(title='वामन महापुराण', files=[('sa_vAmanapurANa1-69.txt', 1), ('sa_vAmanapurANasaromAhAtmya.txt', 2)],
                   part='भाग', chapter='अध्याय', order=49, complete=True,
                   parts={1: 'वामन पुराण', 2: 'सरोमाहात्म्य'}),
    'markandeya': dict(title='मार्कंडेय महापुराण', files=[('sa_mArkaNDeyapurANa1-93.txt', 0)], chapter='अध्याय', order=50,
                       complete=False, missing='GRETIL मध्ये अध्याय 1–93 उपलब्ध आहेत; पुढील अध्याय अजून नाहीत.'),
    'matsya': dict(title='मत्स्य महापुराण', files=[('sa_matsyapurANa1-176.txt', 0)], chapter='अध्याय', order=51,
                   complete=False, missing='GRETIL मध्ये अध्याय 1–176 उपलब्ध आहेत (एकूण सुमारे 291); पुढील अध्याय अजून नाहीत.'),
    'shiva': dict(title='शिव महापुराण', files=[('sa_zivapurANabooks-1-and-7.txt', None)], part='भाग', chapter='अध्याय',
                  order=52, complete=False, remap={1: 1, 71: 2, 72: 3},
                  parts={1: 'विद्येश्वर संहिता', 2: 'वायवीय संहिता – पूर्वभाग', 3: 'वायवीय संहिता – उत्तरभाग'},
                  missing='GRETIL मध्ये फक्त विद्येश्वर संहिता (1) व वायवीय संहिता (7) उपलब्ध आहेत; इतर संहिता अजून नाहीत.'),
    'skanda': dict(title='स्कंद महापुराण', files=[('sa_skandapurANa1-31,14.txt', 1), ('sa_skandapurANa-revAkhaNDa-rks.txt', 2)],
                   part='भाग', chapter='अध्याय', order=53, complete=False,
                   parts={1: 'आदि स्कंद पुराण (अध्याय 1–31)', 2: 'रेवाखंड'},
                   missing='GRETIL मध्ये प्राचीन स्कंद पुराणाचे अध्याय 1–31 व रेवाखंड उपलब्ध आहेत; इतर खंड (काशीखंड, सह्याद्रिखंड इ.) अजून नाहीत.'),
    'vayu': dict(title='वायु महापुराण – रेवाखंड', files=[('sa_revAkhANDa-of-the-vAyupurANa-rkv.txt', 0)], chapter='अध्याय',
                 order=54, complete=False, missing='GRETIL मध्ये वायु पुराणाचा फक्त रेवाखंड उपलब्ध आहे.'),
    'narasimha': dict(title='नरसिंह पुराण (उपपुराण)', files=[('sa_narasiMhapurANa.txt', 0)], chapter='अध्याय', order=55,
                      complete=True),
}

# Shad-darshana sutras. kind: 'apn' = adhyaya.pada.sutra, 'pn' = one
# number for the chapter (pada / adhyaya) and the sutra.
DARSHANAS = {
    'nyayasutra': dict(title='न्यायसूत्र (गौतम)', file='sa_gautama-nyAyasUtra.txt', order=60,
                       subtitle='षड्दर्शन – न्याय दर्शन', part='अध्याय', chapter='आन्हिक'),
    'vaisheshikasutra': dict(title='वैशेषिकसूत्र (कणाद)', file='sa_kaNAda-vaizeSikasUtra.txt', order=61,
                             subtitle='षड्दर्शन – वैशेषिक दर्शन', part='अध्याय', chapter='आन्हिक'),
    'samkhyasutra': dict(title='सांख्यसूत्र (कपिल)', file='sa_kapila-sAMkhyasUtra.txt', order=62,
                         subtitle='षड्दर्शन – सांख्य दर्शन', chapter='अध्याय'),
    'samkhyakarika': dict(title='सांख्यकारिका (ईश्वरकृष्ण)', file='sa_IzvarakRSNa-sAMkhyakArikA.txt', order=63,
                          subtitle='षड्दर्शन – सांख्य दर्शन', chapter='भाग'),
    'yogasutra': dict(title='योगसूत्र (पतंजलि)', file='sa_pataJjali-yogasUtra.txt', order=64,
                      subtitle='षड्दर्शन – योग दर्शन', chapter='पाद'),
    'mimamsasutra': dict(title='मीमांसासूत्र (जैमिनि)', file='sa_jaimini-mImAMsAsUtra.txt', order=65,
                         subtitle='षड्दर्शन – पूर्वमीमांसा दर्शन', part='अध्याय', chapter='पाद'),
    'brahmasutra': dict(title='ब्रह्मसूत्र (बादरायण)', file='sa_bAdarAyaNa-brahmasUtra.txt', order=66,
                        subtitle='षड्दर्शन – उत्तरमीमांसा (वेदांत) दर्शन', part='अध्याय', chapter='पाद'),
}

REF = re.compile(
    r"\s*/{0,2}\s*(?P<tag>[A-Za-zśṣṭḍṇñāīūṛ]+)_(?P<a>\d+)(?:[.,](?P<b>\d+))?(?:[.,](?P<c>\d+))?(?:[.,](?P<d>\d+))?(?P<half>ab|cd|ef)?\*?\s*/{0,2}")


def deva(text):
    out = sanscript.transliterate(text, sanscript.IAST, sanscript.DEVANAGARI)
    return out.replace('//', '॥').replace('/', '।').replace('|', '।')


def body_lines(path):
    text = open(path, encoding='utf-8').read()
    text = text.split('\n# Text', 1)[-1]
    return text


def split_purana(path, fixed_part):
    """[(part, chapter, iast text)] in order."""
    text = body_lines(path)
    text = re.sub(r'^\s*%.*$', '', text, flags=re.M)            # "% chapter {1}"
    text = re.sub(r'^\s*:\S*\s*', '', text, flags=re.M)          # ":ś " markers
    text = re.sub(r'\(\d+\)', '', text)                          # footnote marks
    text = re.sub(r'\b[A-Za-zśṣ]+_[\d.,]+/0\b', '', text)        # speaker refs
    text = re.sub(r'(?m)^\s*chapter \d+\s*', '', text)
    chapters = []
    pos = 0
    for m in REF.finditer(text):
        nums = [int(x) for x in (m['a'], m['b'], m['c'], m['d']) if x is not None]
        if len(nums) == 4:  # book.part,chapter.verse (Shiva Purana)
            part, ch, verse = nums[0] * 10 + nums[1], nums[2], nums[3]
        elif len(nums) == 3:
            part, ch, verse = nums
        elif len(nums) == 2:
            part, (ch, verse) = 0, nums
        else:
            continue
        if fixed_part is not None:
            part = fixed_part
        seg = text[pos:m.start()]
        pos = m.end()
        seg = re.sub(r'(?<!\w)\d+[a-z]?(?!\w)', '', seg)          # page / line numbers
        if '&' in seg:
            # Long metres: "a $ b & c % d" (GRETIL sometimes repeats a half).
            halves = []
            for h in (x.strip() for x in seg.split('&')):
                if h and (not halves or halves[-1] != h):
                    halves.append(h)
            seg = ' ।\n'.join(halves)
        seg = seg.replace('$', ' ').replace('%', ' ')
        end = ' ।\n' if m['half'] == 'ab' else f' ॥ {verse} ॥\n\n'
        key = (part, ch)
        if not chapters or chapters[-1][0] != key:
            # A colophon ("iti … 'dhyāyaḥ") at the start belongs to the chapter before.
            colo = re.match(r"\s*((?:iti|ity)\b[^\n]*?dhyāyaḥ[^\n]*\n?)", seg)
            if colo and chapters:
                chapters[-1][1].append(colo.group(1).strip() + '\n')
                seg = seg[colo.end():]
            chapters.append([key, []])
        chapters[-1][1].append(seg.strip() + end)
    if chapters:
        tail = text[pos:].strip()
        if tail and len(tail) < 2000:
            chapters[-1][1].append(tail + '\n')
    return [(k[0], k[1], ''.join(parts)) for k, parts in chapters]


def clean_lines(s, headings=False):
    lines = [re.sub(r'\s+', ' ', l).strip() for l in s.split('\n')]
    out, blank = [], False
    for l in lines:
        if not l:
            if not blank and out:
                out.append('')
            blank = True
            continue
        # Never let a verse line look like app markup.
        if l.startswith(('- ', '> ')) or (l.startswith('## ') and not headings):
            l = l.lstrip('-># ')
        out.append(l)
        blank = False
    return '\n'.join(out).strip()


def chapter_title(body, skip=()):
    """A short heading line near the top (e.g. "मत्स्यावतारवर्णनं"), else the first half-verse."""
    lines = [l for l in body.split('\n') if l.strip() and not re.match(r'इत[िय्]', l) and l not in skip
             and not l.rstrip().endswith(':')]
    for l in lines[:5]:
        if len(l) < 45 and '।' not in l and '॥' not in l and 'ध्याय' not in l and not (re.search(r'(उवाच|ऊचुः)', l) and len(l) < 40):
            return l
    for l in lines:
        if 'ध्याय' in l or (re.search(r'(उवाच|ऊचुः)', l) and len(l) < 40) or len(l) < 12:
            continue
        return re.sub(r'\s*[।॥].*$', '', l)[:70]
    return lines[0][:70] if lines else ''


def build_purana(src, out, bid, cfg):
    chapters = []
    seen = set()
    for f, fixed in cfg['files']:
        for part, ch, iast in split_purana(os.path.join(src, f), fixed):
            remap = cfg.get('remap')
            if remap:
                if part not in remap:
                    continue
                part = remap[part]
            if (part, ch) in seen:
                continue
            seen.add((part, ch))
            body = clean_lines(deva(iast))
            if not body:
                continue
            first = chapter_title(body)
            chapters.append({
                'id': f'{bid}-{part}-{ch}',
                'stabak': part,
                'adhyay': ch,
                'adhyayTo': ch,
                'title': first[:70],
                'topics': [],
                'body': body,
                'proofread': False,
            })
    chapters.sort(key=lambda c: (c['stabak'], c['adhyay']))
    # Running headers ("श्रीगरुडमहापुराणम्-") are not chapter titles.
    from collections import Counter
    common = {t for t, n in Counter(c['title'] for c in chapters).items() if n > 3}
    if common:
        for c in chapters:
            if c['title'] in common:
                c['title'] = chapter_title(c['body'], skip=common)
    # Stray references outside the book's parts (e.g. in an introduction).
    if any(c['stabak'] for c in chapters):
        chapters = [c for c in chapters if c['stabak']]
    parts = cfg.get('parts')
    if parts:
        for c in chapters:
            c['topics'] = [parts.get(c['stabak'], '')] if c['stabak'] in parts else []
    note = LICENCE + ' मजकूर संगणकीय e-text वरून आहे; काही ठिकाणी शब्द जोडलेले किंवा अक्षरचुका असू शकतात.'
    if not cfg.get('complete'):
        note = '⚠️ अपूर्ण: ' + cfg['missing'] + ' ' + note
    verses = sum(len(re.findall(r'॥ [०-९]+ ॥', c['body'])) for c in chapters)
    meta = {
        'id': bid, 'title': cfg['title'],
        'subtitle': f'मूळ संस्कृत • {len(chapters)} अध्याय • सुमारे {verses} श्लोक',
        'author': 'महर्षी वेदव्यास',
        'edition': 'GRETIL संस्कृत e-text, देवनागरीत रूपांतरित',
        'note': note, 'order': cfg['order'],
        'chapterLabel': cfg.get('chapter', 'अध्याय'),
    }
    if any(c['stabak'] for c in chapters):
        meta['partLabel'] = cfg.get('part', 'भाग')
    write(out, bid, meta, chapters)


SUTRA_REF = re.compile(r"[|/.]{0,2}\s*[A-Za-z]+_(\d+)(?:[.,](\d+))?(?:[.,](\d+))?\s*[|/]{0,2}")


def build_darshana(src, out, bid, cfg):
    text = body_lines(os.path.join(src, cfg['file']))
    text = re.sub(r'\{[^}]*\}', ' ', text)                    # sutra names / comments
    text = re.sub(r'(?m)^\s*\([^)]*\)\s*$', ' ', text)        # topic lines "(…)"
    text = re.sub(r'\(atha [^)]*\)', ' ', text)
    text = re.sub(r'(?<=[a-zāīūṛ])\d(?=\W)', '', text)          # footnote digits "aviśuddhi1"
    groups = {}

    def add(a, p, n, sutra, heading=None):
        sutra = re.sub(r'\s+', ' ', sutra).strip(' ,;')
        if not sutra:
            return
        g = groups.setdefault((a, p), [])
        if heading:
            g.append('## ' + deva(heading))
        g.append(f'{deva(sutra)} ॥ {deva(str(n))} ॥\n')

    pref = list(re.finditer(r'(?:\[([^\]]*)\]\s*)?(\d+)\.(\d+)\.(\d+):', text))
    if len(pref) > 20:  # "1.1.3: sutra" style (Nyaya)
        for i, m in enumerate(pref):
            end = pref[i + 1].start() if i + 1 < len(pref) else len(text)
            sutra = re.sub(r'\[[^\]]*\]', ' ', text[m.end():end])
            head = re.sub(r'\(.*?\)', '', m.group(1)).strip() if m.group(1) else None
            add(int(m[2]), int(m[3]), int(m[4]), sutra, head)
    else:
        pos = 0
        for m in SUTRA_REF.finditer(text):
            nums = [int(x) for x in m.groups() if x is not None]
            seg = re.sub(r'\[[^\]]*\]', ' ', text[pos:m.start()])
            pos = m.end()
            if len(nums) == 3:
                add(nums[0], nums[1], nums[2], seg)
            elif len(nums) == 2:
                add(0, nums[0], nums[1], seg)
            else:
                add(0, 1, nums[0], seg)
    chapters = []
    for (a, p), lines in sorted(groups.items()):
        body = clean_lines('\n'.join(lines), headings=True)
        label = f"{cfg.get('part', '')} {a}, " if a else ''
        chapters.append({'id': f'{bid}-{a}-{p}', 'stabak': a, 'adhyay': p, 'adhyayTo': p,
                         'title': f"{label}{cfg['chapter']} {p}", 'topics': [], 'body': body, 'proofread': False})
    count = sum(len(re.findall(r'॥ [०-९]+ ॥', c['body'])) for c in chapters)
    meta = {'id': bid, 'title': cfg['title'], 'subtitle': f"{cfg['subtitle']} • मूळ संस्कृत • {count} सूत्रे",
            'edition': 'GRETIL संस्कृत e-text, देवनागरीत रूपांतरित', 'note': LICENCE, 'order': cfg['order'],
            'chapterLabel': cfg['chapter']}
    if any(c['stabak'] for c in chapters):
        meta['partLabel'] = cfg['part']
    write(out, bid, meta, chapters)


def write(out, bid, meta, chapters):
    os.makedirs(os.path.join(out, bid), exist_ok=True)
    json.dump(meta, open(os.path.join(out, bid, 'book.json'), 'w', encoding='utf-8'), ensure_ascii=False)
    json.dump(chapters, open(os.path.join(out, f'{bid}.json'), 'w', encoding='utf-8'), ensure_ascii=False)
    print(f"{bid}: {len(chapters)} chapters, {sum(len(c['body']) for c in chapters)} chars – {meta['subtitle']}")


def main(src, out, only):
    def ok(f):
        if os.path.exists(os.path.join(src, f)):
            return True
        print(f'skipped – {f} not found')
        return False

    for bid, cfg in PURANAS.items():
        if (not only or bid in only) and all(ok(f) for f, _ in cfg['files']):
            build_purana(src, out, bid, cfg)
    for bid, cfg in DARSHANAS.items():
        if (not only or bid in only) and ok(cfg['file']):
            build_darshana(src, out, bid, cfg)


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2], set(sys.argv[3:]))
