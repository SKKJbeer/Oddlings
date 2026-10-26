"""Tests fuer die Grafik-Pipeline: Atlas-Pruefung und Kartenvorlage.

python3 -m unittest discover -s tools/art-check/tests
"""
import json, os, shutil, subprocess, sys, tempfile, unittest
from PIL import Image

HIER = os.path.dirname(os.path.abspath(__file__))
WURZEL = os.path.abspath(os.path.join(HIER, "../../.."))
sys.path.insert(0, os.path.join(WURZEL, "tools/art-check"))
import check_assets  # noqa: E402

VERTRAG = {
    "atlas": "Atlas.spriteatlas", "punkteJeZelle": 10, "maxBytesJeDatei": 100000,
    "assets": {"tower_x": {"seiteZellen": 2, "anker": 0.0, "alpha": True},
               "ground": {"zellen": [3, 2], "alpha": False}},
}


class AtlasPruefung(unittest.TestCase):
    def setUp(self):
        self.w = tempfile.mkdtemp()
        os.makedirs(os.path.join(self.w, "art"))
        json.dump(VERTRAG, open(os.path.join(self.w, "art/asset-vertrag.json"), "w"))
        open(os.path.join(self.w, "art/ENTSTEHUNG.md"), "w").write("`tower_x` `ground` FLUX.1-schnell")
        self.lege("tower_x", lambda f: self.figur(20 * f))
        self.lege("ground", lambda f: Image.new("RGB", (30 * f, 20 * f), (0, 120, 0)))

    def tearDown(self):
        shutil.rmtree(self.w)

    @staticmethod
    def figur(h):
        b = Image.new("RGBA", (h, h), (0, 0, 0, 0))
        b.paste((200, 50, 50, 255), (h // 4, h // 4, 3 * h // 4, h))
        return b

    def lege(self, name, mache, skalen=(2, 3)):
        o = os.path.join(self.w, "Atlas.spriteatlas", f"{name}.imageset")
        os.makedirs(o, exist_ok=True)
        open(os.path.join(o, "Contents.json"), "w").write("{}")
        for f in skalen:
            mache(f).save(os.path.join(o, f"{name}@{f}x.png"))

    def fehler(self):
        return check_assets.pruefe(self.w)

    def test_gueltiger_atlas(self):
        self.assertEqual(self.fehler(), [])

    def test_unbekannter_name(self):
        self.lege("tower_wach", lambda f: self.figur(20 * f))
        self.assertTrue(any("nicht im Vertrag" in z for z in self.fehler()))

    def test_fehlende_aufloesung(self):
        shutil.rmtree(os.path.join(self.w, "Atlas.spriteatlas/tower_x.imageset"))
        self.lege("tower_x", lambda f: self.figur(20 * f), skalen=(2,))
        self.assertTrue(any("@3x fehlt" in z for z in self.fehler()))

    def test_falsche_hoehe(self):
        self.lege("tower_x", lambda f: self.figur(25 * f))
        self.assertTrue(any("Groesse" in z for z in self.fehler()))

    def test_fuss_nicht_am_anker(self):
        def schwebt(f):
            h = 20 * f
            b = Image.new("RGBA", (h, h), (0, 0, 0, 0))
            b.paste((200, 50, 50, 255), (h // 4, h // 4, 3 * h // 4, h // 2))
            return b
        self.lege("tower_x", schwebt)
        self.assertTrue(any("Fuss" in z for z in self.fehler()))

    def test_nicht_freigestellt(self):
        self.lege("tower_x", lambda f: Image.new("RGBA", (20 * f, 20 * f), (90, 90, 90, 255)))
        self.assertTrue(any("nicht freigestellt" in z for z in self.fehler()))

    def test_hintergrund_in_den_ecken(self):
        def halb(f):
            b = self.figur(20 * f)
            b.putpixel((0, 0), (90, 90, 90, 255))
            return b
        self.lege("tower_x", halb)
        self.assertTrue(any("Ecken" in z for z in self.fehler()))

    def test_boden_mit_loch(self):
        self.lege("ground", lambda f: Image.new("RGBA", (30 * f, 20 * f), (0, 0, 0, 0)))
        self.assertTrue(any("Loecher" in z for z in self.fehler()))

    def test_bild_im_falschen_ordner(self):
        v = dict(VERTRAG, assets=dict(VERTRAG["assets"], ground={"zellen": [3, 2], "alpha": False, "ordner": "Boden", "format": "jpg"}))
        json.dump(v, open(os.path.join(self.w, "art/asset-vertrag.json"), "w"))
        self.assertTrue(any("Vertrag sagt" in z for z in self.fehler()))

    def test_boden_als_jpeg_im_eigenen_ordner(self):
        v = dict(VERTRAG, assets=dict(VERTRAG["assets"], ground={"zellen": [3, 2], "alpha": False, "ordner": "Boden", "format": "jpg"}))
        json.dump(v, open(os.path.join(self.w, "art/asset-vertrag.json"), "w"))
        shutil.rmtree(os.path.join(self.w, "Atlas.spriteatlas/ground.imageset"))
        o = os.path.join(self.w, "Boden/ground.imageset")
        os.makedirs(o)
        open(os.path.join(o, "Contents.json"), "w").write("{}")
        for f in (2, 3):
            Image.new("RGB", (30 * f, 20 * f), (0, 120, 0)).save(os.path.join(o, f"ground@{f}x.jpg"))
        self.assertEqual(self.fehler(), [])

    def test_herkunft_fehlt(self):
        open(os.path.join(self.w, "art/ENTSTEHUNG.md"), "w").write("`ground` FLUX.1-schnell")
        self.assertTrue(any("keine Herkunft" in z for z in self.fehler()))

    def test_verbotenes_modell(self):
        open(os.path.join(self.w, "art/ENTSTEHUNG.md"), "a").write(" FLUX.1-dev")
        self.assertTrue(any("nicht-kommerziell" in z for z in self.fehler()))

    def test_zu_gross(self):
        import random
        r = random.Random(1)
        def rauschen(f):
            b = Image.new("RGBA", (200 * f, 200 * f))
            b.putdata([(r.randrange(256), r.randrange(256), r.randrange(256), 255) for _ in range(b.width * b.height)])
            return b
        VERTRAG2 = dict(VERTRAG, assets=dict(VERTRAG["assets"], tower_x={"seiteZellen": 20, "anker": 0.0, "alpha": False}))
        json.dump(VERTRAG2, open(os.path.join(self.w, "art/asset-vertrag.json"), "w"))
        self.lege("tower_x", rauschen)
        self.assertTrue(any("Bytes" in z for z in self.fehler()))


class Oberflaechenbilder(unittest.TestCase):
    """Symbole (Punktgroesse, mittig) und grosse Bilder (Pixelgroesse, JPEG) im UI-Ordner."""
    V = {"atlas": "Atlas.spriteatlas", "punkteJeZelle": 10, "maxBytesJeDatei": 400000,
         "assets": {"ui_icon_x": {"punkte": 20, "alpha": True, "ordner": "UI"},
                    "ui_bild": {"pixel": [60, 30], "alpha": False, "ordner": "UI", "format": "jpg"}}}

    def setUp(self):
        self.w = tempfile.mkdtemp()
        os.makedirs(os.path.join(self.w, "art"))
        json.dump(self.V, open(os.path.join(self.w, "art/asset-vertrag.json"), "w"))
        open(os.path.join(self.w, "art/ENTSTEHUNG.md"), "w").write("`ui_icon_x` `ui_bild` FLUX.1-schnell")
        self.symbol(lambda s: (s // 4, s // 4, 3 * s // 4, 3 * s // 4))
        self.lege("ui_bild", "jpg", lambda f: Image.new("RGB", (20 * f, 10 * f), (0, 90, 0)))

    def tearDown(self):
        shutil.rmtree(self.w)

    def lege(self, name, endung, mache):
        o = os.path.join(self.w, "UI", f"{name}.imageset")
        os.makedirs(o, exist_ok=True)
        open(os.path.join(o, "Contents.json"), "w").write("{}")
        for f in (2, 3):
            mache(f).save(os.path.join(o, f"{name}@{f}x.{endung}"))

    def symbol(self, kasten, seite=20):
        def mache(f):
            s = seite * f
            b = Image.new("RGBA", (s, s), (0, 0, 0, 0))
            b.paste((200, 50, 50, 255), kasten(s))
            return b
        self.lege("ui_icon_x", "png", mache)

    def test_gueltig(self):
        self.assertEqual(check_assets.pruefe(self.w), [])

    def test_symbol_falsche_groesse(self):
        self.symbol(lambda s: (s // 4, s // 4, 3 * s // 4, 3 * s // 4), seite=24)
        self.assertTrue(any("Quadrat" in z for z in check_assets.pruefe(self.w)))

    def test_symbol_nicht_mittig(self):
        self.symbol(lambda s: (0, 0, s // 3, s // 3))
        self.assertTrue(any("nicht mittig" in z for z in check_assets.pruefe(self.w)))

    def test_bild_falsche_pixel(self):
        self.lege("ui_bild", "jpg", lambda f: Image.new("RGB", (21 * f, 10 * f), (0, 90, 0)))
        self.assertTrue(any("ui_bild" in z and "Groesse" in z for z in check_assets.pruefe(self.w)))


class EchtesRepo(unittest.TestCase):
    def test_repo_atlas_haelt_den_vertrag(self):
        self.assertEqual(check_assets.pruefe(WURZEL), [])

    def test_vertrag_kennt_die_ids_der_simulation(self):
        # Namen folgen den IDs in der Missionskonfiguration (watch, lightning, spore, raider, ...).
        konf = json.load(open(os.path.join(WURZEL, "Packages/OddlingsCore/Sources/OddlingsCore/Resources/Balance/mvp-mission-01.json")))
        vertrag = json.load(open(os.path.join(WURZEL, "art/asset-vertrag.json")))["assets"]
        ids = lambda x: x.keys() if isinstance(x, dict) else [e["id"] for e in x]
        for t in ids(konf["towers"]):
            self.assertIn(f"tower_{t}", vertrag)
        for g in ids(konf["enemies"]):
            self.assertIn(f"enemy_{g}", vertrag)


class Regionsvorlage(unittest.TestCase):
    def test_lichtungen_liegen_unter_den_knoten(self):
        region = os.path.join(WURZEL, "Packages/OddlingsCore/Sources/OddlingsCore/Resources/Campaign/region-01.json")
        knoten = json.load(open(region))["nodes"]
        with tempfile.TemporaryDirectory() as t:
            aus = os.path.join(t, "r.png")
            subprocess.run([sys.executable, os.path.join(WURZEL, ".claude/skills/spielgrafik/scripts/regionsvorlage.py"),
                            region, aus, "640"], check=True, capture_output=True)
            bild = Image.open(aus).convert("RGB")
            self.assertEqual(bild.size, (640, 400))  # 16:10 wie CampaignStyle.mapAspect
            hell = lambda p: 0.299 * p[0] + 0.587 * p[1] + 0.114 * p[2]
            for k in knoten:
                p = bild.getpixel((int(k["position"][0] * 640), int(k["position"][1] * 400)))
                if k["kind"] == "boss":
                    self.assertGreater(p[0], p[1], k["id"])  # Bosslichtung roetlich-dunkel, nicht Wald
                else:
                    self.assertGreater(hell(p), 105, k["id"])  # Lichtung heller als jede Baumkrone
            # Weit weg von allen Knoten ist Wald.
            self.assertLess(hell(bild.getpixel((int(0.40 * 640), int(0.15 * 400)))), 105)


class Kartenvorlage(unittest.TestCase):
    def test_weg_liegt_wo_die_simulation_ihn_fuehrt(self):
        konf = os.path.join(WURZEL, "Packages/OddlingsCore/Sources/OddlingsCore/Resources/Balance/mvp-mission-01.json")
        karte = json.load(open(konf))["map"]
        with tempfile.TemporaryDirectory() as t:
            aus = os.path.join(t, "v.png")
            subprocess.run([sys.executable, os.path.join(WURZEL, ".claude/skills/spielgrafik/scripts/kartenvorlage.py"),
                            konf, aus, "32"], check=True, capture_output=True)
            bild = Image.open(aus).convert("RGB")
            self.assertEqual(bild.size, (karte["width"] * 32, karte["height"] * 32))
            sand = lambda p: p[0] > p[1] and p[0] > 150  # Weg ist sandfarben, Wiese gruen
            # Jeder innere Wegpunkt (Ecke) liegt auf Sand.
            for x, y in karte["path"][1:-1]:
                self.assertTrue(sand(bild.getpixel((int(x * 32), int(y * 32)))), (x, y))
            # Zellmitte weit weg vom Weg ist Wiese: Zelle (0, 8) unten links.
            self.assertFalse(sand(bild.getpixel((16, 8 * 32 + 16))))


if __name__ == "__main__":
    unittest.main()
