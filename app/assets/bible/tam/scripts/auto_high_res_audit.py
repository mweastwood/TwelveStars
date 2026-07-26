import os
import sys
import json
import re
import subprocess

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
BASE_DIR = os.path.dirname(SCRIPT_DIR)
VENV_PYTHON = os.path.join(BASE_DIR, ".venv", "bin", "python3")

sys.path.append(SCRIPT_DIR)
from compile_usfm import BIBLE_BOOK_MAP, BOOK_NAMES
from compare_cpdv import get_missing_verses, compare_book

def run_cmd(cmd_list):
    res = subprocess.run(cmd_list, capture_output=True, text=True)
    return res.returncode, res.stdout, res.stderr

def get_current_high_res_dict():
    ocr_py_path = os.path.join(SCRIPT_DIR, "ocr_pdf.py")
    with open(ocr_py_path, "r", encoding="utf-8") as f:
        code = f.read()
    exec_scope = {}
    exec(code, exec_scope)
    return exec_scope.get("HIGH_RESOLUTION_PAGES", {})

def save_high_res_dict(high_res_dict):
    ocr_py_path = os.path.join(SCRIPT_DIR, "ocr_pdf.py")
    with open(ocr_py_path, "r", encoding="utf-8") as f:
        code = f.read()

    new_dict_str = "HIGH_RESOLUTION_PAGES = {\n"
    for v_num in sorted(high_res_dict.keys()):
        p_set = high_res_dict[v_num]
        if not p_set:
            continue
        new_dict_str += f"    {v_num}: {{\n"
        for p_num in sorted(p_set):
            new_dict_str += f"        {p_num},\n"
        new_dict_str += "    },\n"
    new_dict_str += "}"

    # Replace HIGH_RESOLUTION_PAGES = { ... } in code using regex matching braces
    pattern = r"HIGH_RESOLUTION_PAGES\s*=\s*\{[\s\S]*?\n\}"
    updated_code = re.sub(pattern, new_dict_str, code)
    with open(ocr_py_path, "w", encoding="utf-8") as f:
        f.write(updated_code)

def find_page_for_missing_verse(book_id, ch, v, vol, start_page, end_page):
    ocr_raw_dir = os.path.join(BASE_DIR, "raw_ocr")
    for p in range(start_page, end_page + 1):
        jpath = os.path.join(ocr_raw_dir, f"vol{vol}_page_{p}.json")
        if not os.path.exists(jpath):
            continue
        with open(jpath, "r", encoding="utf-8") as f:
            data = json.load(f)
        lines = data.get("lines", [])
        for line in lines:
            txt = line.get("text", "")
            if re.search(r'\b' + str(v) + r'\.\s*', txt):
                return p
    return None

def main():
    print("=" * 80)
    print(" STARTING AUTONOMOUS HIGH-RESOLUTION OCR AUDIT ACROSS ALL MISSING VERSES")
    print("=" * 80)

    # 1. Get initial missing verses across all 73 books
    missing_map = get_missing_verses()
    total_initial_missing = sum(len(m) for m in missing_map.values())
    print(f"Total initial missing verses across all books: {total_initial_missing}")

    pages_to_test = {}

    for book_id, missing_list in missing_map.items():
        if not missing_list or book_id not in BIBLE_BOOK_MAP:
            continue
        vol, start_p, end_p = BIBLE_BOOK_MAP[book_id]
        for ch, v in missing_list:
            p = find_page_for_missing_verse(book_id, ch, v, vol, start_p, end_p)
            if p is not None:
                pages_to_test.setdefault((vol, p), []).append((book_id, ch, v))

    print(f"Found {len(pages_to_test)} unique pages containing candidate missing verses.")
    
    kept_high_res_pages = []

    for (vol, page_idx), verse_list in sorted(pages_to_test.items()):
        affected_books = sorted(list(set(b for b, c, v in verse_list)))
        print(f"\n--- Testing High-Res (scale=4) on Vol {vol} Page {page_idx} (PDF page {page_idx+1}) ---")
        print(f"    Candidate missing verses on page: {verse_list}")

        # Measure baseline missing count for affected books
        baseline_missing = {}
        for b in affected_books:
            baseline_missing[b] = len(get_missing_verses(b).get(b, []))

        # Add page to HIGH_RESOLUTION_PAGES
        high_res_dict = get_current_high_res_dict()
        high_res_dict.setdefault(vol, set()).add(page_idx)
        save_high_res_dict(high_res_dict)

        # Run ocr_pdf.py for page_idx with --force
        ocr_py_path = os.path.join(SCRIPT_DIR, "ocr_pdf.py")
        print(f"    Running high-res OCR on Vol {vol} Page {page_idx}...")
        code, out, err = run_cmd([VENV_PYTHON, ocr_py_path, "--volume", str(vol), "--start", str(page_idx), "--end", str(page_idx), "--force"])
        if code != 0:
            print(f"    OCR Error: {err}")
            continue

        # Recompile affected books
        improved = False
        for b in affected_books:
            run_cmd([VENV_PYTHON, os.path.join(SCRIPT_DIR, "compile_usfm.py"), "--book", b])
            new_missing = len(get_missing_verses(b).get(b, []))
            diff = baseline_missing[b] - new_missing
            if diff > 0:
                print(f"    🎉 RECOVERY SUCCESS for Book {b}! Missing verses reduced from {baseline_missing[b]} to {new_missing} (-{diff})")
                improved = True

        if improved:
            kept_high_res_pages.append((vol, page_idx))
            print(f"    Keeping Vol {vol} Page {page_idx} at High Resolution.")
        else:
            print(f"    No missing verses recovered. Reverting Vol {vol} Page {page_idx} to scale=2...")
            # Remove from HIGH_RESOLUTION_PAGES
            high_res_dict = get_current_high_res_dict()
            if vol in high_res_dict and page_idx in high_res_dict[vol]:
                high_res_dict[vol].remove(page_idx)
                if not high_res_dict[vol]:
                    del high_res_dict[vol]
            save_high_res_dict(high_res_dict)

            # Re-run OCR at scale 2
            run_cmd([VENV_PYTHON, ocr_py_path, "--volume", str(vol), "--start", str(page_idx), "--end", str(page_idx), "--force"])
            for b in affected_books:
                run_cmd([VENV_PYTHON, os.path.join(SCRIPT_DIR, "compile_usfm.py"), "--book", b])

    print("\n" + "=" * 80)
    print(" HIGH-RESOLUTION AUDIT COMPLETE")
    print("=" * 80)
    print(f"Pages kept at High-Res: {kept_high_res_pages}")
    
    # Final metrics
    run_cmd([VENV_PYTHON, os.path.join(SCRIPT_DIR, "compare_cpdv.py")])

if __name__ == "__main__":
    main()
