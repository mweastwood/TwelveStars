import os
import re
import json

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CATECHISM_DIR = os.path.dirname(SCRIPT_DIR)
OUTPUT_DIR = os.path.join(CATECHISM_DIR, 'json')

os.makedirs(OUTPUT_DIR, exist_ok=True)

def clean_text(text):
    text = re.sub(r'\r\n', '\n', text)
    text = re.sub(r'[\r\f]', '', text)
    return text.strip()

def strip_gutenberg_header_footer(text):
    start_match = re.search(r'\*\*\*\s*START OF (THE|THIS) PROJECT GUTENBERG EBOOK.*?\*\*\*', text, re.IGNORECASE)
    if start_match:
        text = text[start_match.end():]
    
    end_match = re.search(r'\*\*\*\s*END OF (THE|THIS) PROJECT GUTENBERG EBOOK', text, re.IGNORECASE)
    if end_match:
        text = text[:end_match.start()]
        
    return text.strip()

def parse_baltimore_file(filepath, book_id, title, subtitle):
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        raw = f.read()
        
    cleaned = strip_gutenberg_header_footer(raw)
    lines = cleaned.splitlines()
    
    sections = []
    current_section = None
    
    # Regex patterns
    lesson_pattern = re.compile(r'^\s*(LESSON\s+[A-Z0-9\-]+|LESSON\s+[A-Z\s]+|ON THE LORD\'S PRAYER|THE LORD\'S PRAYER|PRONUNCIATION OF NAMES|PRAYERS)\.?', re.IGNORECASE)
    q_pattern = re.compile(r'^\s*Q\.\s*(\d+)\.?\s*(.*)', re.IGNORECASE)
    a_pattern = re.compile(r'^\s*A\.\s*(.*)', re.IGNORECASE)
    
    current_q = None
    current_q_num = None
    current_q_text = ""
    current_a_text = ""
    is_answering = False
    
    def finalize_qa():
        nonlocal current_q, current_q_num, current_q_text, current_a_text, is_answering
        if current_q_num is not None and current_section is not None:
            current_section["content"].append({
                "type": "qa",
                "questionNumber": current_q_num,
                "question": current_q_text.strip(),
                "answer": current_a_text.strip()
            })
        current_q_num = None
        current_q_text = ""
        current_a_text = ""
        is_answering = False

    intro_lines = []
    
    for line in lines:
        stripped = line.strip()
        if not stripped:
            continue
            
        # Check for Lesson Header
        match_lesson = re.match(r'^\s*(LESSON\s+[A-Z0-9\-\s]+|PRONUNCIATION OF NAMES|PRAYERS)\.?\s*$', stripped, re.IGNORECASE)
        if match_lesson and len(stripped) < 40 and not stripped.startswith("Q.") and not stripped.startswith("A."):
            finalize_qa()
            sec_id = f"sec_{len(sections) + 1}"
            current_section = {
                "id": sec_id,
                "title": stripped,
                "subtitle": "",
                "content": []
            }
            sections.append(current_section)
            continue
            
        # Check if line is Lesson Subtitle right after Lesson Title
        if current_section is not None and len(current_section["content"]) == 0 and not current_section["subtitle"] and not stripped.startswith("Q.") and not stripped.startswith("A."):
            if stripped.isupper() or stripped.startswith("ON "):
                current_section["subtitle"] = stripped
                continue

        # Check for Q. ###
        match_q = q_pattern.match(stripped)
        if match_q:
            finalize_qa()
            current_q_num = int(match_q.group(1))
            current_q_text = match_q.group(2)
            is_answering = False
            if current_section is None:
                current_section = {
                    "id": "sec_1",
                    "title": "Introduction & Prayers",
                    "subtitle": "",
                    "content": []
                }
                sections.append(current_section)
            continue
            
        # Check for A.
        match_a = a_pattern.match(stripped)
        if match_a and current_q_num is not None:
            current_a_text = match_a.group(1)
            is_answering = True
            continue
            
        if is_answering:
            current_a_text += " " + stripped
        elif current_q_num is not None:
            current_q_text += " " + stripped
        else:
            if current_section is not None and len(current_section["content"]) == 0:
                current_section["content"].append({
                    "type": "text",
                    "text": stripped
                })

    finalize_qa()
    
    # Filter empty sections
    valid_sections = [s for s in sections if len(s["content"]) > 0 or s["subtitle"]]
    
    # Build Table of Contents
    toc = []
    for sec in valid_sections:
        toc_title = sec["title"]
        if sec["subtitle"]:
            toc_title += f": {sec['subtitle']}"
        toc.append({
            "id": sec["id"],
            "title": toc_title
        })

    data = {
        "bookId": book_id,
        "title": title,
        "subtitle": subtitle,
        "author": "Third Plenary Council of Baltimore",
        "toc": toc,
        "sections": valid_sections
    }
    
    out_path = os.path.join(OUTPUT_DIR, f"{book_id}.json")
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        
    print(f"Successfully generated {out_path} ({len(valid_sections)} sections)")

def parse_trent(filepath):
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        raw = f.read()

    cleaned = clean_text(raw)
    lines = cleaned.splitlines()
    
    sections = []
    current_part = "PART I"
    current_section = None
    
    part_pattern = re.compile(r'^\s*(PART\s+[I|V|X]+)\.?\s*$', re.IGNORECASE)
    chap_pattern = re.compile(r'^\s*(CHAP(?:TER)?\.?\s+[I|V|X\d]+)\.?(.*)', re.IGNORECASE)
    
    for line in lines:
        stripped = line.strip()
        if not stripped:
            continue
            
        m_part = part_pattern.match(stripped)
        if m_part:
            current_part = m_part.group(1).upper()
            continue
            
        m_chap = chap_pattern.match(stripped)
        if m_chap and len(stripped) < 80:
            chap_num = m_chap.group(1).upper()
            chap_title = m_chap.group(2).strip(" .—–-")
            sec_id = f"sec_trent_{len(sections) + 1}"
            full_title = f"{current_part}, {chap_num}"
            if chap_title:
                full_title += f": {chap_title}"
                
            current_section = {
                "id": sec_id,
                "title": full_title,
                "part": current_part,
                "chapter": chap_num,
                "content": []
            }
            sections.append(current_section)
            continue
            
        if current_section is not None:
            # Skip page headers / footers like "PART I. CHAPTER II."
            if re.match(r'^\s*PART\s+[I|V|X]+.*?CHAPTER.*?\d+\s*$', stripped, re.IGNORECASE):
                continue
            if len(current_section["content"]) > 0 and current_section["content"][-1]["type"] == "text":
                current_section["content"][-1]["text"] += "\n" + stripped
            else:
                current_section["content"].append({
                    "type": "text",
                    "text": stripped
                })

    valid_sections = [s for s in sections if len(s["content"]) > 0]
    
    toc = []
    for sec in valid_sections:
        toc.append({
            "id": sec["id"],
            "title": sec["title"]
        })

    data = {
        "bookId": "council_of_trent",
        "title": "Catechism of the Council of Trent",
        "subtitle": "The Roman Catechism (Translated by Rev. J. Donovan, 1829)",
        "author": "Council of Trent / St. Pius V",
        "toc": toc,
        "sections": valid_sections
    }
    
    out_path = os.path.join(OUTPUT_DIR, "council_of_trent.json")
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        
    print(f"Successfully generated {out_path} ({len(valid_sections)} sections)")

if __name__ == '__main__':
    baltimore_dir = os.path.join(CATECHISM_DIR, 'baltimore')
    trent_dir = os.path.join(CATECHISM_DIR, 'trent')
    
    parse_baltimore_file(
        os.path.join(baltimore_dir, 'baltimore_catechism_no1.txt'),
        'baltimore_1',
        'Baltimore Catechism No. 1',
        'For First Communion Classes'
    )
    parse_baltimore_file(
        os.path.join(baltimore_dir, 'baltimore_catechism_no2.txt'),
        'baltimore_2',
        'Baltimore Catechism No. 2',
        'For Confirmation & Grammar Classes'
    )
    parse_baltimore_file(
        os.path.join(baltimore_dir, 'baltimore_catechism_no3.txt'),
        'baltimore_3',
        'Baltimore Catechism No. 3',
        'For Two Years\' Course for Post-Confirmation Classes'
    )
    parse_baltimore_file(
        os.path.join(baltimore_dir, 'baltimore_catechism_no4_explanation.txt'),
        'baltimore_4',
        'Baltimore Catechism No. 4',
        'An Explanation of the Baltimore Catechism (Fr. Kinkead)'
    )
    parse_trent(
        os.path.join(trent_dir, 'catechism_of_the_council_of_trent_donovan_1829.txt')
    )
