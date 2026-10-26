"""Tests fuer die Grafik-Pipeline: Atlas-Pruefung und Kartenvorlage.

python3 -m unittest discover -s tools/art-check/tests
"""
import json, math, os, shutil, subprocess, sys, tempfile, unittest
from PIL import Image, ImageDraw, ImageStat

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


class Regionscollage(unittest.TestCase):
    """Einfarbige Teile statt gemalter: So laesst sich messen, ob ein Baum auf einer
    Lichtung oder einem Weg gelandet ist."""

    def test_lichtungen_und_wege_bleiben_frei(self):
        region = os.path.join(WURZEL, "Packages/OddlingsCore/Sources/OddlingsCore/Resources/Campaign/region-01.json")
        knoten = {k["id"]: k for k in json.load(open(region))["nodes"]}
        with tempfile.TemporaryDirectory() as t:
            Image.new("RGB", (200, 200), (120, 200, 90)).save(os.path.join(t, "gras.png"))
            Image.new("RGB", (200, 200), (210, 180, 120)).save(os.path.join(t, "weg.png"))
            baum = Image.new("RGBA", (60, 60), (0, 0, 0, 0))
            ImageDraw.Draw(baum).ellipse((0, 0, 59, 59), fill=(255, 0, 255, 255))
            baum.save(os.path.join(t, "baum0.png"))
            aus = os.path.join(t, "k.png")
            subprocess.run([sys.executable, os.path.join(WURZEL, ".claude/skills/spielgrafik/scripts/regionscollage.py"),
                            region, t, aus, "800"], check=True, capture_output=True)
            bild = Image.open(aus).convert("RGB")
            self.assertEqual(bild.size, (800, 500))  # 16:10 wie CampaignStyle.mapAspect
            baumig = lambda p: p[0] > p[1] + 60 and p[2] > p[1] + 60  # magenta, auch abgedunkelt
            for k in knoten.values():
                x, y = k["position"][0] * 800, k["position"][1] * 500
                # Knotenmitte und ein Ring in Medaillengroesse (26 von 454 pt) ohne Baum.
                for w in range(0, 360, 30):
                    r = 0 if w == 0 else 800 * 26 / 454
                    p = (int(x + r * math.cos(math.radians(w))), int(y + r * math.sin(math.radians(w))))
                    if 0 <= p[0] < 800 and 0 <= p[1] < 500:
                        self.assertFalse(baumig(bild.getpixel(p)), f"{k['id']} {w}")
            # Mitte jedes Weges frei, und abseits steht Wald.
            for k in knoten.values():
                for v in k.get("requires", []):
                    (x0, y0), (x1, y1) = knoten[v]["position"], k["position"]
                    mx = (x0 + x1) / 2 * 800 - (y1 - y0) * 500 * 0.18 / 2
                    my = (y0 + y1) / 2 * 500 + (x1 - x0) * 800 * 0.18 / 2
                    self.assertFalse(baumig(bild.getpixel((int(mx), int(my)))), f"{v}-{k['id']}")
            self.assertTrue(baumig(bild.getpixel((int(0.40 * 800), int(0.12 * 500)))))


class Regionskarte(unittest.TestCase):
    """Das ausgelieferte Bild selbst: Unter jedem Knoten liegt eine Lichtung. Ein
    neu gemaltes oder anders zusammengesetztes Bild, das die Lagen nicht trifft,
    faellt hier auf und nicht erst auf dem iPhone."""

    def test_unter_jedem_knoten_liegt_eine_lichtung(self):
        region = os.path.join(WURZEL, "Packages/OddlingsCore/Sources/OddlingsCore/Resources/Campaign/region-01.json")
        bild = Image.open(os.path.join(WURZEL, "App/Assets.xcassets/Maps/map_region01.imageset/map_region01@3x.jpg")).convert("L")
        B, H = bild.size
        self.assertAlmostEqual(B / H, 1.6, places=2)  # CampaignStyle.mapAspect
        schnitt = ImageStat.Stat(bild).mean[0]
        r = B * 26 / 454  # Medaille 52 pt auf einer rund 454 pt breiten Karte
        for k in json.load(open(region))["nodes"]:
            x, y = k["position"][0] * B, k["position"][1] * H
            maske = Image.new("L", bild.size, 0)
            ImageDraw.Draw(maske).ellipse((x - r, y - r, x + r, y + r), fill=255)
            hell = ImageStat.Stat(bild, maske).mean[0]
            # Lichtung im Sonnenlicht gegen dunklen Wald; die Bosslichtung ist absichtlich finster.
            self.assertGreater(hell, schnitt * (1.1 if k["kind"] == "boss" else 1.25), k["id"])


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
