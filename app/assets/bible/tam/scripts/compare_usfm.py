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

def compare_book(book_id, ocr_dir, unam_dir, verbose=False):
    # Locate files
    ocr_files = [f for f in os.listdir(ocr_dir) if f"-{book_id}-" in f and f.endswith(".usfm")]
    unam_files = [f for f in os.listdir(unam_dir) if f"-{book_id}-" in f and f.endswith(".usfm")]
    
    if not unam_files:
        return None
        
    unam_path = os.path.join(unam_dir, unam_files[0])
    if not ocr_files:
        return {
            "book_id": book_id,
            "found_ocr": False,
            "unam_verses": 0,
            "matched_verses": 0,
            "word_sim": 0.0,
            "char_sim": 0.0
        }
        
    ocr_path = os.path.join(ocr_dir, ocr_files[0])
    
    unam_data = parse_usfm_verses(unam_path)
    ocr_data = parse_usfm_verses(ocr_path)
    
    if unam_data is None or ocr_data is None:
        return None
        
    total_unam_verses = 0
    matched_verses = 0
    word_sim_sum = 0.0
    char_sim_sum = 0.0
    
    for ch in sorted(unam_data.keys()):
        unam_ch = unam_data[ch]
        ocr_ch = ocr_data.get(ch, {})
        
        for v in sorted(unam_ch.keys()):
            total_unam_verses += 1
            unam_txt = unam_ch[v]
            
            if v in ocr_ch:
                matched_verses += 1
                ocr_txt = ocr_ch[v]
                
                # Word-level similarity
                unam_words = clean_text(unam_txt).split()
                ocr_words = clean_text(ocr_txt).split()
                
                if unam_words and ocr_words:
                    w_overlap = set(unam_words) & set(ocr_words)
                    w_sim = len(w_overlap) / max(len(unam_words), len(ocr_words))
                else:
                    w_sim = 0.0
                    
                # Character-level similarity
                c_sim = SequenceMatcher(None, clean_text(unam_txt), clean_text(ocr_txt)).ratio()
                
                word_sim_sum += w_sim
                char_sim_sum += c_sim
                
                if verbose:
                    print(f"  [{book_id}] Ch {ch:2d}:{v:2d} | Word Sim: {w_sim*100:5.1f}% | Char Sim: {c_sim*100:5.1f}%")
            else:
                if verbose:
                    print(f"  [{book_id}] Ch {ch:2d}:{v:2d} | MISSING")
                    
    word_sim_avg = (word_sim_sum / total_unam_verses * 100) if total_unam_verses > 0 else 0.0
    char_sim_avg = (char_sim_sum / total_unam_verses * 100) if total_unam_verses > 0 else 0.0
    recall_rate = (matched_verses / total_unam_verses * 100) if total_unam_verses > 0 else 0.0
    
    return {
        "book_id": book_id,
        "found_ocr": True,
        "unam_verses": total_unam_verses,
        "matched_verses": matched_verses,
        "recall_rate": recall_rate,
        "word_sim": word_sim_avg,
        "char_sim": char_sim_avg
    }

def main():
    parser = argparse.ArgumentParser(description="Compare generated OCR USFM files against reference UNAM files.")
    parser.add_argument("--book", type=str, help="Book ID to compare (e.g. GEN, MAT, PSA)")
    parser.add_argument("--verbose", action="store_true", help="Print detailed verse-level output")
    args = parser.parse_args()
    
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    ocr_dir = os.path.join(base_dir, "ocr")
    unam_dir = os.path.join(base_dir, "unam")
    
    # Gather all available UNAM books
    unam_books = []
    for fname in sorted(os.listdir(unam_dir)):
        if fname.endswith(".usfm"):
            match = re.search(r'^\d+-([A-Z0-9]{3})-', fname)
            if match:
                unam_books.append(match.group(1))
                
    if args.book:
        target_books = [args.book.upper()]
    else:
        target_books = unam_books
        
    print("==========================================================================================")
    print(f" TORRES AMAT (1836) vs UNAM ACCURACY COMPARISON METRICS ({len(target_books)} Books)")
    print("==========================================================================================")
    print(f"{'Book':<6} | {'UNAM Verses':<12} | {'OCR Verses':<12} | {'Recall Rate':<12} | {'Word Sim':<10} | {'Char Sim':<10}")
    print("------------------------------------------------------------------------------------------")
    
    total_unam_all = 0
    total_matched_all = 0
    word_sim_weighted_sum = 0.0
    char_sim_weighted_sum = 0.0
    
    for book_id in target_books:
        res = compare_book(book_id, ocr_dir, unam_dir, verbose=args.verbose)
        if not res or not res['found_ocr']:
            print(f"{book_id:<6} | {'NOT FOUND':<12} | {'-':<12} | {'-':<12} | {'-':<10} | {'-':<10}")
            continue
            
        total_unam_all += res['unam_verses']
        total_matched_all += res['matched_verses']
        word_sim_weighted_sum += (res['word_sim'] * res['unam_verses'])
        char_sim_weighted_sum += (res['char_sim'] * res['unam_verses'])
        
        print(f"{book_id:<6} | {res['unam_verses']:<12d} | {res['matched_verses']:<12d} | {res['recall_rate']:<11.2f}% | {res['word_sim']:<9.2f}% | {res['char_sim']:<9.2f}%")
        
    print("==========================================================================================")
    if total_unam_all > 0:
        overall_recall = (total_matched_all / total_unam_all) * 100
        overall_word_sim = word_sim_weighted_sum / total_unam_all
        overall_char_sim = char_sim_weighted_sum / total_unam_all
        print(f"{'TOTAL':<6} | {total_unam_all:<12d} | {total_matched_all:<12d} | {overall_recall:<11.2f}% | {overall_word_sim:<9.2f}% | {overall_char_sim:<9.2f}%")
    print("==========================================================================================")

if __name__ == "__main__":
    main()
