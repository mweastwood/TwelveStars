import unittest
import os
import sys

# Add scripts directory to module path
scripts_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.append(scripts_dir)

from compare_cpdv import parse_usfm_verses

class TestDeuteronomyUSFM(unittest.TestCase):
    """
    Unit tests to verify human-verified USFM verse text accuracy
    for Deuteronomy 14:7 and 14:21 in the 1836 Torres Amat dataset.
    """

    @classmethod
    def setUpClass(cls):
        base_dir = os.path.dirname(scripts_dir)
        cls.usfm_path = os.path.join(base_dir, "ocr", "05-DEU-SPA[B]TAM1836[pd].usfm")
        cls.assertTrue(os.path.exists(cls.usfm_path), f"USFM file not found at {cls.usfm_path}")
        cls.verses = parse_usfm_verses(cls.usfm_path)

    def test_deuteronomy_14_7(self):
        """Verifies Deuteronomy 14:7 text is clean, un-truncated, and without attached verse tails."""
        expected = (
            "Mas no debeis comer de los que rumian y no tienen la uña hendida, "
            "como el camello, la liebre, el querogrilo: á estos los tendreis por inmundos, "
            "porque aunque rumian, no tienen hendida la uña:"
        )
        self.assertIn(14, self.verses, "Chapter 14 missing from Deuteronomy USFM")
        self.assertIn(7, self.verses[14], "Verse 7 missing from Deuteronomy Chapter 14")
        self.assertEqual(self.verses[14][7], expected)

    def test_deuteronomy_14_21(self):
        """Verifies Deuteronomy 14:21 text is complete, de-hyphenated ('consagrado'), and restored."""
        expected = (
            "Pero de carne mortecina no comais nada: la darás al extranjero que se halla "
            "dentro de tus muros para que la coma, ó se la venderás: por cuanto tú eres un pueblo "
            "consagrado al Señor Dios tuyo. No cocerás el cabrito en la leche de su madre."
        )
        self.assertIn(14, self.verses, "Chapter 14 missing from Deuteronomy USFM")
        self.assertIn(21, self.verses[14], "Verse 21 missing from Deuteronomy Chapter 14")
        self.assertEqual(self.verses[14][21], expected)

if __name__ == "__main__":
    unittest.main()
