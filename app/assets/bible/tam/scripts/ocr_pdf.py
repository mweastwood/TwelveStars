import os
import sys
import json
import argparse
from pypdf import PdfReader, PdfWriter
from paddleocr import PaddleOCR

# Disable MKLDNN to prevent framework-level CPU instruction bugs
os.environ["FLAGS_use_mkldnn"] = "0"
os.environ["PADDLE_PDX_ENABLE_MKLDNN_BYDEFAULT"] = "0"

def parse_args():
    parser = argparse.ArgumentParser(description="Run PaddleOCR on PDF page range and cache raw outputs.")
    parser.add_argument("--volume", type=int, default=1, help="Volume number (1, 2, 3, or 4)")
    parser.add_argument("--start", type=int, required=True, help="Start page index (0-indexed)")
    parser.add_argument("--end", type=int, required=True, help="End page index (0-indexed, inclusive)")
    return parser.parse_args()

def main():
    args = parse_args()
    
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    vol_filename = f"vol{args.volume}_scan.pdf"
    pdf_path = os.path.join(base_dir, "pdf", vol_filename)
    ocr_raw_dir = os.path.join(base_dir, "ocr_raw")
    
    if not os.path.exists(pdf_path):
        print(f"Error: PDF scan file {pdf_path} not found.")
        sys.exit(1)
        
    os.makedirs(ocr_raw_dir, exist_ok=True)
    
    print(f"Reading PDF: {pdf_path}...")
    reader = PdfReader(pdf_path)
    total_pages = len(reader.pages)
    
    start_idx = max(0, args.start)
    end_idx = min(total_pages - 1, args.end)
    
    # Filter pages that are already cached
    pages_to_process = []
    for idx in range(start_idx, end_idx + 1):
        cache_path = os.path.join(ocr_raw_dir, f"vol{args.volume}_page_{idx}.json")
        if os.path.exists(cache_path):
            print(f"  Page index {idx} already cached. Skipping.")
        else:
            pages_to_process.append(idx)
            
    if not pages_to_process:
        print("All pages in range are already cached. Exiting.")
        sys.exit(0)
        
    print(f"Need to run OCR on {len(pages_to_process)} pages: {pages_to_process}")
    
    print("Initializing PaddleOCR (Spanish)...")
    ocr = PaddleOCR(use_textline_orientation=True, lang="es", enable_mkldnn=False)
    
    # Process pages in small groups
    for idx in pages_to_process:
        print(f"Processing page index {idx} (PDF page {idx + 1}) / {total_pages}...")
        
        # Extract page to temp file
        writer = PdfWriter()
        writer.add_page(reader.pages[idx])
        temp_path = os.path.join(base_dir, f"temp_ocr_{idx}.pdf")
        with open(temp_path, "wb") as f_temp:
            writer.write(f_temp)
            
        try:
            # Run OCR on single page
            # DeprecationWarning check: using ocr() since we want the bounding box parsing wrapper
            results = ocr.ocr(temp_path)
            
            # Save raw outputs
            page_result = results[0] if results else {}
            
            # Format data to save
            lines_data = []
            if page_result and 'rec_texts' in page_result:
                texts = page_result['rec_texts']
                boxes = page_result['rec_boxes']
                scores = page_result['rec_scores']
                
                for j in range(len(texts)):
                    text = texts[j]
                    box = boxes[j]
                    score = scores[j]
                    
                    # box can be numpy array or list of coordinates
                    box_list = box.tolist() if hasattr(box, "tolist") else list(box)
                    
                    lines_data.append({
                        "text": text,
                        "box": box_list,
                        "score": float(score)
                    })
                    
            cache_data = {
                "volume": args.volume,
                "page_index": idx,
                "pdf_page": idx + 1,
                "lines": lines_data
            }
            
            cache_path = os.path.join(ocr_raw_dir, f"vol{args.volume}_page_{idx}.json")
            with open(cache_path, "w", encoding="utf-8") as f_json:
                json.dump(cache_data, f_json, indent=2, ensure_ascii=False)
                
            print(f"  Successfully cached index {idx} to {cache_path}")
            
        except Exception as e:
            print(f"Error running OCR on page index {idx}: {e}")
        finally:
            if os.path.exists(temp_path):
                os.remove(temp_path)
                
    print("OCR caching process completed.")

if __name__ == "__main__":
    main()
