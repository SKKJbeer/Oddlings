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

    def folge(self, anzahl):
        v = dict(VERTRAG, assets=dict(VERTRAG["assets"], tower_x_walk={"folge": 3, "seiteZellen": 2, "anker": 0.0, "alpha": True}))
        json.dump(v, open(os.path.join(self.w, "art/asset-vertrag.json"), "w"))
        open(os.path.join(self.w, "art/ENTSTEHUNG.md"), "a").write(" `tower_x_walk`")
        for i in anzahl:
            self.lege(f"tower_x_walk_{i:02d}", lambda f: self.figur(20 * f))

    def test_bildfolge_vollstaendig(self):
        self.folge([0, 1, 2])
        self.assertEqual(self.fehler(), [])

    def test_bildfolge_mit_luecke(self):
        self.folge([0, 2])
        self.assertTrue(any("Folge verlangt" in z for z in self.fehler()), self.fehler())

    def test_bildfolge_zu_lang(self):
        self.folge([0, 1, 2, 3])
        self.assertTrue(any("Folge verlangt" in z for z in self.fehler()), self.fehler())

    def test_blickrichtung_passt_zur_seitenfolge(self):
        self.folge([0, 1, 2])
        v = json.load(open(os.path.join(self.w, "art/asset-vertrag.json")))
        v["assets"]["tower_x_walkFront"] = {"folge": 3, "seiteZellen": 2, "anker": 0.0, "alpha": True}
        json.dump(v, open(os.path.join(self.w, "art/asset-vertrag.json"), "w"))
        open(os.path.join(self.w, "art/ENTSTEHUNG.md"), "a").write(" `tower_x_walkFront`")
        for i in range(3):
            self.lege(f"tower_x_walkFront_{i:02d}", lambda f: self.figur(20 * f))
        self.assertEqual(self.fehler(), [])
        v["assets"]["tower_x_walkFront"]["anker"] = 0.1
        json.dump(v, open(os.path.join(self.w, "art/asset-vertrag.json"), "w"))
        self.assertTrue(any("Seitenfolge hat" in z for z in self.fehler()), self.fehler())

    def test_kamera_ausserhalb_des_spielraums(self):
        v = dict(VERTRAG, kamera={"art": "orthografisch", "hoehe": 40, "figurenSpielraum": 10})
        json.dump(v, open(os.path.join(self.w, "art/asset-vertrag.json"), "w"))
        os.makedirs(os.path.join(self.w, "art/figuren-3d/enemy_x"))
        rig = os.path.join(self.w, "art/figuren-3d/enemy_x/rig.json")
        json.dump({"kameraHoehe": 30}, open(rig, "w"))
        self.assertEqual(self.fehler(), [])
        json.dump({"kameraHoehe": 12}, open(rig, "w"))
        self.assertTrue(any("gemeinsame Kamera" in z for z in self.fehler()), self.fehler())

    def test_folge_ohne_kontur(self):
        self.folge([0, 1, 2])
        v = json.load(open(os.path.join(self.w, "art/asset-vertrag.json")))
        v["konturPunkte"] = 1
        json.dump(v, open(os.path.join(self.w, "art/asset-vertrag.json"), "w"))
        # Die Testfigur ist ein helles Rot ohne Rand.
        self.assertTrue(any("keine dunkle Kontur" in z for z in self.fehler()), self.fehler())
        sys.path.insert(0, os.path.join(WURZEL, "tools/figuren-3d"))
        from konturpass import kontur
        for i in range(3):
            self.lege(f"tower_x_walk_{i:02d}", lambda f: kontur(self.figur(20 * f), f))
        self.assertEqual(self.fehler(), [])

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


class Angleichen(unittest.TestCase):
    """FX 02: Rohrender werden an das gemalte Bild angeglichen, ohne zu flackern."""

    def test_farbe_kontur_und_gleiche_umrechnung(self):
        with tempfile.TemporaryDirectory() as w:
            vorbild = Image.new("RGBA", (60, 60), (0, 0, 0, 0))
            vorbild.paste((90, 200, 60, 255), (5, 5, 55, 55))
            vorbild.save(os.path.join(w, "vorbild.png"))
            os.makedirs(os.path.join(w, "ein"))
            roh = Image.new("RGBA", (40, 40), (0, 0, 0, 0))
            roh.paste((40, 60, 35, 255), (10, 5, 30, 35))
            for n in ("walk_00", "walk_01"):
                roh.save(os.path.join(w, "ein", f"{n}.png"))
            subprocess.run([sys.executable, os.path.join(WURZEL, ".claude/skills/spielgrafik/scripts/angleichen.py"),
                            os.path.join(w, "vorbild.png"), os.path.join(w, "ein"), os.path.join(w, "aus")],
                           check=True, capture_output=True)
            a, b = (Image.open(os.path.join(w, "aus", f"walk_0{i}.png")) for i in (0, 1))
            self.assertEqual(a.size, roh.size)  # nicht zugeschnitten, Anker bleibt
            self.assertEqual(a.tobytes(), b.tobytes())  # eine Umrechnung fuer die ganze Folge
            r, g, _, _ = a.getpixel((20, 20))
            self.assertGreater(g, 120)  # heller und gruener als das Rohbild
            self.assertGreater(g, r)
            self.assertGreater(a.getpixel((9, 20))[3], 0)  # Kontur ausserhalb der Figur


class Kampfplatz(unittest.TestCase):
    """Einfarbige Teile: Baeume (magenta) stehen nur im Rand, der Weg liegt auf der
    Weggeometrie der Mission, um den Rand verschoben."""

    def test_baeume_nur_im_rand_und_weg_auf_der_geometrie(self):
        konf = os.path.join(WURZEL, "Packages/OddlingsCore/Sources/OddlingsCore/Resources/Balance/mvp-mission-01.json")
        karte = json.load(open(konf))["map"]
        z, m = 20, 2
        with tempfile.TemporaryDirectory() as t:
            Image.new("RGB", (200, 200), (120, 200, 90)).save(os.path.join(t, "gras.png"))
            Image.new("RGB", (200, 200), (210, 150, 90)).save(os.path.join(t, "weg.png"))
            baum = Image.new("RGBA", (60, 60), (0, 0, 0, 0))
            ImageDraw.Draw(baum).ellipse((0, 0, 59, 59), fill=(255, 0, 255, 255))
            baum.save(os.path.join(t, "baum0.png"))
            aus = os.path.join(t, "k.png")
            subprocess.run([sys.executable, os.path.join(WURZEL, ".claude/skills/spielgrafik/scripts/kampfplatz.py"),
                            konf, t, aus, str(z), str(m)], check=True, capture_output=True)
            bild = Image.open(aus).convert("RGB")
            self.assertEqual(bild.size, ((karte["width"] + 2 * m) * z, (karte["height"] + 2 * m) * z))
            px = lambda x, y: bild.getpixel((int((x + m) * z), int((y + m) * z)))
            baumig = lambda p: p[0] > p[1] + 40 and p[2] > p[1] + 40
            # Jede Zellmitte des Feldes ist bebaubar oder Weg: kein Baum darauf.
            for x in range(karte["width"]):
                for y in range(karte["height"]):
                    self.assertFalse(baumig(px(x + 0.5, y + 0.5)), (x, y))
            # Ecken des Weges liegen auf Weg (rotbraun), nicht auf Gras.
            for x, y in karte["path"][1:-1]:
                p = px(x, y)
                self.assertGreater(p[0], p[1], (x, y))
            # Im Rand neben dem Feld steht Wald.
            self.assertTrue(baumig(px(-1, karte["height"] / 2)))


class KampfplatzDeko(unittest.TestCase):
    """Grafik 06: Deko (cyan) steht nur im Waldrand, nie auf einer Zellmitte des Feldes,
    und LICHT toent das Bild. Ohne DEKO bleibt M1 unveraendert (eigener Zufall)."""

    def test_deko_nur_im_rand(self):
        konf = os.path.join(WURZEL, "art/karten/wegvorschlaege/mission-04.json")
        karte = json.load(open(konf))["map"]
        z = 20
        with tempfile.TemporaryDirectory() as t:
            Image.new("RGB", (200, 200), (120, 200, 90)).save(os.path.join(t, "gras.png"))
            Image.new("RGB", (200, 200), (210, 150, 90)).save(os.path.join(t, "weg.png"))
            baum = Image.new("RGBA", (60, 60), (0, 0, 0, 0))
            ImageDraw.Draw(baum).ellipse((0, 0, 59, 59), fill=(30, 90, 30, 255))
            baum.save(os.path.join(t, "baum0.png"))
            deko = os.path.join(t, "deko")
            os.makedirs(deko)
            # Das letzte Teil ist hoch (toter Baum, Saeule, Grafik 07): Es darf mit seiner
            # Hoehe nicht aus dem unteren Rand ueber die Bauzellen ragen.
            for i, (b, h) in enumerate(((60, 60), (40, 40), (30, 30), (20, 80))):
                d = Image.new("RGBA", (b, h), (0, 0, 0, 0))
                ImageDraw.Draw(d).rectangle((0, 0, b - 1, h - 1), fill=(0, 255, 255, 255))
                d.save(os.path.join(deko, f"deko{i}.png"))
            aus = os.path.join(t, "k.png")
            umg = dict(os.environ, DEKO=deko, DEKO_ANZAHL="9", LICHT="255,255,255")
            subprocess.run([sys.executable, os.path.join(WURZEL, ".claude/skills/spielgrafik/scripts/kampfplatz.py"),
                            konf, t, aus, str(z), "4x2"], check=True, capture_output=True, env=umg)
            bild = Image.open(aus).convert("RGB")
            px = lambda x, y: bild.getpixel((int((x + 4) * z), int((y + 2) * z)))
            cyan = lambda p: p[1] > p[0] + 60 and p[2] > p[0] + 60
            for x in range(karte["width"]):
                for y in range(karte["height"]):
                    self.assertFalse(cyan(px(x + 0.5, y + 0.5)), (x, y))
            lagen = json.load(open(os.path.join(t, "k-deko.json")))
            self.assertGreater(len(lagen["deko"]), 3)  # es steht ueberhaupt Deko
            for x, y, b in lagen["deko"]:
                r = b / 2 - lagen["ueberhang"]
                im_feld = -r < x < karte["width"] + r and -r < y < karte["height"] + r
                self.assertFalse(im_feld, (x, y, b))
            self.assertTrue(any(cyan(bild.getpixel((xx, yy))) for xx in range(0, bild.width, 4)
                                for yy in range(0, bild.height, 4)))


def kampfplatzkarten():
    """Alle Karten des Vertrags mit Weggeometrie: (Name, Regel, Karte)."""
    vertrag = json.load(open(os.path.join(WURZEL, "art/asset-vertrag.json")))
    for name, regel in sorted(vertrag["assets"].items()):
        if "mission" in regel:
            yield name, regel, json.load(open(os.path.join(WURZEL, regel["mission"])))["map"]


class Kampfplatzbild(unittest.TestCase):
    """Die ausgelieferten Bilder: Rand laut Vertrag, Weg dort, wo die Simulation ihn
    fuehrt, und dunkler Wald im Rand. Fuer jede Mission mit Bild (Grafik 06)."""

    def test_alle_missionen_haben_eine_geometrie(self):
        namen = [n for n, _, _ in kampfplatzkarten()]
        self.assertIn("map_mission01_ground", namen)

    def test_wegvorschlag_stimmt_mit_der_missionsdatei(self):
        # D-081: Uebernimmt ein Missions-Thread den Weg in seine Missionsdatei, muss das
        # Bild auf diese Datei zeigen; weicht der Weg ab, ist der Kampfplatz nachzumalen.
        balance = os.path.join(WURZEL, "Packages/OddlingsCore/Sources/OddlingsCore/Resources/Balance")
        for name, regel, karte in kampfplatzkarten():
            if "wegvorschlaege" not in regel["mission"]:
                continue
            mission = os.path.join(balance, os.path.basename(regel["mission"]))
            if os.path.exists(mission):
                self.assertEqual(json.load(open(mission))["map"]["path"], karte["path"],
                                 f"{name}: Weg der Missionsdatei weicht vom gemalten ab, nachmalen")

    def test_wegvorschlaege_sind_spielbar(self):
        # Grafik 07: Ein Vorschlag muss ein Weg sein, den die Simulation laufen kann und
        # zwischen dessen Bahnen gebaut werden kann. Sonst malt man einen Weg, den kein
        # Missions-Thread uebernehmen kann.
        ordner = os.path.join(WURZEL, "art/karten/wegvorschlaege")
        for datei in sorted(os.listdir(ordner)):
            with self.subTest(datei):
                karte = json.load(open(os.path.join(ordner, datei)))["map"]
                w, h, pfad = karte["width"], karte["height"], karte["path"]
                self.assertEqual(pfad[0][0], -1)
                self.assertEqual(pfad[-1][0], w + 1)
                for x, y in pfad[1:-1]:
                    self.assertTrue(0 < x < w and 0 < y < h, (x, y))
                for (ax, ay), (bx, by) in zip(pfad, pfad[1:]):
                    self.assertTrue(ax == bx or ay == by, ((ax, ay), (bx, by)))
                # Parallele Bahnen: mindestens zwei Zellen Abstand, sonst passt kein Turm dazwischen.
                strecken = list(zip(pfad, pfad[1:]))
                for i, ((ax, ay), (bx, by)) in enumerate(strecken):
                    for (cx, cy), (dx, dy) in strecken[i + 2:]:
                        if ax == bx and cx == dx and min(max(ay, by), max(cy, dy)) > max(min(ay, by), min(cy, dy)):
                            self.assertGreaterEqual(abs(ax - cx), 2, (ax, cx))
                        if ay == by and cy == dy and min(max(ax, bx), max(cx, dx)) > max(min(ax, bx), min(cx, dx)):
                            self.assertGreaterEqual(abs(ay - cy), 2, (ay, cy))

    def test_weg_und_wald_liegen_richtig(self):
        for name, regel, karte in kampfplatzkarten():
            with self.subTest(name):
                mx, my = regel["rand"]  # Zellen links/rechts und oben/unten (BattleStyle.groundMargin)
                self.assertEqual(regel["zellen"], [karte["width"] + 2 * mx, karte["height"] + 2 * my])
                bild = Image.open(os.path.join(WURZEL, regel["ordner"], f"{name}.imageset", f"{name}@3x.jpg")).convert("RGB")
                z = bild.width / regel["zellen"][0]
                px = lambda x, y: bild.getpixel((int((x + mx) * z), int((y + my) * z)))
                for x, y in karte["path"][1:-1]:
                    p = px(x, y)
                    self.assertGreater(p[0], p[1], (x, y))  # Erde, nicht Gras
                # Mitte jedes geraden Wegstuecks ebenso: Ecken allein liessen einen verschobenen Weg durch.
                for (ax, ay), (bx, by) in zip(karte["path"][1:-2], karte["path"][2:-1]):
                    p = px((ax + bx) / 2, (ay + by) / 2)
                    self.assertGreater(p[0], p[1], ((ax + bx) / 2, (ay + by) / 2))
                hell = lambda x, y: sum(px(x, y)) / 3
                feld = sum(hell(x + 0.5, y + 0.5) for x in range(karte["width"]) for y in range(karte["height"])) / (karte["width"] * karte["height"])
                # Rand als Streifen gemittelt, nicht als Einzelpixel: Ein heller Busch im Wald
                # ist erlaubt, ein heller Waldrand nicht.
                def streifen(punkte):
                    return sum(hell(x, y) for x, y in punkte) / len(punkte)
                h, w = karte["height"], karte["width"]
                for name_, punkte in (("links", [(-1.5, y / 2) for y in range(2 * h)]),
                                      ("aussen links", [(-mx + 0.5, y / 2) for y in range(2 * h)]),
                                      ("aussen rechts", [(w + mx - 0.5, y / 2) for y in range(2 * h)]),
                                      ("oben", [(x / 2, -1.5) for x in range(2 * w)]),
                                      ("unten", [(x / 2, h + 1.5) for x in range(2 * w)])):
                    self.assertLess(streifen(punkte), feld * 0.8, name_)


class TuermeInDerWelt(unittest.TestCase):
    """D-120, D-196: Jeder Turm hat einen Schatten, der am Grundriss sitzt, jeder
    Kampfplatz Licht, und das Licht ist dasselbe, mit dem der Boden gemalt wurde."""

    ATLAS = os.path.join(WURZEL, "App/Assets.xcassets/Battle.spriteatlas")
    KARTEN = os.path.join(WURZEL, "App/Assets.xcassets/Maps")

    def missionen(self):
        import re
        return [re.fullmatch(r"map_mission(\w+)_ground\.imageset", e).group(1)
                for e in sorted(os.listdir(self.KARTEN)) if e.startswith("map_mission")]

    def bild(self, name):
        return Image.open(os.path.join(self.ATLAS, f"{name}.imageset", f"{name}@3x.png")).convert("RGBA")

    def test_jeder_turm_hat_einen_schatten(self):
        import re
        tuerme = [e[:-9] for e in os.listdir(self.ATLAS) if re.fullmatch(r"tower_[a-z]+(_\d)?\.imageset", e)]
        self.assertGreater(len(tuerme), 3)
        for t in tuerme:
            self.assertTrue(os.path.isdir(os.path.join(self.ATLAS, f"{t}_shadow.imageset")), t)

    def test_jeder_kampfplatz_hat_licht(self):
        licht = json.load(open(os.path.join(WURZEL, "App/Battle/kampfplatzlicht.json")))
        for m in self.missionen():
            self.assertIn(f"mission-{m}", licht, m)

    def test_kein_sockel_und_kein_fundament_mehr(self):
        # D-196: Sie lagen um den vordersten Punkt des Fußes statt um den Grundriss
        # und zeigten dem Turm einen Boden in anderer Perspektive.
        for e in os.listdir(self.ATLAS):
            self.assertFalse(e.startswith(("footing_", "tower_plinth", "tower_contact")), e)

    def test_licht_ist_das_licht_des_bodens(self):
        # Steht der Wert nicht in der Entstehung des Bodens, wurde einer der beiden
        # geändert und der andere nicht. M1 ist der Vorgabewert von kampfplatz.py.
        licht = json.load(open(os.path.join(WURZEL, "App/Battle/kampfplatzlicht.json")))
        quelle = open(os.path.join(WURZEL, "art/karten/ENTSTEHUNG.md"), encoding="utf-8").read()
        quelle += open(os.path.join(WURZEL, ".claude/skills/spielgrafik/scripts/kampfplatz.py"), encoding="utf-8").read()
        for mission, rgb in licht.items():
            if mission.startswith("mission-"):
                self.assertIn(",".join(map(str, rgb)), quelle, mission)

    def kronen(self):
        return json.load(open(os.path.join(WURZEL, "App/Battle/turmkronen.json")))

    def turmbilder(self, art):
        import re
        return [e[:-9] for e in sorted(os.listdir(self.ATLAS))
                if re.fullmatch(rf"tower_{art}(_[a-z0-9]+)?\.imageset", e) and not e.endswith(("_shadow.imageset", "_grass.imageset"))]

    def test_jeder_wachturm_hat_schuetzen_auf_der_plattform(self):
        # A-5 Teil 3 (D-185): Ohne Eintrag stünde der Wachturm leer da, die
        # Armbrust ist aus dem Bild gemalt. Der Fuß muss auf Stein oder Holz stehen.
        kronen = self.kronen()
        bilder = self.turmbilder("watch")
        self.assertGreaterEqual(len(bilder), 4)
        for name in bilder:
            punkte = kronen.get(name, {}).get("schuetzen", [])
            self.assertTrue(punkte, f"{name}: keine Schützen in turmkronen.json")
            a = self.bild(name).getchannel("A")
            for u, v in punkte:
                x, y = round(u * (a.width - 1)), round((1 - v) * (a.height - 1))
                self.assertGreater(a.getpixel((x, y)), 200, f"{name}: Schütze bei ({u}, {v}) steht in der Luft")
        self.assertEqual(len(kronen["tower_watch_volley"]["schuetzen"]), 2, "Salve: zwei Schützen")

    def test_jeder_sporenturm_hat_eine_hutlinie_im_bild(self):
        # D-188: Die Linie trennt Stiel und Hut; darüber verschiebt das Gitter.
        # Unter ihr ist der Stiel schmaler als der Hut darüber.
        kronen = self.kronen()
        for name in self.turmbilder("spore"):
            linie = kronen.get(name, {}).get("hutLinie")
            self.assertIsNotNone(linie, f"{name}: keine hutLinie")
            a = self.bild(name).getchannel("A")

            def breite(v):
                y = round((1 - v) * (a.height - 1))
                xs = [x for x in range(a.width) if a.getpixel((x, y)) > 200]
                return (max(xs) - min(xs)) if xs else 0
            self.assertGreater(breite(linie + 0.08), 1.3 * breite(linie - 0.08), f"{name}: Linie {linie} trennt nicht Hut und Stiel")

    def test_schuetze_hat_acht_gleiche_richtungen(self):
        # Die Szene wechselt beim Drehen das Bild; andere Größe oder Länge ließe ihn springen.
        assets = json.load(open(os.path.join(WURZEL, "art/asset-vertrag.json")))["assets"]
        # Der Schütze folgt dem Volk: jede Figur (Zwerg `tower_guard`, Elf `tower_guardElf`)
        # mit allen acht Richtungen und demselben Vertrag; der Zwerg ist Pflicht (Rückfall).
        import re
        figuren = {m.group(1) for k in assets if (m := re.fullmatch(r"(tower_guard\w*)_shoot\d", k))}
        self.assertIn("tower_guard", figuren)
        richtungen = [assets.get(f"{figur}_shoot{r}") for figur in sorted(figuren) for r in range(8)]
        self.assertTrue(all(richtungen), f"{sorted(figuren)}: shoot0 bis 7 im Vertrag")
        self.assertEqual(len({json.dumps(r, sort_keys=True) for r in richtungen}), 1)

    def test_schatten_faellt_nach_rechts_unten(self):
        # Licht von oben links (art-direction.md): Der Schwerpunkt des Schattens
        # liegt rechts unterhalb des Fußes, der in der Bildmitte sitzt.
        for name in ("tower_watch_shadow", "tower_spore_shadow", "tower_lightning_shadow"):
            a = self.bild(name).getchannel("A")
            w, h = a.size
            summe = sx = sy = 0
            for y in range(0, h, 2):
                for x in range(0, w, 2):
                    v = a.getpixel((x, y))
                    summe += v; sx += v * x; sy += v * y
            # Seit D-196 sitzt das Kontaktdunkel hinter dem Anker (Bildmitte), um die
            # Mitte des Grundrisses; der Schwerpunkt liegt trotzdem rechts und nicht
            # weit darüber.
            z = json.load(open(os.path.join(WURZEL, "art/asset-vertrag.json")))["punkteJeZelle"] * 3
            self.assertGreater(sx / summe, w / 2 + 0.05 * z, name)
            self.assertGreater(sy / summe, h / 2 - 0.2 * z, name)

    def test_dunkel_sitzt_unter_dem_turm_nicht_davor(self):
        # D-196: Der Anker (Bildmitte) ist der vorderste Punkt des Grundrisses. Das
        # Kontaktdunkel gehört dahinter, unter den Turm; vor dem Fuß links der Mitte,
        # wo der Schlagschatten (45° nach rechts unten) nicht hinreicht, liegt Gras. Ein dunkles Band dort ließe
        # den Turm über seinem Schatten schweben (bis 0.47.0 so).
        z = json.load(open(os.path.join(WURZEL, "art/asset-vertrag.json")))["punkteJeZelle"] * 3
        tuerme = [e[:-9] for e in os.listdir(self.ATLAS) if e.endswith("_shadow.imageset")
                  and e.startswith("tower_")]
        self.assertGreater(len(tuerme), 10)
        for name in tuerme:
            a = self.bild(name).getchannel("A")
            w, h = a.size
            self.assertGreater(a.getpixel((w // 2, round(h / 2 - 0.1 * z))), 150, f"{name}: kein Dunkel unter dem Fuß")
            for dx in (0.22, 0.28):
                vorn = a.getpixel((round(w / 2 - dx * z), round(h / 2 + 0.12 * z)))
                self.assertLess(vorn, 60, f"{name}: Dunkel vor dem Fuß ({vorn})")

    def test_skript_rechnet_gleich(self):
        # Gleiche Eingabe, gleiches Bild: Der Atlas ist aus dem Skript entstanden.
        with tempfile.TemporaryDirectory() as t:
            for teil in ("art", "App/Assets.xcassets", "Packages/OddlingsCore/Sources/OddlingsCore/Resources/Balance"):
                shutil.copytree(os.path.join(WURZEL, teil), os.path.join(t, teil))
            subprocess.run([sys.executable, os.path.join(WURZEL, ".claude/skills/spielgrafik/scripts/turmboden.py"), t],
                           check=True, capture_output=True)
            for name in ("tower_watch_shadow", "tower_spore_rot_shadow", "tower_lightning_2_shadow"):
                for f in (2, 3):
                    rel = f"App/Assets.xcassets/Battle.spriteatlas/{name}.imageset/{name}@{f}x.png"
                    alt = Image.open(os.path.join(WURZEL, rel)).convert("RGBA")
                    neu = Image.open(os.path.join(t, rel)).convert("RGBA")
                    self.assertEqual(list(alt.getdata()), list(neu.getdata()), rel)


class TuermeImLicht(unittest.TestCase):
    """D-200 bis D-203: gemalte Türme im Licht der 3D-Welt (turmlicht.py)."""

    ATLAS = os.path.join(WURZEL, "App/Assets.xcassets/Battle.spriteatlas")
    QUELLE = os.path.join(WURZEL, "art/tuerme-in-der-welt/quelle")

    def namen(self):
        return sorted(d[:-4] for d in os.listdir(self.QUELLE) if d.endswith(".png"))

    def atlas(self, name):
        return Image.open(os.path.join(self.ATLAS, f"{name}.imageset", f"{name}@3x.png")).convert("RGBA")

    def quelle(self, name):
        return Image.open(os.path.join(self.QUELLE, f"{name}.png")).convert("RGBA")

    def test_jedes_turmbild_hat_quelle_und_grasmaske(self):
        import re
        bilder = sorted(e[:-9] for e in os.listdir(self.ATLAS)
                        if re.fullmatch(r"tower_(watch|lightning|spore|bank)(_[a-z0-9]+)?\.imageset", e)
                        and not e.endswith(("_shadow.imageset", "_grass.imageset")))
        self.assertEqual(bilder, self.namen())
        for name in bilder:
            self.assertTrue(os.path.isdir(os.path.join(self.ATLAS, f"{name}_grass.imageset")), name)

    def test_umriss_bleibt_pixelgenau(self):
        # Kronen und Schützen (D-185) sitzen auf Punkten im Bild; das Licht darf nichts verschieben.
        for name in self.namen():
            self.assertEqual(self.atlas(name).getchannel("A").tobytes(), self.quelle(name).getchannel("A").tobytes(), name)

    def test_schattenseite_rechts_lichtseite_links(self):
        # Sonne von oben links hinten (Vertrag): rechts dunkler als die Malerei, links nicht.
        for name in self.namen():
            neu, alt = self.atlas(name), self.quelle(name)
            w, h = neu.size
            def mittel(bild, x0, x1):
                box = (x0, 0, x1, int(h * 0.75))
                hell = ImageStat.Stat(bild.convert("L").crop(box), mask=bild.getchannel("A").crop(box).point(lambda v: 255 if v > 200 else 0))
                return hell.mean[0]
            rechts = mittel(neu, w // 2, w) / mittel(alt, w // 2, w)
            links = mittel(neu, 0, w // 2) / mittel(alt, 0, w // 2)
            self.assertLess(rechts, 0.92, name)
            self.assertGreater(links, rechts + 0.08, name)

    def skript(self, modul):
        # Die Skripte lesen die Wurzel beim Laden aus sys.argv.
        import importlib
        sys.path.insert(0, os.path.join(WURZEL, ".claude/skills/spielgrafik/scripts"))
        alt = sys.argv
        sys.argv = ["x", WURZEL]
        try:
            return importlib.import_module(modul)
        finally:
            sys.argv = alt

    def test_gras_deckt_die_fusslinie_und_nur_sie(self):
        turmboden = self.skript("turmboden")
        for name in self.namen():
            maske = self.atlas(f"{name}_grass").getchannel("A")
            mx, unten, ha, hb = turmboden.fuss(self.quelle(name))
            self.assertGreater(maske.getpixel((round(mx), round(unten))), 200, f"{name}: Fußlinie vorn frei")
            # Über der halben Turmhöhe liegt kein Gras.
            self.assertIsNone(maske.crop((0, 0, maske.width, maske.height // 2)).getbbox(), name)
            # Hinter dem Grundriss (Mitte) bleibt der Fuß sichtbar.
            self.assertLess(maske.getpixel((round(mx), round(unten - 2 * hb))), 60, name)

    def test_skript_rechnet_gleich(self):
        turmlicht = self.skript("turmlicht")
        neu = turmlicht.licht(self.quelle("tower_spore"))
        self.assertEqual(neu.tobytes(), self.atlas("tower_spore").tobytes())


class Diorama(unittest.TestCase):
    """A-4 (D-140, D-165, D-166): eine Kamera, eine Sonne, ein Maßstab im Vertrag; der Plan
    des Dioramas stellt nichts Hohes auf Weg oder Insel; das Bild zeigt die Inseln dort,
    wo die Simulation sie kennt."""

    MISSION = os.path.join(WURZEL, "Packages/OddlingsCore/Sources/OddlingsCore/Resources/Balance/mvp-mission-01.json")
    ORT = os.path.join(WURZEL, "tools/kampfplatz-3d/orte/mission-01.json")

    def vertrag(self):
        return json.load(open(os.path.join(WURZEL, "art/asset-vertrag.json")))

    def test_kamera_und_sonne_stehen_im_vertrag(self):
        v = self.vertrag()
        self.assertEqual(v["kamera"]["art"], "orthografisch")
        self.assertTrue(30 <= v["kamera"]["hoehe"] <= 60)
        self.assertTrue(0 <= v["kamera"]["figurenSpielraum"] <= 15)
        # Licht von links hinten: Schatten fallen nach rechts unten (art-direction, D-120).
        self.assertTrue(90 < v["sonne"]["azimut"] < 180)
        self.assertTrue(20 <= v["sonne"]["hoehe"] <= 70)

    def test_massstab_in_der_reihenfolge_des_reviews(self):
        m = self.vertrag()["massstab"]
        reihe = ["fortress", "enemy_moorKing", "tower", "enemy_brute", "enemy_raider", "enemy_runner"]
        werte = [m[n] for n in reihe]
        self.assertEqual(werte, sorted(werte, reverse=True), werte)
        self.assertEqual(len(set(werte)), len(werte))

    def plan(self, t):
        sys.path.insert(0, os.path.join(WURZEL, "tools/kampfplatz-3d"))
        import plan  # noqa: E402
        return plan, plan.plane(self.MISSION, self.ORT, t, 24)

    def test_nichts_hohes_auf_weg_oder_insel(self):
        with tempfile.TemporaryDirectory() as t:
            modul, p = self.plan(t)
            kos = math.cos(math.radians(p["kamera"]["hoehe"]))
            karte = json.load(open(self.MISSION))["map"]
            inseln = modul.inselzellen(karte)
            arten = {d["art"] for d in p["dinge"]}
            self.assertTrue({"baum", "busch", "fels", "kantenstein", "hoehle"} <= arten, arten)
            for d in p["dinge"]:
                if d["art"] in ("kantenstein", "hoehle", "halme"):
                    # Kante der Insel, Höhle am Eingang (Gegner kommen heraus), Grasbüschel
                    # am Wegrand (Grafik 11, D-194): flacher als ein Fuß, verdecken nichts.
                    self.assertLess(d.get("h", 0), 0.2, d) if d["art"] == "halme" else None
                    continue
                x0, y0, x1, y1 = modul.bildflaeche(d, kos)
                # Die Spitze ragt um h·cos nach oben; dort darf keine Inselzelle liegen …
                for cx, cy in inseln:
                    self.assertFalse(x0 < cx + 1 and x1 > cx and y0 < cy + 1 and y1 > cy, (d, cx, cy))
                # … und keine Zellmitte des Wegs.
                for (ax, ay), (bx, by) in zip(karte["path"], karte["path"][1:]):
                    for k in range(21):
                        wx, wy = ax + (bx - ax) * k / 20, ay + (by - ay) * k / 20
                        self.assertFalse(x0 < wx < x1 and y0 < wy < y1, (d, wx, wy))
            # Zwischen den Inseln steht Landschaft (G2: keine leere Wiese).
            im_feld = [d for d in p["dinge"] if d["art"] in ("busch", "fels", "stumpf", "farn")
                       and 0 <= d["x"] <= karte["width"] and 0 <= d["y"] <= karte["height"]]
            self.assertGreaterEqual(len(im_feld), 12)

    def test_bodenplan_deckt_zellen_genau(self):
        # Kabinettprojektion: Am Boden ist eine Zelle im Bild quadratisch und liegt wie in
        # der Simulation. Die Masken des Plans müssen das zeigen.
        with tempfile.TemporaryDirectory() as t:
            _, p = self.plan(t)
            mx, my = p["rand"]
            c = p["px"]
            self.assertEqual(p["bild"], [(p["breite"] + 2 * mx) * c, (p["hoehe"] + 2 * my) * c])
            weg = Image.open(os.path.join(t, "maske-weg.png"))
            insel = Image.open(os.path.join(t, "maske-inseln.png"))
            px = lambda b, x, y: b.getpixel((int((x + mx) * c), int((y + my) * c)))
            karte = json.load(open(self.MISSION))["map"]
            for x, y in karte["path"][1:-1]:
                self.assertEqual(px(weg, x, y), 255, (x, y))
            for z in karte["zones"]:
                for rx, ry, rb, rh in z["rects"]:
                    self.assertEqual(px(insel, rx + 0.5, ry + 0.5), 255, z["id"])
                    self.assertEqual(px(insel, rx - 0.3, ry + rh / 2), 0, z["id"])

    def test_bild_zeigt_die_inseln_als_grashuegel(self):
        # Grafik 11 (D-192): Inselmitten sind Gras, an der Vorderkante liegt die
        # Trockenmauer als dunkler, grauer Streifen. Vorher (A-4) waren es Erdflächen.
        bild = Image.open(os.path.join(WURZEL, "App/Assets.xcassets/Maps/map_mission01_ground.imageset/"
                                       "map_mission01_ground@3x.jpg")).convert("RGB")
        karte = json.load(open(self.MISSION))["map"]
        z = bild.width / (karte["width"] + 8)
        for zone in karte["zones"]:
            for rx, ry, rb, rh in zone["rects"]:
                cx, cy = rx + rb / 2 + 4, ry + rh / 2 + 2
                r, g, b = ImageStat.Stat(bild.crop((int((cx - 0.3) * z), int((cy - 0.3) * z),
                                                    int((cx + 0.3) * z), int((cy + 0.3) * z)))).mean
                self.assertLess(b, 0.5 * g, (zone["id"], "Mitte ist Gras"))
                kante = ImageStat.Stat(bild.crop((int((rx + 4.3) * z), int((ry + rh + 2 - 0.02) * z),
                                                  int((rx + rb + 3.7) * z), int((ry + rh + 2 + 0.12) * z)))).mean
                self.assertLess(sum(kante), 0.5 * (r + g + b), (zone["id"], "Mauer an der Vorderkante"))
                self.assertLess(max(kante) - min(kante), 30, (zone["id"], "Mauer ist grau"))


class KampfplatzInDerWelt(unittest.TestCase):
    """Grafik 11 (D-191 bis D-195): Torburg mit denselben Werten in Werkzeug und App,
    Weg bis ins Tor, Mauern frei von Weg und Inseln."""

    ATLAS = os.path.join(WURZEL, "App/Assets.xcassets/Battle.spriteatlas")
    MISSION = Diorama.MISSION
    ORT = Diorama.ORT

    def vertrag(self):
        return json.load(open(os.path.join(WURZEL, "art/asset-vertrag.json")))

    def bild(self, name):
        return Image.open(os.path.join(self.ATLAS, f"{name}.imageset", f"{name}@3x.png")).convert("RGBA")

    def test_festungswerte_gleich_in_app_und_vertrag(self):
        import re
        f = self.vertrag()["festung"]
        swift = open(os.path.join(WURZEL, "App/Battle/WorldGrounding.swift"), encoding="utf-8").read()
        for schluessel, name in (("tor", "gateInset"), ("torAbstand", "gateDistance"), ("gier", "yaw")):
            wert = re.search(rf"static let {name} = (-?[\d.]+)", swift)
            self.assertIsNotNone(wert, name)
            self.assertAlmostEqual(float(wert.group(1)), f[schluessel], msg=name)
        a = self.vertrag()["assets"]
        stil = open(os.path.join(WURZEL, "App/Battle/BattleStyle.swift"), encoding="utf-8").read()
        self.assertIn(f"fortressSpriteSide: CGFloat = {a['fortress']['seiteZellen']}", stil)
        self.assertIn(f"fortressAnchorY: CGFloat = {a['fortress']['anker']}", stil)

    def test_torburg_liegt_im_atlas(self):
        # Die Herkunft prüft check_assets für jedes Bild im Atlas.
        for name in ("fortress", "fortress_shadow"):
            self.assertTrue(os.path.isdir(os.path.join(self.ATLAS, f"{name}.imageset")), name)

    def plan(self, t):
        sys.path.insert(0, os.path.join(WURZEL, "tools/kampfplatz-3d"))
        import plan  # noqa: E402
        return plan, plan.plane(self.MISSION, self.ORT, t, 24)

    def test_weg_endet_im_tor(self):
        with tempfile.TemporaryDirectory() as t:
            modul, p = self.plan(t)
            karte = json.load(open(self.MISSION))["map"]
            lage = modul.festungslage(karte)
            self.assertAlmostEqual(math.dist(p["weglinie"][-1], lage["tor"]), 0, places=3)
            f = self.vertrag()["festung"]
            self.assertAlmostEqual(math.dist(lage["tor"], lage["fuss"]), f["torAbstand"], places=6)

    def test_mauern_beruehren_weder_weg_noch_insel(self):
        with tempfile.TemporaryDirectory() as t:
            modul, p = self.plan(t)
            karte = json.load(open(self.MISSION))["map"]
            inseln = modul.inselzellen(karte)
            for mauer in p["mauern"]:
                for (ax, ay), (bx, by) in zip(mauer, mauer[1:]):
                    for k in range(11):
                        x, y = ax + (bx - ax) * k / 10, ay + (by - ay) * k / 10
                        self.assertGreater(modul.wegabstand(p["weglinie"], x, y), 0.5, (x, y))
                        for cx, cy in inseln:
                            self.assertFalse(cx - 0.3 < x < cx + 1.3 and cy - 0.3 < y < cy + 1.3, (x, y, cx, cy))


if __name__ == "__main__":
    unittest.main()


class Konturpass(unittest.TestCase):
    """A-3: Die Außenlinie ist so breit wie verlangt, kreisförmig und nur außen."""

    def test_breite_und_nur_aussen(self):
        sys.path.insert(0, os.path.join(WURZEL, "tools/figuren-3d"))
        from konturpass import kontur, KONTURFARBE
        b = Image.new("RGBA", (40, 40), (0, 0, 0, 0))
        b.paste((200, 180, 40, 255), (15, 15, 25, 25))
        k = kontur(b, 3)
        self.assertEqual(k.getpixel((20, 20)), (200, 180, 40, 255))  # innen unverändert
        self.assertEqual(k.getpixel((13, 20))[:3], KONTURFARBE)       # zwei Pixel außen: Linie
        self.assertEqual(k.getpixel((13, 20))[3], 255)
        self.assertEqual(k.getpixel((10, 20))[3], 0)                  # fünf Pixel außen: frei
        self.assertLess(k.getpixel((12, 12))[3], 128)                 # Ecke rund, nicht quadratisch
        self.assertIs(kontur(b, 0), b)
