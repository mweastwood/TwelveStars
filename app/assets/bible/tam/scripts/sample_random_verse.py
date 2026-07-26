#!/usr/bin/env python3
import os
import sys
import json
import random
import argparse
import re

scripts_dir = os.path.dirname(os.path.abspath(__file__))
base_dir = os.path.dirname(scripts_dir)
ocr_dir = os.path.join(base_dir, "ocr")
raw_dir = os.path.join(base_dir, "raw_ocr")

sys.path.append(scripts_dir)
from compare_cpdv import parse_usfm_verses
from compile_usfm import BIBLE_BOOK_MAP, BOOK_NAMES, clean_text_line, ROMAN_NUMERALS

def get_volume_books(vol: int):
    return [book for book, (v, s, e) in BIBLE_BOOK_MAP.items() if v == vol]

def sample_verse(volume: int = None, target_book: str = None, target_ch: int = None, target_v: int = None):
    if target_book:
        target_book = target_book.upper()
        if target_book not in BIBLE_BOOK_MAP:
            print(f"Error: Book {target_book} not found in Bible map")
            return
        chosen_book = target_book
        vol, start_p, end_p = BIBLE_BOOK_MAP[chosen_book]
    else:
        vol = volume if volume else 1
        vol_books = get_volume_books(vol)
        if not vol_books:
            print(f"Error: No books found for Volume {vol}")
            return
        chosen_book = random.choice(vol_books)
        _, start_p, end_p = BIBLE_BOOK_MAP[chosen_book]

    usfm_files = [f for f in os.listdir(ocr_dir) if f"-{chosen_book}-" in f]
    parsed_verses = parse_usfm_verses(os.path.join(ocr_dir, usfm_files[0])) if usfm_files else {}

    ch = target_ch
    v = target_v
    usfm_verse_text = None

    if parsed_verses:
        if ch is None:
            ch = random.choice(sorted(parsed_verses.keys()))
        if v is None and ch in parsed_verses:
            v_keys = [k for k in sorted(parsed_verses[ch].keys()) if k > 0]
            v = random.choice(v_keys) if v_keys else None
            
        if ch in parsed_verses and v in parsed_verses[ch]:
            usfm_verse_text = parsed_verses[ch][v]

    if ch is None: ch = 1
    if v is None: v = 1

    matched_page = None
    matched_lines = []
    pdf_page_val = None

    if usfm_verse_text:
        words = [w for w in re.findall(r'\b[a-zA-ZÁÉÍÓÚÑáéíóúñ]{5,}\b', usfm_verse_text)]
        for p in range(start_p, end_p + 1):
            fpath = os.path.join(raw_dir, f"vol{vol}_page_{p}.json")
            if not os.path.exists(fpath):
                continue
            with open(fpath) as f:
                data = json.load(f)
            lines = [l for l in data.get("lines", []) if l.get("text")]
            page_text = " ".join(clean_text_line(l["text"]) for l in lines)
            
            matches = [kw for kw in words if kw.lower() in page_text.lower()]
            if len(matches) >= max(2, len(words) // 2):
                matched_page = p
                pdf_page_val = data.get("pdf_page", p + 1)
                matched_lines = [l for l in lines if any(kw.lower() in clean_text_line(l["text"]).lower() for kw in matches)]
                break

    # If verse is missing in compiled USFM or keyword search failed, search raw OCR directly for verse prefix within chapter context
    if not matched_page:
        v_pattern = re.compile(rf'^\s*{v}\s*[\./,;-]')
        ch_pattern = re.compile(rf'\b(C[ÁA]P[IÍLl1]TULO|[PŚS]ALMO)\s+([IVXLCDM0-9]+)\b', re.IGNORECASE)
        active_ch = 0
        
        for p in range(start_p, end_p + 1):
            fpath = os.path.join(raw_dir, f"vol{vol}_page_{p}.json")
            if not os.path.exists(fpath):
                continue
            with open(fpath) as f:
                data = json.load(f)
            lines = [l for l in data.get("lines", []) if l.get("text")]
            
            for idx, l in enumerate(lines):
                txt = l["text"].strip()
                cm = ch_pattern.search(txt)
                if cm:
                    tok = cm.group(2).upper()
                    if tok.isdigit():
                        active_ch = int(tok)
                    elif tok in ROMAN_NUMERALS:
                        active_ch = ROMAN_NUMERALS[tok]
                
                if (active_ch == ch or target_ch is None) and v_pattern.match(txt):
                    matched_page = p
                    pdf_page_val = data.get("pdf_page", p + 1)
                    matched_lines = lines[max(0, idx - 1): min(len(lines), idx + 5)]
                    break
            if matched_page:
                break

    if not matched_page:
        matched_page = start_p
        fpath = os.path.join(raw_dir, f"vol{vol}_page_{start_p}.json")
        if os.path.exists(fpath):
            with open(fpath) as f:
                data = json.load(f)
                pdf_page_val = data.get("pdf_page", start_p + 1)

    print("=" * 80)
    print(f" VERSE SAMPLE (Volume {vol})")
    print("=" * 80)
    print(f"Book:                  {chosen_book} ({BOOK_NAMES.get(chosen_book, chosen_book)})")
    print(f"Passage:               {chosen_book} Chapter {ch}, Verse {v}")
    print(f"PDF READER PAGE #:     PAGE {pdf_page_val} (Enter '{pdf_page_val}' in your PDF Reader)")
    print(f"Raw OCR File:          vol{vol}_page_{matched_page}.json")
    print("-" * 80)
    print(" CURRENT COMPILED USFM OUTPUT:")
    if usfm_verse_text:
        print(f"\\v {v} {usfm_verse_text}")
    else:
        print(f"  [MISSING IN COMPILED USFM: Verse {ch}:{v} was not extracted during compilation]")
    print("-" * 80)
    print(f" RAW OCR LINES (from vol{vol}_page_{matched_page}.json):")
    if matched_lines:
        for l in matched_lines[:6]:
            box = l.get("box", [])
            txt = clean_text_line(l.get("text", ""))
            print(f"  box={box}: {txt!r}")
    else:
        print(f"  (See raw_ocr file vol{vol}_page_{matched_page}.json)")
    print("=" * 80)

def main():
    parser = argparse.ArgumentParser(description="Sample a specific or random verse from a volume/book and show PDF reader page number & raw OCR output.")
    parser.add_argument("--volume", type=int, default=None, choices=[1, 2, 3, 4], help="Volume number (1-4)")
    parser.add_argument("--book", type=str, default=None, help="Book ID (e.g. GEN, DEU, PSA, ISA)")
    parser.add_argument("--chapter", "-c", type=int, default=None, help="Chapter number (e.g. 5)")
    parser.add_argument("--verse", "-v", type=int, default=None, help="Verse number (e.g. 18)")
    args = parser.parse_args()

    sample_verse(volume=args.volume, target_book=args.book, target_ch=args.chapter, target_v=args.verse)

if __name__ == "__main__":
    main()
