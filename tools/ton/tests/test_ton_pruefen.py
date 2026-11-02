"""Tests für tools/ton/ton_pruefen.py: Der Prüfer schlägt an, wo er soll."""
import json
import pathlib
import shutil
import sys
import tempfile
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))
import ton_pruefen  # noqa: E402

WURZEL = pathlib.Path(__file__).resolve().parents[3]


class TonPruefenTests(unittest.TestCase):
    def setUp(self):
        self.tmp = pathlib.Path(tempfile.mkdtemp())
        for teil in ("art/ton", "App/Audio"):
            shutil.copytree(WURZEL / teil, self.tmp / teil)

    def tearDown(self):
        shutil.rmtree(self.tmp)

    def liste(self):
        return json.loads((self.tmp / "art/ton/klaenge.json").read_text())

    def schreibe(self, liste):
        (self.tmp / "art/ton/klaenge.json").write_text(json.dumps(liste))

    def test_echtes_repo_ist_sauber(self):
        self.assertEqual(ton_pruefen.pruefen(WURZEL), [])

    def test_fremde_lizenz_faellt_auf(self):
        liste = self.liste()
        liste["quellen"]["rpg80"]["lizenz"] = "CC-BY-SA 3.0"
        self.schreibe(liste)
        self.assertTrue(any("rpg80" in f and "Lizenz" in f for f in ton_pruefen.pruefen(self.tmp)))

    def test_lizenzliste_bleibt_cc0(self):
        liste = self.liste()
        liste["erlaubte_lizenzen"].append("CC-BY 3.0")
        self.schreibe(liste)
        self.assertTrue(any("D-082" in f for f in ton_pruefen.pruefen(self.tmp)))

    def test_fehlende_pruefsumme_faellt_auf(self):
        liste = self.liste()
        del liste["quellen"]["plopp"]["sha256"]
        self.schreibe(liste)
        self.assertTrue(any("plopp" in f and "SHA-256" in f for f in ton_pruefen.pruefen(self.tmp)))

    def test_unbekannte_datei_faellt_auf(self):
        (self.tmp / "App/Audio/Sounds/geheim.caf").write_bytes(b"x")
        self.assertTrue(any("geheim.caf" in f for f in ton_pruefen.pruefen(self.tmp)))

    def test_fehlende_datei_faellt_auf(self):
        (self.tmp / "App/Audio/Sounds/hit_2.caf").unlink()
        fehler = ton_pruefen.pruefen(self.tmp)
        self.assertTrue(any("hit_2.caf" in f and "fehlt" in f for f in fehler))
        self.assertTrue(any("hit_2.caf" in f and "verlangt" in f for f in fehler))

    def test_neue_fassung_im_spiel_braucht_datei(self):
        style = self.tmp / "App/Audio/AudioStyle.swift"
        style.write_text(style.read_text().replace("case .leak: Mix(variants: 1", "case .leak: Mix(variants: 2"))
        self.assertTrue(any("leak_2.caf" in f for f in ton_pruefen.pruefen(self.tmp)))

    def test_zu_grosser_klang_faellt_auf(self):
        (self.tmp / "App/Audio/Sounds/hit_1.caf").write_bytes(b"0" * (ton_pruefen.KLANG_HOECHSTENS + 1))
        self.assertTrue(any("hit_1.caf" in f and "Bytes" in f for f in ton_pruefen.pruefen(self.tmp)))

    def test_quelle_ohne_entstehung_faellt_auf(self):
        datei = self.tmp / "art/ton/ENTSTEHUNG.md"
        datei.write_text(datei.read_text().replace("https://opengameart.org/content/3-pop-sounds", ""))
        self.assertTrue(any("3-pop-sounds" in f for f in ton_pruefen.pruefen(self.tmp)))


if __name__ == "__main__":
    unittest.main()
