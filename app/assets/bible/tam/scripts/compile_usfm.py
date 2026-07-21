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
    "GEN": "Genesis", "EXO": "Éxodo", "LEV": "Levítico", "NUM": "Números", "DEU": "Deuteronomio",
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

def clean_text_line(text):
    return " ".join(text.strip().split())

def parse_args():
    parser = argparse.ArgumentParser(description="Compile raw OCR JSON files into a structured USFM book.")
    parser.add_argument("--book", type=str, required=True, help="Book ID (e.g. GEN, TOB, JDT)")
    parser.add_argument("--volume", type=int, default=1, help="Volume number (1, 2, 3, or 4)")
    parser.add_argument("--start", type=int, required=True, help="Start page index (0-indexed)")
    parser.add_argument("--end", type=int, required=True, help="End page index (0-indexed)")
    return parser.parse_args()

def split_inline_verses(text):
    # This function splits a single string if it contains inline verse markers like:
    # "text. 28. Y text" or "text. 28 Y text"
    # It returns a list of tuples: (verse_num_or_None, segment_text)
    
    # Pattern 1: matching " 28. Y" or " 28. Creó" (number with dot, space, capitalized word)
    # Pattern 2: matching " 28 Y" or " 28 Creó" (number, space, capitalized word)
    # Let's write a regex that splits on these boundaries but captures the verse number
    pattern = r'\b(\d{1,3})\s*[\./,;-]\s+(?=[A-ZÁÉÍÓÚÑ])|\b(\d{1,3})\s+(?=[A-ZÁÉÍÓÚÑ])'
    
    parts = re.split(pattern, text)
    if len(parts) == 1:
        return [(None, text)]
        
    segments = []
    # re.split with groups returns: [pre_text, g1_match, g2_match, post_text, g1_match...]
    # Since we have two groups (one for dotted, one for non-dotted), one of them will be None.
    
    i = 0
    current_v = None
    while i < len(parts):
        part = parts[i]
        if part is None:
            i += 1
            continue
            
        if i % 3 == 0:
            # This is text
            if part.strip():
                segments.append((current_v, part.strip()))
        else:
            # This is a verse number (from group 1 or group 2)
            current_v = int(part)
        i += 1
        
    return segments

def main():
    args = parse_args()
    book_id = args.book.upper()
    
    if book_id not in BOOK_PREFIXES:
        print(f"Error: Unknown book ID {book_id}")
        sys.exit(1)
        
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    ocr_raw_dir = os.path.join(base_dir, "raw_ocr")
    output_dir = os.path.join(base_dir, "ocr")
    os.makedirs(output_dir, exist_ok=True)
    
    prefix = BOOK_PREFIXES[book_id]
    book_name = BOOK_NAMES[book_id]
    output_filename = f"{prefix}-{book_id}-SPA[B]TAM1836[pd].usfm"
    output_path = os.path.join(output_dir, output_filename)
    
    print(f"Compiling book {book_id} ({book_name}) from pages {args.start} to {args.end}...")
    
    # Load and sequence all text lines from JSON files
    all_lines = []
    
    for idx in range(args.start, args.end + 1):
        json_path = os.path.join(ocr_raw_dir, f"vol{args.volume}_page_{idx}.json")
        if not os.path.exists(json_path):
            print(f"Warning: Cached file {json_path} not found. Skipping page {idx}.")
            continue
            
        with open(json_path, "r", encoding="utf-8") as f_json:
            data = json.load(f_json)
            
        page_lines = data.get("lines", [])
        
        # Filter page headers (Y < 70) and footnotes (Y >= 1120)
        scripture_lines = [l for l in page_lines if 70 <= l['box'][1] < 1120]
        
        # Split columns: Left (X < 400), Right (X >= 400)
        left_column = [l for l in scripture_lines if l['box'][0] < 400]
        right_column = [l for l in scripture_lines if l['box'][0] >= 400]
        
        # Sort each column vertically by Y
        left_column.sort(key=lambda l: l['box'][1])
        right_column.sort(key=lambda l: l['box'][1])
        
        # Sequenced page lines
        all_lines.extend(left_column + right_column)
        
    print(f"Sequenced {len(all_lines)} layout text blocks. Parsing verses...")
    
    verses = {}
    current_chapter = 0
    current_verse = 0
    
    for line_data in all_lines:
        raw_text = clean_text_line(line_data['text'])
        if not raw_text:
            continue
            
        text_upper = raw_text.upper()
        
        # Detect chapter headers (e.g., "CAPITULO II", "CAPÍTULO PRIMERO")
        if text_upper.startswith("CAPITULO") or text_upper.startswith("CAPÍTULO"):
            current_chapter += 1
            current_verse = 0
            verses[current_chapter] = {}
            continue
            
        if current_chapter == 0:
            # We haven't encountered a chapter header yet. This is introduction matter.
            continue
            
        # Parse inline verse structures (splitting lines if they pack multiple verses)
        segments = split_inline_verses(raw_text)
        
        for v_num, seg_text in segments:
            seg_text = clean_text_line(seg_text)
            if not seg_text:
                continue
                
            if v_num is not None:
                # Started a new verse segment
                current_verse = v_num
                if current_verse not in verses[current_chapter]:
                    verses[current_chapter][current_verse] = []
                verses[current_chapter][current_verse].append(seg_text)
            else:
                # This is a block of text without a new verse number:
                # If it starts with a verse number at the very beginning (handled by split_inline_verses as None if first part is text, but let's check if the text itself starts with a verse number!)
                start_match = re.match(r'^(\d+)\s*[\./,;-]*\s+(.*)', seg_text)
                if start_match:
                    current_verse = int(start_match.group(1))
                    v_text = start_match.group(2).strip()
                    if current_verse not in verses[current_chapter]:
                        verses[current_chapter][current_verse] = []
                    verses[current_chapter][current_verse].append(v_text)
                else:
                    # Pure continuation text of the active verse
                    if not seg_text.isdigit() and "—" not in seg_text:
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
        
        # Write summary if present under verse 0
        if 0 in verses[ch] and verses[ch][0]:
            summary_txt = " ".join(verses[ch][0])
            usfm_lines.append(f"\\p {summary_txt}")
            
        for v in sorted(verses[ch].keys()):
            if v == 0:
                continue
            v_text = " ".join(verses[ch][v])
            # Basic cleanup of OCR artifacts inside the verse string
            v_text = re.sub(r'\s+', ' ', v_text).strip()
            usfm_lines.append(f"\\v {v} {v_text}")
            
    with open(output_path, "w", encoding="utf-8") as f_out:
        f_out.write("\n".join(usfm_lines) + "\n")
        
    print(f"Successfully generated USFM file: {output_path}")

if __name__ == "__main__":
    main()
