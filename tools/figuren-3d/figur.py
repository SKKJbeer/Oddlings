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
from mathutils import Vector

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
el = math.radians(35)
mitte = 0.5
cam.location = (0, -6 * math.cos(el), mitte + 6 * math.sin(el))
cam.rotation_euler = (math.radians(90) - el, 0, 0)
arm.rotation_euler[2] = koerper.rotation_euler[2] = 0
dreh = bpy.data.objects.new("drehung", None)
sc.collection.objects.link(dreh)
arm.parent = dreh
dreh.rotation_euler[2] = math.radians(rig.get("blick", 45))

# Licht von links oben wie in den Gemälden
for name, rot, e in [("haupt", (45, 0, -40), 3.2), ("fuell", (65, 0, 140), 0.9)]:
    l = bpy.data.lights.new(name, 'SUN')
    l.energy = e
    ob = bpy.data.objects.new(name, l)
    ob.rotation_euler = tuple(math.radians(v) for v in rot)
    sc.collection.objects.link(ob)
welt = bpy.data.worlds.new("welt")
sc.world = welt
welt.use_nodes = True
welt.node_tree.nodes["Background"].inputs[1].default_value = 0.5
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
