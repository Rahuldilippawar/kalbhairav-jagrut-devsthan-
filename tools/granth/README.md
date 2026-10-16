# Granths for Guru Gyan

Katha-Kalpataru (purvardha, stabak 1–7; 1910 Marathi prose edition,
public domain) for approved shishyas.

1. **OCR** – Actions → "OCR a scanned book" downloads the Wikimedia Commons
   scan and publishes `book-part-*.txt` to a pre-release (`ocr-N`).
2. **Split** – `cat book-part-*.txt > book.txt`, then
   `python3 tools/granth/parse_kathakalpataru.py book.txt data/granth/kathakalpataru.json`.
   `titles.json` fixes OCR-garbled chapter titles.
3. **Proofread** – put a corrected chapter in `proofread/<chapter id>.md`
   (first line `# title`, then the text; `## ` for sub-headings) and run
   step 2 again; the app marks it "शुद्ध".
4. **Hand-entered books** (e.g. मूळस्तंभ) – one `data/granth/<book>/aNN.md` per adhyay plus `book.json`; run `python3 tools/granth/build_md_book.py <book>`.
5. **Import** – Actions → "Import granth to Firestore" writes
   `granth/kathakalpataru` (chapter list) and `granth_text/<id>` (texts).
