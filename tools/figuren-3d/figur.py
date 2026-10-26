"""Macht aus einem unbewegten 3D-Modell Bildfolgen für den Sprite-Atlas (FX 02, D-051).

    python figur.py <modell.glb> <rig.json> <ausgabeordner> [pixel=256]

Läuft mit Blender als Python-Paket (`pip install bpy`, eigene Umgebung, nur
Werkzeug, nicht in der App). Ablauf: Modell laden und auf Höhe 1 bringen,
Skelett aus den Gelenkpunkten in rig.json setzen, Haut mit automatischen
Gewichten binden, Bewegungen als Schlüsselbilder setzen, jede Folge rendern.

Warum die Bewegung im Skript steht statt aus einer Bibliothek: TRELLIS liefert
ein Modell ohne Skelett, und unsere Figuren sind keine Menschen (Sack, Keule,
lange Ohren). Ein eigenes kleines Skelett mit Gelenkpunkten je Figur ist
nachvollziehbar und braucht kein Fremdkonto (Mixamo).
"""
import bpy, json, math, os, sys
from mathutils import Matrix, Vector

modell, rigdatei, aus = sys.argv[-4], sys.argv[-3], sys.argv[-2]
pixel = int(sys.argv[-1])
rig = json.load(open(rigdatei))

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=modell)
sc = bpy.context.scene

# Nur die Hülle behalten: ein mitgeliefertes Skelett oder Hilfskörper würden die
# eigene Bindung stören.
for o in list(bpy.data.objects):
    if o.type != 'MESH' or any(o.name.startswith(n) for n in rig.get("weglassen", [])):
        bpy.data.objects.remove(o)
netze = [o for o in bpy.data.objects if o.type == 'MESH']
for o in netze:
    o.parent = None
bpy.ops.object.select_all(action='DESELECT')
for o in netze:
    o.select_set(True)
bpy.context.view_layer.objects.active = netze[0]
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
if len(netze) > 1:
    bpy.ops.object.join()
koerper = bpy.context.view_layer.objects.active
koerper.rotation_euler[2] = math.radians(rig.get("drehungZ", 0))
bpy.ops.object.transform_apply(rotation=True)

# Höhe 1, Füße auf 0, Mitte über dem Ursprung: Gelenkpunkte in rig.json sind
# Anteile dieser Box, damit dieselbe Datei für jede Modellgröße gilt.
ecken = [koerper.matrix_world @ Vector(c) for c in koerper.bound_box]
lo = Vector((min(c.x for c in ecken), min(c.y for c in ecken), min(c.z for c in ecken)))
hi = Vector((max(c.x for c in ecken), max(c.y for c in ecken), max(c.z for c in ecken)))
s = 1 / (hi.z - lo.z)
koerper.location = (-(lo.x + hi.x) / 2 * s, -(lo.y + hi.y) / 2 * s, -lo.z * s)
koerper.scale = (s, s, s)
bpy.ops.object.transform_apply(location=True, scale=True)
breite, tiefe = (hi.x - lo.x) * s, (hi.y - lo.y) * s

# TRELLIS trennt das Netz an jeder Texturnaht in Hunderte Inseln; die
# automatischen Gewichte wirken je Insel, ohne Verschweißen reißt die Figur
# bei der Bewegung an den Nähten auf.
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.mesh.remove_doubles(threshold=rig.get("verschweissen", 0.002))
bpy.ops.object.mode_set(mode='OBJECT')

# TRELLIS liefert Metallic 1; damit spiegelt die Figur nur die dunkle Umgebung
# und das Licht von links oben kommt nicht an.
for m in koerper.data.materials:
    for n in (m.node_tree.nodes if m and m.node_tree else []):
        if n.type == 'BSDF_PRINCIPLED':
            n.inputs["Metallic"].default_value = 0.0

def punkt(p):
    # rig.json: x quer (-0,5..0,5 der Breite), y Tiefe, z Höhe (0..1)
    return Vector((p[0] * breite, p[1] * tiefe, p[2]))

arm_daten = bpy.data.armatures.new("skelett")
arm = bpy.data.objects.new("skelett", arm_daten)
sc.collection.objects.link(arm)
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode='EDIT')
for name, k in rig["knochen"].items():
    b = arm_daten.edit_bones.new(name)
    b.head, b.tail = punkt(k["von"]), punkt(k["bis"])
for name, k in rig["knochen"].items():
    if "eltern" in k:
        arm_daten.edit_bones[name].parent = arm_daten.edit_bones[k["eltern"]]
        arm_daten.edit_bones[name].use_connect = False
bpy.ops.object.mode_set(mode='OBJECT')

bpy.ops.object.select_all(action='DESELECT')
koerper.select_set(True)
arm.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.object.parent_set(type='ARMATURE_AUTO')

# Requisiten (Sack, Keule) sind eigene TRELLIS-Modelle: an der Figur
# mitgeneriert, verschmölzen sie mit Hand und Rücken und ließen sich nicht
# getrennt bewegen. Jedes hängt starr an einem Knochen.
def requisit(r):
    vorher = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=os.path.join(os.path.dirname(modell), r["datei"]))
    neu = [o for o in bpy.data.objects if o not in vorher]
    teile = [o for o in neu if o.type == 'MESH']
    for o in neu:
        if o.type != 'MESH':
            bpy.data.objects.remove(o)
    bpy.ops.object.select_all(action='DESELECT')
    for o in teile:
        o.parent = None
        o.select_set(True)
    bpy.context.view_layer.objects.active = teile[0]
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    if len(teile) > 1:
        bpy.ops.object.join()
    ob = bpy.context.view_layer.objects.active
    for m in ob.data.materials:
        for n in (m.node_tree.nodes if m and m.node_tree else []):
            if n.type == 'BSDF_PRINCIPLED':
                n.inputs["Metallic"].default_value = 0.0
    pkt = [v.co.copy() for v in ob.data.vertices]
    mitte = sum(pkt, Vector()) / len(pkt)
    if r.get("ausrichten"):
        # Längsachse (größte Streuung) nach oben, das dickere Ende (Kopf der
        # Keule, mehr Punkte) oben, Griff unten am Ursprung.
        kov = Matrix(((0, 0, 0), (0, 0, 0), (0, 0, 0)))
        for v in pkt:
            d = v - mitte
            for i in range(3):
                for j in range(3):
                    kov[i][j] += d[i] * d[j]
        achse = Vector((1, 1, 1)).normalized()
        for _ in range(50):
            achse = (kov @ achse).normalized()
        if sum(1 for v in pkt if (v - mitte).dot(achse) > 0) < len(pkt) / 2:
            achse = -achse
        dreh = achse.rotation_difference(Vector((0, 0, 1))).to_matrix().to_4x4()
    else:
        dreh = Matrix.Identity(4)
    ob.data.transform(dreh @ Matrix.Translation(-mitte))
    ecken = [Vector(c) for c in ob.bound_box]
    groesse = max(max(c[i] for c in ecken) - min(c[i] for c in ecken) for i in range(3))
    unten = min(c.z for c in ecken)
    ob.data.transform(Matrix.Translation((0, 0, -unten if r.get("ausrichten") else 0)))
    ob.scale = (r["groesse"] / groesse,) * 3
    ob.rotation_euler = tuple(math.radians(g) for g in r.get("drehung", (0, 0, 0)))
    ob.location = punkt(r["ort"])
    bpy.context.view_layer.update()
    welt = ob.matrix_world.copy()
    ob.parent = arm
    ob.parent_type = 'BONE'
    ob.parent_bone = r["knochen"]
    bpy.context.view_layer.update()
    ob.matrix_world = welt
    return ob

teile = [koerper] + [requisit(r) for r in rig.get("requisiten", [])]

# Comic-Look wie die gemalten Figuren (D-016): Ein Lichtmodell allein macht
# aus der TRELLIS-Textur eine dunkle, weiche Puppe. Darum (1) Farben vor dem
# Licht satter, (2) ein Teil der Farbe leuchtet selbst, damit Schatten
# flächig bleiben statt abzusaufen, (3) eine dunkle Hülle hinter dem Netz
# zeichnet Umriss und Innenkonturen (Ohren vor dem Kopf, Arm vor dem Bauch).
stil = {"saettigung": 1.0, "helligkeit": 1.0, "eigenlicht": 0.0, "kontur": 0.0, **rig.get("stil", {})}
umriss = bpy.data.materials.new("umriss")
umriss.use_nodes = True
un = umriss.node_tree.nodes
un.clear()
ausgang = un.new("ShaderNodeOutputMaterial")
mischung = un.new("ShaderNodeMixShader")
geo = un.new("ShaderNodeNewGeometry")
farbe = un.new("ShaderNodeEmission")
farbe.inputs["Color"].default_value = (0.016, 0.008, 0.006, 1)  # 34/22/18 linear
durch = un.new("ShaderNodeBsdfTransparent")
ul = umriss.node_tree.links
ul.new(geo.outputs["Backfacing"], mischung.inputs["Fac"])
ul.new(farbe.outputs[0], mischung.inputs[1])
ul.new(durch.outputs[0], mischung.inputs[2])
ul.new(mischung.outputs[0], ausgang.inputs["Surface"])
for teil in teile:
    for m in teil.data.materials:
        if not (m and m.node_tree):
            continue
        nodes, links = m.node_tree.nodes, m.node_tree.links
        bsdf = next((n for n in nodes if n.type == 'BSDF_PRINCIPLED'), None)
        if bsdf is None or not bsdf.inputs["Base Color"].is_linked:
            continue
        quelle = bsdf.inputs["Base Color"].links[0].from_socket
        hsv = nodes.new("ShaderNodeHueSaturation")
        hsv.inputs["Saturation"].default_value = stil["saettigung"]
        hsv.inputs["Value"].default_value = stil["helligkeit"]
        links.new(quelle, hsv.inputs["Color"])
        links.new(hsv.outputs["Color"], bsdf.inputs["Base Color"])
        if stil["eigenlicht"] > 0:
            bsdf.inputs["Emission Color"].default_value = (0, 0, 0, 1)
            links.new(hsv.outputs["Color"], bsdf.inputs["Emission Color"])
            bsdf.inputs["Emission Strength"].default_value = stil["eigenlicht"]
    if stil["kontur"] > 0:
        teil.data.materials.append(umriss)
        hulle = teil.modifiers.new("kontur", 'SOLIDIFY')
        hulle.thickness = stil["kontur"] / max(teil.scale)
        hulle.offset = 1
        hulle.use_flip_normals = True
        hulle.use_rim = False
        hulle.material_offset = len(teil.data.materials) - 1

# Bewegungen: je Knochen eine Drehung (Grad um x = vor/zurück, um y = seitlich)
# als Sinus über die Folge, dazu Hub des Beckens. Werte stehen in rig.json.
def setze(folge, i, n):
    t = i / n
    for name, b in arm.pose.bones.items():
        b.rotation_mode = 'XYZ'
        b.rotation_euler = (0, 0, 0)
        b.location = (0, 0, 0)
    for name, (achse, grad, phase) in rig["folgen"][folge].get("schwingen", {}).items():
        w = math.radians(grad) * math.sin(2 * math.pi * (t + phase))
        arm.pose.bones[name].rotation_euler["xyz".index(achse)] = w
    for name, (achse, grad) in rig["folgen"][folge].get("verlauf", {}).items():
        # Einmalige Bewegung (Treffer, Sturz): weich von 0 auf grad
        k = 1 - (1 - t) ** 2 if n > 1 else 1
        arm.pose.bones[name].rotation_euler["xyz".index(achse)] = math.radians(grad) * k
    # Grundhaltung: TRELLIS-Vorlagen stehen mit abgespreizten Armen, damit
    # Hände und Körper getrennt bleiben. Die Drehung steht in rig.json um eine
    # Achse des Modells (nicht des Knochens) und wird unter die Bewegung gelegt.
    for name, (achse, grad) in rig.get("ruhe", {}).items():
        pb = arm.pose.bones[name]
        ruhe = pb.bone.matrix_local.to_3x3()
        welt = Matrix.Rotation(math.radians(grad), 3, achse.upper())
        lokal = ruhe.inverted() @ welt @ ruhe
        pb.rotation_euler = (lokal @ pb.rotation_euler.to_matrix()).to_euler('XYZ')
    hub = rig["folgen"][folge].get("hub", 0)
    if hub and "becken" in arm.pose.bones:
        arm.pose.bones["becken"].location = (0, abs(math.sin(2 * math.pi * t)) * hub, 0)

cam_daten = bpy.data.cameras.new("kamera")
cam_daten.type = 'ORTHO'
cam_daten.ortho_scale = rig.get("bildHoehe", 1.5)
cam = bpy.data.objects.new("kamera", cam_daten)
sc.collection.objects.link(cam)
sc.camera = cam
# 35° von oben wie die gemalten Figuren, Figur 45° zur Kamera gedreht
el = math.radians(rig.get("kameraHoehe", 35))
mitte = 0.5
cam.location = (0, -6 * math.cos(el), mitte + 6 * math.sin(el))
cam.rotation_euler = (math.radians(90) - el, 0, 0)
arm.rotation_euler[2] = koerper.rotation_euler[2] = 0
dreh = bpy.data.objects.new("drehung", None)
sc.collection.objects.link(dreh)
arm.parent = dreh
dreh.rotation_euler[2] = math.radians(rig.get("blick", 45))

# Licht von links oben wie in den Gemälden
# Stärken je Figur in rig.json, weil die Texturen von TRELLIS je Bild
# unterschiedlich hell ausfallen.
licht = {"haupt": 3.2, "fuell": 0.9, "welt": 0.5, **rig.get("licht", {})}
# Randlicht von hinten oben setzt die Figur wie im Gemälde vom Boden ab.
licht.setdefault("rand", 0.0)
for name, rot in [("haupt", (45, 0, -40)), ("fuell", (65, 0, 140)), ("rand", (-55, 0, 25))]:
    e = licht[name]
    l = bpy.data.lights.new(name, 'SUN')
    l.energy = e
    ob = bpy.data.objects.new(name, l)
    ob.rotation_euler = tuple(math.radians(v) for v in rot)
    sc.collection.objects.link(ob)
welt = bpy.data.worlds.new("welt")
sc.world = welt
welt.use_nodes = True
welt.node_tree.nodes["Background"].inputs[1].default_value = licht["welt"]
sc.render.engine = 'CYCLES'
sc.cycles.device = 'CPU'
sc.cycles.samples = 32
sc.render.film_transparent = True
sc.render.resolution_x = sc.render.resolution_y = pixel
sc.view_settings.view_transform = 'Standard'

os.makedirs(aus, exist_ok=True)
for folge, f in rig["folgen"].items():
    n = f["bilder"]
    for i in range(n):
        setze(folge, i, n)
        bpy.context.view_layer.update()
        sc.render.filepath = os.path.join(aus, f"{folge}_{i:02d}.png")
        bpy.ops.render.render(write_still=True)
print("fertig", aus)
