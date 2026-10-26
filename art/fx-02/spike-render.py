import bpy, sys, math, os
src, action, out, frames = sys.argv[-4], sys.argv[-3], sys.argv[-2], int(sys.argv[-1])
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
sc = bpy.context.scene
for o in list(bpy.data.objects):
    if o.name.startswith("Icosphere"): bpy.data.objects.remove(o)
arm = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
arm.animation_data.action = bpy.data.actions[action]
# 45 Grad: Figur läuft nach rechts und zeigt der Kamera ihr Gesicht
arm.rotation_mode = 'XYZ'; arm.rotation_euler[2] = math.radians(45)
cam_data = bpy.data.cameras.new("cam"); cam_data.type = 'ORTHO'; cam_data.ortho_scale = 1.1
cam = bpy.data.objects.new("cam", cam_data); sc.collection.objects.link(cam); sc.camera = cam
el = math.radians(35)  # 3/4 von oben
d = 6
cam.location = (0, -d*math.cos(el), 0.22 + d*math.sin(el))
cam.rotation_euler = (math.radians(90)-el, 0, 0)
for name, rot, e in [("key", (50, 0, 30), 3.0), ("fill", (60, 0, -120), 1.0)]:
    l = bpy.data.lights.new(name, 'SUN'); l.energy = e
    ob = bpy.data.objects.new(name, l); ob.rotation_euler = tuple(math.radians(v) for v in rot); sc.collection.objects.link(ob)
world = bpy.data.worlds.new("w"); sc.world = world; world.use_nodes = True
world.node_tree.nodes["Background"].inputs[1].default_value = 0.6
sc.render.engine = 'CYCLES'; sc.cycles.samples = 24; sc.cycles.device = 'CPU'
sc.render.film_transparent = True
sc.render.resolution_x = sc.render.resolution_y = 256
sc.view_settings.view_transform = 'Standard'
a = bpy.data.actions[action]; f0, f1 = a.frame_range
for i in range(frames):
    sc.frame_set(round(f0 + (f1 - f0) * i / frames))
    sc.render.filepath = os.path.join(out, f"{action}_{i:02d}.png")
    bpy.ops.render.render(write_still=True)
