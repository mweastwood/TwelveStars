import os
import re
import unicodedata

# 3-letter USFM code mappings for Spanish names (including traditional Vulgate names)
# 3-letter USFM code mappings for Spanish names (including traditional Vulgate names)
SPANISH_NAMES = {
    "GEN": ["GENESIS"], 
    "EXO": ["EXODO"], 
    "LEV": ["LEVITICO"], 
    "NUM": ["NUMEROS"], 
    "DEU": ["DEUTERONOMIO"],
    "JOS": ["JOSUE"], 
    "JDG": ["JUECES"], 
    "RUT": ["RUT", "RUTH"],
    # Volume 2
    "1SA": ["SAMUEL", "REYES", "LIBRO I", "PRIMER LIBRO DE LOS REYES"], 
    "2SA": ["2 SAMUEL", "SEGUNDO DE SAMUEL", "II SAMUEL", "SEGUNDO LIBRO DE LOS REYES", "II REYES", "II. REYES", "LIBRO II", "II A LOS REYES", "IT SAMUEL", "11 SAMUEL"],
    "1KI": ["3 REYES", "TERCER LIBRO DE LOS REYES", "III REYES", "III. REYES", "LIBRO III", "III A LOS REYES", "111 REYES", "IT1 REYES"], 
    "2KI": ["4 REYES", "CUARTO LIBRO DE LOS REYES", "IV REYES", "IV. REYES", "LIBRO IV", "LIBRO IY", "IV A LOS REYES", "IY REYES", "1V REYES"],
    "1CH": ["PARALIPOMENON", "PARALIPOMENOS"], 
    "2CH": ["2 PARALIPOMENOS", "II PARALIPOMENOS", "II. PARALIPOMENON", "II PARALIPOMENON.", "IT PARALIPOMENOS", "11 PARALIPOMENOS"],
    "EZR": ["ESDRAS", "LIBRO I DE ESDRAS"], 
    "NEH": ["NEHEMIAS", "LIBRO DE NEHEMIAS"], 
    "TOB": ["TOBIAS"], 
    "JDT": ["JUDIT", "JUDITH"], 
    "EST": ["ESTER", "ESTHER", "LIBRO DE ESTHER", "LIBRO DE ESTER"], 
    "JOB": ["JOB", "LIBRO DE JOB"],
    # Volume 3
    "PSA": ["SALMOS", "SALTERIO"], 
    "PRO": ["PROVERBIOS", "LIBRO DE LOS PROVERBIOS"], 
    "ECC": ["ECCLESIASTES", "ECLESIASTES", "LIBRO DEL ECCLESIASTES"], 
    "SNG": ["CANTARES", "CANTAR DE LOS CANTARES"],
    "WIS": ["SABIDURIA", "LIBRO DE LA SABIDURIA"], 
    "SIR": ["ECLESIASTICO", "ECLESIÁSTICO", "LIBRO DEL ECLESIASTICO"],
    "ISA": ["ISAIAS", "ISAÍAS"], 
    "JER": ["JEREMIAS", "JEREMÍAS"], 
    "LAM": ["LAMENTACIONES", "TRENOS"], 
    "BAR": ["BARUC", "BARUCH"], 
    "EZK": ["EZEQUIEL", "EZECHIEL", "PROFECIA DE EZECHIEL"], 
    "DAN": ["DANIEL"],
    "HOS": ["OSEAS", "OSÉAS"], 
    "JOL": ["JOEL"], 
    "AMO": ["AMOS", "AMÓS"], 
    "OBD": ["ABDIAS", "ABDÍAS"], 
    "JON": ["JONAS", "JONÁS"], 
    "MIC": ["MICHEAS", "MIQUEAS", "MIQUÉAS"],
    "NAH": ["NAHUM"], 
    "HAB": ["HABACUC", "ABACUC"], 
    "ZEP": ["SOPHONIAS", "SOFONIAS", "SOFONÍAS"], 
    "HAG": ["AGGEO", "HAGEO"], 
    "ZEC": ["ZACHARIAS", "ZACARIAS", "ZACARÍAS"], 
    "MAL": ["MALACHIAS", "MALAQUIAS", "MALAQUÍAS"],
    "1MA": ["MACABEOS", "MACHABEOS"], 
    "2MA": ["2 MACABEOS", "II MACABEOS", "2 MACHABEOS", "II MACHABEOS", "LOS MACHABÉOS II", "LOS MACHABEOS II", "IT MACHABEOS", "11 MACHABEOS", "LIBRO II"],
    # Volume 4
    "MAT": ["MATEO", "SAN MATEO"], 
    "MRK": ["MARCOS", "SAN MARCOS"], 
    "LUK": ["LUCAS", "SAN LUCAS"], 
    "JHN": ["JUAN", "SAN JUAN"],
    "ACT": ["HECHOS", "HECHOS DE LOS APOSTOLES"], 
    "ROM": ["ROMANOS", "A LOS ROMANOS"], 
    "1CO": ["CORINTIOS", "CORINTHIOS"], 
    "2CO": ["2 CORINTIOS", "II CORINTIOS", "2 CORINTHIOS", "II CORINTHIOS", "SEGUNDA EPISTOLA", "IT CORINTHIOS", "11 CORINTHIOS", "II A LOS CORINTHIOS", "IT A LOS CORINTHIOS", "11 A LOS CORINTHIOS", "II A LOS CORINTIOS", "IT A LOS CORINTIOS", "11 A LOS CORINTIOS"], 
    "GAL": ["GALATAS", "A LOS GALATAS"], 
    "EFS": ["EFESIOS", "EPHESIOS", "A LOS EFESIOS", "A LOS EPHESIOS"], 
    "PHP": ["FILIPENSES", "PHILIPENSES", "PHILIPPENSES", "A LOS PHILIPPENSES"], 
    "COL": ["COLOSENSES", "COLOSSENSES", "A LOS COLOSSENSES"],
    "1TH": ["TESALONICENSES", "THESALONICENSES", "THESSALONICENSES"], 
    "2TH": ["2 TESALONICENSES", "II TESALONICENSES", "2 THESSALONICENSES", "II THESSALONICENSES", "II. A LOS THESSALONICENSES", "II A LOS THESSALONICENSES", "IT A LOS THESSALONICENSES", "11 A LOS THESSALONICENSES"],
    "1TI": ["TIMOTEO", "TIMOTHEO"], 
    "2TI": ["2 TIMOTEO", "II TIMOTEO", "2 TIMOTHEO", "II TIMOTHEO", "II. A TIMOTHEO", "II A TIMOTHEO", "IT A TIMOTHEO", "11 A TIMOTHEO"], 
    "TIT": ["TITO", "A TITO"], 
    "PHM": ["FILEMON", "PHILEMON", "A PHILEMON"], 
    "HEB": ["HEBREOS", "A LOS HEBREOS"],
    "JAS": ["SANTIAGO", "EPISTOLA DE SANTIAGO"], 
    "1PE": ["PEDRO"], 
    "2PE": ["2 PEDRO", "II PEDRO", "SEGUNDA DE SAN PEDRO", "II. DE SAN PEDRO", "II DE SAN PEDRO", "IT DE SAN PEDRO", "11 DE SAN PEDRO"], 
    "1JN": ["JUAN"], 
    "2JN": ["2 JUAN", "II JUAN", "SEGUNDA DE SAN JUAN", "II. DE SAN JUAN", "II DE SAN JUAN", "IT DE SAN JUAN", "11 DE SAN JUAN", "APOSTOL SAN JUAN"], 
    "3JN": ["3 JUAN", "III JUAN", "TERCERA DE SAN JUAN", "III. DE SAN JUAN", "III DE SAN JUAN", "IT1 DE SAN JUAN", "111 DE SAN JUAN", "APOSTOL SAN JUAN"],
    "JUD": ["JUDAS", "DE SAN JUDAS"], 
    "REV": ["APOCALIPSIS", "APOCALYPSI", "APOCALYPSIS", "APOCALIPSI", "REVELACION"]
}

VOLUME_LAYOUTS = {
    "vol1": ["GEN", "EXO", "LEV", "NUM", "DEU", "JOS", "JDG", "RUT"],
    "vol2": ["1SA", "2SA", "1KI", "2KI", "1CH", "2CH", "EZR", "NEH", "TOB", "JDT", "EST", "JOB"],
    "vol3": ["PSA", "PRO", "ECC", "SNG", "WIS", "SIR", "ISA", "JER", "LAM", "BAR", "EZK", "DAN", "HOS", "JOL", "AMO", "OBD", "JON", "MIC", "NAH", "HAB", "ZEP", "HAG", "ZEC", "MAL", "1MA", "2MA"],
    "vol4": ["MAT", "MRK", "LUK", "JHN", "ACT", "ROM", "1CO", "2CO", "GAL", "EFS", "PHP", "COL", "1TH", "2TH", "1TI", "2TI", "TIT", "PHM", "HEB", "JAS", "1PE", "2PE", "1JN", "2JN", "3JN", "JUD", "REV"]
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
    "CXV": 115, "CXIX": 119, "CXX": 120, "CXXV": 125, "CXXX": 130, "CXXXV": 135, "CXL": 140, "CXLII": 142, "CXLIII": 143, "CXLIV": 144, "CXLV": 145, "CXLVI": 146, "CXLVII": 147, "CXLVIII": 148, "CXLIX": 149, "CL": 150,
    "PRIMERO": 1, "SEGUNDO": 2, "TERCERO": 3, "CUARTO": 4, "QUINTO": 5, "SEXTO": 6, "SEPTIMO": 7, "OCTAVO": 8, "NOVENO": 9, "DECIMO": 10,
    "UNDECIMO": 11, "DUODECIMO": 12, "DECIMOTERCERO": 13, "DECIMOCUARTO": 14, "DECIMOQUINTO": 15, "DECIMOSEXTO": 16, "DECIMOSEPTIMO": 17, "DECIMOOCTAVO": 18, "DECIMONOVENO": 19, "VIGESIMO": 20,
    "UNICO": 1, "UNICO.": 1, "ÚNICO": 1, "ÚNICO.": 1
}

ALLOWED_STRUCTURAL = {
    "EL", "LA", "LOS", "DE", "DEL", "A", "O", "Y", "APOSTOL", "SAN", "S", 
    "EPISTOLA", "EPISTOLAS", "PROFECIA", "PROFECIAS", "CANTAR", "CANTARES",
    "SALMO", "SALMOS", "APOCALIPSIS", "HECHOS", "PARALIPOMENON", "PARALIPOMENOS",
    "LAMENTACIONES", "SABIDURIA", "SALTERIO", "ECLESIASTICO", 
    "PRIMER", "PRIMERO", "PRIMERA", "SEGUNDO", "SEGUNDA", "TERCER", "TERCERO", "TERCERA", "CUARTO",
    "UNICO", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X",
    "1", "2", "3", "4", "5", "6", "7", "8", "9",
    "LIBRO", "LIBROS"
}

def normalize_text(text):
    text = "".join(c for c in unicodedata.normalize('NFD', text) if unicodedata.category(c) != 'Mn')
    return " ".join(text.upper().split())

def is_all_caps(line):
    letters = [c for c in line if c.isalpha()]
    if not letters:
        return False
    return all(c.isupper() for c in letters)

def match_book_start(line, norm_line, expected_book):
    if "ADVERTENCIA" in norm_line or "PROLOGO" in norm_line or "INDICE" in norm_line:
        return False
        
    if not is_all_caps(line):
        return False
        
    # Get all alphanumeric words
    words = re.findall(r'[A-Z0-9]+', norm_line)
    if not words:
        return False
        
    names = SPANISH_NAMES.get(expected_book, [])
    names = sorted(names, key=len, reverse=True)
    matched_name = None
    for name in names:
        norm_name = normalize_text(name)
        collapsed_line = "".join(words)
        collapsed_name = "".join(re.findall(r'[A-Z0-9]+', norm_name))
        if collapsed_name in collapsed_line:
            matched_name = norm_name
            break
            
    if not matched_name:
        return False
        
    # Verify that every word in the line is structural or part of the book name
    name_words = set(re.findall(r'[A-Z0-9]+', matched_name))
    for word in words:
        if word not in name_words and word not in ALLOWED_STRUCTURAL:
            return False
            
    if len(norm_line) < 45:
        return True
    return False

def parse_volume(filepath, expected_books):
    print(f"Parsing {filepath} with expected book sequence {expected_books}...")
    with open(filepath, "r", encoding="utf-8") as f:
        lines = f.readlines()
        
    books = {}
    
    expected_index = 0
    current_book = expected_books[0]
    next_book = expected_books[1] if len(expected_books) > 1 else None
    
    books[current_book] = {}
    
    current_chapter = None
    current_verse = None
    
    in_footnote = False
    next_book_detected = False
    
    for idx, line in enumerate(lines):
        line = line.strip()
        if not line:
            continue
            
        norm = normalize_text(line)
        
        # Stop parsing if we hit a clean Latin section header
        latin_chapter_match = re.match(r'^\s*CAPUT\s+([IVXLCDM]+|PRIMUM|SECUNDUM|TERTIUM|QUARTUM|QUINTUM|SEXTUM|SEPTIMUM|OCTAVUM|NONUM|DECIMUM)\s*$', norm)
        if latin_chapter_match:
            print(f"  Hit Latin section (CAPUT) at line {idx+1}. Stopping parse for this volume.")
            break
            
        latin_book_match = re.match(r'^\s*LIBER\s+[A-Z]+\s*$', norm)
        if latin_book_match:
            print(f"  Hit Latin section (LIBER) at line {idx+1}. Stopping parse for this volume.")
            break
            
        # Check if we detect the next expected book boundary
        if next_book and not next_book_detected:
            if match_book_start(line, norm, next_book):
                if next_book in ["OBD", "PHM", "2JN", "3JN", "JUD"]:
                    current_book = next_book
                    expected_index += 1
                    next_book = expected_books[expected_index + 1] if expected_index + 1 < len(expected_books) else None
                    next_book_detected = False
                    books[current_book] = {1: {}}
                    current_chapter = 1
                    current_verse = None
                    in_footnote = False
                    print(f"  Transitioned immediately to single-chapter book: {current_book} at line {idx+1}")
                else:
                    next_book_detected = True
                    print(f"  Detected next book boundary: {next_book} at line {idx+1}. Waiting for chapter header to transition...")
                
        # Transition to next book on the first chapter header we see after next book boundary detection
        if next_book_detected:
            chapter_match = re.match(r'^(?:CAPITULO|CAPITULO|SALMO)\s+(\w+)', norm)
            if chapter_match:
                ch_str = chapter_match.group(1).replace(".", "").strip()
                # When transitioning to a new book, the first chapter is always Chapter 1
                ch_num = 1
                current_book = next_book
                expected_index += 1
                next_book = expected_books[expected_index + 1] if expected_index + 1 < len(expected_books) else None
                next_book_detected = False
                books[current_book] = {}
                current_chapter = ch_num
                current_verse = None
                in_footnote = False
                books[current_book][current_chapter] = {}
                print(f"  Transitioned to book: {current_book} at line {idx+1} (Chapter {ch_num})")
                continue
                
        # Parse within the current active book
        # Detect chapter or psalm (for current book)
        chapter_match = re.match(r'^(?:CAPITULO|CAPITULO|SALMO)\s+(\w+)', norm)
        if chapter_match:
            ch_str = chapter_match.group(1).replace(".", "").strip()
            ch_num = ROMAN_NUMERALS.get(ch_str)
            if not ch_num:
                # Self-healing sequential chapter logic!
                if current_chapter is not None:
                    ch_num = current_chapter + 1
                else:
                    ch_num = 1
            current_chapter = ch_num
            current_verse = None
            in_footnote = False
            if current_chapter not in books[current_book]:
                books[current_book][current_chapter] = {}
            continue
            
        if not current_chapter:
            continue
            
        # Detect verse start
        # A verse starts with a number at the start, followed by optional punctuation and spaces
        verse_match = re.match(r'^\s*(\d+)\s*[\./,;/]?\s+(.*)', line)
        is_verse = False
        if verse_match:
            v_num = int(verse_match.group(1))
            v_text = verse_match.group(2).strip()
            
            # Check sequential constraint
            if current_verse is None:
                if v_num <= 5:
                    is_verse = True
            else:
                if current_verse < v_num <= current_verse + 5:
                    is_verse = True
                    
        if is_verse:
            in_footnote = False
            current_verse = v_num
            books[current_book][current_chapter][current_verse] = v_text
            continue
            
        # Detect footnote start (non-sequential digit start)
        if re.match(r'^\s*\d+\s+[A-Za-zÁÉÍÓÚÑ]', line):
            in_footnote = True
            continue
            
        # Discard footnote lines
        if in_footnote:
            continue
            
        # If we are inside a verse, append this line as continuation text
        if current_verse is not None:
            # Skip page headers, running book titles, etc.
            if "—" in line or line.isdigit() or any(match_book_start(line, norm, b) for b in expected_books):
                continue
            prev_text = books[current_book][current_chapter][current_verse]
            books[current_book][current_chapter][current_verse] = (prev_text + " " + line).strip()
            
    return books

def main():
    src_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "raw")
    dest_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "parsed")
    os.makedirs(dest_dir, exist_ok=True)
    
    all_books = {}
    for vol, expected in VOLUME_LAYOUTS.items():
        filepath = os.path.join(src_dir, f"{vol}_ocr.txt")
        if os.path.exists(filepath):
            vol_books = parse_volume(filepath, expected)
            # Merge into all_books
            for book_code, chapters in vol_books.items():
                if book_code not in all_books:
                    all_books[book_code] = {}
                for ch, verses in chapters.items():
                    all_books[book_code][ch] = verses
                    
    # Write parsed books to USFM files
    print(f"\nWriting parsed books to USFM in {dest_dir}...")
    for book_code, chapters in all_books.items():
        if not chapters:
            continue
        usfm_lines = []
        usfm_lines.append(f"\\id {book_code}")
        usfm_lines.append(f"\\h {book_code}")
        usfm_lines.append(f"\\toc1 {book_code}")
        
        # Sort chapters
        for ch_num in sorted(chapters.keys()):
            usfm_lines.append(f"\\c {ch_num}")
            # Sort verses
            verses = chapters[ch_num]
            for v_num in sorted(verses.keys()):
                v_text = verses[v_num]
                usfm_lines.append(f"\\v {v_num} {v_text}")
                
        dest_filepath = os.path.join(dest_dir, f"{book_code}.usfm")
        with open(dest_filepath, "w", encoding="utf-8") as out_f:
            out_f.write("\n".join(usfm_lines) + "\n")
        print(f"  Wrote {dest_filepath} ({len(chapters)} chapters)")

if __name__ == "__main__":
    main()
