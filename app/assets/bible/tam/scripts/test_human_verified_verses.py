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
        7,
        6,
        "Porque tú eres un pueblo consagrado al Señor Dios tuyo. Tu Señor Dios te ha escogido "
        "para que seas pueblo peculiar suyo, entre los pueblos todos que hay sobre la tierra."
    ),
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
    (
        "GEN",
        21,
        29,
        "Por lo que Abimelech le dijo: ¿Qué significan esas siete corderas que has separado?"
    ),
    (
        "GEN",
        27,
        45,
        "Se pase su cólera y se olvide de lo que has hecho contra él: despues enviaré por tí, "
        "y te traeré acá. ¿Por qué he de perder á mis dos hijos en un dia?"
    ),
    (
        "NUM",
        15,
        39,
        "Para que viéndolas se acuerden de todos los mandamientos del Señor, y no vayan en pos "
        "de sus pensamientos, ni pongan sus ojos en objetos que corrompan su corazon;"
    ),
    (
        "PSA",
        73,
        13,
        "Tú diste con tu poder solidez á las aguas del mar Rojo: tú quebrantaste las cabezas "
        "de los dragones, en medio de las aguas."
    ),
    (
        "ISA",
        42,
        21,
        "Y eso que el Señor le tuvo á Israel buena voluntad, escogiéndole para santificarle, "
        "y para dar á conocer la grandeza y excelencia de su santa Ley."
    ),
    (
        "JER",
        29,
        23,
        "Por haber hecho ellos necedades abominables en Israél, y cometido adulterios "
        "con las mujeres de sus amigos, y hablado mentirosamente en nombre mio, sin haberles "
        "yo dado ninguna comision: Yo mismo soy el juez y el testigo de todo eso, dice el Señor."
    ),
    (
        "MAT",
        8,
        33,
        "Los porqueros echaron á huir: y llegados á la ciudad, lo contaron todo, "
        "y en particular lo de los endemoniados."
    ),
    (
        "LUK",
        12,
        56,
        "Hipócritas, si sabeis pronosticar por los varios aspectos del cielo y de la tierra, "
        "¿cómo no conoceis este tiempo del Mesías?"
    ),
    (
        "ACT",
        14,
        22,
        "En seguida, habiendo ordenado sacerdotes en cada una de las iglesias, despues de "
        "oraciones y ayunos, los encomendaron al Señor, en quien habian creido."
    ),
    (
        "ROM",
        8,
        34,
        "¿Quién osará condenarlos? Despues que Jesu-Christo no solamente murió por nosotros, "
        "sino que tambien resucitó, y está sentado á la diestra de Dios, en donde asimismo "
        "intercede por nosotros."
    ),
    (
        "REV",
        10,
        10,
        "Entonces recibí el libro de la mano del Angel, y le devoré: y era en mi boca dulce "
        "como la miel: pero habiéndolo devorado, quedó mi vientre ó interior lleno de amargura:"
    ),
    (
        "JOS",
        2,
        13,
        "Con que salveis á mi padre y madre, á mis hermanos y hermanas, y todos sus bienes, "
        "y nos libreis de la muerte."
    ),
    (
        "JDG",
        3,
        16,
        "Aod proveyóse de una daga de dos cortes, con su guarnicion, larga como la palma "
        "de la mano, y ciñósela debajo del sayo en el muslo derecho."
    ),
    (
        "1CH",
        4,
        38,
        "Estos son los jefes famosos de las parentelas ó linajes de la tribu de Simeon, "
        "cuyas familias se multiplicaron sobremanera."
    ),
    (
        "JON",
        1,
        11,
        "Entonces le dijeron: ¿Qué haremos de tí, á fin de que la mar se nos aplaque? "
        "Pues la mar iba embraveciéndose cada vez mas."
    ),
    (
        "GEN",
        49,
        24,
        "Apoyó su arco, ó su confianza en el fuerte Dios, y fueron desatadas las cadenas "
        "de sus brazos y manos por la mano del Todo-poderoso Dios de Jacob: de donde "
        "salió para pastor y piedra fundamental de Israél."
    ),
    (
        "LEV",
        10,
        1,
        "Pero Nadab y Abiú, hijos de Aaron, tomandolos incensarios, pusieron en ellos "
        "fuego, é incienso encima, ofreciendo ante el Señor fuego extraño: lo cual les "
        "estaba vedado."
    ),
    (
        "NUM",
        17,
        3,
        "El nombre de Aaron estará en la vara de la tribu de Leví; y cada una de las "
        "otras familias ó tribus tendrá su vara peculiar."
    ),
    (
        "RUT",
        3,
        18,
        "Dijo entonces Noemí: Espera, hija mia, hasta que veamos en qué para la cosa. "
        "Porque Booz es hombre honrado, que no parará hasta que cumpla lo que te ha prometido."
    ),
    (
        "2CH",
        24,
        13,
        "Y estos obreros trabajaron con esmero; y repararon las hendiduras de las paredes, "
        "restituyendo el templo del Señor á su antiguo estado, y consolidándole perfectamente."
    ),
    (
        "OBA",
        1,
        7,
        "Te han arrojado fuera de tu país: todos tus aliados se han burlado de tí, "
        "se han alzado contra tí los amigos tuyos, aquellos mismos que comian en tu mesa "
        "te han armado asechanzas. No hay en Edom cordura."
    ),
    (
        "2TI",
        2,
        22,
        "Por tanto huye de las pasiones juveniles, y sigue la justicia, la fe, la caridad, "
        "y la paz con aquellos que invocan al Señor con limpio corazon y son capaces de ella."
    ),
    (
        "ISA",
        47,
        5,
        "Tú, oh hija de los Chaldéos, infeliz Babylonia, guarda un mudo silencio, "
        "y escóndete en las tinieblas; porque ya no te llamarán mas la señora de los reinos."
    ),
    (
        "ECC",
        5,
        6,
        "Donde los sueños son muchos, son muchísimas las vanidades, y sin fin las palabras: "
        "pero tú teme á Dios."
    ),
    (
        "PSA",
        47,
        6,
        "Ellos mismos, cuando la vieron así, quedaron asombrados, llenos de turbacion, conmovidos,"
    ),
    (
        "2TI",
        3,
        16,
        "Toda escritura inspirada de Dios es propia para enseñar, para convencer, para corregir á los pecadores, para dirigir á los buenos en la justicia ó virtud:"
    ),
    (
        "ISA",
        24,
        11,
        "Habrá gritos y quimeras en las calles por la escasez del vino: todo contento queda desterrado, desapareció la alegría de la tierra."
    ),
    (
        "ISA",
        5,
        18,
        "¡Ay de vosotros que arrastrais la iniquidad con las cuerdas de la vanidad, y al pecado á manera de carro, del cual tirais como bestias!"
    ),
    (
        "ISA",
        20,
        1,
        "El año en que Tharthan, enviado por Sargon, rey de los Assyrios, llegó á Azoto, y la combatió y la tomó;"
    ),
    (
        "ISA",
        24,
        5,
        "Inficionada está la tierra por sus habitadores, pues han quebrantado las leyes, han alterado el derecho, rompieron la alianza sempiterna."
    ),
    (
        "ISA",
        28,
        17,
        "Y ejerceré el juicio con peso, y la justicia con medida; y un pedrisco trastornará la esperanza puesta en la mentira, y vuestra proteccion quedará sumergida en las aguas de la calamidad."
    ),
    (
        "ISA",
        30,
        5,
        "Todos en Israél quedarán corridos, á causa de un pueblo que de nada les ha podido servir, y que no les ha auxiliado, ni les ha sido de utilidad alguna, sino de confusion y de oprobio."
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
