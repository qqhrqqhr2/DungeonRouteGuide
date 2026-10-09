"""Sketch maps for the new Forever dungeons (no game map art exists for them).

Drawn in the style of the game's dungeon maps: parchment, dark ink rims,
soft inner shading, paper grain. Rendered at 2048 px and saved as 1024 px
TGA files in ../Maps (the addon positions markers on a 512 grid, so the
size of the image does not matter for placement).

    python sketches.py [output folder] [preview folder]
"""
import math, os, random, sys
from PIL import Image, ImageDraw, ImageFilter, ImageChops

N = 2048
OUT = 1024

INK = (78, 52, 28)
PAL = {
    "floor":  (228, 210, 166),
    "floor2": (212, 190, 142),
    "road":   (218, 198, 152),
    "grass":  (180, 190, 120),
    "fel":    (150, 178, 92),
    "arcane": (190, 170, 214),
    "snow":   (232, 234, 228),
    "water":  (104, 140, 150),
    "rubble": (200, 178, 132),
}


def noise(scale, amount, seed):
    random.seed(seed)
    small = Image.effect_noise((max(2, N // scale), max(2, N // scale)), amount).convert("L")
    return small.resize((N, N), Image.BICUBIC)


def parchment(seed):
    base = Image.new("RGB", (N, N), (196, 168, 120))
    blotch = noise(64, 40, seed).point(lambda v: max(0, min(255, (v - 100) * 3)))
    base = Image.composite(Image.new("RGB", (N, N), (176, 146, 100)), base, blotch)
    grain = noise(2, 30, seed + 1).point(lambda v: max(0, min(255, (v - 128) * 2 + 128)))
    base = ImageChops.multiply(base, Image.merge("RGB", [grain.point(lambda v: 200 + v // 5)] * 3))
    # fibres
    d = ImageDraw.Draw(base)
    random.seed(seed + 2)
    for _ in range(900):
        x, y = random.uniform(0, N), random.uniform(0, N)
        a = random.uniform(0, math.pi)
        l = random.uniform(8, 40)
        d.line([(x, y), (x + l * math.cos(a), y + l * math.sin(a))], fill=(170, 140, 96), width=1)
    # dark worn edges
    vig = Image.new("L", (N, N), 0)
    dv = ImageDraw.Draw(vig)
    dv.rectangle([60, 60, N - 60, N - 60], fill=255)
    vig = vig.filter(ImageFilter.GaussianBlur(110))
    return Image.composite(base, Image.new("RGB", (N, N), (92, 64, 36)), vig)


def grow(mask, px):
    return mask.filter(ImageFilter.GaussianBlur(px / 2)).point(lambda v: 255 if v > 18 else 0)


def shrink(mask, px):
    return mask.filter(ImageFilter.GaussianBlur(px / 2)).point(lambda v: 255 if v > 237 else 0)


class Sketch:
    def __init__(self, w, h, seed):
        self.w, self.h, self.seed = w, h, seed
        self.layers = []          # (palette key, mask)
        self.ink = Image.new("RGBA", (N, N), (0, 0, 0, 0))
        self.inkd = ImageDraw.Draw(self.ink)

    def c(self, x, y):
        return (x / self.w * N, y / self.h * N)

    def s(self, v):
        return v / self.w * N

    def layer(self, key):
        m = Image.new("L", (N, N), 0)
        self.layers.append((key, m))
        return ImageDraw.Draw(m)

    # shapes ------------------------------------------------------------
    def rect(self, key, x0, y0, x1, y1):
        d = self.layer(key)
        d.rectangle([*self.c(x0, y0), *self.c(x1, y1)], fill=255)

    def poly(self, key, pts):
        d = self.layer(key)
        d.polygon([self.c(*p) for p in pts], fill=255)

    def circ(self, key, x, y, r):
        d = self.layer(key)
        cx, cy = self.c(x, y)
        rr = self.s(r)
        d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=255)

    def band(self, key, pts, width):
        d = self.layer(key)
        P = [self.c(*p) for p in pts]
        w = self.s(width)
        d.line(P, fill=255, width=int(w), joint="curve")
        for p in P:
            d.ellipse([p[0] - w / 2, p[1] - w / 2, p[0] + w / 2, p[1] + w / 2], fill=255)

    # ink details (drawn on top) ----------------------------------------
    def pillar(self, x, y, r=6):
        cx, cy = self.c(x, y)
        rr = self.s(r)
        self.inkd.rectangle([cx - rr, cy - rr, cx + rr, cy + rr], fill=INK + (255,))

    def dot(self, x, y, r, col=INK):
        cx, cy = self.c(x, y)
        rr = self.s(r)
        self.inkd.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=col + (255,), outline=INK + (255,), width=4)

    def tree(self, x, y, r=10, col=(118, 140, 70)):
        cx, cy = self.c(x, y)
        rr = self.s(r)
        self.inkd.ellipse([cx - rr + 6, cy - rr + 8, cx + rr + 6, cy + rr + 8], fill=(60, 40, 20, 90))
        self.inkd.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=col + (255,), outline=INK + (255,), width=4)
        self.inkd.ellipse([cx - rr * 0.5, cy - rr * 0.6, cx + rr * 0.1, cy - rr * 0.1], fill=tuple(min(255, v + 30) for v in col) + (255,))

    def stairs(self, x0, y0, x1, y1, steps=8):
        for i in range(steps + 1):
            t = i / steps
            x, y = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
            dx, dy = (y1 - y0), -(x1 - x0)
            l = math.hypot(dx, dy) or 1
            k = 14 / l
            a, b = self.c(x - dx * k, y - dy * k), self.c(x + dx * k, y + dy * k)
            self.inkd.line([a, b], fill=INK + (200,), width=4)

    def rocks(self, n, seed, avoid=None):
        random.seed(seed)
        for _ in range(n):
            x, y = random.uniform(0, self.w), random.uniform(0, self.h)
            if avoid and avoid.getpixel((int(x / self.w * (N - 1)), int(y / self.h * (N - 1)))) > 0:
                continue
            cx, cy = self.c(x, y)
            r = random.uniform(30, 62)
            # mountain peak: lit west face, shaded east face, ink outline
            top, left, right, foot = (cx, cy - r), (cx - r, cy + r * 0.6), (cx + r, cy + r * 0.6), (cx + r * 0.25, cy + r * 0.6)
            self.inkd.polygon([top, left, foot], fill=(196, 168, 120, 255))
            self.inkd.polygon([top, foot, right], fill=(150, 120, 82, 255))
            self.inkd.line([left, top, right], fill=INK + (255,), width=4)
            for k in range(1, 4):
                t = k / 4
                a = (top[0] + (right[0] - top[0]) * t, top[1] + (right[1] - top[1]) * t)
                self.inkd.line([a, (a[0] - r * 0.18, a[1] + r * 0.28)], fill=INK + (160,), width=2)

    # render ------------------------------------------------------------
    def union(self):
        u = Image.new("L", (N, N), 0)
        for _, m in self.layers:
            u = ImageChops.lighter(u, m)
        return u

    def render(self):
        img = parchment(self.seed)
        # drop shadow under everything that is walkable
        u = self.union()
        sh = grow(u, 18).filter(ImageFilter.GaussianBlur(22))
        sh = ImageChops.offset(sh, 10, 14).point(lambda v: v * 0.55)
        img = Image.composite(Image.new("RGB", (N, N), (70, 48, 26)), img, sh)
        grain = noise(3, 26, self.seed + 9)
        blot = noise(40, 30, self.seed + 10)
        for key, m in self.layers:
            col = PAL[key]
            rim = grow(m, 14)
            img = Image.composite(Image.new("RGB", (N, N), INK), img, rim)
            fill = Image.new("RGB", (N, N), col)
            # paper grain and soft blotches in the fill
            tex = ImageChops.add(grain.point(lambda v: v // 6), blot.point(lambda v: v // 8), 1, -30)
            fill = ImageChops.subtract(fill, Image.merge("RGB", [tex] * 3))
            if key == "water":
                d = ImageDraw.Draw(fill)
                random.seed(self.seed + 3)
                for _ in range(260):
                    x, y = random.uniform(0, N), random.uniform(0, N)
                    l = random.uniform(16, 46)
                    d.arc([x - l, y - 6, x + l, y + 6], 200, 340, fill=(150, 184, 190), width=3)
            img = Image.composite(fill, img, m)
            # inner shade along the walls, light edge just inside the rim
            edge = ImageChops.subtract(m, shrink(m, 26)).filter(ImageFilter.GaussianBlur(10))
            edge = ImageChops.multiply(edge, m).point(lambda v: v * 0.45)
            img = Image.composite(Image.new("RGB", (N, N), tuple(int(v * 0.72) for v in col)), img, edge)
            hl = ImageChops.subtract(m, shrink(m, 6)).point(lambda v: v * 0.35)
            img = Image.composite(Image.new("RGB", (N, N), tuple(min(255, v + 22) for v in col)), img, hl)
        img.paste(self.ink, (0, 0), self.ink)
        # thin frame
        d = ImageDraw.Draw(img)
        d.rectangle([18, 18, N - 18, N - 18], outline=(70, 46, 24), width=10)
        d.rectangle([34, 34, N - 34, N - 34], outline=(150, 118, 70), width=4)
        return img.resize((OUT, OUT), Image.LANCZOS)


# --------------------------------------------------------------------------
def thanes():
    S = Sketch(820, 900, 11)
    for pts in [[(40, 205), (130, 290), (240, 335), (330, 360)], [(470, 362), (560, 320), (640, 282)],
                [(230, 262), (400, 232), (590, 190)]]:
        S.band("rubble", pts, 26)
    S.poly("floor2", [(470, 385), (560, 380), (620, 330), (700, 312), (780, 340), (805, 410), (770, 470), (712, 478),
                      (700, 560), (675, 560), (668, 470), (630, 440), (560, 425), (470, 420)])
    S.rect("floor", 378, 150, 422, 378)
    S.circ("floor", 400, 85, 64)
    S.rect("floor", 328, 376, 470, 517)
    S.rect("floor", 328, 528, 470, 668)
    S.rect("floor", 393, 510, 407, 535)
    for x0, x1 in [(250, 300), (500, 548)]:
        S.rect("floor", x0, 528, x1, 668)
    S.rect("floor", 300, 590, 328, 604); S.rect("floor", 470, 590, 500, 604)
    S.rect("floor", 57, 565, 215, 632); S.rect("floor", 585, 565, 742, 632)
    S.rect("floor", 215, 590, 250, 605); S.rect("floor", 548, 590, 585, 605)
    for xs in [(65, 102, 140, 178), (595, 632, 670, 707)]:
        for x in xs:
            S.rect("floor2", x, 522, x + 28, 565); S.rect("floor2", x, 632, x + 28, 676)
    S.rect("floor", 264, 668, 280, 716); S.rect("floor", 264, 702, 368, 716)
    S.rect("floor", 520, 668, 536, 716); S.rect("floor", 432, 702, 536, 716)
    S.rect("floor", 366, 680, 432, 888)
    S.rect("floor2", 344, 745, 366, 820); S.rect("floor2", 432, 745, 454, 820)
    S.circ("floor2", 399, 598, 24)
    for x, y in [(358, 410), (440, 410), (358, 484), (440, 484), (358, 560), (440, 560), (358, 636), (440, 636)]:
        S.pillar(x, y, 7)
    random.seed(5)
    for pts in [[(40, 205), (130, 290), (240, 335), (330, 360)], [(470, 362), (560, 320), (640, 282)],
                [(230, 262), (400, 232), (590, 190)]]:
        for _ in range(16):
            t = random.random(); i = min(int(t * (len(pts) - 1)), len(pts) - 2); f = t * (len(pts) - 1) - i
            x = pts[i][0] + (pts[i + 1][0] - pts[i][0]) * f + random.uniform(-12, 12)
            y = pts[i][1] + (pts[i + 1][1] - pts[i][1]) * f + random.uniform(-12, 12)
            S.dot(x, y, random.uniform(3, 7), col=(150, 122, 84))
    S.stairs(399, 880, 399, 830, 6)
    return S


def excavation():
    S = Sketch(900, 832, 23)
    S.poly("snow", [(0, 610), (420, 610), (430, 700), (560, 780), (560, 832), (0, 832)])
    valleys = [
        [(140, 330), (260, 300), (330, 330), (360, 375), (330, 470), (300, 520), (230, 530), (170, 470), (120, 420)],
        [(260, 250), (330, 220), (470, 220), (500, 270), (470, 330), (360, 345), (280, 320)],
        [(330, 345), (470, 330), (560, 360), (560, 470), (520, 500), (420, 480), (340, 470)],
        [(540, 360), (620, 350), (650, 420), (610, 460), (555, 450)],
        [(250, 470), (360, 470), (380, 540), (330, 575), (240, 555)],
    ]
    for v in valleys:
        S.poly("grass", v)
    S.poly("water", [(360, 378), (470, 368), (482, 410), (540, 440), (552, 472), (505, 472), (470, 448), (420, 466), (366, 462)])
    S.band("water", [(0, 170), (200, 120), (420, 95), (600, 95), (680, 130)], 12)
    S.band("road", [(610, 400), (700, 380), (760, 420), (790, 520)], 14)
    S.rocks(260, 4, avoid=grow(S.union(), 40))
    random.seed(8)
    for v in (valleys[0], valleys[1], valleys[4]):
        for _ in range(5):
            x = sum(p[0] for p in v) / len(v) + random.uniform(-50, 50)
            y = sum(p[1] for p in v) / len(v) + random.uniform(-30, 30)
            S.tree(x, y, 9)
    return S


def ruins():
    S = Sketch(791, 900, 37)
    S.poly("water", [(0, 720), (150, 700), (260, 800), (420, 850), (560, 800), (700, 660), (791, 640), (791, 900), (0, 900)])
    S.band("road", [(390, 0), (388, 100)], 22)
    S.band("road", [(370, 20), (250, 40), (120, 80), (40, 140), (0, 200)], 16)
    wall = [(78, 140), (390, 105), (705, 140), (705, 520), (655, 640), (560, 765), (420, 830), (260, 785), (150, 685), (92, 545), (72, 300)]
    S.poly("floor2", wall)
    for pts in [[(95, 250), (700, 250)], [(95, 440), (700, 440)], [(182, 140), (182, 640)], [(590, 140), (590, 600)], [(388, 105), (388, 300)]]:
        S.band("road", pts, 16)
    for x, y in [(182, 250), (590, 250), (182, 440), (590, 440), (388, 190)]:
        S.circ("road", x, y, 18)
    S.rect("floor", 210, 135, 322, 242); S.rect("floor", 440, 135, 532, 242); S.rect("floor", 365, 98, 412, 140)
    for x0, x1 in [(100, 120), (160, 205), (570, 612), (655, 680)]:
        S.rect("water", x0, 290, x1, 410)
    S.poly("water", [(165, 488), (205, 488), (205, 520), (255, 520), (255, 550), (165, 550)])
    S.poly("water", [(565, 540), (612, 540), (606, 625), (525, 715), (485, 692), (560, 612)])
    S.rect("floor", 322, 305, 458, 525)
    S.circ("floor2", 390, 452, 62)
    S.circ("floor2", 390, 522, 26)
    for x, y, s in [(372, 590, 26), (402, 655, 22), (335, 720, 24), (272, 722, 20), (212, 690, 18), (182, 602, 16), (470, 580, 18), (130, 600, 14)]:
        S.rect("rubble", x - s, y - s, x + s, y + s)
    S.circ("floor", 472, 590, 20)
    for p in wall:
        S.pillar(p[0], p[1], 11)
    for x, y in [(340, 320), (440, 320), (340, 400), (440, 400)]:
        S.pillar(x, y, 6)
    return S


def dalaran():
    S = Sketch(512, 512, 41)
    S.circ("floor2", 256, 215, 205)
    S.band("road", [(256, 52), (340, 68), (408, 118), (446, 190), (440, 270), (400, 330), (330, 368), (256, 378),
                    (180, 368), (110, 330), (72, 270), (66, 190), (104, 118), (172, 68), (256, 52)], 22)
    S.band("road", [(256, 165), (256, 378)], 20)
    S.band("road", [(98, 250), (414, 250)], 20)
    S.circ("arcane", 256, 112, 62)
    S.circ("arcane", 256, 112, 26)
    S.rect("floor", 92, 212, 176, 288)
    S.circ("floor", 386, 262, 40)
    S.circ("water", 386, 262, 16)
    S.poly("fel", [(330, 150), (392, 128), (436, 160), (430, 206), (384, 214), (340, 196)])
    S.circ("road", 256, 250, 30)
    S.rect("floor2", 24, 430, 488, 476)
    S.band("water", [(40, 453), (472, 453)], 8)
    S.circ("floor", 330, 453, 34); S.circ("arcane", 330, 453, 14)
    S.circ("floor", 150, 453, 22); S.circ("arcane", 150, 453, 8)
    S.circ("water", 30, 453, 12)
    S.band("road", [(440, 430), (440, 330)], 14)
    S.stairs(440, 425, 440, 335, 10)
    for a in range(8):
        S.pillar(256 + 46 * math.cos(a * math.pi / 4), 112 + 46 * math.sin(a * math.pi / 4), 4)
    for x in (104, 124, 144, 164):
        for y in (228, 272):
            S.pillar(x, y, 5)
    for x, y in [(356, 160), (380, 148), (408, 166), (370, 190), (402, 196), (420, 180)]:
        S.tree(x, y, 9, col=(110, 150, 60))
    return S


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Maps")
    for name, fn in [("Thanes", thanes), ("Excavation", excavation), ("RuinsLordaeron", ruins), ("Dalaran", dalaran)]:
        img = fn().render()
        img.save(os.path.join(out, name + ".tga"))
        if len(sys.argv) > 2:
            img.resize((512, 512), Image.LANCZOS).save(os.path.join(sys.argv[2], name + "_pv.png"))
        print(name)
