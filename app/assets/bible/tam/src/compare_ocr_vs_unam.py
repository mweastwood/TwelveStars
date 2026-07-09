import os
import re

OCR_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "parsed")
UNAM_DIR = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "usfm"))

MAP_UNAM_TO_OCR = {
    "OBA": "OBD",
    "NAM": "NAH",
    "EPH": "EFS",
    "JAM": "JAS",
}

def parse_usfm_verses(filepath):
    verses = {}
    current_chapter = None
    if not os.path.exists(filepath):
        return verses
        
    with open(filepath, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line.startswith("\\c "):
                try:
                    current_chapter = int(line.split()[1])
                    verses[current_chapter] = {}
                except:
                    pass
            elif line.startswith("\\v ") and current_chapter is not None:
                parts = line.split(maxsplit=2)
                if len(parts) >= 2:
                    v_str = parts[1]
                    # Parse verse number, handle ranges like 1-2
                    v_match = re.match(r'^(\d+)', v_str)
                    if v_match:
                        v_num = int(v_match.group(1))
                        v_text = parts[2] if len(parts) > 2 else ""
                        verses[current_chapter][v_num] = v_text
    return verses

def compare_books():
    # Find all UNAM files
    unam_files = sorted(os.listdir(UNAM_DIR))
    
    total_unam_verses = 0
    total_ocr_verses = 0
    matched_verses = 0
    mismatched_text_count = 0
    
    results = []
    
    for u_file in unam_files:
        if not u_file.endswith(".usfm"):
            continue
            
        # Extract the USFM book code (e.g. 01-GEN-SPA... -> GEN)
        parts = u_file.split("-")
        if len(parts) < 2:
            continue
        book_code = parts[1]
        
        ocr_code = MAP_UNAM_TO_OCR.get(book_code, book_code)
        ocr_file = f"{ocr_code}.usfm"
        ocr_path = os.path.join(OCR_DIR, ocr_file)
        unam_path = os.path.join(UNAM_DIR, u_file)
        
        if not os.path.exists(ocr_path):
            print(f"Book {book_code}: OCR file does not exist!")
            continue
            
        unam_verses = parse_usfm_verses(unam_path)
        ocr_verses = parse_usfm_verses(ocr_path)
        
        book_unam_count = sum(len(unam_verses[ch]) for ch in unam_verses)
        book_ocr_count = sum(len(ocr_verses[ch]) for ch in ocr_verses)
        
        total_unam_verses += book_unam_count
        total_ocr_verses += book_ocr_count
        
        book_matched = 0
        book_mismatched = 0
        
        for ch in unam_verses:
            if ch not in ocr_verses:
                continue
            for v in unam_verses[ch]:
                if v in ocr_verses[ch]:
                    book_matched += 1
                    # Basic word token comparison to see if the text is close
                    u_words = set(re.findall(r'\w+', unam_verses[ch][v].lower()))
                    o_words = set(re.findall(r'\w+', ocr_verses[ch][v].lower()))
                    if u_words and o_words:
                        overlap = len(u_words.intersection(o_words)) / max(len(u_words), len(o_words))
                        if overlap < 0.3: # less than 30% overlap means likely wrong verse text
                            book_mismatched += 1
                            
        matched_verses += book_matched
        mismatched_text_count += book_mismatched
        
        pct = (book_ocr_count / book_unam_count * 100) if book_unam_count > 0 else 0
        print(f"{book_code:<5} | UNAM Verses: {book_unam_count:<5} | OCR Verses: {book_ocr_count:<5} | Match: {pct:6.2f}% | Text mismatch: {book_mismatched}")
        results.append((book_code, book_unam_count, book_ocr_count, pct, book_mismatched))
        
    print("\n" + "="*50)
    print(f"Total UNAM verses across 66 books: {total_unam_verses}")
    print(f"Total OCR verses across 66 books:  {total_ocr_verses}")
    print(f"Verse Match Rate (presence):       {(matched_verses / total_unam_verses * 100):.2f}%")
    print(f"Text Match Rate (similarity >30%): {((matched_verses - mismatched_text_count) / total_unam_verses * 100):.2f}%")
    print("="*50)

if __name__ == "__main__":
    compare_books()
