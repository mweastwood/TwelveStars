import unittest
import os
import sys

# Add scripts directory to module path
scripts_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.append(scripts_dir)

from compare_cpdv import parse_usfm_verses

# Data-driven list of human-verified verses to protect against regressions:
# Format: (book_id, chapter, verse, expected_text)
HUMAN_VERIFIED_VERSES = [
    (
        "DEU",
        14,
        7,
        "Mas no debeis comer de los que rumian y no tienen la uña hendida, "
        "como el camello, la liebre, el querogrilo: á estos los tendreis por inmundos, "
        "porque aunque rumian, no tienen hendida la uña:"
    ),
    (
        "DEU",
        14,
        21,
        "Pero de carne mortecina no comais nada: la darás al extranjero que se halla "
        "dentro de tus muros para que la coma, ó se la venderás: por cuanto tú eres un pueblo "
        "consagrado al Señor Dios tuyo. No cocerás el cabrito en la leche de su madre."
    ),
    (
        "GEN",
        3,
        15,
        "Yo pondré enemistades entre tí y la mujer, y entre tu raza y la descendencia suya: "
        "ella quebrantará tu cabeza, y andarás acechando á su calcañar."
    ),
    (
        "GEN",
        4,
        15,
        "Díjole el Señor: No será así: antes bien cualquiera que matare á Cain, lo pagará "
        "con las setenas. Y puso el Señor en Cain una señal, para que ninguno que le "
        "encontrase le matara."
    ),
]

class TestHumanVerifiedVerses(unittest.TestCase):
    """
    Unit tests to verify human-verified USFM verse text accuracy
    across the 1836 Torres Amat Bible dataset to prevent regressions.
    """

    @classmethod
    def setUpClass(cls):
        cls.ocr_dir = os.path.join(os.path.dirname(scripts_dir), "ocr")
        cls.assertTrue(os.path.exists(cls.ocr_dir), f"OCR directory not found at {cls.ocr_dir}")
        cls.loaded_books = {}

    def _get_verses_for_book(self, book_id: str):
        if book_id not in self.loaded_books:
            files = [f for f in os.listdir(self.ocr_dir) if f"-{book_id}-" in f]
            self.assertTrue(len(files) > 0, f"No USFM file found for book {book_id}")
            usfm_path = os.path.join(self.ocr_dir, files[0])
            self.loaded_books[book_id] = parse_usfm_verses(usfm_path)
        return self.loaded_books[book_id]

    def test_human_verified_verses(self):
        """Iterates through all human-verified (book, chapter, verse) expected text test cases."""
        for book_id, ch, v, expected in HUMAN_VERIFIED_VERSES:
            with self.subTest(book=book_id, chapter=ch, verse=v):
                verses = self._get_verses_for_book(book_id)
                self.assertIn(ch, verses, f"Chapter {ch} missing from {book_id} USFM")
                self.assertIn(v, verses[ch], f"Verse {v} missing from {book_id} Chapter {ch}")
                
                # Normalize whitespace and trailing artifact punctuation
                actual_clean = verses[ch][v].replace("°", "").replace("'", "").strip()
                actual_clean = " ".join(actual_clean.split())
                expected_clean = " ".join(expected.split())
                
                self.assertEqual(actual_clean, expected_clean, f"Verse text mismatch for {book_id} {ch}:{v}")

if __name__ == "__main__":
    unittest.main()
