import os
import sys
import re
import unicodedata
from pypdf import PdfReader, PdfWriter
from paddleocr import PaddleOCR

# Disable MKLDNN to prevent framework-level CPU instruction bugs
os.environ["FLAGS_use_mkldnn"] = "0"
os.environ["PADDLE_PDX_ENABLE_MKLDNN_BYDEFAULT"] = "0"

def clean_text_line(text):
    # Remove excessive spaces and clean up OCR noise
    return " ".join(text.strip().split())

def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    vol1_path = os.path.join(base_dir, "pdf", "vol1_scan.pdf")
    output_usfm = os.path.join(base_dir, "ocr", "01-GEN-SPA[B]TAM1836[pd].usfm")
    
    if not os.path.exists(vol1_path):
        print(f"Error: {vol1_path} not found. Please run download_scans.py first.")
        sys.exit(1)
        
    print("Loading PDF reader...")
    reader = PdfReader(vol1_path)
    
    # Genesis starts at page index 16 (page 17) and ends at page index 73 (page 74)
    start_page_idx = 16
    end_page_idx = 73
    total_pages = end_page_idx - start_page_idx + 1
    
    print(f"Extracting {total_pages} pages of Genesis (indices {start_page_idx} to {end_page_idx})...")
    
    temp_files = []
    for idx in range(start_page_idx, end_page_idx + 1):
        writer = PdfWriter()
        writer.add_page(reader.pages[idx])
        temp_path = os.path.join(base_dir, f"temp_page_{idx}.pdf")
        with open(temp_path, "wb") as f_temp:
            writer.write(f_temp)
        temp_files.append(temp_path)
        
    print(f"Initializing PaddleOCR (Spanish)...")
    ocr = PaddleOCR(use_textline_orientation=True, lang="es", enable_mkldnn=False)
    
    print("Running OCR over all extracted Genesis pages (this may take some time)...")
    # Process pages in batches of 5 to manage memory usage while retaining speed
    batch_size = 5
    all_pages_results = []
    
    for i in range(0, len(temp_files), batch_size):
        batch = temp_files[i:i+batch_size]
        print(f"  Processing batch {i // batch_size + 1} / {(len(temp_files) + batch_size - 1) // batch_size}...")
        batch_results = ocr.ocr(batch)
        all_pages_results.extend(batch_results)
        
    # Clean up temp files
    print("Cleaning up temporary page files...")
    for temp_path in temp_files:
        try:
            os.remove(temp_path)
        except Exception as e:
            print(f"Error removing {temp_path}: {e}")
            
    print("Processing OCR output and sorting layout columns...")
    
    verses = {}
    current_chapter = 0
    current_verse = 0
    
    for page_idx, page_result in enumerate(all_pages_results):
        actual_pdf_page = start_page_idx + page_idx + 1
        if not page_result or 'rec_texts' not in page_result:
            print(f"Warning: No text detected on page index {start_page_idx + page_idx} (PDF page {actual_pdf_page})")
            continue
            
        texts = page_result['rec_texts']
        boxes = page_result['rec_boxes']
        
        # Bundle text and coordinates
        lines = []
        for j in range(len(texts)):
            text = texts[j]
            box = boxes[j]
            try:
                x, y = int(box[0]), int(box[1])
            except:
                x, y = 0, 0
            lines.append({'text': text, 'x': x, 'y': y})
            
        # Filter layout components:
        # - Discard page headers (Y < 150)
        # - Discard footnotes/commentary (Y >= 1120)
        scripture_lines = [l for l in lines if 150 <= l['y'] < 1120]
        
        # Separate columns (Left: X < 400, Right: X >= 400)
        left_column = [l for l in scripture_lines if l['x'] < 400]
        right_column = [l for l in scripture_lines if l['x'] >= 400]
        
        # Sort each column vertically
        left_column.sort(key=lambda l: l['y'])
        right_column.sort(key=lambda l: l['y'])
        
        # Concatenate columns
        ordered_lines = left_column + right_column
        
        for line in ordered_lines:
            text = clean_text_line(line['text'])
            if not text:
                continue
                
            text_upper = text.upper()
            
            # Detect chapter headers (e.g. "CAPITULO L", "CAPÍTULO PRIMERO")
            if text_upper.startswith("CAPITULO") or text_upper.startswith("CAPÍTULO"):
                current_chapter += 1
                current_verse = 0
                verses[current_chapter] = {}
                continue
                
            # Detect verse numbers (e.g. "1. ", "12. ")
            verse_match = re.match(r'^(\d+)\s*[\./,;-]*\s+(.*)', text)
            if verse_match:
                v_num = int(verse_match.group(1))
                v_text = verse_match.group(2).strip()
                current_verse = v_num
                
                if current_chapter > 0:
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append(v_text)
            else:
                # Continuation text of the current verse or summary description (verse 0)
                if current_chapter > 0:
                    # Ignore standalone numbers that might be leaked page numbers/noise
                    if not text.isdigit() and "—" not in text:
                        if current_verse not in verses[current_chapter]:
                            verses[current_chapter][current_verse] = []
                        verses[current_chapter][current_verse].append(text)
                        
    print(f"Writing USFM format output to {output_usfm}...")
    usfm_lines = [
        r"\id GEN",
        r"\h Genesis",
        r"\toc1 Genesis",
    ]
    
    for ch in sorted(verses.keys()):
        usfm_lines.append(f"\\c {ch}")
        
        # Write chapter summary first if present under key 0
        if 0 in verses[ch] and verses[ch][0]:
            summary_txt = " ".join(verses[ch][0])
            usfm_lines.append(f"\\p {summary_txt}")
            
        for v in sorted(verses[ch].keys()):
            if v == 0:
                continue
            v_text = " ".join(verses[ch][v])
            usfm_lines.append(f"\\v {v} {v_text}")
            
    with open(output_usfm, "w", encoding="utf-8") as f_usfm:
        f_usfm.write("\n".join(usfm_lines) + "\n")
        
    print(f"Successfully processed Genesis. Generated USFM file: {output_usfm}")

if __name__ == "__main__":
    main()
