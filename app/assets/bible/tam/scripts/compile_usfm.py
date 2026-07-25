"""
Torres Amat (1836) Spanish Bible USFM Compiler
================================================
Compiles raw Google Vision OCR JSON files (vol{1..4}_page_{N}.json) into standardized USFM 3.0 files.

Key Features & Heuristics:
1. Volume Page Mapping: Maps all 73 Catholic Bible books across Volumes 1-4.
2. Dynamic Page Column Splitting: Automatically calculates per-page column midpoints to process left and right columns sequentially.
3. Top Margin Page Header Removal: Filters out running headers, page numbers, and title banners.
4. Footnote & Commentary Filtering: Identifies and excludes bottom-margin commentary notes and references.
5. Latin Vulgate Screening: Excludes parallel Latin Vulgate text columns.
6. Sequence-Aware Chapter Extraction: Translates Roman numerals and resolves OCR typos (e.g. IV -> IX).
7. Monotonic Verse Splitting: Splits inline verse numbers while preventing footnote reference numbers from resetting verse counters.
8. Citation & Artifact Cleaning: Strips inline marginal cross-references (e.g. Jerem. IV, v. 13).
"""

import argparse
import json
import os
import re
import sys
from typing import Dict, List, Optional, Tuple

# ==============================================================================
# CONSTANTS & METADATA MAPS
# ==============================================================================

# Standard USFM 2-digit numerical prefixes
BOOK_PREFIXES: Dict[str, str] = {
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

# Spanish book titles for \\h and \\toc1 headers
BOOK_NAMES: Dict[str, str] = {
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

# Volume index and page ranges (start_page, end_page) for all 73 Catholic Bible books
BIBLE_BOOK_MAP: Dict[str, Tuple[int, int, int]] = {
    # Volume 1
    "GEN": (1, 18, 73),
    "EXO": (1, 74, 116),
    "LEV": (1, 117, 148),
    "NUM": (1, 149, 204),
    "DEU": (1, 205, 273),
    "JOS": (1, 260, 293),
    "JDG": (1, 296, 329),
    "RUT": (1, 330, 335),

    # Volume 2
    "1SA": (2, 12, 48),
    "2SA": (2, 49, 77),
    "1KI": (2, 78, 108),
    "2KI": (2, 109, 139),
    "1CH": (2, 140, 168),
    "2CH": (2, 169, 203),
    "EZR": (2, 204, 212),
    "NEH": (2, 213, 228),
    "TOB": (2, 229, 240),
    "JDT": (2, 241, 256),
    "EST": (2, 257, 269),
    "JOB": (2, 270, 305),

    # Volume 3
    "PSA": (3, 14, 76),
    "PRO": (3, 77, 96),
    "ECC": (3, 97, 104),
    "SNG": (3, 105, 111),
    "WIS": (3, 112, 125),
    "SIR": (3, 126, 166),
    "ISA": (3, 167, 221),
    "JER": (3, 218, 270),
    "LAM": (3, 271, 275),
    "BAR": (3, 276, 283),
    "EZK": (3, 284, 325),
    "DAN": (3, 326, 345),
    "HOS": (3, 346, 352),
    "JOL": (3, 353, 357),
    "AMO": (3, 358, 363),
    "OBA": (3, 363, 363),
    "JON": (3, 364, 365),
    "MIC": (3, 366, 371),
    "NAM": (3, 372, 373),
    "HAB": (3, 374, 376),
    "ZEP": (3, 377, 380),  # Sofonías
    "HAG": (3, 381, 382),
    "ZEC": (3, 383, 389),
    "MAL": (3, 390, 394),
    "1MA": (3, 393, 425),
    "2MA": (3, 426, 450),

    # Volume 4
    "MAT": (4, 14, 49),
    "MRK": (4, 50, 70),
    "LUK": (4, 71, 109),
    "JHN": (4, 110, 139),
    "ACT": (4, 140, 184),
    "ROM": (4, 185, 210),
    "1CO": (4, 211, 232),
    "2CO": (4, 233, 248),
    "GAL": (4, 249, 259),
    "EPH": (4, 260, 267),
    "PHP": (4, 268, 272),
    "COL": (4, 273, 279),
    "1TH": (4, 280, 284),  # 1 Tesalonicenses
    "2TH": (4, 285, 288),  # 2 Tesalonicenses
    "1TI": (4, 289, 296),
    "2TI": (4, 297, 303),
    "TIT": (4, 304, 308),
    "PHM": (4, 307, 308),  # Filemón
    "HEB": (4, 308, 325),  # Hebreos
    "JAM": (4, 326, 331),  # Santiago
    "1PE": (4, 332, 337),  # 1 Pedro
    "2PE": (4, 338, 342),  # 2 Pedro
    "1JN": (4, 343, 348),
    "2JN": (4, 349, 351),
    "3JN": (4, 352, 352),
    "JUD": (4, 353, 356),
    "REV": (4, 357, 377),
}

# Mapping of Roman numerals and Spanish ordinal words to integers (1-150)
ROMAN_NUMERALS: Dict[str, int] = {
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
    "PRIMERO": 1, "SEGUNDO": 2, "TERCERO": 3, "CUARTO": 4, "QUINTO": 5, "SEXTO": 6, "SEPTIMO": 7, "SÉPTIMO": 7, "OCTAVO": 8, "NOVENO": 9, "DECIMO": 10, "DÉCIMO": 10,
    "UNICO": 1, "ÚNICO": 1
}

# Common Latin vocabulary set for Vulgate line detection
LATIN_STOP_WORDS = {
    'et', 'in', 'est', 'non', 'cum', 'ad', 'sed', 'ut', 'ab', 'ex', 'deus', 'dominus', 'domini', 'domino',
    'filius', 'filii', 'filios', 'eius', 'eum', 'eos', 'suam', 'suum', 'suis', 'dicit', 'dixit', 'quod', 'quae',
    'qui', 'fecit', 'factum', 'propter', 'autem', 'enim', 'ergo', 'super', 'sub', 'per'
}

# ==============================================================================
# TEXT CLEANING & FORMATTING HELPERS
# ==============================================================================

def clean_text_line(text: str) -> str:
    """Normalizes whitespace in a raw OCR string."""
    return " ".join(text.strip().split())


def clean_scripture_verse_text(text: str) -> str:
    """
    Cleans inline cross-reference citations and trailing footnote callout numbers
    from compiled scripture text lines (e.g. 'Jerem. IV, v. 13' or trailing ' 7.').
    """
    ref_pattern = (
        r'\b(?:Jerem|Isai|Luc|Joan|Matth|Psalm|Deuter|Gen|Exod|Lev|Num|Deut|Jos|Judic|'
        r'Reg|Paral|Esd|Nehem|Tob|Judit|Esth|Job|Prov|Ecles|Cant|Sab|Eclus|Bar|Ezech|'
        r'Dan|Osee|Joel|Amos|Abd|Jonas|Mich|Nah|Hab|Soph|Agg|Zach|Mal|Mac|Rom|Cor|Gal|'
        r'Eph|Phil|Col|Thess|Tim|Tit|Philem|Hebr|Jac|Petr|Jud|Apoc)\b\.?\s+[IVXLCDM\d]+\s*,\s*v\.?\s*\d*'
    )
    text = re.sub(ref_pattern, '', text, flags=re.IGNORECASE)
    text = re.sub(r'\s+\d{1,2}\.\s*$', '', text)
    return " ".join(text.split())

# ==============================================================================
# LAYOUT & LINE FILTERING HEURISTICS
# ==============================================================================

def is_page_header_line(text: str, y_coord: float, page_h: float, x_coord: float = 0.0, vol: int = 0) -> bool:
    """
    Determines if an OCR line belongs to the top-margin running header (page numbers, titles).
    Relative Y-coordinate evaluation prevents hardcoding absolute pixel bounds across volumes.
    """
    text_clean = text.strip()
    text_up = text_clean.upper()

    # Filter top-right running headers like 'CAPITULO XLIV.' or 'CAPITULO VII.' in top margins across volumes
    if y_coord <= page_h * 0.12 and x_coord > 500 and "CAPITULO" in text_up and text_clean.endswith("."):
        if not re.match(r'^\s*(?:C[ÁA]P[IÍLl1]TULO|CAPUT|[SŚ]ALMO|PSALMO)\s+(?:II|LII)\.?\s*$', text_up):
            return True

    if y_coord < page_h * 0.035:
        return True
    if y_coord >= page_h * 0.08:
        return False
        
    text_clean = text.strip()
    text_up = text_clean.upper()

    # Do NOT filter standalone chapter titles like 'CAPITULO III.'
    if re.match(r'^\s*(?:C[ÁA]P[IÍLl1]TULO|CAPUT|[SŚ]ALMO|PSALMO)\s+[IVXLCDM0-9ÁÉÍÓÚ]+\.?\s*$', text_up):
        return False

    # Filter running headers like '251 I. A LOS CORINTHIOS. CAPITULO XI. 252' or '561 OSEAS. CAPITULO V. 562'
    if y_coord <= page_h * 0.055 and ("CAPITULO" in text_up or "SALMO" in text_up or "RUTH" in text_up or "OSEAS" in text_up or "OSÉAS" in text_up):
        if re.search(r'\d{3}', text_clean) or "CORINTHIOS" in text_up or "OSEAS" in text_up or "OSÉAS" in text_up:
            return True
        
    if re.match(r'^\d{1,3}\s*[\./,;-]', text_clean):
        return False
        
    if text_clean.isdigit():
        return True
        
    header_keywords = [
        "SAGRADA BIBLIA", "ADVERTENCIA", "LIBRO DE LOS SALMOS",
        "PROFECÍA DE ABDÍAS", "DEL APÓSTOL SAN PABLO", "CORINTHIOS"
    ]
    if any(h in text_up for h in header_keywords):
        return True
        
    # Match patterns like '259 I. ESDRAS. CAPITULO III. 260'
    if re.search(r'^\d+\s+[A-ZÁÉÍÓÚÑ\s\.\-]+\d*$', text_up) or re.search(r'^\d*\s+[A-ZÁÉÍÓÚÑ\s\.\-]+\s+\d+$', text_up):
        return True
        
    return False


def is_footnote_line(text: str, y_coord: float, page_h: float) -> bool:
    """
    Identifies bottom-margin commentary notes, annotations, and Vulgate references.
    Uses pattern matching for commentary trigger words below 70% page height.
    """
    text_up = text.upper()
    if re.search(r'\b(C[ÁA]P[IÍLl1]TULO|CAPUT|[SŚ]ALMO|PSALMO)\b', text_up):
        return False
        
    text_clean = text.strip()
    if re.match(r'^\d{1,3}\s*[\./,;-]', text_clean):
        return False
        
    if y_coord >= page_h * 0.70:
        commentary_pattern = r'\b(?:Véase|Vulgata|Hebreo|Expositores|San Gerónimo|San Agustín|Crisóstomo|Setenta)\b'
        if re.match(r'^(?:\d{1,2}|[a-z]|\*|†|‡)\s+[A-ZÁÉÍÓÚa-z]', text_clean) or re.search(commentary_pattern, text_clean, re.IGNORECASE):
            return True
            
    if y_coord >= page_h * 0.95:
        return True
        
    return False


def is_latin_line(text: str) -> bool:
    """
    Screens out lines belonging to parallel Latin Vulgate text columns
    by checking the density of standard Latin stop words.
    """
    text_clean = re.sub(r'[^\w\s]', ' ', text.lower())
    tokens = text_clean.split()
    if not tokens:
        return False
        
    latin_matches = sum(1 for tok in tokens if tok in LATIN_STOP_WORDS)
    return (latin_matches / len(tokens)) > 0.40

# ==============================================================================
# CHAPTER & VERSE PARSING HELPERS
# ==============================================================================

def extract_chapter_number(text: str, expected_ch: Optional[int] = None) -> Optional[int]:
    """
    Extracts chapter numbers from 'CAPITULO IV' or 'SALMO IX' headers.
    Includes sequence-aware error correction for Tesseract OCR Roman numeral misreads (e.g. IV -> IX).
    """
    # Ignore mid-sentence inline references like 'en el capítulo V', 'en el Salmo segundo'
    if re.search(r'\b(?:en|del|al|con|sobre)\s+(?:el\s+)?(?:C[ÁA]P[IÍLl1]TULO|CAPUT|[SŚ]ALMO|PSALMO)\b', text, re.IGNORECASE):
        return None
        
    text_clean = re.sub(r'[^\w\s]', ' ', text.upper())
    match = re.search(r'^\s*(?:C[ÁA]P[IÍLl1]TULO|CAPUT|[SŚ]ALMO|PSALMO)\s+([A-Z0-9ÁÉÍÓÚ]+)', text_clean)
    if not match:
        match = re.search(r'\b(?:C[ÁA]P[IÍLl1]TULO|CAPUT|[SŚ]ALMO|PSALMO)\s+([A-Z0-9ÁÉÍÓÚ]+)', text_clean)
        
    if match:
        tok = match.group(1)
        val = None
        if tok in ROMAN_NUMERALS:
            val = ROMAN_NUMERALS[tok]
        elif tok.isdigit():
            val = int(tok)
            
        if val is not None:
            if expected_ch is not None and expected_ch > 0:
                if val == expected_ch:
                    return val
                # Handle specific Tesseract Roman numeral misreads
                if val == 4 and expected_ch == 9:
                    return 9
                if val == 6 and expected_ch == 11:
                    return 11
                if val == 7 and expected_ch == 12:
                    return 12
                # Handle Tesseract extra 'X' misread (e.g. XVII -> XXVII where val == expected_ch + 10)
                if val in (expected_ch + 10, expected_ch + 20):
                    return expected_ch
                # Accept sequential transitions (val within 5 of expected_ch)
                if abs(val - expected_ch) <= 5:
                    return val
            return val
    return None


def split_inline_verses(text: str, current_v: int = 0) -> List[Tuple[Optional[int], str]]:
    """
    Splits OCR text lines that contain inline verse number prefixes (e.g. '1 Tú pues, hijo mio...').
    Enforces monotonic verse number progression to prevent inline footnote reference numbers
    (e.g., 'Señor 5, y saltaré') from falsely resetting the current verse counter.
    """
    text = text.translate(str.maketrans("⁰¹²³⁴⁵⁶⁷⁸⁹", "0123456789"))
    pattern = r'(?:^|[\s\?!\.,;:\-\—«“]+)(\d{1,3})\s*[\./,;:)\-\—«“]*\s*(?=[A-ZÁÉÍÓÚÑa-z"«“])'
    
    parts = re.split(pattern, text)
    if len(parts) <= 1:
        return [(None, text)]
        
    segments = []
    if parts[0].strip():
        segments.append((None, parts[0].strip()))
        
    i = 1
    while i < len(parts):
        v_num_str = parts[i]
        seg_content = parts[i+1] if i+1 < len(parts) else ""
        if v_num_str and v_num_str.isdigit():
            val = int(v_num_str)
            # Accept as verse number if >= current_v or starting fresh / verse 1
            if current_v == 0 or val >= current_v or val == 1:
                segments.append((val, seg_content.strip()))
            else:
                # Treat backward number jump as inline footnote reference text
                segments.append((None, f"{v_num_str} {seg_content.strip()}"))
        i += 2
        
    return segments


def sort_page_columns(scripture_lines: List[dict]) -> List[dict]:
    """
    Calculates per-page dynamic column midpoints and sorts lines sequentially
    (left column top-to-bottom, followed by right column top-to-bottom).
    """
    min_x = min(l['box'][0] for l in scripture_lines)
    max_x = max(l['box'][2] for l in scripture_lines)
    mid_x = (min_x + max_x) / 2
    
    left_column = [l for l in scripture_lines if l['box'][0] < mid_x]
    right_column = [l for l in scripture_lines if l['box'][0] >= mid_x]
    
    left_column.sort(key=lambda l: l['box'][1])
    right_column.sort(key=lambda l: l['box'][1])
    
    if len(right_column) < 3:
        page_sorted = scripture_lines[:]
        page_sorted.sort(key=lambda l: l['box'][1])
        return page_sorted
    else:
        return left_column + right_column

# ==============================================================================
# CORE COMPILER LOGIC
# ==============================================================================

def compile_book(book_id: str, volume: int, start_page: int, end_page: int, ocr_raw_dir: str, output_dir: str) -> None:
    """
    Compiles raw OCR JSON pages for a specified book into a structured USFM file.
    """
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
            
        raw_lines = data.get("lines", [])
        if not raw_lines:
            continue
            
        page_h = max(l['box'][3] for l in raw_lines)
        has_body_cap = any(l['box'][1] > 100 and re.search(r'\bC[ÁA]P[IÍLl1\s]*TULO\b', l['text'].upper()) for l in raw_lines)
        
        scripture_lines = []
        for line in raw_lines:
            if has_body_cap and line["box"][1] < 75 and re.search(r'\bC[ÁA]P[IÍLl1\s]*TULO\b', line["text"].upper()):
                continue
            if not is_page_header_line(line["text"], line["box"][1], page_h, line["box"][0], volume):
                if not is_footnote_line(line["text"], line["box"][1], page_h) and not is_latin_line(line["text"]):
                    scripture_lines.append(line)
        if not scripture_lines:
            continue
            
        all_lines.extend(sort_page_columns(scripture_lines))
        
    verses: Dict[int, Dict[int, List[str]]] = {}
    current_chapter = 0
    current_verse = 0
    
    for line_data in all_lines:
        raw_text = clean_text_line(line_data['text'])
        if not raw_text:
            continue
            
        text_upper = raw_text.upper()
        
        # Check if line is inline verse prefix like 'CAP. 32. Pues...' or 'CaP. 11. El Señor...'
        cap_v_match = re.match(r'^C[aA][pP]\.?\s*(\d{1,3})[\./,;-]*\s*(.*)', raw_text)
        if cap_v_match:
            current_verse = int(cap_v_match.group(1))
            v_text = cap_v_match.group(2).strip()
            if current_chapter == 0:
                current_chapter = 1
                verses[current_chapter] = {}
            if current_chapter not in verses:
                verses[current_chapter] = {}
            if current_verse not in verses[current_chapter]:
                verses[current_chapter][current_verse] = []
            if v_text:
                verses[current_chapter][current_verse].append(v_text)
            continue
            
        # Fix 1KI OCR typos and verse prefix rules
        if book_id == "1KI":
            if current_chapter == 1 and current_verse in [50, 51] and "hombre de bien" in raw_text:
                raw_text = "52. " + raw_text
            elif current_chapter == 1 and current_verse in [51, 52] and "Envió pues el rey" in raw_text:
                raw_text = "53. " + raw_text
            elif current_chapter == 4 and current_verse in [27, 28] and "Dió tambien Dios" in raw_text:
                raw_text = "29. " + raw_text
            elif current_chapter == 4 and current_verse in [28, 29] and "sabiduría de Salomón" in raw_text:
                raw_text = "30. " + raw_text
            elif current_chapter == 4 and current_verse in [29, 30] and "mas sabio" in raw_text:
                raw_text = "31. " + raw_text
            elif current_chapter == 4 and current_verse in [32, 33] and "pueblos" in raw_text:
                raw_text = "34. " + raw_text
            elif current_chapter == 7 and current_verse in [17, 18] and "Asimismo los capiteles" in raw_text:
                raw_text = "19. " + raw_text
            elif current_chapter == 7 and current_verse in [18, 19] and "de nuevo otros capiteles" in raw_text:
                raw_text = "20. " + raw_text
            elif current_chapter == 15 and current_verse in [1, 2] and "todos los pecados" in raw_text:
                raw_text = "3. " + raw_text
            elif current_chapter == 17 and current_verse in [20, 21] and "Escuchó el Señor" in raw_text:
                raw_text = "22. " + raw_text
            elif current_chapter == 18 and current_verse in [23, 24] and "Dijo pues Elías" in raw_text:
                raw_text = "25. " + raw_text
            elif current_chapter == 20 and current_verse in [4, 5] and "Mañana pues" in raw_text:
                raw_text = "6. " + raw_text

        # Fix 2SA OCR typos and verse prefix rules
        if book_id == "2SA":
            if current_chapter == 7 and current_verse == 26 and "Oracion" in raw_text:
                raw_text = "27. " + raw_text
            elif current_chapter == 7 and current_verse == 27 and "Señor Dios" in raw_text:
                raw_text = "28. " + raw_text
            elif current_chapter == 7 and current_verse == 28 and "Ahora pues" in raw_text:
                raw_text = "29. " + raw_text
            elif current_chapter == 11 and current_verse == 25 and "mujer" in raw_text:
                raw_text = "26. " + raw_text
            elif current_chapter == 18 and current_verse == 32 and "Turbado" in raw_text:
                raw_text = "33. " + raw_text
            elif current_chapter == 23 and current_verse == 26 and "Maharai" in raw_text:
                raw_text = "27. " + raw_text
            elif current_chapter == 23 and current_verse == 34 and "Eliam" in raw_text:
                raw_text = "35. " + raw_text

        # Fix 1SA OCR typos and verse prefix rules
        if book_id == "1SA":
            if current_chapter == 7 and "CAPIOVILI" in text_upper:
                current_chapter = 8
                current_verse = 0
                if current_chapter not in verses:
                    verses[current_chapter] = {}
                continue
            elif current_chapter == 15 and current_verse == 35 and "Ramatha" in raw_text:
                raw_text = "36. " + raw_text

        # Fix JOS OCR typos and verse prefix rules
        if book_id == "JOS":
            if current_chapter == 3 and current_verse == 5 and "Tomad la arca" in raw_text:
                raw_text = "6. " + raw_text
            elif current_chapter == 3 and current_verse == 7 and "sacerdotes" in raw_text:
                raw_text = "8. " + raw_text
            elif current_chapter == 4 and current_verse == 1 and "Escoged doce" in raw_text:
                raw_text = "2. " + raw_text
            elif current_chapter == 6 and current_verse == 24 and "Rahab ramera" in raw_text:
                raw_text = "25. " + raw_text
            elif current_chapter == 9 and current_verse == 4 and "remiendos" in raw_text:
                raw_text = "5. " + raw_text
            elif current_chapter == 9 and current_verse == 5 and "fueron á Josué" in raw_text:
                raw_text = "6. " + raw_text
            elif current_chapter == 10 and current_verse == 9 and "aterró" in raw_text:
                raw_text = "10. " + raw_text
            elif current_chapter == 11 and current_verse == 6 and "Vino pues Josué" in raw_text:
                raw_text = "7. " + raw_text
            elif current_chapter == 11 and current_verse == 9 and "dada la vuelta" in raw_text:
                raw_text = "10. " + raw_text
            elif current_chapter == 12 and current_verse == 17 and "Aphaec" in raw_text:
                raw_text = "18. " + raw_text
            elif current_chapter == 12 and current_verse == 21 and "Cedes" in raw_text:
                raw_text = "22. " + raw_text
            elif current_chapter == 14 and current_verse == 6 and "Cuarenta años" in raw_text:
                raw_text = "7. " + raw_text
            elif current_chapter == 14 and current_verse == 7 and "mis hermanos" in raw_text:
                raw_text = "8. " + raw_text
            elif current_chapter == 14 and current_verse == 8 and "juró Moysés" in raw_text:
                raw_text = "9. " + raw_text
            elif current_chapter == 15 and current_verse == 0 and "Fue pues la suerte" in raw_text:
                raw_text = "1. " + raw_text
            elif current_chapter == 15 and current_verse == 26 and "Bethphelet" in raw_text:
                raw_text = "27. " + raw_text
            elif current_chapter == 15 and current_verse == 29 and "Horma" in raw_text:
                raw_text = "30. " + raw_text
            elif current_chapter == 15 and current_verse == 34 and "Jerimoth" in raw_text:
                raw_text = "35. " + raw_text
            elif current_chapter == 15 and current_verse == 39 and "Cabbon" in raw_text:
                raw_text = "40. " + raw_text
            elif current_chapter == 15 and current_verse == 47 and "monte Jather" in raw_text:
                raw_text = "48. " + raw_text
            elif current_chapter == 15 and current_verse == 54 and "Maon, y Carmel" in raw_text:
                raw_text = "55. " + raw_text
            elif current_chapter == 19 and current_verse == 17 and "Jezrael" in raw_text:
                raw_text = "18. " + raw_text
            elif current_chapter == 19 and current_verse == 20 and "Remeth" in raw_text:
                raw_text = "21. " + raw_text
            elif current_chapter == 21 and current_verse == 1 and "Señor mandó" in raw_text:
                raw_text = "2. " + raw_text
            elif current_chapter == 21 and current_verse == 2 and "Dieron pues" in raw_text:
                raw_text = "3. " + raw_text
            elif current_chapter == 21 and current_verse == 4 and "demás de los hijos" in raw_text:
                raw_text = "5. " + raw_text
            elif current_chapter == 21 and current_verse == 6 and "hijos de Merari" in raw_text:
                raw_text = "7. " + raw_text
            elif current_chapter == 21 and current_verse == 7 and "dieron los hijos" in raw_text:
                raw_text = "8. " + raw_text
            elif current_chapter == 21 and current_verse == 17 and "Anathoth" in raw_text:
                raw_text = "18. " + raw_text
            elif current_chapter == 21 and current_verse == 25 and "Todas las ciudades" in raw_text:
                raw_text = "26. " + raw_text
            elif current_chapter == 22 and current_verse == 33 and "hijos de Ruben" in raw_text:
                raw_text = "34. " + raw_text
            elif current_chapter == 24 and current_verse == 28 and "murió Josué" in raw_text:
                raw_text = "29. " + raw_text

        # Fix NUM OCR typos and top header guards
        if book_id == "NUM":
            if current_chapter == 10 and "CAPITULO VIII" in text_upper:
                continue
            elif current_chapter == 10 and "CAPITULO IX" in text_upper:
                current_chapter = 11
                current_verse = 0
                if current_chapter not in verses:
                    verses[current_chapter] = {}
                continue
            elif current_chapter == 15 and "CAPITULO XIV" in text_upper:
                current_chapter = 15
                current_verse = 0
                if current_chapter not in verses:
                    verses[current_chapter] = {}
                continue
            elif current_chapter == 1 and current_verse == 12 and "Phegiel" in raw_text:
                raw_text = "13. " + raw_text
            elif current_chapter == 1 and current_verse == 14 and "Ahira" in raw_text:
                raw_text = "15. " + raw_text
            elif current_chapter == 1 and current_verse == 31 and "hijos de Joseph" in raw_text:
                raw_text = "32. " + raw_text
            elif current_chapter == 2 and current_verse == 31 and "número de los hijos" in raw_text:
                raw_text = "32. " + raw_text
            elif current_chapter == 2 and current_verse == 33 and "hiciéronlo los hijos" in raw_text:
                raw_text = "34. " + raw_text
            elif current_chapter == 3 and current_verse == 19 and "hijos de Merari" in raw_text:
                raw_text = "20. " + raw_text
            elif current_chapter == 3 and current_verse == 24 and "Tabernáculo del testimonio" in raw_text:
                raw_text = "25. " + raw_text
            elif current_chapter == 3 and current_verse == 45 and "rescate de los doscientos" in raw_text:
                raw_text = "46. " + raw_text
            elif current_chapter == 4 and current_verse == 43 and "cincuenta" in raw_text:
                raw_text = "44. " + raw_text
            elif current_chapter == 4 and current_verse == 44 and "familia" in raw_text:
                raw_text = "45. " + raw_text
            elif current_chapter == 7 and current_verse == 29 and "príncipe" in raw_text:
                raw_text = "30. " + raw_text
            elif current_chapter == 7 and current_verse == 30 and "escudilla" in raw_text:
                raw_text = "31. " + raw_text
            elif current_chapter == 7 and current_verse == 31 and "becerro" in raw_text:
                raw_text = "32. " + raw_text
            elif current_chapter == 11 and current_verse == 2 and "Llamóse pues" in raw_text:
                raw_text = "3. " + raw_text
            elif current_chapter == 11 and current_verse == 9 and "Oyó pues Moysés" in raw_text:
                raw_text = "10. " + raw_text
            elif current_chapter == 12 and current_verse == 6 and "siervo Moysés" in raw_text:
                raw_text = "7. " + raw_text
            elif current_chapter == 12 and current_verse == 7 and "boca á boca" in raw_text:
                raw_text = "8. " + raw_text
            elif current_chapter == 13 and current_verse == 10 and "tribu de Joseph" in raw_text:
                raw_text = "11. " + raw_text
            elif current_chapter == 13 and current_verse == 33 and "mónstruos" in raw_text:
                raw_text = "34. " + raw_text
            elif current_chapter == 15 and current_verse == 17 and "Díles: Cuando" in raw_text:
                raw_text = "18. " + raw_text
            elif current_chapter == 16 and current_verse == 37 and "cayeron quemados" in raw_text:
                raw_text = "38. " + raw_text
            elif current_chapter == 20 and current_verse == 13 and "Envió entre tanto" in raw_text:
                raw_text = "14. " + raw_text
            elif current_chapter == 20 and current_verse == 16 and "permitas" in raw_text:
                raw_text = "17. " + raw_text
            elif current_chapter == 22 and current_verse == 20 and "Balaam" in raw_text:
                raw_text = "21. " + raw_text
            elif current_chapter == 22 and current_verse == 31 and "Angel" in raw_text:
                raw_text = "32. " + raw_text
            elif current_chapter == 26 and current_verse == 54 and "distribuirá" in raw_text:
                raw_text = "55. " + raw_text
            elif current_chapter == 29 and current_verse == 34 and "octavo" in raw_text:
                raw_text = "35. " + raw_text
            elif current_chapter == 31 and current_verse == 21 and "oro, y la plata" in raw_text:
                raw_text = "22. " + raw_text
            elif current_chapter == 31 and current_verse == 28 and "Eleázaro" in raw_text:
                raw_text = "29. " + raw_text
            elif current_chapter == 31 and current_verse == 30 and "Hiciéronlo pues" in raw_text:
                raw_text = "31. " + raw_text
            elif current_chapter == 32 and current_verse == 4 and "Te pedimos" in raw_text:
                raw_text = "5. " + raw_text
            elif current_chapter == 32 and current_verse == 29 and "armados" in raw_text:
                raw_text = "30. " + raw_text
            elif current_chapter == 33 and current_verse == 49 and "Habló tambien" in raw_text:
                raw_text = "50. " + raw_text
            elif current_chapter == 33 and current_verse == 53 and "repartireis" in raw_text:
                raw_text = "54. " + raw_text
            elif current_chapter == 34 and current_verse == 27 and "Pedahel" in raw_text:
                raw_text = "28. " + raw_text
            elif current_chapter == 35 and current_verse == 7 and "se darán" in raw_text:
                raw_text = "8. " + raw_text
            elif current_chapter == 35 and current_verse == 22 and "piedra" in raw_text:
                raw_text = "23. " + raw_text
            elif current_chapter == 35 and current_verse == 32 and "contamineis" in raw_text:
                raw_text = "33. " + raw_text

        # Fix LEV OCR typos and top header guards
        if book_id == "LEV":
            if current_chapter == 11 and current_verse == 40 and "arrastra" in raw_text:
                raw_text = "41. " + raw_text
            elif current_chapter == 11 and current_verse == 41 and "cuatro piés" in raw_text:
                raw_text = "42. " + raw_text
            elif current_chapter == 11 and current_verse == 42 and "contaminar" in raw_text:
                raw_text = "43. " + raw_text
            elif current_chapter == 17 and current_verse == 0 and "Habló mas el Señor" in raw_text:
                raw_text = "1. " + raw_text
            elif current_chapter == 20 and current_verse == 25 and "santos para mí" in raw_text:
                raw_text = "26. " + raw_text
            elif current_chapter == 20 and current_verse == 26 and "pitónico" in raw_text:
                raw_text = "27. " + raw_text
            elif current_chapter == 22 and current_verse == 27 and "vaca ó oveja" in raw_text:
                raw_text = "28. " + raw_text
            elif current_chapter == 22 and current_verse == 31 and "profaneis" in raw_text:
                raw_text = "32. " + raw_text
            elif current_chapter == 26 and current_verse == 45 and "Estos son los juicios" in raw_text:
                raw_text = "46. " + raw_text

        # Fix GEN OCR typos and top header guards
        if book_id == "GEN":
            if current_chapter == 14 and "CAPITULO II" in text_upper and line_data["box"][1] > 100:
                current_chapter = 15
                current_verse = 0
                if current_chapter not in verses:
                    verses[current_chapter] = {}
                continue
            elif current_chapter == 27 and "CAPITULO XIX" in text_upper and line_data["box"][1] > 100:
                current_chapter = 28
                current_verse = 0
                if current_chapter not in verses:
                    verses[current_chapter] = {}
                continue

        # Fix JER OCR typos and top header guards
        if book_id == "JER":
            if current_chapter == 2 and raw_text.startswith("2s. Defiende"):
                raw_text = "25." + raw_text[3:]

        # Fix ISA OCR typos and top header guards
        if book_id == "ISA":
            if current_chapter == 5 and raw_text.startswith(". Ay de vosotros"):
                raw_text = "18. Ay de vosotros" + raw_text[16:]
            elif current_chapter == 22 and line_data["box"][1] < 100 and line_data["box"][0] > 500 and "CAPITULO XXII" in text_upper:
                current_chapter = 23
                current_verse = 0
                if current_chapter not in verses:
                    verses[current_chapter] = {}
                continue
            elif current_chapter == 23 and current_verse == 16 and raw_text.startswith("1. Y sucederá"):
                raw_text = "17." + raw_text[2:]
            elif current_chapter == 24 and current_verse == 4 and "inficionada" in raw_text:
                raw_text = "5. " + raw_text
            elif current_chapter == 28 and current_verse == 16 and "el granizo destruirá" in raw_text:
                raw_text = "17. " + raw_text
            elif current_chapter == 29 and current_verse == 20 and "pecar á los hombres" in raw_text:
                raw_text = "21. " + raw_text
            elif current_chapter == 30 and current_verse == 4 and "confundidos de un pueblo" in raw_text:
                raw_text = "5. " + raw_text
            elif current_chapter == 30 and current_verse == 26 and "nombre del Señor viene" in raw_text:
                raw_text = "27. " + raw_text
            elif current_chapter == 37 and current_verse == 21 and "Despreciote" in raw_text:
                raw_text = "22. " + raw_text
            elif current_chapter == 37 and current_verse == 22 and "afrentado" in raw_text:
                raw_text = "23. " + raw_text
            elif current_chapter == 37 and current_verse == 36 and ("despavorido" in raw_text or "Sennacherib" in raw_text):
                raw_text = "37. " + raw_text
            elif current_chapter == 37 and current_verse == 37 and "adorando" in raw_text:
                raw_text = "38. " + raw_text
            elif current_chapter == 38 and current_verse == 4 and "dí á Ezechias" in raw_text:
                raw_text = "5. " + raw_text
            elif current_chapter == 38 and current_verse == 19 and "salvo me has hecho" in raw_text:
                raw_text = "20. " + raw_text
            elif current_chapter == 38 and current_verse == 20 and "cataplasma" in raw_text:
                raw_text = "21. " + raw_text
            elif current_chapter == 38 and current_verse == 21 and "señal habré" in raw_text:
                raw_text = "22. " + raw_text
            elif current_chapter == 40 and current_verse == 17 and "quién pues" in raw_text:
                raw_text = "18. " + raw_text
            elif current_chapter == 40 and current_verse == 18 and "estatua de fundicion" in raw_text:
                raw_text = "19. " + raw_text
            elif current_chapter == 41 and current_verse == 19 and "vean, y sepan" in raw_text:
                raw_text = "20. " + raw_text
            elif current_chapter == 44 and current_verse == 10 and "socios suyos" in raw_text:
                raw_text = "11. " + raw_text
            elif current_chapter == 44 and current_verse == 12 and "carpintero tendió" in raw_text:
                raw_text = "13. " + raw_text
            elif current_chapter == 46 and current_verse == 2 and "Oidme, casa de Jacob" in raw_text:
                raw_text = "3. " + raw_text
            elif current_chapter == 47 and current_verse == 9 and "confiado has" in raw_text:
                raw_text = "10. " + raw_text
            elif current_chapter == 49 and current_verse == 23 and "quitará" in raw_text:
                raw_text = "24. " + raw_text
            elif current_chapter == 50 and current_verse == 6 and "auxiliador" in raw_text:
                raw_text = "7. " + raw_text
            elif current_chapter == 50 and current_verse == 8 and "me ayuda" in raw_text:
                raw_text = "9. " + raw_text
            elif current_chapter == 58 and current_verse == 4 and "este tal" in raw_text:
                raw_text = "5. " + raw_text
            elif current_chapter == 66 and current_verse == 11 and "derramaré" in raw_text:
                raw_text = "12. " + raw_text
            elif current_chapter == 66 and current_verse == 12 and "hijo" in raw_text:
                raw_text = "13. " + raw_text

        # Fix EXO OCR typos and top header guards
        if book_id == "EXO":
            if line_data["box"][1] < 65 and "CAPITULO" in text_upper:
                continue
            if current_chapter == 12 and "defecto 7" in raw_text:
                raw_text = raw_text.replace("defecto 7", "defecto")
            elif current_chapter == 25 and raw_text.startswith("21. Y la cubrirás"):
                raw_text = "24." + raw_text[3:]
            elif current_chapter == 28 and raw_text.startswith("3β."):
                raw_text = "36." + raw_text[3:]
            elif current_chapter == 30 and raw_text.startswith("2 Que tenga"):
                raw_text = "2. Que tenga " + raw_text[11:].strip()
            elif current_chapter == 34 and raw_text.startswith("1o."):
                raw_text = "10." + raw_text[3:]

        # Fix EZK OCR typos and top header guards
        if book_id == "EZK":
            if line_data["box"][1] < 60 and "CAPITULO" in text_upper:
                continue
            if current_chapter == 23 and raw_text.startswith(". Oolla"):
                raw_text = raw_text.replace(". Oolla", "5. Oolla")
            elif current_chapter == 28 and "creacion" in raw_text:
                raw_text = re.sub(r'[\s\d³²¹⁴⁵⁶⁷⁸⁹0-9]+$', '', raw_text)
            elif current_chapter == 28 and current_verse == 13 and "trono de Dios" in raw_text:
                raw_text = "14. " + raw_text
            elif current_chapter == 36 and current_verse > 20 and raw_text.startswith("1 pueblo"):
                raw_text = raw_text[1:].strip()
            elif current_chapter == 36 and current_verse == 28 and raw_text.startswith("venir el trigo"):
                raw_text = "29. " + raw_text
            elif current_chapter == 36 and current_verse == 29 and raw_text.startswith("frutos de los"):
                raw_text = "30. " + raw_text
            elif current_chapter == 37 and current_verse == 14 and raw_text.startswith("16."):
                raw_text = raw_text.replace("16.", "15.")
            elif current_chapter == 39 and current_verse > 5 and raw_text.startswith("1 pábulo"):
                raw_text = raw_text[1:].strip()
            elif current_chapter == 39 and current_verse == 7 and raw_text.startswith("las picas"):
                raw_text = "9. " + raw_text
            elif current_chapter == 39 and current_verse == 9 and raw_text.startswith("armas; y disfrutarán"):
                raw_text = "10. " + raw_text
            elif current_chapter == 41 and "Santo de los Santos" in raw_text:
                raw_text = "4. " + raw_text
            elif current_chapter == 41 and raw_text.startswith("dor de la casa era de cuatro codos"):
                raw_text = "5. " + raw_text

        # Fix DEU OCR typos and top header guards
        if book_id == "DEU":
            if line_data["box"][1] < 50 and "CAPITULO" in text_upper:
                continue
            if current_chapter == 13 and raw_text.startswith("v. Si un hermano"):
                raw_text = raw_text.replace("v. Si un hermano", "6. Si un hermano")
            elif current_chapter == 19 and raw_text.startswith(". Allanando"):
                raw_text = raw_text.replace(". Allanando", "3. Allanando")
            elif current_chapter == 24 and raw_text.startswith(". Acuérdate"):
                raw_text = raw_text.replace(". Acuérdate", "22. Acuérdate")

        # Fix EST OCR typos and top header guards
        if book_id == "EST":
            if line_data["box"][1] < 100 and re.search(r'\bCAPITULO\s+(III|V|VII|IX|X|XIII|XV|XVI)[\.\s]*$', text_upper):
                continue
            if current_chapter >= 8 and "CAPITULO IV" in text_upper:
                raw_text = raw_text.replace("CAPITULO IV", "CAPITULO IX").replace("Capitulo IV", "Capitulo IX")
                text_upper = raw_text.upper()
            elif current_chapter == 14 and raw_text.startswith("I. Asimismo"):
                raw_text = raw_text.replace("I.", "1.")
            elif current_chapter == 1 and raw_text.startswith("15.'"):
                raw_text = raw_text.replace("15.'", "15.")

        # Fix JDG OCR typos
        if book_id == "JDG":
            if current_chapter == 3 and raw_text.startswith("a0. Quedó"):
                raw_text = raw_text.replace("a0.", "30.")
            elif current_chapter == 8 and raw_text.startswith("31. No acordándose"):
                raw_text = raw_text.replace("31.", "34.")
            elif current_chapter == 9 and raw_text.startswith("51") and "Abimelech" in raw_text:
                raw_text = re.sub(r'^51\.?', '54.', raw_text)
            elif current_chapter == 11 and raw_text.startswith("3. Pero al volver"):
                raw_text = raw_text.replace("3.", "34.")
            elif current_chapter == 13 and raw_text.startswith("21. Parió"):
                raw_text = raw_text.replace("21.", "24.")
            elif current_chapter == 16 and raw_text.startswith("21. Lo que viendo"):
                raw_text = raw_text.replace("21.", "24.")
            elif current_chapter == 1 and raw_text.startswith("10. Y el Señor estuvo"):
                raw_text = raw_text.replace("10.", "19.")
            elif current_chapter == 13 and raw_text.startswith("l0."):
                raw_text = raw_text.replace("l0.", "10.")
            elif current_chapter == 20 and raw_text.startswith("10. Con esto los hijos"):
                raw_text = raw_text.replace("10.", "19.")

        # Check for chapter header (e.g. CAPITULO I)
        if book_id == "LAM":
            if line_data["box"][1] < 100 and re.search(r'\bCAPITULO\s+(II|III|IV|V)[\.\s]*$', text_upper):
                continue
            if current_chapter == 3:
                if "TeT. 2." in raw_text or "TET. 2." in text_upper:
                    current_verse = 25
                elif "T. 26." in raw_text:
                    current_verse = 26
                elif "Jo..Present" in raw_text or "JO..PRESENT" in text_upper:
                    current_verse = 30
                elif "CAP. 32." in raw_text:
                    current_verse = 32
                elif raw_text.startswith("CA.") and "Puesto que no" in raw_text:
                    current_verse = 33

        if book_id == "1TI":
            if line_data["box"][1] < 100 and ("CAPITULO IV" in text_upper or "CAPITULO VI" in text_upper):
                continue

        if book_id == "GAL":
            if line_data["box"][1] < 100 and ("CAPITULO III" in text_upper or "CAPITULO VI" in text_upper):
                continue

        if book_id == "PHP":
            if line_data["box"][1] < 100 and "CAPITULO III" in text_upper:
                continue

        if book_id == "1PE":
            if line_data["box"][1] < 100 and ("CAPITULO III" in text_upper or "CAPITULO IV" in text_upper):
                continue

        if book_id == "1JN":
            if line_data["box"][1] < 100 and "CAPITULO V" in text_upper:
                continue

        if book_id == "2PE":
            if line_data["box"][1] < 100 and "CAPITULO III" in text_upper:
                continue

        if book_id == "MAL":
            if text_upper in ["00G", "00 G", "00"]:
                continue

        if book_id == "ZEC":
            if line_data["box"][1] < 100 and re.search(r'\bCAPITULO\s+X[\.\s]*$', text_upper):
                continue

        if book_id == "1CO":
            if line_data["box"][1] < 100 and (re.search(r'\bCAPITULO\s+X[\.\s]*$', text_upper) or re.search(r'\bCAPITULO\s+XI[\.\s]*$', text_upper)):
                continue
            if "en pos de los ídolos" in raw_text or "en pos de los idolos" in raw_text:
                current_chapter = 12
                current_verse = 2

        if book_id == "JOL":
            if line_data["box"][1] < 100 and "CAPITULO III" in text_upper:
                continue

        if book_id == "1TH":
            if line_data["box"][1] < 100 and "CAPITULO IV" in text_upper:
                continue
            if current_chapter == 1 and current_verse == 0 and ("I. Pablo" in raw_text or "Pablo, y Silvano" in raw_text):
                current_verse = 1
            elif "Por cuyo motivo" in raw_text:
                current_chapter = 3
                current_verse = 1

        if book_id == "HOS":
            if line_data["box"][1] < 70 and "CAPITULO" in text_upper:
                continue
            if "La maldicion y la mentira" in raw_text or "La maldición y la mentira" in raw_text:
                current_chapter = 4
                current_verse = 2

        if book_id == "2CO":
            if "Y yo os acogeré" in raw_text or "Y yo os acogeré:" in raw_text:
                current_chapter = 6
                current_verse = 18
            elif "Y así no ponemos nosotros la mira" in raw_text:
                current_chapter = 4
                current_verse = 18
            elif "Con lo que tiramos" in raw_text:
                current_chapter = 8
                current_verse = 20
            elif "de su buen corazon:" in raw_text or "de su buen corazon" in raw_text:
                current_chapter = 8
                current_verse = 2
            elif "Llevando tambien el Evangelio" in raw_text or "Llevando también el Evangelio" in raw_text:
                current_chapter = 10
                current_verse = 16

        if book_id == "COL":
            if line_data["box"][1] < 100 and "CAPITULO III" in text_upper:
                continue
            if "CAPITULO VI" in text_upper:
                current_chapter = 4
                current_verse = 0
                if current_chapter not in verses:
                    verses[current_chapter] = {}
                continue

        if book_id == "JAM":
            if line_data["box"][1] < 100 and ("CAPITULO III" in text_upper or "CAPITULO V" in text_upper):
                continue

        if book_id == "EPH" and "trabado todo el" in raw_text:
            current_chapter = 2

        if book_id == "RUT":
            if line_data["box"][1] < 100 and "CAPITULO III" in text_upper:
                continue
            if current_chapter == 2 and ("Noemí procura casar" in raw_text or "Ese Booz, con cuyas criadas" in raw_text):
                current_chapter = 3
                current_verse = 0

        if book_id == "SNG":
            if "Ea ven, querido Esposo" in raw_text or "Ea ven" in raw_text:
                current_chapter = 7
            elif current_chapter == 5 and "jacintos" in raw_text:
                current_verse = 14

        is_verse_start = bool(re.match(r'^\d{1,3}\s*[\./,;-]', raw_text)) or (book_id == "LAM" and bool(re.match(r'^[A-Z]{1,8}[\.:\s]*\d{1,3}\s*[\./,;-]?', text_upper)))
        if not is_verse_start and re.search(r'\b(C[ÁA]P[IÍLl1]TULO|CAPUT|[SŚ]ALMO|PSALMO)\b', text_upper) and not re.search(r'^\d+\s+CAP', text_upper):
            ch_num = extract_chapter_number(raw_text, expected_ch=current_chapter + 1)
            if ch_num is not None:
                current_chapter = ch_num
                current_verse = 0
                if current_chapter not in verses:
                    verses[current_chapter] = {}
                continue

        if book_id == "OBA" and current_verse == 17 and ("llama la casa" in raw_text or "casa de Joseph" in raw_text):
            current_verse = 18
            if current_verse not in verses[1]:
                verses[1][current_verse] = []
            verses[1][current_verse].append(raw_text)
            continue

        # Parse verses and verse segments
        segments = split_inline_verses(raw_text, current_v=current_verse)
        
        for v_num, seg_text in segments:
            seg_text = clean_text_line(seg_text)
            if not seg_text:
                continue

            # GEN verse splits and transitions
            if book_id == "GEN":
                if current_chapter == 1 and current_verse == 27 and "Bendíjolos Dios" in seg_text:
                    current_verse = 28
                elif current_chapter == 1 and current_verse == 28 and "Dijo tambien Dios" in seg_text:
                    current_verse = 29
                elif current_chapter == 2 and current_verse == 5 and "fuente" in seg_text:
                    current_verse = 6
                elif current_chapter == 7 and current_verse == 4 and "Hizo pues Noé" in seg_text:
                    current_verse = 5
                elif current_chapter == 7 and current_verse == 23 and "prevalecieron" in seg_text:
                    current_verse = 24
                elif current_chapter == 14 and current_verse == 13 and "Oyendo pues Abram" in seg_text:
                    current_verse = 14
                elif current_chapter == 14 and current_verse == 14 and "dividiendo" in seg_text:
                    current_verse = 15
                elif current_chapter == 14 and current_verse == 15 and "recobró" in seg_text:
                    current_verse = 16
                elif current_chapter == 14 and current_verse == 16 and "Salió el rey" in seg_text:
                    current_verse = 17
                elif current_chapter == 14 and current_verse == 17 and "Melchisedech" in seg_text:
                    current_verse = 18
                elif current_chapter == 14 and current_verse == 18 and "bendijo" in seg_text:
                    current_verse = 19
                elif current_chapter == 14 and current_verse == 19 and "bendito sea" in seg_text:
                    current_verse = 20
                elif current_chapter == 14 and current_verse == 20 and "Dijo el rey" in seg_text:
                    current_verse = 21
                elif current_chapter == 14 and current_verse == 21 and "respondió Abram" in seg_text:
                    current_verse = 22
                elif current_chapter == 14 and current_verse == 22 and "hilo" in seg_text:
                    current_verse = 23
                elif current_chapter == 14 and current_verse == 23 and "comido" in seg_text:
                    current_verse = 24
                elif current_chapter == 15 and current_verse == 9 and "Tomó Abram" in seg_text:
                    current_verse = 10
                elif current_chapter == 15 and current_verse == 10 and "descendian" in seg_text:
                    current_verse = 11
                elif current_chapter == 15 and current_verse == 11 and "sol" in seg_text:
                    current_verse = 12
                elif current_chapter == 24 and current_verse == 37 and "sino que irás" in seg_text:
                    current_verse = 38
                elif current_chapter == 26 and current_verse == 23 and "apareciósele" in seg_text:
                    current_verse = 24
                elif current_chapter == 27 and current_verse == 22 and "conoció" in seg_text:
                    current_verse = 23
                elif current_chapter == 27 and current_verse == 28 and "sírvante" in seg_text:
                    current_verse = 29
                elif current_chapter == 27 and current_verse == 35 and "Jacob" in seg_text:
                    current_verse = 36
                elif current_chapter == 27 and current_verse == 38 and "grosura" in seg_text:
                    current_verse = 39
                elif current_chapter == 27 and current_verse == 39 and "espada" in seg_text:
                    current_verse = 40
                elif current_chapter == 27 and current_verse == 40 and "Aborrecia" in seg_text:
                    current_verse = 41
                elif current_chapter == 27 and current_verse == 41 and "Avisadas" in seg_text:
                    current_verse = 42
                elif current_chapter == 27 and current_verse == 42 and "Ahora pues" in seg_text:
                    current_verse = 43
                elif current_chapter == 27 and current_verse == 43 and "mitigue" in seg_text:
                    current_verse = 44
                elif current_chapter == 27 and current_verse == 44 and "olvide" in seg_text:
                    current_verse = 45
                elif current_chapter == 27 and current_verse == 45 and "Rebecca" in seg_text:
                    current_verse = 46
                elif current_chapter == 41 and current_verse == 0 and "Pasados dos años" in seg_text:
                    current_verse = 1
                elif current_chapter == 41 and current_verse == 1 and "siete vacas" in seg_text:
                    current_verse = 2
                elif current_chapter == 41 and current_verse == 5 and "siete espigas" in seg_text:
                    current_verse = 6
                elif current_chapter == 41 and current_verse == 6 and "nacian" in seg_text:
                    current_verse = 7
                elif current_chapter == 41 and current_verse == 7 and "recordó" in seg_text:
                    current_verse = 8
                elif current_chapter == 41 and current_verse == 8 and "acordándose" in seg_text:
                    current_verse = 9
                elif current_chapter == 41 and current_verse == 30 and "desvanecerá" in seg_text:
                    current_verse = 31
                elif current_chapter == 41 and current_verse == 41 and "anillo" in seg_text:
                    current_verse = 42
                elif current_chapter == 41 and current_verse == 47 and "juntóse" in seg_text:
                    current_verse = 48
                elif current_chapter == 48 and current_verse == 14 and "Bendijo Jacob" in seg_text:
                    current_verse = 15
                elif current_chapter == 48 and current_verse == 15 and "Angel" in seg_text:
                    current_verse = 16
                elif current_chapter == 48 and current_verse == 16 and "Viendo Joseph" in seg_text:
                    current_verse = 17
                elif current_chapter == 48 and current_verse == 17 and "Dijo á su padre" in seg_text:
                    current_verse = 18
                elif current_chapter == 48 and current_verse == 18 and "no lo quiso" in seg_text:
                    current_verse = 19
                elif current_chapter == 48 and current_verse == 19 and "bendíjolos" in seg_text:
                    current_verse = 20
                elif current_chapter == 48 and current_verse == 20 and "Dijo mas" in seg_text:
                    current_verse = 21
                elif current_chapter == 48 and current_verse == 21 and "Yo te doy" in seg_text:
                    current_verse = 22

            # EXO verse splits and transitions
            if book_id == "EXO":
                if current_chapter == 3 and current_verse == 17 and "Yo ya sé que el Rey" in seg_text:
                    current_verse = 19
                elif current_chapter == 3 and current_verse == 19 and "despojareis" in seg_text:
                    current_verse = 22
                elif current_chapter == 6 and current_verse == 25 and "sacaran de la tierra" in seg_text:
                    current_verse = 26
                elif current_chapter == 6 and current_verse == 26 and "hablaron" in seg_text:
                    current_verse = 27
                elif current_chapter == 6 and current_verse == 27 and "de Egypto," in seg_text:
                    current_verse = 28
                elif current_chapter == 6 and current_verse == 28 and ("todas las cosas" in seg_text or "Rey de Egypto" in seg_text):
                    current_verse = 29
                elif current_chapter == 12 and current_verse == 5 and "guardareis hasta" in seg_text:
                    current_verse = 6
                elif current_chapter == 12 and current_verse == 23 and ("ni haceros daño" in seg_text or "Guardareis esta" in seg_text):
                    current_verse = 24
                elif current_chapter == 12 and current_verse == 24 and ("dar el Señor, como" in seg_text or "tiene prometido" in seg_text):
                    current_verse = 25
                elif current_chapter == 12 and current_verse == 26 and ("cuando pasó de largo" in seg_text or "las casas de los hijos" in seg_text):
                    current_verse = 27
                elif current_chapter == 12 and current_verse == 28 and ("muerte á todos los primogénitos" in seg_text or "primogénito de Pharaon" in seg_text):
                    current_verse = 29
                elif current_chapter == 30 and current_verse == 35 and ("polvo muy fino" in seg_text or "reducido todo" in seg_text):
                    current_verse = 36
                elif current_chapter == 38 and current_verse == 8 and ("Formó despues el atrio" in seg_text or "meridional" in seg_text):
                    current_verse = 9

            # EZK verse splits and transitions
            if book_id == "EZK":
                if current_chapter == 3 and current_verse == 10 and ("fueron traidos" in seg_text or "traidos" in seg_text):
                    current_verse = 11
                elif current_chapter == 3 and current_verse == 16 and ("centinela" in seg_text or "boca" in seg_text):
                    current_verse = 17
                elif current_chapter == 6 and current_verse == 4 and ("simulacro" in seg_text or "presencia" in seg_text or "cad" in seg_text) and not seg_text.startswith("4."):
                    current_verse = 5
                elif current_chapter == 9 and current_verse == 8 and "de piedad" in seg_text:
                    current_verse = 10
                elif current_chapter == 9 and current_verse == 10 and "me mandaste" in seg_text:
                    current_verse = 11
                elif current_chapter == 12 and current_verse == 21 and "pararán todas las visiones" in seg_text:
                    current_verse = 22
                elif current_chapter == 12 and current_verse == 22 and ("vulgo" in seg_text or "llegar los dias" in seg_text):
                    current_verse = 23
                elif current_chapter == 16 and current_verse == 29 and "ramera y descarada" in seg_text:
                    current_verse = 30
                elif current_chapter == 16 and current_verse == 38 and "vestidos" in seg_text:
                    current_verse = 39
                elif current_chapter == 16 and current_verse == 39 and "espadas" in seg_text:
                    current_verse = 40
                elif current_chapter == 20 and current_verse == 39 and ("vuestras ofrendas" in seg_text or "monte santo" in seg_text):
                    current_verse = 40
                elif current_chapter == 20 and current_verse == 45 and ("campiña del Mediodía" in seg_text or "campiña" in seg_text):
                    current_verse = 46
                elif current_chapter == 23 and current_verse == 5 and "jóvenes gallardos" in seg_text:
                    current_verse = 6
                elif current_chapter == 23 and "en poder de los Assyrios" in seg_text:
                    current_verse = 7
                elif current_chapter == 25 and current_verse == 6 and "polvo" in seg_text:
                    current_verse = 7
                elif current_chapter == 28 and current_verse == 4 and ("plata" in seg_text or "tesoros" in seg_text):
                    current_verse = 5
                elif current_chapter == 28 and current_verse == 5 and "como si fuera de un Dios" in seg_text:
                    current_verse = 6
                elif current_chapter == 28 and current_verse == 8 and ("heridos" in seg_text or "dirás" in seg_text or "de matar" in seg_text):
                    current_verse = 9
                elif current_chapter == 36 and current_verse == 26 and "guardeis mis" in seg_text:
                    current_verse = 27
                elif current_chapter == 36 and current_verse == 31 and "tenedlo así" in seg_text:
                    current_verse = 32
                elif current_chapter == 36 and current_verse == 32 and "repararé" in seg_text:
                    current_verse = 33
                elif current_chapter == 46 and current_verse == 17 and "heredad del pueblo" in seg_text:
                    current_verse = 18
                elif current_chapter == 46 and current_verse == 18 and ("caia hácia el Poniente" in seg_text or "Poniente" in seg_text):
                    current_verse = 19

            # DEU verse splits and transitions
            if book_id == "DEU":
                if current_chapter == 1 and current_verse == 25 and "á la palabra de Dios" in seg_text:
                    current_verse = 26
                elif current_chapter == 3 and current_verse == 28 and ("Phogor" in seg_text or "templo del" in seg_text):
                    current_verse = 29
                elif current_chapter == 5 and current_verse == 19 and "falso testimonio" in seg_text:
                    current_verse = 20
                elif current_chapter == 11 and current_verse == 21 and "estrechándoos" in seg_text:
                    current_verse = 22
                elif current_chapter == 11 and current_verse == 22 and "que vosotros" in seg_text:
                    current_verse = 23
                elif current_chapter == 20 and current_verse == 19 and "córtalos" in seg_text:
                    current_verse = 20
                elif current_chapter == 22 and current_verse == 10 and ("buey" in seg_text or "asno" in seg_text):
                    parts = re.split(r'(buey)', seg_text, maxsplit=1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 11
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("".join(parts[1:]))
                    continue
                elif current_chapter == 29 and current_verse == 17 and "cuyo corazon" in seg_text:
                    current_verse = 18
                elif current_chapter == 29 and current_verse == 18 and "aunque me abandone" in seg_text:
                    current_verse = 19
                elif current_chapter == 31 and current_verse == 0 and "cántico" in seg_text:
                    current_verse = 1
                elif current_chapter == 31 and current_verse == 1 and ("pasar ese rio" in seg_text or "pasado ese" in seg_text):
                    current_verse = 2
                elif current_chapter == 31 and current_verse == 5 and "amedrenteis" in seg_text:
                    current_verse = 6
                elif current_chapter == 31 and ("abandonaré" in seg_text or "esconderé" in seg_text):
                    current_verse = 17
                elif current_chapter == 32 and current_verse == 44 and ("palabras" in seg_text or "c e preec" in seg_text):
                    current_verse = 45
                elif current_chapter == 32 and current_verse == 50 and "aguas de Contradiccion" in seg_text:
                    current_verse = 51

            # JDG verse splits
            if book_id == "JDG":
                if current_chapter == 5 and current_verse == 18 and ("reyes" in seg_text and "pelearon" in seg_text):
                    parts = re.split(r'(reyes de Chanaan|reyes)', seg_text, maxsplit=1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 19
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("".join(parts[1:]))
                    continue
                elif current_chapter == 6 and current_verse == 23 and ("Gedeon un altar" in seg_text or "altar al Señor" in seg_text or "Paz del Señor" in seg_text):
                    parts = re.split(r'(Gedeon un altar|altar al Señor|Paz del Señor)', seg_text, maxsplit=1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 24
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("".join(parts[1:]))
                    continue
                elif current_chapter == 11 and current_verse == 34 and "de cumplirle" in seg_text:
                    parts = seg_text.split("de cumplirle", 1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append(parts[0] + "de cumplirle")
                    current_verse = 35
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[1].strip():
                        verses[current_chapter][current_verse].append(parts[1].strip())
                    continue
                elif current_chapter == 20 and current_verse == 4 and ("Cuando" in seg_text or "unos hombres" in seg_text):
                    current_verse = 5
                elif current_chapter == 20 and current_verse == 5 and ("exceso tan" in seg_text or "abominable" in seg_text):
                    current_verse = 6
                elif current_chapter == 20 and current_verse == 6 and ("debeis hacer" in seg_text or "debeis" in seg_text):
                    current_verse = 7

            # LAM verse splits
            if book_id == "LAM":
                if current_chapter == 1 and current_verse == 17 and ("sus órdenes le irrité" in seg_text or "sus ordenes le irrite" in seg_text):
                    parts = re.split(r'(sus órdenes le irrité|sus ordenes le irrite)', seg_text, maxsplit=1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 18
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("".join(parts[1:]))
                    continue
                elif current_chapter == 3 and current_verse == 26 and "el yugo ya desde su mocedad" in seg_text:
                    parts = seg_text.split("el yugo ya desde su mocedad", 1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 27
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("el yugo ya desde su mocedad" + parts[1])
                    continue
                elif current_chapter == 3 and current_verse == 27 and "sobre sí el yugo" in seg_text:
                    parts = seg_text.split("sobre sí el yugo", 1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 28
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("sobre sí el yugo" + parts[1])
                    continue
                elif current_chapter == 3 and current_verse == 28 and "consigue lo que espera" in seg_text:
                    parts = seg_text.split("consigue lo que espera", 1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 29
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("consigue lo que espera" + parts[1])
                    continue
                elif current_chapter == 3 and current_verse == 30 and "Señor 13." in seg_text:
                    parts = seg_text.split("Señor 13.", 1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 31
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("Señor 13." + parts[1])
                    continue
                elif current_chapter == 3 and current_verse == 52 and "to la losa sobre mí" in seg_text:
                    parts = seg_text.split("to la losa sobre mí", 1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 53
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("to la losa sobre mí" + parts[1])
                    continue
                elif current_chapter == 3 and current_verse == 56 and "dijiste: No temas" in seg_text:
                    parts = seg_text.split("dijiste: No temas", 1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 57
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("dijiste: No temas" + parts[1])
                    continue
                elif current_chapter == 3 and current_verse == 64 and "las aflicciones que les enviarás" in seg_text:
                    parts = seg_text.split("las aflicciones que les enviarás", 1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 65
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("las aflicciones que les enviarás" + parts[1])
                    continue
                elif current_chapter == 4 and "obra de manos de alfarero" in seg_text:
                    parts = seg_text.split("obra de manos de alfarero", 1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 2
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("obra de manos de alfarero" + parts[1])
                    continue

            # 1TI Ch 2 verse splits
            if book_id == "1TI":
                if current_chapter == 2 and current_verse == 4 and "Jesu-Christo hombre" in seg_text:
                    parts = seg_text.split("Jesu-Christo hombre", 1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 5
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("Jesu-Christo hombre" + parts[1])
                    continue
                elif current_chapter == 2 and current_verse == 5 and "doctor de las Gentes" in seg_text:
                    parts = seg_text.split("doctor de las Gentes", 1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 6
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 7
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("doctor de las Gentes" + parts[1])
                    continue
                elif current_chapter == 2 and current_verse == 8 and "cabellos rizados" in seg_text:
                    parts = seg_text.split("cabellos rizados", 1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 9
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("cabellos rizados" + parts[1])
                    continue

            # GAL Ch 5 v13 split
            if book_id == "GAL":
                if current_chapter == 5 and "de libertad: cuidad solamente" in seg_text:
                    parts = seg_text.split("de libertad: cuidad solamente", 1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 13
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("de libertad: cuidad solamente" + parts[1])
                    continue

            # 1JN Ch 2 v15 & v16 splits
            if book_id == "1JN":
                if current_chapter == 2 and current_verse == 14 and "al mundo, ni las cosas mundanas" in seg_text:
                    parts = seg_text.split("al mundo, ni las cosas mundanas", 1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 15
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("al mundo, ni las cosas mundanas" + parts[1])
                    continue
                elif current_chapter == 2 and current_verse == 15 and "concupiscencia de los ojos" in seg_text:
                    parts = seg_text.split("concupiscencia de los ojos", 1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 16
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("concupiscencia de los ojos" + parts[1])
                    continue

            # MAL Ch 3 v9 split
            if book_id == "MAL":
                if current_chapter == 3 and current_verse == 8 and ("la nacion toda" in seg_text or "la nación toda" in seg_text):
                    parts = re.split(r'(la nacion toda|la nación toda)', seg_text, maxsplit=1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 9
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("".join(parts[1:]))
                    continue

            # ZEC Ch 9 v4 split
            if book_id == "ZEC":
                if current_chapter == 9 and current_verse == 3 and "pábulo del fuego" in seg_text:
                    parts = seg_text.split("pábulo del fuego", 1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 4
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("pábulo del fuego" + parts[1])
                    continue

            # ZEP Ch 2 v14 split
            if book_id == "ZEP":
                if current_chapter == 2 and current_verse == 13 and "poder." in seg_text:
                    parts = seg_text.split("poder.", 1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 14
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("poder." + parts[1])
                    continue

            # AMO Ch 8 verse splits
            if book_id == "AMO":
                if current_chapter == 8 and current_verse == 9 and "amargura." in seg_text:
                    parts = seg_text.split("amargura.", 1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 10
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("amargura." + parts[1])
                    continue
                elif current_chapter == 8 and current_verse == 10 and "palabra del Señor." in seg_text:
                    parts = seg_text.split("palabra del Señor.", 1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 11
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("palabra del Señor." + parts[1])
                    continue

            # 1CO Ch 14 verse split
            if book_id == "1CO":
                if current_chapter == 14 and current_verse == 25 and "inspirado de Dios para hacer un himno" in seg_text:
                    parts = seg_text.split("inspirado de Dios para hacer un himno", 1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 26
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("inspirado de Dios para hacer un himno" + parts[1])
                    continue

            # JOL Ch 2 verse splits
            if book_id == "JOL":
                if current_chapter == 2 and current_verse == 2 and "nadie pueda librarse" in seg_text:
                    parts = seg_text.split("nadie pueda librarse", 1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 3
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("nadie pueda librarse" + parts[1])
                    continue
                elif current_chapter == 2 and current_verse == 6 and "de su camino." in seg_text:
                    parts = seg_text.split("de su camino.", 1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 7
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("de su camino." + parts[1])
                    continue
                elif current_chapter == 2 and current_verse == 7 and "línea recta por su senda" in seg_text:
                    parts = seg_text.split("línea recta por su senda", 1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 8
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("línea recta por su senda" + parts[1])
                    continue

            # 1TH Ch 3, Ch 4 verse splits & typo fixes
            if book_id == "1TH":
                if current_chapter == 3 and current_verse == 10 and "dirigir nuestros pasos" in seg_text:
                    parts = seg_text.split("dirigir nuestros pasos", 1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 11
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("dirigir nuestros pasos" + parts[1])
                    continue
                elif current_chapter == 4 and current_verse == 1 and "del Señor Jesus." in seg_text:
                    parts = seg_text.split("del Señor Jesus.", 1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 2
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("del Señor Jesus." + parts[1])
                    continue
                elif current_chapter == 4 and "la voluntad de Dios" in seg_text:
                    parts = re.split(r'(\. Es e la voluntad|la voluntad de Dios)', seg_text, maxsplit=1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 3
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("".join(parts[1:]))
                    continue
                elif current_chapter == 4 and current_verse == 8 and "amaros unos" in seg_text:
                    parts = seg_text.split("amaros unos", 1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 9
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("amaros unos" + parts[1])
                    continue
                elif current_chapter == 4 and current_verse == 16 and "seremos arrebatados" in seg_text:
                    parts = seg_text.split("seremos arrebatados", 1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 17
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("seremos arrebatados" + parts[1])
                    continue
                elif current_chapter == 4 and "Consolaos pues los unos" in seg_text:
                    v_num = 18

            # HOS Ch 4, Ch 5 and Ch 8 verse splits
            if book_id == "HOS":
                if current_chapter == 4 and current_verse == 1 and "y el robo, y el" in seg_text:
                    parts = seg_text.split("y el robo, y el", 1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 2
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("y el robo, y el" + parts[1])
                    continue
                elif current_chapter == 5 and current_verse == 11 and "coma seré yo" in seg_text:
                    parts = seg_text.split("coma seré yo", 1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 12
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("coma seré yo" + parts[1])
                    continue
                elif current_chapter == 5 and "éste no podrá daros" in seg_text:
                    parts = seg_text.split("éste no podrá daros", 1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 13
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("éste no podrá daros" + parts[1])
                    continue
                elif current_chapter == 5 and ("presa y me iré" in seg_text or "tomaré, y no habrá" in seg_text or "la tomaré" in seg_text):
                    parts = re.split(r'(presa y me iré|tomaré, y no habrá|la tomaré)', seg_text, maxsplit=1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 14
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("".join(parts[1:]))
                    continue
                elif current_chapter == 8 and current_verse == 2 and ("Mas Israél" in seg_text or "Ma Is" in seg_text):
                    parts = re.split(r'(Mas Israél|Ma Is)', seg_text, maxsplit=1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 3
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("".join(parts[1:]))
                    continue
                elif current_chapter == 8 and current_verse == 3 and ("Ellos reinaron" in seg_text or "ídolos para su perdicion" in seg_text):
                    parts = re.split(r'(Ellos reinaron|ídolos para su perdicion)', seg_text, maxsplit=1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 4
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("".join(parts[1:]))
                    continue

            # COL 3:24 Tesseract typo fix (21 -> 24)
            if book_id == "COL" and current_chapter == 3 and "Sabiendo que recibireis" in seg_text:
                v_num = 24

            # RUT Ch 4:2-4 split fix using exact OCR text
            if book_id == "RUT" and current_chapter == 4 and current_verse == 2 and "vuelto del país" in seg_text:
                parts = re.split(r'(que ha vuelto|vuelto del pa[ií]s)', seg_text, maxsplit=1)
                if current_verse not in verses[current_chapter]:
                    verses[current_chapter][current_verse] = []
                if parts[0].strip():
                    verses[current_chapter][current_verse].append(parts[0].strip())
                current_verse = 3
                if current_verse not in verses[current_chapter]:
                    verses[current_chapter][current_verse] = []
                verses[current_chapter][current_verse].append("Noemí, " + "".join(parts[1:]))
                continue
            elif book_id == "RUT" and current_chapter == 4 and current_verse == 3 and "sino tú" in seg_text:
                parts = seg_text.split("sino tú", 1)
                if current_verse not in verses[current_chapter]:
                    verses[current_chapter][current_verse] = []
                if parts[0].strip():
                    verses[current_chapter][current_verse].append(parts[0].strip())
                current_verse = 4
                if current_verse not in verses[current_chapter]:
                    verses[current_chapter][current_verse] = []
                verses[current_chapter][current_verse].append("sino tú" + parts[1])
                continue
                
            if v_num is not None:
                if current_chapter == 0:
                    current_chapter = 1
                    verses[current_chapter] = {}
                current_verse = v_num
                
                # 2TH 2:15-16 split fix for Vulgate chapter mapping using exact OCR text
                if book_id == "2TH" and current_chapter == 2 and current_verse == 15 and "nuestro Señor" in seg_text:
                    parts = seg_text.split("nuestro Señor", 1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 16
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("nuestro Señor" + parts[1])
                    continue
                elif book_id == "2TH" and current_chapter == 2 and current_verse == 16 and "Aliente" in seg_text:
                    current_verse = 17
                # 1CO 12:1-2 split fix using exact OCR text
                elif book_id == "1CO" and current_chapter == 12 and current_verse == 1 and "en pos de los ídolos" in seg_text:
                    parts = seg_text.split("en pos de los ídolos", 1)
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    if parts[0].strip():
                        verses[current_chapter][current_verse].append(parts[0].strip())
                    current_verse = 2
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append("en pos de los ídolos" + parts[1])
                    continue

                if current_verse not in verses[current_chapter]:
                    verses[current_chapter][current_verse] = []
                verses[current_chapter][current_verse].append(seg_text)
            else:
                start_match = re.match(r'^(?:[A-Z]{1,8}[\.:\s]*)?(\d{1,3})\s*[\./,;-]*\s*(.*)', seg_text, re.IGNORECASE) if book_id == "LAM" else re.match(r'^(\d{1,3})\s*[\./,;-]*\s*(.*)', seg_text)
                if start_match and start_match.group(1):
                    if current_chapter == 0:
                        current_chapter = 1
                        verses[current_chapter] = {}
                    current_verse = int(start_match.group(1))
                    v_text = start_match.group(2).strip()
                    
                    if book_id == "2TH" and current_chapter == 2 and current_verse == 15 and "nuestro Señor" in v_text:
                        parts = v_text.split("nuestro Señor", 1)
                        if current_verse not in verses[current_chapter]:
                            verses[current_chapter][current_verse] = []
                        verses[current_chapter][current_verse].append(parts[0])
                        current_verse = 16
                        if current_verse not in verses[current_chapter]:
                            verses[current_chapter][current_verse] = []
                        verses[current_chapter][current_verse].append("Y nuestro Señor " + parts[1])
                        continue
                    elif book_id == "2TH" and current_chapter == 2 and current_verse == 16 and "Aliente" in v_text:
                        current_verse = 17

                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append(v_text)
                else:
                    if current_chapter > 0 and not seg_text.isdigit() and not re.match(r'^[—\-\s]+$', seg_text):
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
            summary_txt = clean_scripture_verse_text(summary_txt)
            usfm_lines.append(f"\\p {summary_txt}")
            
        for v in sorted(verses[ch].keys()):
            if v == 0:
                continue
            v_text = " ".join(verses[ch][v])
            v_text = clean_scripture_verse_text(v_text)
            if book_id == "EST" and ch == 9:
                v_text = v_text.replace("Pharsandatha", "Farsandata").replace("Delphon", "Delfon").replace("Esphatha", "Esfata").replace("Phoratha", "Forata").replace("Permesta", "Fermesta").replace("Phermesta", "Fermesta")
            usfm_lines.append(f"\\v {v} {v_text}")
            
    with open(output_path, "w", encoding="utf-8") as f_out:
        f_out.write("\n".join(usfm_lines) + "\n")
        
    print(f"  Successfully generated USFM file: {output_path}")

# ==============================================================================
# CLI & ENTRYPOINT
# ==============================================================================

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Compile raw OCR JSON files into structured USFM books.")
    parser.add_argument("--book", type=str, help="Book ID (e.g. GEN, TOB, HAB)")
    parser.add_argument("--volume", type=int, help="Volume number (1, 2, 3, or 4)")
    parser.add_argument("--start", type=int, help="Start page index")
    parser.add_argument("--end", type=int, help="End page index")
    parser.add_argument("--all", action="store_true", help="Compile all 73 Bible books")
    return parser.parse_args()


def main() -> None:
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
