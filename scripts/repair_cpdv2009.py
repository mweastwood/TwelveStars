#!/usr/bin/env python3
import re
import os

CPDV_DIR = os.path.abspath('app/assets/bible/cpdv/usfm')

def repair_psa():
    path = os.path.join(CPDV_DIR, '21-PSA-ENG[B]CPDV2009[pd].p.sfm')
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 1. Strip \qs Pause\qs*
    content = re.sub(r'\\qs\s*Pause\s*\\qs\*', '', content)
    
    # 2. Fix Psalm 63 line 3302 jammed \v 8
    # \fl (Challoner)\f*\v 8 and God will be exalted.
    content = re.sub(r'(\\fl\s+\(Challoner\)\\f\*)\s*(\\v\s+8\s+and\s+God\s+will\s+be\s+exalted\.)', r'\1\n\2', content)
    
    # 3. Fix Psalm 13 renumbering
    # \va 4\va* -> \v 4
    # \va 5\va* -> \v 5
    # \va 6\va* -> \v 6
    # \v 4 \va 7\va* -> \v 7
    # \v 5 \va 8\va* -> \v 8
    # \v 6 \va 9\va* -> \v 9
    # \v 7 \va 10\va* -> \v 10
    psa13_old = r'''\va 4\va* Their throat is an open sepulcher.
\q1 With their tongues, they have been acting deceitfully;
\q2 the venom of asps is under their lips. Their mouth is full of curses and bitterness.
\q1
\va 5\va* Their feet are swift to shed blood.
\q1 Grief and unhappiness are in their ways;
\q2 and the way of peace, they have not known.
\q1
\va 6\va* There is no fear of God before their eyes.
\v 4 \va 7\va* Will they never learn:
\q2 all those who work iniquity, who devour my people like a meal of bread?\f + \fr 13:7 \ft The verb ‘cognoscent’ can refer to knowing or having knowledge; it can also refer to becoming aware of something, or to learning about something.\fl (Conte)\f*
\b
\q1
\v 5 \va 8\va* They have not called upon the Lord.
\q2 There, they have trembled in fear, where there was no fear.
\q1
\v 6 \va 9\va* For the Lord is with the just generation.
\q2 You have confounded the counsel of the needy because the Lord is his hope.
\q1
\v 7 \va 10\va* Who will grant the salvation of Israel from Zion?'''

    psa13_new = r'''\v 4 Their throat is an open sepulcher.
\q1 With their tongues, they have been acting deceitfully;
\q2 the venom of asps is under their lips. Their mouth is full of curses and bitterness.
\q1
\v 5 Their feet are swift to shed blood.
\q1 Grief and unhappiness are in their ways;
\q2 and the way of peace, they have not known.
\q1
\v 6 There is no fear of God before their eyes.
\q1
\v 7 Will they never learn:
\q2 all those who work iniquity, who devour my people like a meal of bread?\f + \fr 13:7 \ft The verb ‘cognoscent’ can refer to knowing or having knowledge; it can also refer to becoming aware of something, or to learning about something.\fl (Conte)\f*
\b
\q1
\v 8 They have not called upon the Lord.
\q2 There, they have trembled in fear, where there was no fear.
\q1
\v 9 For the Lord is with the just generation.
\q2 You have confounded the counsel of the needy because the Lord is his hope.
\q1
\v 10 Who will grant the salvation of Israel from Zion?'''
    
    if psa13_old in content:
        content = content.replace(psa13_old, psa13_new)
        print("Fixed Psalm 13 structure")
    else:
        print("WARNING: Psalm 13 pattern not found")

    # 4. Fix Psalm 92 renumbering
    psa92_old = r'''\va 2\va* The Lord has reigned. He has been clothed with beauty.
\q1
\va 3\va* The Lord has been clothed with strength, and he has girded himself.
\q1 Yet he has also confirmed the world, which will not be moved.
\q1
\v 2 \va 4\va* My throne is prepared from of old. You are from everlasting.
\q1
\v 3 \va 5\va* The floods have lifted up, O Lord,
\q1 the floods have lifted up their voice.
\q1 The floods have lifted up their waves,
\v 4 \va 6\va* before the noise of many waters.
\q1 Wondrous are the surges of the sea; wondrous is the Lord on high.
\q1
\v 5 \va 7\va* Your testimonies have been made exceedingly trustworthy.'''

    psa92_new = r'''\v 2 The Lord has reigned. He has been clothed with beauty.
\q1
\v 3 The Lord has been clothed with strength, and he has girded himself.
\q1 Yet he has also confirmed the world, which will not be moved.
\q1
\v 4 My throne is prepared from of old. You are from everlasting.
\q1
\v 5 The floods have lifted up, O Lord,
\q1 the floods have lifted up their voice.
\q1 The floods have lifted up their waves,
\q1
\v 6 before the noise of many waters.
\q1 Wondrous are the surges of the sea; wondrous is the Lord on high.
\q1
\v 7 Your testimonies have been made exceedingly trustworthy.'''

    if psa92_old in content:
        content = content.replace(psa92_old, psa92_new)
        print("Fixed Psalm 92 structure")
    else:
        print("WARNING: Psalm 92 pattern not found")

    # 5. Fix Psalm 118 acrostics:
    # Pattern: \qa LETTER.\n\q1\n\v NUM (where NUM is 9, 17, 25, 33, 41, 49, 57, 65, 73, 81, 89, 97, 105, 113, 121, 129, 137, 145, 153, 161, 169)
    # Move \qa LETTER. to be after \v NUM
    content = re.sub(
        r'\\qa\s+([A-Z]+)\.\s*\n\s*\\q1\s*\n\s*\\v\s+(\d+)\s+',
        r'\\q1\n\\v \2 \1. ',
        content
    )
    print("Fixed Psalm 118 acrostic placement")

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Saved repaired 21-PSA")

def repair_est():
    path = os.path.join(CPDV_DIR, '19-EST-ENG[B]CPDV2009[pd].p.sfm')
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Fix line 243 jammed \v 3
    content = re.sub(r'(\\f\*)\s*(\\v\s+3\s+And\s+she\s+begged)', r'\1\n\2', content)

    # In 19-EST, the narrative is already in order across 274 verses.
    # The chapter verse counts in CPDV narrative order are:
    counts = [11, 6, 22, 23, 13, 9, 30, 19, 30, 14, 10, 12, 29, 32, 14]
    
    # Let's extract the header before \c 11
    header = content[:content.find(r'\c 11')].strip()
    
    # Find all \v blocks
    # Note: each verse begins with \v \d+ ...
    body = content[content.find(r'\c 11'):]
    
    # We want to strip all existing \c, \cl, \ca, \cd lines from the body
    body_clean_lines = []
    for line in body.splitlines():
        trimmed = line.strip()
        if trimmed.startswith(r'\c ') or trimmed.startswith(r'\ca ') or trimmed.startswith(r'\cl ') or trimmed.startswith(r'\cd '):
            continue
        body_clean_lines.append(line)
    
    body_clean = '\n'.join(body_clean_lines)
    
    # Find all verses
    # Matches: \v \d+(?: \va \d+\va*)? (text)
    # Let's split by \v
    chunks = re.split(r'\n(?=\\v\s+\d+)', '\n' + body_clean)
    verses = [c.strip() for c in chunks if c.strip().startswith(r'\v ')]
    
    if len(verses) != 274:
        raise ValueError(f"Expected 274 verses in Esther, found {len(verses)}")
    
    # Now rebuild 19-EST with sequential \c 1..15 and \v 1..N
    new_lines = [header]
    v_idx = 0
    for ch_idx, v_count in enumerate(counts, start=1):
        new_lines.append(f'\\c {ch_idx}')
        new_lines.append(f'\\cl Esther {ch_idx}')
        for local_v in range(1, v_count + 1):
            raw_v = verses[v_idx]
            v_idx += 1
            v_text = re.sub(r'^\\v\s+\d+\s*(?:\\va\s+\d+\\va\*)?\s*', lambda _, lv=local_v: f'\\v {lv} ', raw_v)
            new_lines.append(v_text)
    
    new_content = '\n'.join(new_lines) + '\n'
    with open(path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print(f"Saved repaired 19-EST (15 chapters, 274 verses)")

def repair_sng():
    path = os.path.join(CPDV_DIR, '24-SNG-ENG[B]CPDV2009[pd].p.sfm')
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # In chapter 1:
    # Replace lines 13-52 with clean sequential \v 1 to \v 21
    # Let's inspect chapter 1
    ch1_old = content[content.find(r'\c 1'):content.find(r'\c 2')]
    
    # We rebuild chapter 1 specifically:
    # Verse 1: lines 13-14
    # Verse 2: combines \va 2 "So much better than wine are your breasts," and \v 2 "fragranced with the finest perfumes.\f ...\f*"
    # Verse 3: combines \va 3 "Your name is oil that has been poured out; therefore, the maidens have loved you." and \v 3 "Draw me forward.\f ...\f*"
    # Verse 4: \va 4
    # Verse 5: \va 5
    # Verse 6: \va 6
    # Verse 7: \va 7
    # Verse 8: \v 4 \va 8
    # Verse 9: \v 5 \va 9
    # Verse 10: \va 10
    # Verse 11: \v 6 \va 11
    # Verse 12: \v 7 \va 12
    # Verse 13: \v 8 \va 13
    # Verse 14: \v 9 \va 14
    # Verse 15: \v 10 \va 15
    # Verse 16: \v 11 \va 16
    # Verse 17: \v 12 \va 17
    # Verse 18: \v 13 \va 18
    # Verse 19: \v 14 \va 19
    # Verse 20: \v 15 \va 20
    # Verse 21: \v 16 \va 21

    # In chapter 2:
    # \va 18\va* -> \v 18
    # \va 19\va* -> \v 19
    content = content.replace(r'\va 18\va* \qac Bride to Chorus:\qac*', r'\v 18 \qac Bride to Chorus:\qac*')
    content = content.replace(r'\va 19\va* \qac Bride to Groom:\qac*', r'\v 19 \qac Bride to Groom:\qac*')

    # In chapter 5:
    # \va 18\va* -> \v 18
    # \va 19\va* -> \v 19
    content = content.replace(r'\va 18\va* His throat is most sweet', r'\v 18 His throat is most sweet')
    content = content.replace(r'\va 19\va* \qac Chorus to Bride:\qac*', r'\v 19 \qac Chorus to Bride:\qac*')

    # In chapter 7:
    # \va 14\va* -> \v 14
    content = content.replace(r'\va 14\va* The mandrakes yield', r'\v 14 The mandrakes yield')

    # In chapter 8:
    # \va 15\va* -> \v 15
    content = content.replace(r'\va 15\va* Flee away, my beloved', r'\v 15 Flee away, my beloved')

    # Now let's carefully rebuild chapter 1:
    v2_part1 = r'\qac Groom to Bride:\qac* So much better than wine are your breasts,'
    v2_part2_match = re.search(r'\\v\s+2\s+fragranced with the finest perfumes\..*?(?=\\q1|\Z)', content, re.S)
    v2_rest = v2_part2_match.group(0)[len(r'\v 2 '):].strip()
    v2_full = f'\\v 2 {v2_part1} {v2_rest}'

    v3_part1 = r'\qac Bride to Groom:\qac* Your name is oil that has been poured out; therefore, the maidens have loved you.'
    v3_part2_match = re.search(r'\\v\s+3\s+Draw me forward\..*?(?=\\q1|\Z)', content, re.S)
    v3_rest = v3_part2_match.group(0)[len(r'\v 3 '):].strip()
    v3_full = f'\\v 3 {v3_part1} {v3_rest}'

    # Replace in content:
    # Replace \va 4..7 with \v 4..7
    content = re.sub(r'\\va\s+4\\va\*', r'\\v 4', content)
    content = re.sub(r'\\va\s+5\\va\*', r'\\v 5', content)
    content = re.sub(r'\\va\s+6\\va\*', r'\\v 6', content)
    content = re.sub(r'\\va\s+7\\va\*', r'\\v 7', content)
    content = re.sub(r'\\v\s+4\s+\\va\s+8\\va\*', r'\\v 8', content)
    content = re.sub(r'\\v\s+5\s+\\va\s+9\\va\*', r'\\v 9', content)
    content = re.sub(r'\\va\s+10\\va\*', r'\\v 10', content)
    content = re.sub(r'\\v\s+6\s+\\va\s+11\\va\*', r'\\v 11', content)
    content = re.sub(r'\\v\s+7\s+\\va\s+12\\va\*', r'\\v 12', content)
    content = re.sub(r'\\v\s+8\s+\\va\s+13\\va\*', r'\\v 13', content)
    content = re.sub(r'\\v\s+9\s+\\va\s+14\\va\*', r'\\v 14', content)
    content = re.sub(r'\\v\s+10\s+\\va\s+15\\va\*', r'\\v 15', content)
    content = re.sub(r'\\v\s+11\s+\\va\s+16\\va\*', r'\\v 16', content)
    content = re.sub(r'\\v\s+12\s+\\va\s+17\\va\*', r'\\v 17', content)
    content = re.sub(r'\\v\s+13\s+\\va\s+18\\va\*', r'\\v 18', content)
    content = re.sub(r'\\v\s+14\s+\\va\s+19\\va\*', r'\\v 19', content)
    content = re.sub(r'\\v\s+15\s+\\va\s+20\\va\*', r'\\v 20', content)
    content = re.sub(r'\\v\s+16\s+\\va\s+21\\va\*', r'\\v 21', content)

    # Now replace the v2 and v3 fragments in chapter 1
    # Replace chunk from \q1 \va 2\va* through \v 3 ...
    frag_old_pattern = re.compile(
        r'\\q1\s*\\va\s+2\\va\*.*?'
        r'\\v\s+3\s+Draw me forward\..*?'
        r'(?=\\q1\s*\\v\s+4)',
        re.S
    )
    frag_new = f'\\q1\n{v2_full}\n\\q1\n{v3_full}\n'
    content = frag_old_pattern.sub(lambda _: frag_new, content)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Saved repaired 24-SNG (all 127 verses)")

def repair_sir():
    path = os.path.join(CPDV_DIR, '26-SIR-ENG[B]CPDV2009[pd].p.sfm')
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Convert \va 1\va* .. \va 9\va* in prologue to \ip
    content = re.sub(r'\\va\s+\d+\\va\*', r'\\ip', content)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Saved repaired 26-SIR (prologue converted to \\ip)")

def repair_lam():
    path = os.path.join(CPDV_DIR, '29-LAM-ENG[B]CPDV2009[pd].p.sfm')
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Convert \va 1\va* .. \va 3\va* in prologue to \ip
    content = re.sub(r'\\va\s+\d+\\va\*', r'\\ip', content)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Saved repaired 29-LAM (prologue converted to \\ip)")

def main():
    print("Repairing CPDV 2009 USFM files...")
    repair_psa()
    repair_est()
    repair_sng()
    repair_sir()
    repair_lam()
    print("Finished repairing all 5 books for CPDV 2009!")

if __name__ == '__main__':
    main()
