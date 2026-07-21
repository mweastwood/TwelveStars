import os
import sys
import re
import unicodedata
from paddleocr import PaddleOCR

# Disable MKLDNN to prevent compilation issues
os.environ["FLAGS_use_mkldnn"] = "0"
os.environ["PADDLE_PDX_ENABLE_MKLDNN_BYDEFAULT"] = "0"

def clean_text(text):
    # Normalize text to remove weird characters, double spaces, and lowercase it for comparison
    text = "".join(c for c in unicodedata.normalize('NFD', text) if unicodedata.category(c) != 'Mn')
    text = text.lower()
    # Replace common OCR misreadings or punctuation
    text = re.sub(r'[^\w\s]', '', text)
    return " ".join(text.split())

def parse_unam_genesis(usfm_path):
    print(f"Parsing UNAM USFM file: {usfm_path}")
    verses = {}
    current_chapter = 0
    
    with open(usfm_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line.startswith(r"\c "):
                current_chapter = int(line.split()[1])
                verses[current_chapter] = {}
            elif line.startswith(r"\v ") and current_chapter in [1, 2]:
                parts = line.split(maxsplit=2)
                if len(parts) >= 3:
                    v_num = int(parts[1])
                    v_text = parts[2]
                    verses[current_chapter][v_num] = v_text
    return verses

def parse_ocr_text_to_verses(pages_results):
    print("Parsing OCR output into structured chapters/verses...")
    ocr_verses = {1: {}, 2: {}}
    current_chapter = 1
    current_verse = 0
    
    for page_idx, page_result in enumerate(pages_results):
        if not page_result or 'rec_texts' not in page_result:
            continue
            
        texts = page_result['rec_texts']
        boxes = page_result['rec_boxes']
        
        # Gather lines with coordinates
        lines = []
        for i in range(len(texts)):
            text = texts[i]
            box = boxes[i]
            try:
                x, y = int(box[0]), int(box[1])
            except:
                x, y = 0, 0
            lines.append({'text': text, 'x': x, 'y': y})
            
        # Filter:
        # Discard headers (Y < 500 on page 3, but page 1 and 2 might have different header locations)
        # However, let's keep it simple:
        # - Discard footnotes (Y >= 1120)
        # - If page is 1 (which contains the intro to Genesis), ignore intro lines.
        # Actually, in the test PDF:
        # Page 1 is the introduction (Advertencia)
        # Page 2 is more introduction
        # Page 3 is Genesis 1 start
        # Wait, if page_idx is 0 or 1, is it part of Genesis 1?
        # Let's check: our prepare_test_pages.py extracted 3 pages starting from PDF Page 17 (Genesis 1:1 start).
        # So:
        # - page_idx 0 in the test PDF is PDF Page 17 (Genesis 1:1 to 1:24)
        # - page_idx 1 in the test PDF is PDF Page 18 (Genesis 1:25 to 2:9)
        # - page_idx 2 in the test PDF is PDF Page 19 (Genesis 2:10 to 2:25)
        # Excellent! So all three pages are scripture pages!
        
        # Discard page headers (Y < 150) and footnotes (Y >= 1120)
        scripture_lines = [l for l in lines if 150 <= l['y'] < 1120]
        
        # Separate columns (Left: X < 400, Right: X >= 400)
        left_column = [l for l in scripture_lines if l['x'] < 400]
        right_column = [l for l in scripture_lines if l['x'] >= 400]
        
        # Sort each column vertically
        left_column.sort(key=lambda l: l['y'])
        right_column.sort(key=lambda l: l['y'])
        
        # Process left column then right column
        ordered_lines = left_column + right_column
        
        for line in ordered_lines:
            text = line['text'].strip()
            if not text:
                continue
                
            # Check for chapter header
            # Matches: CAPITULO PRIMERO, CAPITULO SEGUNDO, CAPITULO II, etc.
            if "CAPITULO" in text.upper() or "CAPÍTULO" in text.upper():
                text_upper = text.upper()
                if "SEGUNDO" in text_upper or " II" in text_upper:
                    current_chapter = 2
                    current_verse = 0
                elif "PRIMERO" in text_upper or " I" in text_upper:
                    current_chapter = 1
                    current_verse = 0
                continue
                
            # Check for verse number start
            # Matches lines starting with "1. ", "12. ", "19.-", etc.
            verse_match = re.match(r'^(\d+)\s*[\./,;-]*\s+(.*)', text)
            if verse_match:
                v_num = int(verse_match.group(1))
                v_text = verse_match.group(2).strip()
                current_verse = v_num
                
                if current_chapter in ocr_verses:
                    ocr_verses[current_chapter][current_verse] = v_text
            else:
                # Continuation text of the active verse
                if current_chapter in ocr_verses and current_verse in ocr_verses[current_chapter]:
                    # Filter out page/volume headers that might be interleaved
                    if not text.isdigit() and "—" not in text:
                        ocr_verses[current_chapter][current_verse] += " " + text
                        
    return ocr_verses

def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    test_pdf = os.path.join(base_dir, "pdf", "genesis_ch1_test.pdf")
    unam_path = os.path.join(base_dir, "usfm", "01-GEN-SPA[B]TAM1836[pd].usfm")
    
    if not os.path.exists(test_pdf):
        print(f"Error: {test_pdf} not found. Run prepare_test_pages.py first.")
        sys.exit(1)
        
    # Parse UNAM Database
    unam_verses = parse_unam_genesis(unam_path)
    
    # Run PaddleOCR
    print(f"Initializing PaddleOCR...")
    ocr = PaddleOCR(use_textline_orientation=True, lang="es", enable_mkldnn=False)
    print(f"Running OCR on {test_pdf}...")
    pages_results = ocr.ocr(test_pdf)
    
    # Parse OCR to Verses
    ocr_verses = parse_ocr_text_to_verses(pages_results)
    
    # Perform Comparison
    print("\n--- COMPARISON METRICS (GENESIS 1 & 2) ---")
    total_unam_count = 0
    matched_count = 0
    similarity_sum = 0.0
    
    for ch in [1, 2]:
        print(f"\nChapter {ch}:")
        unam_ch = unam_verses.get(ch, {})
        ocr_ch = ocr_verses.get(ch, {})
        
        for v_num in sorted(unam_ch.keys()):
            total_unam_count += 1
            unam_txt = unam_ch[v_num]
            
            if v_num in ocr_ch:
                matched_count += 1
                ocr_txt = ocr_ch[v_num]
                
                # Calculate word-level overlap
                unam_words = clean_text(unam_txt).split()
                ocr_words = clean_text(ocr_txt).split()
                
                if unam_words and ocr_words:
                    overlap_words = set(unam_words) & set(ocr_words)
                    similarity = len(overlap_words) / max(len(unam_words), len(ocr_words))
                else:
                    similarity = 0.0
                    
                similarity_sum += similarity
                print(f"  Verse {v_num:2d}: PRESENT | Similarity: {similarity*100:6.2f}%")
            else:
                print(f"  Verse {v_num:2d}: MISSING")
                
    # Summary
    verse_match_rate = (matched_count / total_unam_count) * 100 if total_unam_count > 0 else 0
    text_overlap_rate = (similarity_sum / total_unam_count) * 100 if total_unam_count > 0 else 0
    
    print("\n==================================================")
    print(f"Total UNAM verses (Ch 1 & 2):       {total_unam_count}")
    print(f"Total OCR verses found:             {matched_count}")
    print(f"Verse Match Rate (presence):       {verse_match_rate:.2f}%")
    print(f"Average Text Overlap Rate:          {text_overlap_rate:.2f}%")
    print("==================================================")

if __name__ == "__main__":
    main()
