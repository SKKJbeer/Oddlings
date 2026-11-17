"""Tests für scripts/kontaktabzug.py (D-145).

python3 -m unittest discover -s scripts/tests
"""
import io, json, os, sys, tempfile, unittest
from contextlib import redirect_stdout
from pathlib import Path
from PIL import Image

HIER = Path(__file__).resolve().parent
sys.path.insert(0, str(HIER.parent))
import kontaktabzug  # noqa: E402


def mission(ordner: Path, name: str, messung: dict | None, bilder: int = 5) -> None:
    mappe = ordner / name
    mappe.mkdir()
    for i in range(bilder):
        # Hochkant wie aus dem Simulator.
        Image.new("RGB", (390, 844), (40 * i, 120, 60)).save(mappe / f"bild-{i + 1}.png")
    if messung is not None:
        (mappe / f"kontaktabzug-{name}.json").write_text(json.dumps(messung))


GUT = {"frames": 1000, "stackedFrames": 3, "maxDeviationFields": 0.3, "maxEnemies": 12, "bends": 40, "footfalls": 90}


class Kontaktabzug(unittest.TestCase):
    def lauf(self, ordner: Path) -> str:
        ausgabe = io.StringIO()
        with redirect_stdout(ausgabe):
            self.assertEqual(kontaktabzug.main(ordner), 0)
        return ausgabe.getvalue()

    def test_blatt_und_uebersicht_quer(self):
        with tempfile.TemporaryDirectory() as tmp:
            ordner = Path(tmp)
            mission(ordner, "mission-01", GUT)
            mission(ordner, "mission-02", GUT)
            text = self.lauf(ordner)
            self.assertNotIn("::warning::", text)
            blatt = Image.open(ordner / "blatt-mission-01.jpg")
            self.assertGreater(blatt.width, blatt.height, "Bilder quer gedreht und nebeneinander")
            self.assertTrue((ordner / "uebersicht.jpg").exists())
            self.assertIn("in Ordnung", (ordner / "bericht.md").read_text())

    def test_warnt_bei_ueberschreitung_und_fehlender_messung(self):
        with tempfile.TemporaryDirectory() as tmp:
            ordner = Path(tmp)
            schlecht = dict(GUT, stackedFrames=200, maxDeviationFields=0.9, bends=0)
            mission(ordner, "mission-03", schlecht)
            mission(ordner, "mission-04", None)
            text = self.lauf(ordner)
            self.assertIn("mission-03: Abweichung", text)
            self.assertIn("mission-03: deckungsgleiche", text)
            self.assertIn("mission-03: kein Gegner lief", text)
            self.assertIn("mission-04: Die App hat keine Messung", text)


if __name__ == "__main__":
    unittest.main()
