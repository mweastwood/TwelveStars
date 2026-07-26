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
            "recall_rate": 0.0,
            "missing_verses": [],
            "extra_verses": []
        }
        
    ocr_path = os.path.join(ocr_dir, ocr_files[0])
    cpdv_data = parse_usfm_verses(cpdv_path)
    ocr_data = parse_usfm_verses(ocr_path)
    
    if cpdv_data is None or ocr_data is None:
        return None
        
    total_cpdv_verses = sum(len(v) for v in cpdv_data.values())
    matched_verses = 0
    missing_verses = []
    extra_verses = []

    # Find missing verses (in reference but missing in compiled OCR)
    for ref_ch in sorted(cpdv_data.keys()):
        ref_v_dict = cpdv_data[ref_ch]
        ocr_v_dict = ocr_data.get(ref_ch, {})
        for ref_v in sorted(ref_v_dict.keys()):
            if ref_v in ocr_v_dict:
                matched_verses += 1
            else:
                missing_verses.append((ref_ch, ref_v))

    # Find extra/unmapped verses (in compiled OCR but not in reference)
    for ocr_ch in sorted(ocr_data.keys()):
        ref_v_dict = cpdv_data.get(ocr_ch, {})
        for ocr_v in sorted(ocr_data[ocr_ch].keys()):
            if ocr_v not in ref_v_dict:
                extra_verses.append((ocr_ch, ocr_v))
                    
    recall_rate = (matched_verses / total_cpdv_verses * 100) if total_cpdv_verses > 0 else 0.0
    
    return {
        "book_id": book_id,
        "found_ocr": True,
        "cpdv_verses": total_cpdv_verses,
        "matched_verses": matched_verses,
        "recall_rate": recall_rate,
        "missing_verses": missing_verses,
        "extra_verses": extra_verses
    }

def get_missing_verses(target_book=None):
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    ocr_dir = os.path.join(base_dir, "ocr")
    cpdv_dir = os.path.join(base_dir, "cpdv")
    if not os.path.exists(cpdv_dir):
        cpdv_dir = os.path.join(base_dir, "unam")
        
    books = [target_book] if target_book else sorted(list(set([
        f.split("-")[1] for f in os.listdir(cpdv_dir) if "-" in f and (f.endswith(".usfm") or f.endswith(".sfm"))
    ])))
    
    res_map = {}
    for b in books:
        res = compare_book(b, ocr_dir, cpdv_dir)
        if res and res.get("missing_verses"):
            res_map[b] = res["missing_verses"]
    return res_map

def main():
    parser = argparse.ArgumentParser(description="Compare generated OCR USFM files against reference CPDV/UNAM files and extract missing verses.")
    parser.add_argument("--book", type=str, help="Book ID to compare (e.g. GEN, MAT, PSA, ISA)")
    parser.add_argument("--missing", action="store_true", help="Print specific missing verse numbers for test suite inclusion")
    args = parser.parse_args()
    
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    ocr_dir = os.path.join(base_dir, "ocr")
    
    # Try CPDV directory first, fallback to UNAM reference directory
    cpdv_dir = os.path.abspath(os.path.join(base_dir, "..", "cpdv", "usfm"))
    if not os.path.exists(cpdv_dir):
        cpdv_dir = os.path.join(base_dir, "unam")
    
    cpdv_books = []
    for fname in sorted(os.listdir(cpdv_dir)):
        if fname.endswith(".sfm") or fname.endswith(".usfm"):
            match = re.search(r'^\d+-([A-Z0-9]{3})-', fname)
            if match:
                cpdv_books.append(match.group(1))
                
    target_books = [args.book.upper()] if args.book else cpdv_books
        
    print("==========================================================================================")
    print(f" TORRES AMAT (1836) vs REFERENCE METRICS ({len(target_books)} Books)")
    print("==========================================================================================")
    print(f"{'Book':<6} | {'Ref Verses':<12} | {'OCR Verses':<12} | {'Recall Rate':<12} | {'Missing Count':<14}")
    print("------------------------------------------------------------------------------------------")
    
    total_cpdv_all = 0
    total_matched_all = 0
    all_missing_by_book = {}
    
    for book_id in target_books:
        res = compare_book(book_id, ocr_dir, cpdv_dir)
        if not res or not res['found_ocr']:
            print(f"{book_id:<6} | {'NOT FOUND':<12} | {'-':<12} | {'-':<12} | {'-':<14}")
            continue
            
        total_cpdv_all += res['cpdv_verses']
        total_matched_all += res['matched_verses']
        missing_count = len(res['missing_verses'])
        if missing_count > 0:
            all_missing_by_book[book_id] = res['missing_verses']
        
        print(f"{book_id:<6} | {res['cpdv_verses']:<12d} | {res['matched_verses']:<12d} | {res['recall_rate']:<11.2f}% | {missing_count:<14d}")
        
    print("==========================================================================================")
    if total_cpdv_all > 0:
        overall_recall = (total_matched_all / total_cpdv_all) * 100
        print(f"{'TOTAL':<6} | {total_cpdv_all:<12d} | {total_matched_all:<12d} | {overall_recall:<11.2f}% | {sum(len(m) for m in all_missing_by_book.values()):<14d}")
    print("==========================================================================================")

    if args.missing or args.book:
        print("\n==========================================================================================")
        print(" DETAILED MISSING VERSE BREAKDOWN FOR HUMAN VERIFICATION SUITE")
        print("==========================================================================================")
        if not all_missing_by_book:
            print(" No missing verses found across the target books!")
        else:
            for b_id, missing_list in all_missing_by_book.items():
                print(f"\nBook: {b_id} ({len(missing_list)} missing verses):")
                # Group by chapter
                ch_grouped = {}
                for ch, v in missing_list:
                    ch_grouped.setdefault(ch, []).append(v)
                for ch, vs in sorted(ch_grouped.items()):
                    vs_str = ", ".join(str(v) for v in vs)
                    print(f"  Chapter {ch:2d}: {b_id} {ch}:{vs_str}")

if __name__ == "__main__":
    main()
