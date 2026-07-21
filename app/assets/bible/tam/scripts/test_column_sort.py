import os
import sys
from paddleocr import PaddleOCR

def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    test_pdf = os.path.join(base_dir, "pdf", "genesis_ch1_test.pdf")
    
    if not os.path.exists(test_pdf):
        print(f"Error: Test PDF {test_pdf} not found. Please run prepare_test_pages.py first.")
        sys.exit(1)
        
    print(f"Initializing PaddleOCR (Spanish)...")
    ocr = PaddleOCR(use_textline_orientation=True, lang="es", enable_mkldnn=False)
    
    print(f"Running OCR on {test_pdf}...")
    pages_results = ocr.ocr(test_pdf)
    
    # We want to test sorting on Page 3 (index 2) where Genesis 1 actually starts
    if len(pages_results) < 3:
        print("Error: PDF has fewer than 3 pages.")
        sys.exit(1)
        
    page_result = pages_results[2]
    texts = page_result['rec_texts']
    boxes = page_result['rec_boxes']
    scores = page_result['rec_scores']
    
    # Bundle text, box, and score together
    lines = []
    for i in range(len(texts)):
        text = texts[i]
        box = boxes[i]
        score = scores[i]
        try:
            x, y = int(box[0]), int(box[1])
        except:
            x, y = 0, 0
        lines.append({'text': text, 'x': x, 'y': y, 'score': score})
        
    # Filter out headers and footnotes
    # Let's say:
    # - Header is Y < 500 (e.g. LIBRO DEL GÉNESIS is at Y=185)
    # - Footnote is Y >= 1120
    header_lines = [l for l in lines if l['y'] < 500]
    footnote_lines = [l for l in lines if l['y'] >= 1120]
    scripture_lines = [l for l in lines if 500 <= l['y'] < 1120]
    
    # Separate scripture lines into left and right columns
    # Threshold X = 400
    left_column = [l for l in scripture_lines if l['x'] < 400]
    right_column = [l for l in scripture_lines if l['x'] >= 400]
    
    # Sort columns vertically by Y coordinate
    left_column.sort(key=lambda l: l['y'])
    right_column.sort(key=lambda l: l['y'])
    
    # Print headers
    print("\n--- HEADERS ---")
    header_lines.sort(key=lambda l: l['y'])
    for l in header_lines:
        print(f"[{l['x']:3d}, {l['y']:3d}]: {l['text']}")
        
    # Print left column
    print("\n--- LEFT COLUMN (SPANISH SCRIPTURE) ---")
    for l in left_column:
        print(f"[{l['x']:3d}, {l['y']:3d}]: {l['text']}")
        
    # Print right column
    print("\n--- RIGHT COLUMN (SPANISH SCRIPTURE CONT.) ---")
    for l in right_column:
        print(f"[{l['x']:3d}, {l['y']:3d}]: {l['text']}")
        
    # Print footnotes
    print("\n--- FOOTNOTES ---")
    footnote_lines.sort(key=lambda l: l['y'])
    for l in footnote_lines:
        print(f"[{l['x']:3d}, {l['y']:3d}]: {l['text']}")

if __name__ == "__main__":
    main()
