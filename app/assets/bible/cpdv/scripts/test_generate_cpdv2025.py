#!/usr/bin/env python3
"""
Unit tests for CPDV 2025 generator script (generate_cpdv2025.py).
"""
import os
import subprocess
import sys
import unittest

# Add scripts directory to module path
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

from generate_cpdv2025 import clean_verse_text, BOOKS


class TestCleanVerseText(unittest.TestCase):
    def test_clean_verse_text_strips_chapter_anchors(self):
        raw = 'In the beginning God created heaven, and earth. [<A NAME="c1">Genesis 1</A>]'
        expected = 'In the beginning God created heaven, and earth.'
        self.assertEqual(clean_verse_text(raw), expected)

    def test_clean_verse_text_strips_trailing_alternate_chapter_hyphenated(self):
        # Covers Psalm 8:10 trailing (9 - 10)
        raw = 'O Lord, our Lord, how admirable is your name throughout all the earth! [<A NAME="ps9">Psalm 9</A>] (9 - 10)'
        expected = 'O Lord, our Lord, how admirable is your name throughout all the earth!'
        self.assertEqual(clean_verse_text(raw), expected)

    def test_clean_verse_text_strips_trailing_alternate_chapter_single_number(self):
        # Covers Psalm 9:39 trailing (11)
        raw = (
            'so as to judge for the orphan and the humble, so that man may no longer presume '
            'to magnify himself upon the earth. [<A NAME="ps10">Psalm 10</A>] (11)'
        )
        expected = (
            'so as to judge for the orphan and the humble, so that man may no longer presume '
            'to magnify himself upon the earth.'
        )
        self.assertEqual(clean_verse_text(raw), expected)

    def test_clean_verse_text_strips_trailing_alternate_chapter_alphanumeric(self):
        # Covers Psalm 113:26 trailing (116A)
        raw = (
            'But we who live will bless the Lord, from this time forward, and even forever. '
            '[<A NAME="ps116">Psalm 116</A>] (116A)'
        )
        expected = 'But we who live will bless the Lord, from this time forward, and even forever.'
        self.assertEqual(clean_verse_text(raw), expected)

    def test_clean_verse_text_handles_html_entities_and_song_of_songs(self):
        raw = 'Let him kiss me with the kiss of his mouth; for your &amp; breasts are better than wine. <I>Bride:</I>'
        expected = r'Let him kiss me with the kiss of his mouth; for your & breasts are better than wine. \it Bride:\it*'
        self.assertEqual(clean_verse_text(raw, is_song=True), expected)


class TestGenerateCpdv2025Cli(unittest.TestCase):
    def test_unknown_book_abbreviation_exits_nonzero(self):
        script_path = os.path.join(SCRIPT_DIR, 'generate_cpdv2025.py')
        result = subprocess.run(
            [sys.executable, script_path, 'PSLA'],
            capture_output=True,
            text=True,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('PSLA', result.stderr)
        self.assertIn('Unknown book abbreviation', result.stderr)

    def test_multiple_unknown_book_abbreviations_listed(self):
        script_path = os.path.join(SCRIPT_DIR, 'generate_cpdv2025.py')
        result = subprocess.run(
            [sys.executable, script_path, 'FOO', 'PSA', 'BAZ'],
            capture_output=True,
            text=True,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('FOO', result.stderr)
        self.assertIn('BAZ', result.stderr)

    def test_help_flag_displays_usage_and_exits_zero(self):
        script_path = os.path.join(SCRIPT_DIR, 'generate_cpdv2025.py')
        result = subprocess.run(
            [sys.executable, script_path, '--help'],
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0)
        self.assertIn('Usage:', result.stdout)


if __name__ == '__main__':
    unittest.main()
