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
from compile_usfm import BIBLE_BOOK_MAP, BOOK_NAMES, clean_text_line

# PDF page offsets due to cover pages / title flyleafs in each volume PDF
PDF_PAGE_OFFSETS = {
    1: 2,  # PDF Page = raw_ocr page index + 2
    2: 2,  # PDF Page = raw_ocr page index + 2
    3: 2,  # PDF Page = raw_ocr page index + 2
    4: 2,  # PDF Page = raw_ocr page index + 2
}

def get_volume_books(vol: int):
    return [book for book, (v, s, e) in BIBLE_BOOK_MAP.items() if v == vol]

def sample_verse(volume: int = 1, target_book: str = None):
    vol_books = get_volume_books(volume)
    if not vol_books:
        print(f"Error: No books found for Volume {volume}")
        return

    if target_book:
        target_book = target_book.upper()
        if target_book not in vol_books:
            print(f"Error: Book {target_book} is not in Volume {volume} (Books in Volume {volume}: {', '.join(vol_books)})")
            return
        chosen_book = target_book
    else:
        chosen_book = random.choice(vol_books)

    vol, start_p, end_p = BIBLE_BOOK_MAP[chosen_book]

    usfm_files = [f for f in os.listdir(ocr_dir) if f"-{chosen_book}-" in f]
    if not usfm_files:
        print(f"Error: USFM file for {chosen_book} not found in {ocr_dir}")
        return

    usfm_path = os.path.join(ocr_dir, usfm_files[0])
    parsed_verses = parse_usfm_verses(usfm_path)

    if not parsed_verses:
        print(f"Error: Could not parse verses from {usfm_path}")
        return

    ch = random.choice(sorted(parsed_verses.keys()))
    if not parsed_verses[ch]:
        print(f"Error: No verses found in chapter {ch} of {chosen_book}")
        return
    v = random.choice(sorted(parsed_verses[ch].keys()))
    usfm_verse_text = parsed_verses[ch][v]

    words = [w for w in re.findall(r'\b[a-zA-ZÁÉÍÓÚÑáéíóúñ]{4,}\b', usfm_verse_text)]
    key_words = words[:3] if len(words) >= 3 else words

    matched_page = None
    matched_lines = []

    for p in range(start_p, end_p + 1):
        fpath = os.path.join(raw_dir, f"vol{volume}_page_{p}.json")
        if not os.path.exists(fpath):
            continue
        with open(fpath) as f:
            data = json.load(f)
        lines = [l for l in data.get("lines", []) if l.get("text")]
        page_text = " ".join(clean_text_line(l["text"]) for l in lines)
        
        matches = [kw for kw in key_words if kw.lower() in page_text.lower()]
        if len(matches) >= max(1, len(key_words) // 2) or f"{v}." in page_text:
            matched_page = p
            for l in lines:
                txt = clean_text_line(l["text"])
                if any(kw.lower() in txt.lower() for kw in key_words) or f"{v}." in txt:
                    matched_lines.append(l)
            break

    if not matched_page:
        matched_page = start_p

    pdf_offset = PDF_PAGE_OFFSETS.get(volume, 2)
    pdf_reader_page = matched_page + pdf_offset

    print("=" * 80)
    print(f" RANDOM VERSE SAMPLE (Volume {volume})")
    print("=" * 80)
    print(f"Book:                  {chosen_book} ({BOOK_NAMES.get(chosen_book, chosen_book)})")
    print(f"Passage:               {chosen_book} Chapter {ch}, Verse {v}")
    print(f"PDF Reader Page #:     PAGE {pdf_reader_page} (Enter '{pdf_reader_page}' in your PDF Reader)")
    print(f"Raw OCR File:          vol{volume}_page_{matched_page}.json")
    print("-" * 80)
    print(" CURRENT COMPILED USFM OUTPUT:")
    print(f"\\v {v} {usfm_verse_text}")
    print("-" * 80)
    print(f" RAW OCR LINES (from vol{volume}_page_{matched_page}.json):")
    if matched_lines:
        for l in matched_lines[:8]:
            box = l.get("box", [])
            txt = clean_text_line(l.get("text", ""))
            print(f"  box={box}: {txt!r}")
    else:
        print(f"  (See full page JSON at vol{volume}_page_{matched_page}.json)")
    print("=" * 80)

def main():
    parser = argparse.ArgumentParser(description="Sample a random verse from a volume and show PDF reader page & raw OCR output.")
    parser.add_argument("--volume", type=int, default=1, choices=[1, 2, 3, 4], help="Volume number (1-4)")
    parser.add_argument("--book", type=str, default=None, help="Book ID (e.g. GEN, DEU, PSA, MAT)")
    args = parser.parse_args()

    sample_verse(volume=args.volume, target_book=args.book)

if __name__ == "__main__":
    main()
