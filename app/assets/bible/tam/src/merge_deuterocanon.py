import os

OCR_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "parsed")
DEST_DIR = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "usfm"))

DEUTERO_BOOKS = {
    "TOB": ("17-TOB-SPA[B]TAM1836[pd].usfm", "Tobit"),
    "JDT": ("18-JDT-SPA[B]TAM1836[pd].usfm", "Judith"),
    "WIS": ("25-WIS-SPA[B]TAM1836[pd].usfm", "Wisdom"),
    "SIR": ("26-SIR-SPA[B]TAM1836[pd].usfm", "Sirach"),
    "BAR": ("30-BAR-SPA[B]TAM1836[pd].usfm", "Baruch"),
    "1MA": ("45-1MA-SPA[B]TAM1836[pd].usfm", "1 Maccabees"),
    "2MA": ("46-2MA-SPA[B]TAM1836[pd].usfm", "2 Maccabees")
}

def merge_books():
    print("Merging Deuterocanonical books into target assets directory...")
    
    for abbrev, (target_name, book_title) in DEUTERO_BOOKS.items():
        src_path = os.path.join(OCR_DIR, f"{abbrev}.usfm")
        dest_path = os.path.join(DEST_DIR, target_name)
        
        if not os.path.exists(src_path):
            print(f"ERROR: Source file {src_path} does not exist!")
            continue
            
        print(f"Copying {abbrev} to {target_name}...")
        
        with open(src_path, "r", encoding="utf-8") as f_in, open(dest_path, "w", encoding="utf-8") as f_out:
            for line in f_in:
                # Update headers to match the format of other files
                if line.startswith("\\id "):
                    f_out.write(f"\\id {abbrev}\n")
                elif line.startswith("\\h "):
                    f_out.write(f"\\h {book_title}\n")
                elif line.startswith("\\toc1 "):
                    f_out.write(f"\\toc1 {book_title}\n")
                else:
                    f_out.write(line)
                    
    print("Deuterocanonical books merged successfully.")

if __name__ == "__main__":
    merge_books()
