#!/usr/bin/env python3
import urllib.request
import re
import html
import os
import sys

BOOKS = [
    (1, 'GEN', 'Genesis', 'OT-01_Genesis.htm'),
    (2, 'EXO', 'Exodus', 'OT-02_Exodus.htm'),
    (3, 'LEV', 'Leviticus', 'OT-03_Leviticus.htm'),
    (4, 'NUM', 'Numbers', 'OT-04_Numbers.htm'),
    (5, 'DEU', 'Deuteronomy', 'OT-05_Deuteronomy.htm'),
    (6, 'JOS', 'Joshua', 'OT-06_Joshua.htm'),
    (7, 'JDG', 'Judges', 'OT-07_Judges.htm'),
    (8, 'RUT', 'Ruth', 'OT-08_Ruth.htm'),
    (9, '1SA', '1 Samuel', 'OT-09_1-Samuel.htm'),
    (10, '2SA', '2 Samuel', 'OT-10_2-Samuel.htm'),
    (11, '1KI', '1 Kings', 'OT-11_1-Kings.htm'),
    (12, '2KI', '2 Kings', 'OT-12_2-Kings.htm'),
    (13, '1CH', '1 Chronicles', 'OT-13_1-Chronicles.htm'),
    (14, '2CH', '2 Chronicles', 'OT-14_2-Chronicles.htm'),
    (15, 'EZR', 'Ezra', 'OT-15_Ezra.htm'),
    (16, 'NEH', 'Nehemiah', 'OT-16_Nehemiah.htm'),
    (17, 'TOB', 'Tobit', 'OT-17_Tobit.htm'),
    (18, 'JDT', 'Judith', 'OT-18_Judith.htm'),
    (19, 'EST', 'Esther', 'OT-19_Esther.htm'),
    (20, 'JOB', 'Job', 'OT-20_Job.htm'),
    (21, 'PSA', 'Psalms', 'OT-21_Psalms.htm'),
    (22, 'PRO', 'Proverbs', 'OT-22_Proverbs.htm'),
    (23, 'ECC', 'Ecclesiastes', 'OT-23_Ecclesiastes.htm'),
    (24, 'SNG', 'Canticle of Canticles', 'OT-24_Song2.htm'),
    (25, 'WIS', 'Wisdom', 'OT-25_Wisdom.htm'),
    (26, 'SIR', 'Sirach', 'OT-26_Sirach.htm'),
    (27, 'ISA', 'Isaiah', 'OT-27_Isaiah.htm'),
    (28, 'JER', 'Jeremiah', 'OT-28_Jeremiah.htm'),
    (29, 'LAM', 'Lamentations', 'OT-29_Lamentations.htm'),
    (30, 'BAR', 'Baruch', 'OT-30_Baruch.htm'),
    (31, 'EZK', 'Ezekiel', 'OT-31_Ezekiel.htm'),
    (32, 'DAN', 'Daniel', 'OT-32_Daniel.htm'),
    (33, 'HOS', 'Hosea', 'OT-33_Hosea.htm'),
    (34, 'JOL', 'Joel', 'OT-34_Joel.htm'),
    (35, 'AMO', 'Amos', 'OT-35_Amos.htm'),
    (36, 'OBA', 'Obadiah', 'OT-36_Obadiah.htm'),
    (37, 'JON', 'Jonah', 'OT-37_Jonah.htm'),
    (38, 'MIC', 'Micah', 'OT-38_Micah.htm'),
    (39, 'NAM', 'Nahum', 'OT-39_Nahum.htm'),
    (40, 'HAB', 'Habakkuk', 'OT-40_Habakkuk.htm'),
    (41, 'ZEP', 'Zephaniah', 'OT-41_Zephaniah.htm'),
    (42, 'HAG', 'Haggai', 'OT-42_Haggai.htm'),
    (43, 'ZEC', 'Zechariah', 'OT-43_Zechariah.htm'),
    (44, 'MAL', 'Malachi', 'OT-44_Malachi.htm'),
    (45, '1MA', '1 Maccabees', 'OT-45_1-Maccabees.htm'),
    (46, '2MA', '2 Maccabees', 'OT-46_2-Maccabees.htm'),
    (49, 'MAT', 'Matthew', 'NT-01_Matthew.htm'),
    (50, 'MRK', 'Mark', 'NT-02_Mark.htm'),
    (51, 'LUK', 'Luke', 'NT-03_Luke.htm'),
    (52, 'JHN', 'John', 'NT-04_John.htm'),
    (53, 'ACT', 'Acts', 'NT-05_Acts.htm'),
    (54, 'ROM', 'Romans', 'NT-06_Romans.htm'),
    (55, '1CO', '1 Corinthians', 'NT-07_1-Corinthians.htm'),
    (56, '2CO', '2 Corinthians', 'NT-08_2-Corinthians.htm'),
    (57, 'GAL', 'Galatians', 'NT-09_Galatians.htm'),
    (58, 'EPH', 'Ephesians', 'NT-10_Ephesians.htm'),
    (59, 'PHP', 'Philippians', 'NT-11_Philippians.htm'),
    (60, 'COL', 'Colossians', 'NT-12_Colossians.htm'),
    (61, '1TH', '1 Thessalonians', 'NT-13_1-Thessalonians.htm'),
    (62, '2TH', '2 Thessalonians', 'NT-14_2-Thessalonians.htm'),
    (64, '1TI', '1 Timothy', 'NT-15_1-Timothy.htm'),
    (65, '2TI', '2 Timothy', 'NT-16_2-Timothy.htm'),
    (66, 'TIT', 'Titus', 'NT-17_Titus.htm'),
    (67, 'PHM', 'Philemon', 'NT-18_Philemon.htm'),
    (68, 'HEB', 'Hebrews', 'NT-19_Hebrews.htm'),
    (69, 'JAM', 'James', 'NT-20_James.htm'),
    (70, '1PE', '1 Peter', 'NT-21_1-Peter.htm'),
    (71, '2PE', '2 Peter', 'NT-22_2-Peter.htm'),
    (72, '1JN', '1 John', 'NT-23_1-John.htm'),
    (73, '2JN', '2 John', 'NT-24_2-John.htm'),
    (74, '3JN', '3 John', 'NT-25_3-John.htm'),
    (75, 'JUD', 'Jude', 'NT-26_Jude.htm'),
    (76, 'REV', 'Revelation', 'NT-27_Revelation.htm')
]

OUTPUT_DIR = os.path.abspath('app/assets/bible/cpdv2025/usfm')

def clean_verse_text(chunk, is_song=False):
    # Remove chapter anchors like [<A NAME=...>]
    chunk = re.sub(r'\[<A\s+NAME=[^>]+>.*?\]', '', chunk, flags=re.S)
    
    # In Song of Songs, convert <I>Speaker:</I> to \it Speaker:\it*
    if is_song:
        chunk = re.sub(r'<I>(.*?)</I>', r'\\it \1\\it* ', chunk, flags=re.I)

    # Remove all other HTML tags
    chunk = re.sub(r'<[^>]+>', ' ', chunk)
    
    # Unescape HTML entities
    chunk = html.unescape(chunk)
    
    # Strip leading/trailing whitespace and collapse internal whitespace
    chunk = re.sub(r'\s+', ' ', chunk).strip()
    return chunk

def generate_book(bnum, abbrev, bname, fname):
    url = f'https://www.sacredbible.org/catholic/{fname}'
    raw = urllib.request.urlopen(url, timeout=30).read().decode("cp1252")
    
    matches = list(re.finditer(r'\{(\d+):(\d+)\}', raw))
    if not matches:
        raise ValueError(f'No verses found for {bname} in {fname}')
    
    chapters = {}
    is_song = (abbrev == 'SNG')
    
    for i, m in enumerate(matches):
        start = m.end()
        end = matches[i+1].start() if i+1 < len(matches) else len(raw)
        chunk = raw[start:end]
        
        # If last verse, trim trailing navigation/footer text
        if i == len(matches) - 1:
            chunk = chunk.split('The Sacred Bible')[0]
            chunk = chunk.split('<!--')[0]
        
        c = int(m.group(1))
        v = int(m.group(2))
        text = clean_verse_text(chunk, is_song=is_song)
        if not text:
            raise ValueError(f'Empty verse text for {bname} {c}:{v}')
        
        if c not in chapters:
            chapters[c] = []
        chapters[c].append((v, text))
    
    num_str = f'{bnum:02d}'
    lines = [
        f'\\id {abbrev} ENG (usfm) - CPDV 2025 The Sacred Bible: Catholic Public Domain Version (2025 Edition) ☩',
        '\\ide UTF-8',
        f'\\h {bname}',
        f'\\toc1 The Book of {bname}',
        f'\\toc2 {bname}',
        f'\\toc3 {abbrev}',
        f'\\mt1 {bname}'
    ]
    
    for c in sorted(chapters.keys()):
        lines.append(f'\\c {c}')
        lines.append(f'\\cl {bname} {c}')
        lines.append('\\p')
        for v, text in chapters[c]:
            lines.append(f'\\v {v} {text}')
    
    usfm_content = '\n'.join(lines) + '\n'
    out_path = os.path.join(OUTPUT_DIR, f'{num_str}-{abbrev}-ENG[B]CPDV2025[pd].usfm')
    with open(out_path, 'w', encoding='utf-8') as f:
        f.write(usfm_content)
    
    total_verses = sum(len(vlist) for vlist in chapters.values())
    return len(chapters), total_verses

def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    print(f'Generating CPDV 2025 USFM files in {OUTPUT_DIR}...')
    total_all_verses = 0
    
    for bnum, abbrev, bname, fname in BOOKS:
        ch_count, v_count = generate_book(bnum, abbrev, bname, fname)
        total_all_verses += v_count
        print(f'[{bnum:02d}] {abbrev:5} {bname:25}: {ch_count:3} chapters, {v_count:4} verses')
    
    print(f'\nFinished generating all 73 books for CPDV 2025! Total verses: {total_all_verses}')

if __name__ == '__main__':
    main()
