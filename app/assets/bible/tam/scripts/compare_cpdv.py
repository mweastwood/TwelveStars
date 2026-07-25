import os
import sys
import re
import argparse
import unicodedata
from difflib import SequenceMatcher

def clean_text(text):
    text = "".join(c for c in unicodedata.normalize('NFD', text) if unicodedata.category(c) != 'Mn')
    text = text.lower()
    text = re.sub(r'[^\w\s]', '', text)
    return " ".join(text.split())

def parse_usfm_verses(usfm_path):
    verses = {}
    current_chapter = 0
    if not os.path.exists(usfm_path):
        return None
    with open(usfm_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line.startswith(r"\c "):
                parts = line.split()
                if len(parts) >= 2 and parts[1].isdigit():
                    current_chapter = int(parts[1])
                    verses[current_chapter] = {}
            elif line.startswith(r"\v ") and current_chapter > 0:
                parts = line.split(maxsplit=2)
                if len(parts) >= 3 and parts[1].isdigit():
                    v_num = int(parts[1])
                    v_text = parts[2].strip()
                    verses[current_chapter][v_num] = v_text
    return verses

def compare_book(book_id, ocr_dir, cpdv_dir, verbose=False):
    ocr_files = [f for f in os.listdir(ocr_dir) if f"-{book_id}-" in f and f.endswith(".usfm")]
    cpdv_files = [f for f in os.listdir(cpdv_dir) if f"-{book_id}-" in f and (f.endswith(".usfm") or f.endswith(".sfm"))]
    
    if not cpdv_files:
        return None
        
    cpdv_path = os.path.join(cpdv_dir, cpdv_files[0])
    if not ocr_files:
        return {
            "book_id": book_id,
            "found_ocr": False,
            "cpdv_verses": 0,
            "matched_verses": 0,
            "recall_rate": 0.0
        }
        
    ocr_path = os.path.join(ocr_dir, ocr_files[0])
    cpdv_data = parse_usfm_verses(cpdv_path)
    ocr_data = parse_usfm_verses(ocr_path)
    
    if cpdv_data is None or ocr_data is None:
        return None
        
    total_cpdv_verses = sum(len(v) for v in cpdv_data.values())
    matched_verses = 0
    
    for ocr_ch, ocr_v_dict in ocr_data.items():
        cpdv_ch_data = cpdv_data.get(ocr_ch, {})
        for v in ocr_v_dict:
            if v in cpdv_ch_data:
                matched_verses += 1
                    
    recall_rate = (matched_verses / total_cpdv_verses * 100) if total_cpdv_verses > 0 else 0.0
    
    return {
        "book_id": book_id,
        "found_ocr": True,
        "cpdv_verses": total_cpdv_verses,
        "matched_verses": matched_verses,
        "recall_rate": recall_rate
    }

def main():
    parser = argparse.ArgumentParser(description="Compare generated OCR USFM files against reference CPDV (Latin Vulgate) files.")
    parser.add_argument("--book", type=str, help="Book ID to compare (e.g. GEN, MAT, PSA)")
    args = parser.parse_args()
    
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    ocr_dir = os.path.join(base_dir, "ocr")
    cpdv_dir = os.path.abspath(os.path.join(base_dir, "..", "cpdv", "usfm"))
    
    cpdv_books = []
    for fname in sorted(os.listdir(cpdv_dir)):
        if fname.endswith(".sfm") or fname.endswith(".usfm"):
            match = re.search(r'^\d+-([A-Z0-9]{3})-', fname)
            if match:
                cpdv_books.append(match.group(1))
                
    target_books = [args.book.upper()] if args.book else cpdv_books
        
    print("==========================================================================================")
    print(f" TORRES AMAT (1836) vs CPDV (LATIN VULGATE) METRICS ({len(target_books)} Books)")
    print("==========================================================================================")
    print(f"{'Book':<6} | {'CPDV Verses':<12} | {'OCR Verses':<12} | {'Recall Rate':<12}")
    print("------------------------------------------------------------------------------------------")
    
    total_cpdv_all = 0
    total_matched_all = 0
    
    for book_id in target_books:
        res = compare_book(book_id, ocr_dir, cpdv_dir)
        if not res or not res['found_ocr']:
            print(f"{book_id:<6} | {'NOT FOUND':<12} | {'-':<12} | {'-':<12}")
            continue
            
        total_cpdv_all += res['cpdv_verses']
        total_matched_all += res['matched_verses']
        
        print(f"{book_id:<6} | {res['cpdv_verses']:<12d} | {res['matched_verses']:<12d} | {res['recall_rate']:<11.2f}%")
        
    print("==========================================================================================")
    if total_cpdv_all > 0:
        overall_recall = (total_matched_all / total_cpdv_all) * 100
        print(f"{'TOTAL':<6} | {total_cpdv_all:<12d} | {total_matched_all:<12d} | {overall_recall:<11.2f}%")
    print("==========================================================================================")

if __name__ == "__main__":
    main()
