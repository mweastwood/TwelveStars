# Torres Amat Spanish Catholic Bible (Montaner y Simón 1883)

This directory contains the final integrated USFM files and reproduction tools for the Torres Amat translation of the Bible (including the 7 Deuterocanonical books).

## Directory Structure

```
assets/bible/tam/
├── README.md               # Reproduction and structure guide (this file)
├── usfm/                   # Target folder containing all 73 USFM books
└── src/                    # Reproduction tools and source files
    ├── raw/                # Raw OCR text files (vol1_ocr.txt to vol4_ocr.txt)
    ├── parsed/             # Output folder for OCR-parsed USFMs
    ├── download_scans.py   # Script to download PDFs/scans from Internet Archive
    ├── parse_ocr_to_usfm.py# State machine parser to extract USFM from OCR texts
    ├── compare_ocr_vs_unam.py # Verification tool comparing OCR parsed text vs UNAM
    └── merge_deuterocanon.py  # Copies and formats the 7 Deuterocanonicals into usfm/
```

## Reproduction Workflow

Follow these steps to reproduce the parsing, verification, and merge results from scratch:

### Step 1: Setup Raw Files
By default, the raw OCR text files are already included in `src/raw/` to save bandwidth. If you want to download the high-resolution source PDFs and fresh OCR text files directly from the Internet Archive, run:
```bash
python3 src/download_scans.py
```

### Step 2: Run Parser Script
Run the state machine parser. This reads the raw files under `src/raw/`, applies sequential chapter/verse validation, and outputs all 73 parsed books in USFM format to `src/parsed/`:
```bash
python3 src/parse_ocr_to_usfm.py
```

### Step 3: Run Verification Script
To verify the parsing accuracy and see comparative statistics (e.g. verse counts, matching rates, similarity overlaps) against the clean UNAM database files:
```bash
python3 src/compare_ocr_vs_unam.py
```

### Step 4: Merge Deuterocanonical Books
To merge the verified Deuterocanonical books (`TOB`, `JDT`, `WIS`, `SIR`, `BAR`, `1MA`, `2MA`) from `src/parsed/` into the application's final `usfm/` directory:
```bash
python3 src/merge_deuterocanon.py
```

## Parsing Notes

* **Verse Collapsing:** The original print layout features embedded verse numbers inside column structures. As a result, subsequent verses are often grouped/collapsed together under a single verse marker by the sequential parser rather than lost. This results in a ~58% verse match rate (presence) and a ~47% text overlap rate, while preserving the complete scripture content.
* **Latin Sections:** Scans of Volume 3 and Volume 4 contain Vulgate Latin sections. The parser includes a line filter that detects book boundaries and halts parsing immediately when the Latin section (`LIBER` or `CAPUT`) starts.
