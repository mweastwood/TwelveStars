import os
import sys
# Disable MKLDNN/OneDNN to prevent compilation conversion bugs in PaddlePaddle 3.3.x CPU mode
os.environ["FLAGS_use_mkldnn"] = "0"
os.environ["PADDLE_PDX_ENABLE_MKLDNN_BYDEFAULT"] = "0"

from paddleocr import PaddleOCR

def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    test_pdf = os.path.join(base_dir, "pdf", "genesis_ch1_test.pdf")
    
    if not os.path.exists(test_pdf):
        print(f"Error: Test PDF {test_pdf} not found. Please run prepare_test_pages.py first.")
        sys.exit(1)
        
    print(f"Initializing PaddleOCR (Spanish)...")
    # use_textline_orientation detects text orientation (e.g. if page is slightly rotated)
    ocr = PaddleOCR(use_textline_orientation=True, lang="es", enable_mkldnn=False)
    
    print(f"Running OCR on {test_pdf}...")
    # ocr() returns a list containing one list of results per page
    pages_results = ocr.ocr(test_pdf)
    
    print("\n--- OCR Results ---")
    for page_idx, page_result in enumerate(pages_results):
        print(f"\n================ PAGE {page_idx + 1} ================")
        if not page_result or 'rec_texts' not in page_result:
            print("No text detected on this page.")
            continue
            
        texts = page_result['rec_texts']
        boxes = page_result['rec_boxes']
        scores = page_result['rec_scores']
        
        for i in range(len(texts)):
            text = texts[i]
            box = boxes[i]
            score = scores[i]
            
            # box is a 1D array/list of 4 elements: [x, y, w, h] or similar
            try:
                x, y = int(box[0]), int(box[1])
            except:
                x, y = 0, 0
                
            print(f"[{x:3d}, {y:3d}] (Conf: {score:.2f}): {text}")

if __name__ == "__main__":
    main()
