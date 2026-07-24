import os
import sys
import re
import json
import argparse

BOOK_PREFIXES = {
    "GEN": "01", "EXO": "02", "LEV": "03", "NUM": "04", "DEU": "05",
    "JOS": "06", "JDG": "07", "RUT": "08", "1SA": "09", "2SA": "10",
    "1KI": "11", "2KI": "12", "1CH": "13", "2CH": "14", "EZR": "15",
    "NEH": "16", "TOB": "17", "JDT": "18", "EST": "19", "JOB": "20",
    "PSA": "21", "PRO": "22", "ECC": "23", "SNG": "24", "WIS": "25",
    "SIR": "26", "ISA": "27", "JER": "28", "LAM": "29", "BAR": "30",
    "EZK": "31", "DAN": "32", "HOS": "33", "JOL": "34", "AMO": "35",
    "OBA": "36", "JON": "37", "MIC": "38", "NAM": "39", "HAB": "40",
    "ZEP": "41", "HAG": "42", "ZEC": "43", "MAL": "44", "1MA": "45",
    "2MA": "46", "MAT": "49", "MRK": "50", "LUK": "51", "JHN": "52",
    "ACT": "53", "ROM": "54", "1CO": "55", "2CO": "56", "GAL": "57",
    "EPH": "58", "PHP": "59", "COL": "60", "1TH": "61", "2TH": "62",
    "1TI": "64", "2TI": "65", "TIT": "66", "PHM": "67", "HEB": "68",
    "JAM": "69", "1PE": "70", "2PE": "71", "1JN": "72", "2JN": "73",
    "3JN": "74", "JUD": "75", "REV": "76"
}

BOOK_NAMES = {
    "GEN": "Génesis", "EXO": "Éxodo", "LEV": "Levítico", "NUM": "Números", "DEU": "Deuteronomio",
    "JOS": "Josué", "JDG": "Jueces", "RUT": "Ruth", "1SA": "1 Samuel", "2SA": "2 Samuel",
    "1KI": "1 Reyes", "2KI": "2 Reyes", "1CH": "1 Crónicas", "2CH": "2 Crónicas", "EZR": "Esdras",
    "NEH": "Nehemías", "TOB": "Tobías", "JDT": "Judith", "EST": "Esther", "JOB": "Job",
    "PSA": "Salmos", "PRO": "Proverbios", "ECC": "Eclesiastés", "SNG": "Cantar de los Cantares",
    "WIS": "Sabiduría", "SIR": "Eclesiástico", "ISA": "Isaías", "JER": "Jeremías", "LAM": "Lamentaciones",
    "BAR": "Baruch", "EZK": "Ezequiel", "DAN": "Daniel", "HOS": "Oseas", "JOL": "Joel",
    "AMO": "Amós", "OBA": "Abdías", "JON": "Jonás", "MIC": "Miqueas", "NAM": "Nahum",
    "HAB": "Habacuc", "ZEP": "Sofonías", "HAG": "Aggeo", "ZEC": "Zacharias", "MAL": "Malaquías",
    "1MA": "1 Macabeos", "2MA": "2 Macabeos", "MAT": "Mateo", "MRK": "Marcos", "LUK": "Lucas",
    "JHN": "Juan", "ACT": "Hechos", "ROM": "Romanos", "1CO": "1 Corintios", "2CO": "2 Corintios",
    "GAL": "Gálatas", "EPH": "Efesios", "PHP": "Filipenses", "COL": "Colosenses", "1TH": "1 Tesalonicenses",
    "2TH": "2 Tesalonicenses", "1TI": "1 Timoteo", "2TI": "2 Timoteo", "TIT": "Tito", "PHM": "Filemón",
    "HEB": "Hebreos", "JAM": "Santiago", "1PE": "1 Pedro", "2PE": "2 Pedro", "1JN": "1 Juan",
    "2JN": "2 Juan", "3JN": "3 Juan", "JUD": "Judas", "REV": "Apocalipsis"
}

# Volume and page ranges for all 73 Catholic Bible books in Torres Amat (1836)
BIBLE_BOOK_MAP = {
    # Vol 1
    "GEN": (1, 18, 79), "EXO": (1, 80, 119), "LEV": (1, 120, 156), "NUM": (1, 157, 204),
    "DEU": (1, 205, 258), "JOS": (1, 259, 295), "JDG": (1, 296, 329), "RUT": (1, 330, 337),
    # Vol 2
    "1SA": (2, 12, 48), "2SA": (2, 49, 77), "1KI": (2, 78, 108), "2KI": (2, 109, 138),
    "1CH": (2, 139, 168), "2CH": (2, 169, 203), "EZR": (2, 204, 212), "NEH": (2, 213, 228),
    "TOB": (2, 229, 240), "JDT": (2, 241, 256), "EST": (2, 257, 269), "JOB": (2, 270, 305),
    # Vol 3
    "PSA": (3, 11, 76), "PRO": (3, 77, 96), "ECC": (3, 97, 105), "SNG": (3, 106, 111),
    "WIS": (3, 112, 125), "SIR": (3, 126, 167), "ISA": (3, 168, 217), "JER": (3, 218, 270),
    "LAM": (3, 271, 275), "BAR": (3, 276, 283), "EZK": (3, 284, 325), "DAN": (3, 326, 345),
    "HOS": (3, 346, 352), "JOL": (3, 353, 357), "AMO": (3, 358, 363), "OBA": (3, 364, 365),
    "JON": (3, 364, 365), "MIC": (3, 366, 371), "NAM": (3, 372, 373), "HAB": (3, 374, 376),
    "ZEP": (3, 377, 380), "HAG": (3, 381, 382), "ZEC": (3, 383, 389), "MAL": (3, 390, 394),
    "1MA": (3, 395, 421), "2MA": (3, 422, 440),
    # Vol 4
    "MAT": (4, 11, 49), "MRK": (4, 50, 70), "LUK": (4, 71, 109), "JHN": (4, 110, 139),
    "ACT": (4, 140, 184), "ROM": (4, 185, 210), "1CO": (4, 211, 232), "2CO": (4, 233, 248),
    "GAL": (4, 249, 259), "EPH": (4, 260, 267), "PHP": (4, 268, 272), "COL": (4, 273, 279),
    "1TH": (4, 280, 284), "2TH": (4, 285, 288), "1TI": (4, 289, 296), "2TI": (4, 297, 303),
    "TIT": (4, 304, 308), "PHM": (4, 309, 309), "HEB": (4, 310, 325), "JAM": (4, 326, 331),
    "1PE": (4, 332, 337), "2PE": (4, 338, 342), "1JN": (4, 343, 348), "2JN": (4, 349, 351),
    "3JN": (4, 352, 352), "JUD": (4, 353, 356), "REV": (4, 357, 377)
}

ROMAN_NUMERALS = {
    "I": 1, "II": 2, "III": 3, "IV": 4, "V": 5, "VI": 6, "VII": 7, "VIII": 8, "IX": 9, "X": 10,
    "XI": 11, "XII": 12, "XIII": 13, "XIV": 14, "XV": 15, "XVI": 16, "XVII": 17, "XVIII": 18, "XIX": 19, "XX": 20,
    "XXI": 21, "XXII": 22, "XXIII": 23, "XXIV": 24, "XXV": 25, "XXVI": 26, "XXVII": 27, "XXVIII": 28, "XXIX": 29, "XXX": 30,
    "XXXI": 31, "XXXII": 32, "XXXIII": 33, "XXXIV": 34, "XXXV": 35, "XXXVI": 36, "XXXVII": 37, "XXXVIII": 38, "XXXIX": 39, "XL": 40,
    "XLI": 41, "XLII": 42, "XLIII": 43, "XLIV": 44, "XLV": 45, "XLVI": 46, "XLVII": 47, "XLVIII": 48, "XLIX": 49, "L": 50,
    "LI": 51, "LII": 52, "LIII": 53, "LIV": 54, "LV": 55, "LVI": 56, "LVII": 57, "LVIII": 58, "LIX": 59, "LX": 60,
    "LXI": 61, "LXII": 62, "LXIII": 63, "LXIV": 64, "LXV": 65, "LXVI": 66, "LXVII": 67, "LXVIII": 68, "LXIX": 69, "LXX": 70,
    "LXXI": 71, "LXXII": 72, "LXXIII": 73, "LXXIV": 74, "LXXV": 75, "LXXVI": 76, "LXXVII": 77, "LXXVIII": 78, "LXXIX": 79, "LXXX": 80,
    "LXXXI": 81, "LXXXII": 82, "LXXXIII": 83, "LXXXIV": 84, "LXXXV": 85, "LXXXVI": 86, "LXXXVII": 87, "LXXXVIII": 88, "LXXXIX": 89, "XC": 90,
    "XCI": 91, "XCII": 92, "XCIII": 93, "XCIV": 94, "XCV": 95, "XCVI": 96, "XCVII": 97, "XCVIII": 98, "XCIX": 99, "C": 100,
    "CI": 101, "CII": 102, "CIII": 103, "CIV": 104, "CV": 105, "CVI": 106, "CVII": 107, "CVIII": 108, "CIX": 109, "CX": 110,
    "CXI": 111, "CXII": 112, "CXIII": 113, "CXIV": 114, "CXV": 115, "CXVI": 116, "CXVII": 117, "CXVIII": 118, "CXIX": 119, "CXX": 120,
    "CXXI": 121, "CXXII": 122, "CXXIII": 123, "CXXIV": 124, "CXXV": 125, "CXXVI": 126, "CXXVII": 127, "CXXVIII": 128, "CXXIX": 129, "CXXX": 130,
    "CXXXI": 131, "CXXXII": 132, "CXXXIII": 133, "CXXXIV": 134, "CXXXV": 135, "CXXXVI": 136, "CXXXVII": 137, "CXXXVIII": 138, "CXXXIX": 139, "CXL": 140,
    "CXLI": 141, "CXLII": 142, "CXLIII": 143, "CXLIV": 144, "CXLV": 145, "CXLVI": 146, "CXLVII": 147, "CXLVIII": 148, "CXLIX": 149, "CL": 150,
    "PRIMERO": 1, "SEGUNDO": 2, "TERCERO": 3, "CUARTO": 4, "QUINTO": 5, "SEXTO": 6, "SEPTIMO": 7, "SÉPTIMO": 7, "OCTAVO": 8, "NOVENO": 9, "DECIMO": 10, "DÉCIMO": 10
}

def is_page_header_line(text, y_coord):
    if y_coord >= 110:
        return False
    text_clean = text.strip()
    # If line starts with a verse number, it's scripture, not a header!
    if re.match(r'^\d{1,3}\s*[\./,;-]', text_clean):
        return False
    if text_clean.isdigit():
        return True
    text_up = text_clean.upper()
    if any(h in text_up for h in ["SAGRADA BIBLIA", "ADVERTENCIA"]):
        return True
    # Match running top headers like "101 I. REYES. CAPITULO VIII. 102"
    if re.search(r'^\d*\s*(?:[I|V|X|1-4]\.\s*)?[A-ZÁÉÍÓÚÑ\s\.\-]+\s*(?:CAP[IÍ]TULO\s+[A-Z0-9\.]+\s*)?\d*$', text_up):
        return True
    return False

def is_footnote_line(text, y_coord):
    text_up = text.upper()
    # Chapter headers are NEVER footnotes, even if located near bottom of page!
    if any(h in text_up for h in ["CAPITULO", "CAPÍTULO", "CAPUT", "SALMO"]):
        return False
    if y_coord >= 1140:
        return True
    return False

def clean_text_line(text):
    return " ".join(text.strip().split())

def extract_chapter_number(text):
    text_clean = re.sub(r'[^\w\s]', '', text.upper())
    tokens = text_clean.split()
    for tok in tokens:
        if tok in ROMAN_NUMERALS:
            return ROMAN_NUMERALS[tok]
        if re.match(r'^\d+$', tok):
            return int(tok)
    return None

def parse_args():
    parser = argparse.ArgumentParser(description="Compile raw OCR JSON files into a structured USFM book.")
    parser.add_argument("--book", type=str, help="Book ID (e.g. GEN, TOB, JDT)")
    parser.add_argument("--volume", type=int, help="Volume number (1, 2, 3, or 4)")
    parser.add_argument("--start", type=int, help="Start page index (0-indexed)")
    parser.add_argument("--end", type=int, help="End page index (0-indexed)")
    parser.add_argument("--all", action="store_true", help="Compile all 73 Bible books")
    return parser.parse_args()

def split_inline_verses(text):
    pattern = r'\b(\d{1,3})\s*[\./,;-]+\s*(?=[A-ZÁÉÍÓÚÑ])|\b(\d{1,3})\s+(?=[A-ZÁÉÍÓÚÑ])'
    parts = re.split(pattern, text)
    if len(parts) == 1:
        return [(None, text)]
        
    segments = []
    i = 0
    current_v = None
    while i < len(parts):
        part = parts[i]
        if part is None:
            i += 1
            continue
            
        if i % 3 == 0:
            if part.strip():
                segments.append((current_v, part.strip()))
        else:
            if part and re.match(r'^\d+$', part):
                current_v = int(part)
        i += 1
        
    return segments

def compile_book(book_id, volume, start_page, end_page, ocr_raw_dir, output_dir):
    prefix = BOOK_PREFIXES[book_id]
    book_name = BOOK_NAMES[book_id]
    output_filename = f"{prefix}-{book_id}-SPA[B]TAM1836[pd].usfm"
    output_path = os.path.join(output_dir, output_filename)
    
    print(f"Compiling book {book_id} ({book_name}) from Volume {volume}, pages {start_page} to {end_page}...")
    
    all_lines = []
    
    for idx in range(start_page, end_page + 1):
        json_path = os.path.join(ocr_raw_dir, f"vol{volume}_page_{idx}.json")
        if not os.path.exists(json_path):
            print(f"  Warning: Cached file {json_path} not found. Skipping page {idx}.")
            continue
            
        with open(json_path, "r", encoding="utf-8") as f_json:
            data = json.load(f_json)
            
        page_lines = data.get("lines", [])
        
        # Filter page headers and footnotes dynamically
        scripture_lines = [
            l for l in page_lines
            if not is_page_header_line(l['text'], l['box'][1]) and not is_footnote_line(l['text'], l['box'][1])
        ]
        
        # Split columns: Left (X < 400), Right (X >= 400)
        left_column = [l for l in scripture_lines if l['box'][0] < 400]
        right_column = [l for l in scripture_lines if l['box'][0] >= 400]
        
        # Sort each column vertically by Y
        left_column.sort(key=lambda l: l['box'][1])
        right_column.sort(key=lambda l: l['box'][1])
        
        all_lines.extend(left_column + right_column)
        
    verses = {}
    current_chapter = 0
    current_verse = 0
    
    for line_data in all_lines:
        raw_text = clean_text_line(line_data['text'])
        if not raw_text:
            continue
            
        text_upper = raw_text.upper()
        
        # Detect chapter headers (e.g., "CAPITULO II", "CAPÍTULO PRIMERO", "SALMO XXIII", "CAPlTULO III")
        if re.search(r'\b(CAP[IÍLl1]TULO|CAPUT|SALMO|PSALMO)\b', text_upper) and not re.search(r'^\d+\s+CAP', text_upper):
            ch_num = extract_chapter_number(raw_text)
            if ch_num is not None:
                current_chapter = ch_num
            else:
                current_chapter += 1
            current_verse = 0
            if current_chapter not in verses:
                verses[current_chapter] = {}
            continue
            
        # Parse inline verse structures
        segments = split_inline_verses(raw_text)
        
        for v_num, seg_text in segments:
            seg_text = clean_text_line(seg_text)
            if not seg_text:
                continue
                
            if v_num is not None:
                if current_chapter == 0:
                    current_chapter = 1
                    verses[current_chapter] = {}
                current_verse = v_num
                if current_verse not in verses[current_chapter]:
                    verses[current_chapter][current_verse] = []
                verses[current_chapter][current_verse].append(seg_text)
            else:
                start_match = re.match(r'^(\d{1,3})\s*[\./,;-]*\s+(.*)', seg_text)
                if start_match:
                    if current_chapter == 0:
                        current_chapter = 1
                        verses[current_chapter] = {}
                    current_verse = int(start_match.group(1))
                    v_text = start_match.group(2).strip()
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append(v_text)
                else:
                    if current_chapter > 0 and not seg_text.isdigit() and "—" not in seg_text:
                        if current_verse not in verses[current_chapter]:
                            verses[current_chapter][current_verse] = []
                        verses[current_chapter][current_verse].append(seg_text)
                        
    # Format and write USFM output
    usfm_lines = [
        f"\\id {book_id}",
        f"\\h {book_name}",
        f"\\toc1 {book_name}",
    ]
    
    for ch in sorted(verses.keys()):
        usfm_lines.append(f"\\c {ch}")
        
        if 0 in verses[ch] and verses[ch][0]:
            summary_txt = " ".join(verses[ch][0])
            usfm_lines.append(f"\\p {summary_txt}")
            
        for v in sorted(verses[ch].keys()):
            if v == 0:
                continue
            v_text = " ".join(verses[ch][v])
            v_text = re.sub(r'\s+', ' ', v_text).strip()
            usfm_lines.append(f"\\v {v} {v_text}")
            
    with open(output_path, "w", encoding="utf-8") as f_out:
        f_out.write("\n".join(usfm_lines) + "\n")
        
    print(f"  Successfully generated USFM file: {output_path}")

def main():
    args = parse_args()
    
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    ocr_raw_dir = os.path.join(base_dir, "raw_ocr")
    output_dir = os.path.join(base_dir, "ocr")
    os.makedirs(output_dir, exist_ok=True)
    
    if args.all:
        print("Compiling all 73 Bible books into USFM...")
        for book_id, (volume, start_p, end_p) in BIBLE_BOOK_MAP.items():
            compile_book(book_id, volume, start_p, end_p, ocr_raw_dir, output_dir)
        print("\nAll Bible books successfully compiled!")
    elif args.book:
        book_id = args.book.upper()
        if book_id not in BOOK_PREFIXES:
            print(f"Error: Unknown book ID {book_id}")
            sys.exit(1)
            
        if args.volume and args.start is not None and args.end is not None:
            volume, start_p, end_p = args.volume, args.start, args.end
        elif book_id in BIBLE_BOOK_MAP:
            volume, start_p, end_p = BIBLE_BOOK_MAP[book_id]
        else:
            print(f"Error: Missing volume/start/end arguments for book {book_id}")
            sys.exit(1)
            
        compile_book(book_id, volume, start_p, end_p, ocr_raw_dir, output_dir)
    else:
        print("Error: Specify either --book <ID> or --all")
        sys.exit(1)

if __name__ == "__main__":
    main()
