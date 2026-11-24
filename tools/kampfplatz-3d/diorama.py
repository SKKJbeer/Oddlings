#!/usr/bin/env python3
"""Rendert einen Kampfplatz als 3D-Diorama aus dem Plan von plan.py (A-4, D-140).

$HOME/bpy/bin/python -I diorama.py <planordner> <ausgabe.png> [samples=64]

Kamera und Sonne kommen aus dem Plan (also aus art/asset-vertrag.json): orthografisch,
`kamera.hoehe` Grad über dem Boden, ohne Gierwinkel. Die Welt ist in der Tiefe um
K = 1/sin(hoehe) gestreckt, die Dinge selbst nicht: So liegt jede Zelle am Boden im Bild
genau dort und genau so groß wie in der Simulation, und was steht, zeigt seine Seite im
selben Winkel wie die Türme.

Welt: x = Zelle x, y = -Zelle y · K (vorn = Bildschirm unten), z nach oben, Einheit Zelle.
"""
import json, math, os, random, sys
import bpy, bmesh
from mathutils import Vector

ordner, ziel = sys.argv[1], sys.argv[2]
SAMPLES = int(sys.argv[3]) if len(sys.argv) > 3 else 64
plan = json.load(open(os.path.join(ordner, "plan.json")))
EL = math.radians(plan["kamera"]["hoehe"])
K = 1 / math.sin(EL)
W, H = plan["breite"], plan["hoehe"]
MX, MY = plan["rand"]
BB, HH = plan["bild"]
F = plan["farben"]
rnd = random.Random(11)


def welt(x, y, z=0.0):
    return Vector((x, -y * K, z))


def lin(rgb):
    """sRGB 0..255 → linear 0..1, wie Blender Farben im Shader erwartet."""
    return tuple(((c / 255 + 0.055) / 1.055) ** 2.4 if c / 255 > 0.04045 else c / 255 / 12.92 for c in rgb) + (1.0,)


bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene

# --- Materialien ------------------------------------------------------------------------


def bildmaterial(name, bild, dy=0.0, dunkel=1.0):
    """Bodenbild in Bildschirmlage: u, v aus der Weltlage zurückgerechnet. `dy` ist die
    Verschiebung einer erhöhten Fläche in der Tiefe (siehe Inseln), damit ihre Oberseite
    dasselbe Stück Bild trägt wie die Zellen darunter."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    n, l = m.node_tree.nodes, m.node_tree.links
    bsdf = n["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 0.95
    geo = n.new("ShaderNodeNewGeometry")
    sep = n.new("ShaderNodeSeparateXYZ")
    l.new(geo.outputs["Position"], sep.inputs[0])
    u = n.new("ShaderNodeMath"); u.operation = "MULTIPLY_ADD"
    u.inputs[1].default_value = 1 / (W + 2 * MX); u.inputs[2].default_value = MX / (W + 2 * MX)
    l.new(sep.outputs["X"], u.inputs[0])
    # Zelle y = -(Y - dy)/K; v = 1 - (y + MY)/(H + 2MY)
    v = n.new("ShaderNodeMath"); v.operation = "MULTIPLY_ADD"
    v.inputs[1].default_value = 1 / (K * (H + 2 * MY))
    v.inputs[2].default_value = 1 - MY / (H + 2 * MY) - dy / (K * (H + 2 * MY))
    l.new(sep.outputs["Y"], v.inputs[0])
    uv = n.new("ShaderNodeCombineXYZ")
    l.new(u.outputs[0], uv.inputs[0]); l.new(v.outputs[0], uv.inputs[1])
    tex = n.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(os.path.join(ordner, bild))
    tex.extension = "EXTEND"
    l.new(uv.outputs[0], tex.inputs["Vector"])
    if dunkel != 1.0:
        mix = n.new("ShaderNodeMix"); mix.data_type = "RGBA"; mix.blend_type = "MULTIPLY"
        mix.inputs["Factor"].default_value = 1.0
        mix.inputs["B"].default_value = (dunkel, dunkel * 0.95, dunkel * 0.9, 1)
        l.new(tex.outputs["Color"], mix.inputs["A"])
        l.new(mix.outputs["Result"], bsdf.inputs["Base Color"])
    else:
        l.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    return m


def farbmaterial(name, rgb, rau=0.85, streuung=0.18):
    """Einfarbig mit großflächigem Rauschen: Ohne Variation sähe es nach Baukasten aus."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    n, l = m.node_tree.nodes, m.node_tree.links
    bsdf = n["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = rau
    noise = n.new("ShaderNodeTexNoise"); noise.inputs["Scale"].default_value = 3.0
    ramp = n.new("ShaderNodeValToRGB")
    a = tuple(max(0, c * (1 - streuung)) for c in lin(rgb)[:3]) + (1,)
    b = tuple(min(1, c * (1 + streuung)) for c in lin(rgb)[:3]) + (1,)
    ramp.color_ramp.elements[0].color = a
    ramp.color_ramp.elements[1].color = b
    l.new(noise.outputs["Fac"], ramp.inputs["Fac"])
    l.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    return m


mat_cache = {}


def mat(art, i):
    key = (art, i)
    if key not in mat_cache:
        liste = plan["waldfarben"] if art == "krone" else F[art]
        rgb = liste[i % len(liste)] if isinstance(liste[0], list) else liste
        mat_cache[key] = farbmaterial(f"{art}{i}", rgb)
    return mat_cache[key]


# --- Boden ---------------------------------------------------------------------------------
bpy.ops.mesh.primitive_plane_add(size=1)
boden = bpy.context.object
boden.scale = (W + 2 * MX + 2, (H + 2 * MY + 2) * K, 1)
boden.location = welt(W / 2, H / 2)
boden.data.materials.append(bildmaterial("boden", "boden.png"))

# --- Inseln: flache Plateaus aus festgetretener Erde ------------------------------------
# Eine erhöhte Fläche erschiene um h·cos(EL) zu hoch. Darum rückt jede Insel um
# h·cos/sin nach vorn: Die Oberseite deckt im Bild genau ihre Zellen, die Stirnseite
# hängt darunter wie bei einem Sockel.
hi = plan["inselhoehe"]
dy = -hi * math.cos(EL) / math.sin(EL)
oben = bildmaterial("insel", "insel.png", dy=dy)
# Stirnseite aus Erde (Grafik 11, D-192): Der Hügel zeigt, dass er Höhe hat.
seite = farbmaterial("inselrand", F.get("inselrand", (96, 74, 52)), streuung=0.25)
ECKE = plan.get("inselecke", 0.18)


def rundrechteck(x, y, b, h, r, n=8):
    r = min(r, b / 2, h / 2)
    pkt = []
    for cx, cy, a0 in ((x + b - r, y + r, -90), (x + b - r, y + h - r, 0), (x + r, y + h - r, 90), (x + r, y + r, 180)):
        for k in range(n + 1):
            a = math.radians(a0 + k * 90 / n)
            pkt.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pkt


for z in plan["inseln"]:
    for rx, ry, rb, rh in z["rects"]:
        # Gerundeter Grundriss, um die Höhe nach unten gezogen; Oberseite deckt die Zellen.
        bm = bmesh.new()
        unten = [bm.verts.new(welt(px, py, -hi) + Vector((0, dy, 0)))
                 for px, py in rundrechteck(rx + 0.03, ry + 0.03, rb - 0.06, rh - 0.06, ECKE)]
        flaeche = bm.faces.new(unten)
        ex = bmesh.ops.extrude_face_region(bm, geom=[flaeche])
        hoch = [e for e in ex["geom"] if isinstance(e, bmesh.types.BMVert)]
        bmesh.ops.translate(bm, verts=hoch, vec=Vector((0, 0, 2 * hi)))
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        me = bpy.data.meshes.new("insel")
        bm.to_mesh(me); bm.free()
        ob = bpy.data.objects.new("insel", me)
        sc.collection.objects.link(ob)
        bev = ob.modifiers.new("kante", "BEVEL"); bev.width = 0.05; bev.segments = 3
        ob.data.materials.append(oben); ob.data.materials.append(seite)
        for p in ob.data.polygons:
            p.material_index = 0 if p.normal.z > 0.9 else 1

# --- Dinge -----------------------------------------------------------------------------------


def klumpen(ort, groesse, material, unterteilung=2, zerknittert=0.18, saat=0):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=unterteilung, radius=1, location=ort)
    ob = bpy.context.object
    ob.scale = groesse
    tex = bpy.data.textures.new(f"t{saat}", "CLOUDS"); tex.noise_scale = 0.6
    d = ob.modifiers.new("knitter", "DISPLACE"); d.texture = tex; d.strength = zerknittert
    d.texture_coords = "OBJECT"
    ob.modifiers.new("glatt", "SUBSURF").levels = 1
    bpy.ops.object.shade_smooth()
    ob.data.materials.append(material)
    return ob


def zylinder(ort, r, h, material):
    bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=r, depth=h, location=ort + Vector((0, 0, h / 2)))
    ob = bpy.context.object
    bpy.ops.object.shade_smooth()
    ob.data.materials.append(material)
    return ob


stamm = farbmaterial("stamm", F["stamm"])
for i, d in enumerate(plan["dinge"]):
    # Kantensteine sitzen auf der Inselkante und rücken mit ihr nach vorn.
    p = welt(d["x"], d["y"]) + (Vector((0, dy, hi * 0.5 + d.get("lage", 0) * 0.08)) if d.get("insel") else Vector())
    art, r, h = d["art"], d["r"], d["h"]
    if art == "baum":
        zylinder(p, h * 0.07, h * 0.45, stamm)
        krone = mat("krone", d.get("farbe", 0))
        for k in range(4):
            a = rnd.uniform(0, 2 * math.pi)
            off = Vector((math.cos(a) * r * 0.35, math.sin(a) * r * 0.35, h * (0.55 + 0.12 * k)))
            s = r * (0.85 - 0.12 * k) * rnd.uniform(0.9, 1.1)
            klumpen(p + off, (s, s, s * 0.85), krone, saat=i * 7 + k)
    elif art == "busch":
        for k in range(3):
            off = Vector((rnd.uniform(-r, r) * 0.5, rnd.uniform(-r, r) * 0.4, h * 0.45))
            s = r * rnd.uniform(0.55, 0.8)
            klumpen(p + off, (s, s, h * 0.55), mat("busch", d["farbe"] + k), saat=i * 7 + k)
    elif art == "fels":
        klumpen(p + Vector((0, 0, h * 0.3)), (r, r * 0.8, h * 0.75), mat("fels", d["farbe"]), 1, 0.25, i)
    elif art == "kantenstein":
        klumpen(p + Vector((0, 0, h * 0.2)), (r, r * 0.85, h * 0.7), mat("kantenstein", d["farbe"]), 2, 0.06, i)
    elif art == "stumpf":
        zylinder(p, r, h, mat("stumpf", d["farbe"]))
    elif art == "farn":
        for k in range(5):
            a = k / 5 * 2 * math.pi + rnd.uniform(-0.3, 0.3)
            off = Vector((math.cos(a) * r * 0.45, math.sin(a) * r * 0.45, h * 0.35))
            blatt = klumpen(p + off, (r * 0.45, r * 0.16, h * 0.35), mat("farn", d["farbe"]), 1, 0.05, i * 7 + k)
            blatt.rotation_euler = (0, 0.35, a)
    elif art == "blumen":
        for k in range(6):
            off = Vector((rnd.uniform(-r, r), rnd.uniform(-r, r) * 0.8, h * 0.5))
            klumpen(p + off, (0.035, 0.035, 0.03), mat("blumen", d["farbe"] + k), 1, 0.0, i * 7 + k)
    elif art == "halme":
        # Grasbüschel am Wegrand (Grafik 11, W8): bricht die harte Kante zwischen Weg und Wiese.
        for k in range(6):
            a = rnd.uniform(0, 2 * math.pi)
            bpy.ops.mesh.primitive_cone_add(vertices=5, radius1=0.02, depth=h * rnd.uniform(0.7, 1.2),
                                            location=p + Vector((math.cos(a) * 0.04, math.sin(a) * 0.04, h * 0.45)))
            halm = bpy.context.object
            halm.rotation_euler = (rnd.uniform(-0.5, 0.5), rnd.uniform(-0.5, 0.5), 0)
            halm.data.materials.append(mat("farn", d["farbe"] + k))
    elif art == "hoehle":
        # Felsbuckel mit dunklem Maul nach rechts: Die Gegner kommen heraus.
        fels = farbmaterial("hoehle", F["hoehle"], streuung=0.25)
        for k, (ox, oz, s) in enumerate(((-0.35, 0.45, 0.85), (0.1, 0.65, 0.7), (-0.5, 0.25, 0.75), (0.2, 0.2, 0.55))):
            klumpen(p + Vector((ox, 0.35, oz)), (s, s * 0.9, s * 0.8), fels, 2, 0.3, 900 + k)
        maul = farbmaterial("maul", (18, 14, 12), streuung=0.0)
        m = klumpen(p + Vector((0.45, -0.15, 0.3)), (0.12, 0.42, 0.36), maul, 2, 0.04, 950)
        m.rotation_euler = (0, 0, 0.25)

# --- Mauerzüge der Torburg (Grafik 11, D-191) -------------------------------------------
# Von den Türmen der Torburg in den Wald: Die Burg riegelt das Tal ab. Die Torburg selbst
# ist ein eigenes Bild obenauf (bauten.py), damit Durchbrüche an ihr spielen können.
mauerstein = farbmaterial("mauer", F.get("mauer", (118, 116, 112)), streuung=0.22)
MAUER_H, MAUER_D = 0.6, 0.42
dach = farbmaterial("mauerdach", F.get("dach", (70, 92, 112)), streuung=0.12)
for linie in plan.get("mauern", []):
    # Turm am Ende jedes Mauerstücks: das Stück endet im Wald, nicht im Nichts.
    ende = welt(*linie[-1])
    zylinder(ende, 0.36, 1.05, mauerstein)
    bpy.ops.mesh.primitive_cone_add(vertices=20, radius1=0.44, depth=0.6, location=ende + Vector((0, 0, 1.35)))
    spitze = bpy.context.object
    bpy.ops.object.shade_smooth()
    spitze.data.materials.append(dach)
    for (ax, ay), (bx, by) in zip(linie, linie[1:]):
        a, b = welt(ax, ay), welt(bx, by)
        lang = (b - a).length
        if lang < 1e-4:
            continue
        mitte = (a + b) / 2
        winkel = math.atan2(b.y - a.y, b.x - a.x)
        bpy.ops.mesh.primitive_cube_add(size=1, location=mitte + Vector((0, 0, MAUER_H / 2)))
        ob = bpy.context.object
        ob.scale = (lang + MAUER_D * 0.5, MAUER_D, MAUER_H)
        ob.rotation_euler = (0, 0, winkel)
        bpy.ops.object.transform_apply(scale=True)
        ob.modifiers.new("fase", "BEVEL").width = 0.02
        ob.data.materials.append(mauerstein)
        # Zinnen nur an der Außenkante (zum Wald): Über die ganze Breite lasen sie sich
        # von oben wie Leitersprossen.
        quer = Vector((-(b - a).y, (b - a).x, 0)).normalized()
        if quer.x < 0:
            quer = -quer
        n = max(1, int(lang / 0.28))
        for k in range(n):
            t = (k + 0.5) / n
            q = a + (b - a) * t + quer * (MAUER_D * 0.36)
            bpy.ops.mesh.primitive_cube_add(size=1, location=q + Vector((0, 0, MAUER_H + 0.06)))
            z = bpy.context.object
            z.scale = (0.15, 0.1, 0.14)
            z.rotation_euler = (0, 0, winkel)
            z.data.materials.append(mauerstein)

# --- Licht und Kamera --------------------------------------------------------------------
az, alt = math.radians(plan["sonne"]["azimut"]), math.radians(plan["sonne"]["hoehe"])
zur_sonne = Vector((math.cos(az) * math.cos(alt), math.sin(az) * math.cos(alt), math.sin(alt)))
sonne = bpy.data.lights.new("sonne", "SUN")
sonne.energy = 3.5
sonne.angle = math.radians(4)
sonne.color = lin(plan["licht"])[:3]
so = bpy.data.objects.new("sonne", sonne)
sc.collection.objects.link(so)
so.rotation_euler = zur_sonne.to_track_quat("Z", "Y").to_euler()

welt_bg = bpy.data.worlds.new("himmel")
welt_bg.use_nodes = True
welt_bg.node_tree.nodes["Background"].inputs["Color"].default_value = lin(plan["himmel"])
welt_bg.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.7
sc.world = welt_bg

kd = bpy.data.cameras.new("kamera")
kd.type = "ORTHO"
kd.ortho_scale = W + 2 * MX
kd.clip_end = 400
kam = bpy.data.objects.new("kamera", kd)
sc.collection.objects.link(kam)
sc.camera = kam
blick = Vector((0, math.cos(EL), -math.sin(EL)))
kam.location = welt(W / 2, H / 2) - blick * 100
kam.rotation_euler = (math.pi / 2 - EL, 0, 0)

sc.render.engine = "CYCLES"
sc.cycles.device = "CPU"
sc.cycles.samples = SAMPLES
sc.cycles.use_denoising = True
sc.render.resolution_x, sc.render.resolution_y = BB, HH
sc.render.resolution_percentage = 100
sc.view_settings.view_transform = "Standard"
sc.render.image_settings.file_format = "PNG"
sc.render.filepath = ziel
bpy.ops.render.render(write_still=True)
print("✓", ziel)
