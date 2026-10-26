"""Setzt das Titelbild aus gemaltem Hintergrund und den Spielfiguren zusammen.
komponieren.py <hintergrund> <figurenordner> <aus> <breite> [vorschau_mit_menue]"""
import sys
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance, ImageChops
hg, fig, aus, W = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4])
H = round(W / (2796 / 1290))
bg = Image.open(hg).convert("RGB").transpose(Image.FLIP_LEFT_RIGHT)
s = W / bg.width
bg = bg.resize((W, round(bg.height * s)), Image.LANCZOS)
bg = bg.crop((0, bg.height - H - round(bg.height * 0.02), W, bg.height - round(bg.height * 0.02)))
bild = bg.convert("RGBA")
# name, mitte x, fuss y, hoehe (Anteile), spiegeln, dunst
FIG = [("fortress", .20, .47, .46, False, .18),
       ("tower_spore", .425, .70, .25, False, .08),
       ("tower_lightning", .30, .74, .33, False, .05),
       ("enemy_runner", .175, .78, .16, False, .04),
       ("enemy_raider", .265, .92, .24, True, 0),
       ("enemy_brute", .37, 1.0, .30, True, 0),
       ("tower_watch", .07, 1.02, .44, False, 0)]
for n, x, y, h, sp, dunst in FIG:
    f = Image.open(f"{fig}/{n}-frei.png").convert("RGBA")
    f = f.crop(f.getbbox())
    if sp: f = f.transpose(Image.FLIP_LEFT_RIGHT)
    fh = round(h * H); f = f.resize((round(f.width * fh / f.height), fh), Image.LANCZOS)
    # Licht der Szene: warm von rechts oben (Sonne im gespiegelten Bild), Ferne im Dunst.
    rgb = f.convert("RGB")
    warm = Image.new("RGB", f.size, (255, 226, 170))
    rgb = ImageChops.multiply(rgb, warm)
    rgb = Image.blend(rgb, ImageEnhance.Brightness(rgb).enhance(1.08), .5)
    if dunst: rgb = Image.blend(rgb, Image.new("RGB", f.size, (236, 214, 160)), dunst)
    f = Image.merge("RGBA", (*rgb.split(), f.getchannel("A")))
    px, py = round(x * W - f.width / 2), round(y * H - f.height)
    # Kontaktschatten unter dem Fuss.
    sch = Image.new("L", bild.size, 0)
    sw, shh = f.width * .9, f.height * .07
    ImageDraw.Draw(sch).ellipse((x * W - sw / 2, y * H - shh * .6, x * W + sw / 2, y * H + shh * .4), fill=150)
    sch = sch.filter(ImageFilter.GaussianBlur(f.height * .03))
    bild = Image.composite(Image.new("RGBA", bild.size, (40, 30, 20, 255)), bild, sch)
    bild.alpha_composite(f, (px, py)) if px >= 0 and py >= 0 else bild.paste(f, (px, py), f)
# Gesamtlicht: leichte Vignette, damit der Blick links bleibt.
vig = Image.new("L", bild.size, 0)
ImageDraw.Draw(vig).ellipse((-W * .3, -H * .4, W * .9, H * 1.5), fill=255)
vig = vig.filter(ImageFilter.GaussianBlur(W * .08))
bild = Image.composite(bild, Image.blend(bild, Image.new("RGBA", bild.size, (30, 20, 12, 255)), .35), vig)
bild = bild.convert("RGB")
bild.save(aus, quality=92) if aus.endswith(".jpg") else bild.save(aus)
if len(sys.argv) > 5:
    v = bild.convert("RGBA")
    g = Image.new("L", (W, 1)); 
    for i in range(W):
        t = i / W; a = 0 if t < .35 else min(1, (t - .35) / .27) * .92
        g.putpixel((i, 0), round(a * 255))
    v = Image.composite(Image.new("RGBA", v.size, (0x2E, 0x1F, 0x14, 255)), v, g.resize((W, H)))
    d = ImageDraw.Draw(v); bx = W - 28 * W / 844 - min(340, W * .4); bw = min(340 * W / 844, W * .4)
    for yy, hh, c in ((.38, 64, (230, 170, 40)), (.56, 48, (0x4A, 0x31, 0x22)), (.70, 44, (0x4A, 0x31, 0x22))):
        k = W / 844
        d.rounded_rectangle((W - 28 * k - bw, yy * H, W - 28 * k, yy * H + hh * k), 14 * k, fill=c, outline=(0x22, 0x16, 0x0F), width=round(3 * k))
    v.convert("RGB").save(sys.argv[5])
