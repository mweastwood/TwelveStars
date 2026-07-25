import unittest
import os
import sys

# Add scripts directory to module path
scripts_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.append(scripts_dir)

from compare_cpdv import parse_usfm_verses

class TestHumanVerifiedVerses(unittest.TestCase):
    """
    Unit tests to verify human-verified USFM verse text accuracy
    across the 1836 Torres Amat Bible dataset to prevent regressions.
    """

    @classmethod
    def setUpClass(cls):
        cls.ocr_dir = os.path.join(os.path.dirname(scripts_dir), "ocr")
        cls.assertTrue(os.path.exists(cls.ocr_dir), f"OCR directory not found at {cls.ocr_dir}")

    def _get_verses_for_book(self, book_id: str):
        files = [f for f in os.listdir(self.ocr_dir) if f"-{book_id}-" in f]
        self.assertTrue(len(files) > 0, f"No USFM file found for book {book_id}")
        usfm_path = os.path.join(self.ocr_dir, files[0])
        return parse_usfm_verses(usfm_path)

    def test_deuteronomy_14_7(self):
        """Verifies Deuteronomy 14:7 text is clean, un-truncated, and without attached verse tails."""
        verses = self._get_verses_for_book("DEU")
        expected = (
            "Mas no debeis comer de los que rumian y no tienen la uña hendida, "
            "como el camello, la liebre, el querogrilo: á estos los tendreis por inmundos, "
            "porque aunque rumian, no tienen hendida la uña:"
        )
        self.assertIn(14, verses, "Chapter 14 missing from Deuteronomy USFM")
        self.assertIn(7, verses[14], "Verse 7 missing from Deuteronomy Chapter 14")
        self.assertEqual(verses[14][7], expected)

    def test_deuteronomy_14_21(self):
        """Verifies Deuteronomy 14:21 text is complete, de-hyphenated ('consagrado'), and restored."""
        verses = self._get_verses_for_book("DEU")
        expected = (
            "Pero de carne mortecina no comais nada: la darás al extranjero que se halla "
            "dentro de tus muros para que la coma, ó se la venderás: por cuanto tú eres un pueblo "
            "consagrado al Señor Dios tuyo. No cocerás el cabrito en la leche de su madre."
        )
        self.assertIn(14, verses, "Chapter 14 missing from Deuteronomy USFM")
        self.assertIn(21, verses[14], "Verse 21 missing from Deuteronomy Chapter 14")
        self.assertEqual(verses[14][21], expected)

if __name__ == "__main__":
    unittest.main()
