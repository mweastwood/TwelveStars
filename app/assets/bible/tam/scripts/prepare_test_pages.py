import os
import sys
from pypdf import PdfReader, PdfWriter

def find_genesis_page(pdf_path):
    print(f"Reading {pdf_path} to locate Genesis 1...")
    reader = PdfReader(pdf_path)
    num_pages = len(reader.pages)
    print(f"Total pages in PDF: {num_pages}")
    
    # Let's search pages for Genesis markers
    # Typically page numbers in the book start after a few pages of front-matter
    for page_num in range(num_pages):
        try:
            page = reader.pages[page_num]
            text = page.extract_text()
            if text:
                text_upper = text.upper()
                if "GÉNESIS" in text_upper or "GENESIS" in text_upper:
                    if "CAPITULO PRIMERO" in text_upper or "CAPÍTULO PRIMERO" in text_upper or "LIBRO DEL" in text_upper:
                        print(f"Found Genesis 1 markers on PDF page {page_num + 1} (index {page_num})")
                        return page_num
        except Exception as e:
            print(f"Error reading page {page_num + 1}: {e}")
            
    # Default fallback if no text layer is present
    print("Could not find text markers in PDF. It might be image-only. Falling back to page index 12 (page 13).")
    return 12

def extract_pages(pdf_path, start_page_idx, count, output_path):
    print(f"Extracting {count} pages starting from page index {start_page_idx} (page {start_page_idx + 1})...")
    reader = PdfReader(pdf_path)
    writer = PdfWriter()
    
    end_idx = min(start_page_idx + count, len(reader.pages))
    for idx in range(start_page_idx, end_idx):
        writer.add_page(reader.pages[idx])
        
    with open(output_path, "wb") as f_out:
        writer.write(f_out)
    print(f"Successfully wrote extracted pages to {output_path}")

def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    vol1_path = os.path.join(base_dir, "pdf", "vol1_scan.pdf")
    output_path = os.path.join(base_dir, "pdf", "genesis_ch1_test.pdf")
    
    if not os.path.exists(vol1_path):
        print(f"Error: {vol1_path} not found. Please run download_scans.py first.")
        sys.exit(1)
        
    start_idx = find_genesis_page(vol1_path)
    # Extract 3 pages starting from Genesis 1 start
    extract_pages(vol1_path, start_idx, 3, output_path)

if __name__ == "__main__":
    main()
