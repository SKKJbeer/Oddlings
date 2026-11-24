#!/usr/bin/env python3
"""Bauten einzeln in der Vertragskamera, heute die Torburg (Grafik 11, D-191).

$HOME/bpy/bin/python -I bauten.py torburg <ausgabe.png> [samples=48] [px=512]

Der Turmsockel (D-190) ist mit D-196 entfallen; seine Perspektive passte nicht zu
den gemalten Türmen.

Gleiche Kamera und Sonne wie das Diorama (art/asset-vertrag.json): orthografisch,
`kamera.hoehe` Grad über dem Boden, ohne Gierwinkel, Sonne `sonne.azimut`/`sonne.hoehe`.
Das Bild ist ein Quadrat mit Seite `seiteZellen` aus dem Vertrag; der Fußpunkt (Ursprung
der Welt) liegt bei (0,5, `anker`) wie bei jedem Sprite. Hintergrund durchsichtig, der
eigene Schatten fällt auf einen Schattenfänger und bleibt im Alpha. Danach übermalt FLUX
das Bild auf hellgrauem Grund (Skill spielgrafik), freistellen, atlas.py.

Welt: x nach rechts, y in die Tiefe (Bildschirm oben), z nach oben, Einheit Zelle.
Die Dinge selbst sind nicht gestreckt (wie die Bäume im Diorama).
"""
import json, math, os, random, sys
import bpy, bmesh
from mathutils import Vector

WURZEL = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
art, ziel = sys.argv[1], sys.argv[2]
SAMPLES = int(sys.argv[3]) if len(sys.argv) > 3 else 48
PX = int(sys.argv[4]) if len(sys.argv) > 4 else 512
V = json.load(open(os.path.join(WURZEL, "art/asset-vertrag.json")))
EL = math.radians(V["kamera"]["hoehe"])
NAME = {"torburg": "fortress"}[art]
SEITE, ANKER = V["assets"][NAME]["seiteZellen"], V["assets"][NAME]["anker"]
rnd = random.Random(5)

bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene


def lin(rgb):
    return tuple(((c / 255 + 0.055) / 1.055) ** 2.4 if c / 255 > 0.04045 else c / 255 / 12.92 for c in rgb) + (1.0,)


def stein(name, rgb, fugen=None, skala=6.0, streuung=0.22):
    """Naturstein: Voronoi-Zellen mit eigener Helligkeit, dunkle Fugen dazwischen.
    Ohne Variation sähe es nach Baukasten aus (wie im Diorama)."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    n, l = m.node_tree.nodes, m.node_tree.links
    bsdf = n["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 0.9
    vor = n.new("ShaderNodeTexVoronoi"); vor.inputs["Scale"].default_value = skala
    ramp = n.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = tuple(c * (1 - streuung) for c in lin(rgb)[:3]) + (1,)
    ramp.color_ramp.elements[1].color = tuple(min(1, c * (1 + streuung)) for c in lin(rgb)[:3]) + (1,)
    l.new(vor.outputs["Color"], ramp.inputs["Fac"])
    if fugen:
        kante = n.new("ShaderNodeTexVoronoi"); kante.feature = "DISTANCE_TO_EDGE"
        kante.inputs["Scale"].default_value = skala
        stufe = n.new("ShaderNodeMath"); stufe.operation = "LESS_THAN"; stufe.inputs[1].default_value = 0.035
        l.new(kante.outputs["Distance"], stufe.inputs[0])
        mix = n.new("ShaderNodeMix"); mix.data_type = "RGBA"
        mix.inputs["B"].default_value = lin(fugen)
        l.new(stufe.outputs[0], mix.inputs["Factor"])
        l.new(ramp.outputs["Color"], mix.inputs["A"])
        l.new(mix.outputs["Result"], bsdf.inputs["Base Color"])
        # Fugen liegen tiefer: Bump statt Geometrie, bleibt billig.
        bump = n.new("ShaderNodeBump"); bump.inputs["Strength"].default_value = 0.6
        l.new(kante.outputs["Distance"], bump.inputs["Height"])
        l.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    else:
        l.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    return m


def farbe(name, rgb, rau=0.85):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = lin(rgb)
    b.inputs["Roughness"].default_value = rau
    return m


def klumpen(ort, groesse, material, zerknittert=0.15, saat=0):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=1, location=ort)
    ob = bpy.context.object
    ob.scale = groesse
    tex = bpy.data.textures.new(f"t{saat}", "CLOUDS"); tex.noise_scale = 0.5
    d = ob.modifiers.new("knitter", "DISPLACE"); d.texture = tex; d.strength = zerknittert
    ob.modifiers.new("glatt", "SUBSURF").levels = 1
    bpy.ops.object.shade_smooth()
    ob.data.materials.append(material)
    return ob


def zylinder(ort, r, h, material, ecken=24, fase=0.0):
    bpy.ops.mesh.primitive_cylinder_add(vertices=ecken, radius=r, depth=h, location=ort + Vector((0, 0, h / 2)))
    ob = bpy.context.object
    if fase:
        bev = ob.modifiers.new("fase", "BEVEL"); bev.width = fase; bev.segments = 3
    bpy.ops.object.shade_smooth()
    ob.data.materials.append(material)
    return ob


def quader(ort, groesse, material, fase=0.02):
    bpy.ops.mesh.primitive_cube_add(size=1, location=ort)
    ob = bpy.context.object
    ob.scale = groesse
    bpy.ops.object.transform_apply(scale=True)
    if fase:
        bev = ob.modifiers.new("fase", "BEVEL"); bev.width = fase; bev.segments = 2
    ob.data.materials.append(material)
    return ob


def kegel(ort, r, h, material):
    bpy.ops.mesh.primitive_cone_add(vertices=20, radius1=r, depth=h, location=ort + Vector((0, 0, h / 2)))
    ob = bpy.context.object
    bpy.ops.object.shade_smooth()
    ob.data.materials.append(material)
    return ob


GRAS = [farbe(f"gras{i}", c) for i, c in enumerate(((74, 124, 40), (88, 140, 48), (60, 116, 46)))]


def buschel(ort, s, saat):
    """Grasbüschel aus schmalen Halmen: bricht jede Kante, an der Boden und Ding sich treffen."""
    for k in range(7):
        a = rnd.uniform(0, 2 * math.pi)
        bpy.ops.mesh.primitive_cone_add(vertices=5, radius1=0.018 * s, depth=0.16 * s * rnd.uniform(0.7, 1.2),
                                        location=ort + Vector((math.cos(a) * 0.03 * s, math.sin(a) * 0.03 * s, 0.07 * s)))
        h = bpy.context.object
        h.rotation_euler = (rnd.uniform(-0.5, 0.5), rnd.uniform(-0.5, 0.5), 0)
        h.data.materials.append(GRAS[(saat + k) % 3])


def torburg():
    """Torburg (D-191): Torhaus mit zwei runden Türmen, Tor zum ankommenden Weg.
    Gedreht um `festung.gier` aus dem Vertrag, damit man Tor und Seite sieht. Der Fuß
    (Ursprung) ist die Mitte des Grundrisses; das Tor liegt `torAbstand` davor."""
    f = V["festung"]
    mauer = stein("mauer", (118, 116, 112), fugen=(48, 46, 44), skala=7.0)
    dach = stein("dach", (70, 92, 112), skala=14.0, streuung=0.12)
    holz = farbe("holz", (104, 66, 36))
    dunkel = farbe("dunkel", (20, 16, 14))
    rot = farbe("banner", (170, 36, 30))
    gold = farbe("gold", (214, 170, 70), rau=0.4)
    teile = []
    # Torhaus: Block zwischen den Türmen, Tor in der Vorderseite (−y = zum Betrachter vor der Drehung)
    breite, tiefe, hoehe = 1.45, 0.9, 1.15
    teile.append(quader(Vector((0, 0, hoehe / 2)), (breite, tiefe, hoehe), mauer))
    for i in range(5):  # Zinnen
        x = -breite / 2 + 0.14 + i * (breite - 0.28) / 4
        teile.append(quader(Vector((x, -tiefe / 2 + 0.08, hoehe + 0.08)), (0.14, 0.16, 0.16), mauer))
        teile.append(quader(Vector((x, tiefe / 2 - 0.08, hoehe + 0.08)), (0.14, 0.16, 0.16), mauer))
    # Torbogen: dunkle Öffnung mit Holztor darin, leicht zurückgesetzt
    teile.append(quader(Vector((0, -tiefe / 2 - 0.005, 0.38)), (0.56, 0.04, 0.76), dunkel, 0))
    bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=0.28, depth=0.04, location=(0, -tiefe / 2 - 0.005, 0.76),
                                        rotation=(math.pi / 2, 0, 0))
    bogen = bpy.context.object; bogen.data.materials.append(dunkel); teile.append(bogen)
    teile.append(quader(Vector((0, -tiefe / 2 + 0.02, 0.4)), (0.5, 0.04, 0.78), holz, 0.01))
    # Fackeln links und rechts vom Tor (Glut malt FLUX)
    for x in (-0.42, 0.42):
        teile.append(quader(Vector((x, -tiefe / 2 - 0.04, 0.82)), (0.05, 0.08, 0.14), holz, 0))
        teile.append(klumpen(Vector((x, -tiefe / 2 - 0.05, 0.93)), (0.045, 0.045, 0.06), gold, 0, 3))
    # Banner über dem Tor
    teile.append(quader(Vector((0, -tiefe / 2 - 0.02, 0.98)), (0.3, 0.02, 0.26), rot, 0))
    # Zwei runde Türme mit Kegeldach, höher als das Torhaus
    for x in (-breite / 2 - 0.1, breite / 2 + 0.1):
        teile.append(zylinder(Vector((x, -0.05, 0)), 0.38, 1.6, mauer, ecken=32, fase=0.02))
        for k in range(10):
            a = k / 10 * 2 * math.pi
            teile.append(quader(Vector((x + math.cos(a) * 0.34, -0.05 + math.sin(a) * 0.34, 1.67)), (0.1, 0.1, 0.13), mauer, 0.01))
        teile.append(kegel(Vector((x, -0.05, 1.6)), 0.46, 0.85, dach))
        # Schießscharten
        for z in (0.75, 1.2):
            teile.append(quader(Vector((x, -0.05 - 0.38, z)), (0.05, 0.03, 0.18), dunkel, 0))
        bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=0.015, depth=0.4, location=(x, -0.05, 2.55))
        st = bpy.context.object; st.data.materials.append(holz); teile.append(st)
        teile.append(quader(Vector((x + 0.12, -0.05, 2.65)), (0.22, 0.01, 0.12), rot, 0))
    # Sockel aus großen Steinen und Gras am Fuß: Die Burg steht im Boden, nicht darauf.
    sockelstein = stein("sockelstein", (112, 108, 102), fugen=(44, 42, 40), skala=5.0)
    teile.append(quader(Vector((0, -0.05, 0.05)), (breite + 0.95, tiefe + 0.1, 0.1), sockelstein, 0.03))
    for k in range(14):
        x = rnd.uniform(-1.1, 1.1)
        y = -tiefe / 2 - rnd.uniform(0.04, 0.12)
        buschel(Vector((x, y, 0)), rnd.uniform(1.0, 1.6), k)
    # Drehung des Ganzen um den Fuß
    leer = bpy.data.objects.new("burg", None)
    sc.collection.objects.link(leer)
    for t in teile:
        t.parent = leer
    leer.rotation_euler = (0, 0, math.radians(f["gier"]))


{"torburg": torburg}[art]()

# --- Schattenfänger, Licht, Kamera --------------------------------------------------------
bpy.ops.mesh.primitive_plane_add(size=40)
boden = bpy.context.object
boden.is_shadow_catcher = True

az, alt = math.radians(V["sonne"]["azimut"]), math.radians(V["sonne"]["hoehe"])
# Vertrag: azimut 90 = in die Tiefe (Bildschirm oben) = +y in dieser Welt.
zur_sonne = Vector((math.cos(az) * math.cos(alt), math.sin(az) * math.cos(alt), math.sin(alt)))
sonne = bpy.data.lights.new("sonne", "SUN")
sonne.energy = 3.5
sonne.angle = math.radians(4)
sonne.color = lin((255, 238, 210))[:3]
so = bpy.data.objects.new("sonne", sonne)
sc.collection.objects.link(so)
so.rotation_euler = zur_sonne.to_track_quat("Z", "Y").to_euler()
himmel = bpy.data.worlds.new("himmel")
himmel.use_nodes = True
himmel.node_tree.nodes["Background"].inputs["Color"].default_value = lin((150, 175, 205))
himmel.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.7
sc.world = himmel

kd = bpy.data.cameras.new("kamera")
kd.type = "ORTHO"
kd.ortho_scale = SEITE
kd.clip_end = 400
kam = bpy.data.objects.new("kamera", kd)
sc.collection.objects.link(kam)
sc.camera = kam
blick = Vector((0, math.cos(EL), -math.sin(EL)))
oben = Vector((0, math.sin(EL), math.cos(EL)))
# Fußpunkt (Ursprung) bei (0,5, ANKER) im Bild: um (ANKER - 0,5)·SEITE entlang „oben“ versetzen.
kam.location = -blick * 100 - oben * ((ANKER - 0.5) * SEITE)
kam.rotation_euler = (math.pi / 2 - EL, 0, 0)

sc.render.engine = "CYCLES"
sc.cycles.device = "CPU"
sc.cycles.samples = SAMPLES
sc.cycles.use_denoising = True
sc.render.film_transparent = True
sc.render.resolution_x = sc.render.resolution_y = PX
sc.view_settings.view_transform = "Standard"
sc.render.image_settings.file_format = "PNG"
sc.render.image_settings.color_mode = "RGBA"
sc.render.filepath = ziel
bpy.ops.render.render(write_still=True)
print("✓", ziel)
