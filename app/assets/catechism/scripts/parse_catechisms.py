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
    return text

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
        
    cleaned = strip_gutenberg_header_footer(clean_text(raw))
    lines = cleaned.splitlines()
    
    sections = []
    current_section = None
    
    # Regex patterns for Baltimore Q&A
    q_pattern = re.compile(r'^\s*(?:\{?\d+\}?\s*)?(?:(\d+)\.\s*Q\.|Q\.\s*(\d+)\.?)\s*(.*)', re.IGNORECASE)
    a_pattern = re.compile(r'^\s*A\.\s*(.*)', re.IGNORECASE)
    lesson_pattern = re.compile(r'^\s*(LESSON\s+[A-Z0-9\-\s]+|PRONUNCIATION OF NAMES|PRAYERS)\.?\s*$', re.IGNORECASE)
    
    current_q_num = None
    current_q_text = ""
    current_a_text = ""
    current_explanation = []
    is_answering = False
    is_explaining = False
    
    def finalize_qa():
        nonlocal current_q_num, current_q_text, current_a_text, current_explanation, is_answering, is_explaining
        if current_q_num is not None and current_section is not None:
            entry = {
                "type": "qa",
                "questionNumber": current_q_num,
                "question": re.sub(r'\s+', ' ', current_q_text).strip(),
                "answer": re.sub(r'\s+', ' ', current_a_text).strip()
            }
            if current_explanation:
                exp_text = "\n\n".join([re.sub(r'\s+', ' ', p).strip() for p in current_explanation if p.strip()])
                if exp_text:
                    entry["explanation"] = exp_text
            current_section["content"].append(entry)
            
        current_q_num = None
        current_q_text = ""
        current_a_text = ""
        current_explanation = []
        is_answering = False
        is_explaining = False

    for line in lines:
        stripped = line.strip()
        if not stripped:
            if is_answering:
                is_answering = False
                is_explaining = True
            continue
            
        # Check for Lesson Header
        match_lesson = lesson_pattern.match(stripped)
        if match_lesson and len(stripped) < 50 and not q_pattern.match(stripped) and not a_pattern.match(stripped):
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
        if current_section is not None and len(current_section["content"]) == 0 and not current_section["subtitle"] and not q_pattern.match(stripped) and not a_pattern.match(stripped):
            if stripped.isupper() or stripped.startswith("ON ") or stripped.startswith("FROM "):
                current_section["subtitle"] = stripped
                continue

        # Check for Question (e.g., "1. Q. Who made..." or "Q. 126. What...")
        match_q = q_pattern.match(stripped)
        if match_q:
            finalize_qa()
            q_num_str = match_q.group(1) if match_q.group(1) is not None else match_q.group(2)
            current_q_num = int(q_num_str) if q_num_str else 0
            current_q_text = match_q.group(3) or ""
            is_answering = False
            is_explaining = False
            if current_section is None:
                current_section = {
                    "id": "sec_1",
                    "title": "PRAYERS & INTRO",
                    "subtitle": "",
                    "content": []
                }
                sections.append(current_section)
            continue
            
        # Check for Answer (A.)
        match_a = a_pattern.match(stripped)
        if match_a and current_q_num is not None:
            current_a_text = match_a.group(1) or ""
            is_answering = True
            is_explaining = False
            continue
            
        if is_answering:
            current_a_text += " " + stripped
        elif is_explaining:
            if current_explanation:
                current_explanation[-1] += " " + stripped
            else:
                current_explanation.append(stripped)
        elif current_q_num is not None:
            current_q_text += " " + stripped
        else:
            if current_section is not None:
                # Check for prayer heading titles like "THE LORD'S PRAYER", "AN ACT OF FAITH"
                if stripped.isupper() and len(stripped) < 70 and not stripped.startswith("Q.") and not stripped.startswith("A."):
                    current_section["content"].append({
                        "type": "heading",
                        "text": stripped
                    })
                else:
                    if current_section["content"] and current_section["content"][-1]["type"] == "text":
                        current_section["content"][-1]["text"] += " " + stripped
                    else:
                        current_section["content"].append({
                            "type": "text",
                            "text": stripped
                        })

    finalize_qa()
    
    valid_sections = [s for s in sections if len(s["content"]) > 0 or s["subtitle"]]
    
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
    
    # Fix hyphenated words across line breaks (e.g. "accord- \n ing" -> "according")
    cleaned = re.sub(r'(\b[a-zA-Z]+)-\s*\n\s*([a-zA-Z]+\b)', r'\1\2', cleaned)
    
    lines = cleaned.splitlines()
    
    # Find start of main body (skip Gutenberg headers, Toc, and Prefaces)
    main_body_start_idx = 0
    for idx, line in enumerate(lines):
        if 'DECREE OF THE COUNCIL OF TRENT' in line.upper():
            main_body_start_idx = idx
            break
            
    body_lines = lines[main_body_start_idx:]
    
    sections = []
    current_part = "PART I"
    current_section = None
    
    part_pattern = re.compile(r'^\s*(PART\s+[I|V|X\d]+)\.?\s*$', re.IGNORECASE)
    chap_pattern = re.compile(r'^\s*(CHAPTER\s+[I|V|X\d]+)\.?\s*$', re.IGNORECASE)
    question_header_pattern = re.compile(r'^\s*(Que?stion\s+[I|V|X\d]+\.?\s*[\—\–\-]?\s*.*)', re.IGNORECASE)
    
    # Running header & page number cleaner
    running_header_pattern = re.compile(r'^\s*(\d+\s+)?(PART\s+[I|V|X]+|CATECHISM|THE TRANSLATOR|PREFACE).*?(\d+)?\s*$', re.IGNORECASE)
    page_num_pattern = re.compile(r'^\s*\d+\s*$')
    
    for line in body_lines:
        stripped = line.strip()
        if not stripped:
            continue
            
        # Filter out OCR page numbers and running headers
        if page_num_pattern.match(stripped):
            continue
        if running_header_pattern.match(stripped) and len(stripped) < 70 and not question_header_pattern.match(stripped):
            continue
            
        m_part = part_pattern.match(stripped)
        if m_part:
            current_part = m_part.group(1).upper()
            continue
            
        m_chap = chap_pattern.match(stripped)
        if m_chap:
            chap_num = m_chap.group(1).upper()
            sec_id = f"sec_trent_{len(sections) + 1}"
            
            current_section = {
                "id": sec_id,
                "title": f"{current_part}, {chap_num}",
                "part": current_part,
                "chapter": chap_num,
                "content": []
            }
            sections.append(current_section)
            continue
            
        if current_section is not None:
            # Check for Question Heading (e.g. "Question I.— What is here meant...")
            m_q_head = question_header_pattern.match(stripped)
            if m_q_head:
                q_text = m_q_head.group(1)
                # Fix common OCR typos in question header
                q_text = re.sub(r'Quxstion', 'Question', q_text, flags=re.IGNORECASE)
                q_text = re.sub(r'Symiol', 'Symbol', q_text, flags=re.IGNORECASE)
                current_section["content"].append({
                    "type": "heading",
                    "text": q_text
                })
                continue
                
            # Paragraph content
            if current_section["content"] and current_section["content"][-1]["type"] == "text":
                current_section["content"][-1]["text"] += " " + stripped
            else:
                current_section["content"].append({
                    "type": "text",
                    "text": stripped
                })

    # Clean up multiline text whitespace
    for sec in sections:
        for item in sec["content"]:
            if item["type"] == "text":
                item["text"] = re.sub(r'\s+', ' ', item["text"]).strip()
            elif item["type"] == "heading":
                item["text"] = re.sub(r'\s+', ' ', item["text"]).strip()

    valid_sections = [s for s in sections if len(s["content"]) > 0]
    
    toc = []
    for sec in valid_sections:
        title = sec["title"]
        if sec["content"] and sec["content"][0]["type"] == "heading":
            title += f": {sec['content'][0]['text']}"
        toc.append({
            "id": sec["id"],
            "title": title
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
