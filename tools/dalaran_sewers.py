"""Dalaran sewers page: the floors of the city WMO's underground groups, seen
from above and painted with the sketch renderer (the game has no map art for
them). Placed in the same absolute minimap pixels as the city's minimap
tiles, so both floors share one coordinate system.

    python dalaran_sewers.py [output folder] [preview folder]

Downloads the WMO (file ID 7116370, client 1.60.1.70245) from wago.tools.
"""
import math, os, struct, subprocess, sys
from PIL import Image, ImageDraw
import sketches as SK

VER = "1.60.1.70245"
ROOT = 7116370
# placement of the city WMO in map 2959 (MODF of ADT 30_30): position, 15 deg
# yaw once the local y axis is mirrored (checked against the minimap tiles)
POS = (16763.455, 90.659, 16791.541)
# underground groups: the deep halls first, so the upper levels paint over them
GROUPS = [(75, "floor2"), (60, "floor2"), (64, "floor2"), (54, "floor2"),
          (61, "floor"), (62, "floor"), (63, "floor"), (66, "floor"), (40, "floor"), (35, "floor"),
          (65, "road"), (55, "road"), (56, "road"), (77, "road")]
# shown square (absolute minimap px): x, y, size
VIEW = (15788, 15983, 540)
CACHE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "wmo_cache")


def fetch(fid):
    os.makedirs(CACHE, exist_ok=True)
    p = os.path.join(CACHE, "%d.wmo" % fid)
    if not os.path.exists(p):
        subprocess.run(["curl", "-s", "-o", p, "https://wago.tools/api/casc/%d?download&version=%s" % (fid, VER)], check=True)
    return open(p, "rb").read()


def chunks(b, start=0):
    i = start
    while i + 8 <= len(b):
        tag = b[i:i + 4][::-1].decode("latin1"); n = struct.unpack("<I", b[i + 4:i + 8])[0]
        yield tag, b[i + 8:i + 8 + n]; i += 8 + n


def group_files():
    for tag, d in chunks(fetch(ROOT)):
        if tag == "GFID": return struct.unpack("<%dI" % (len(d) // 4), d)


def floors(fid):
    """Upward-facing triangles of a group, in absolute minimap px."""
    for tag, d in chunks(fetch(fid)):
        if tag != "MOGP": continue
        sub = dict(chunks(d, 68))
        V = struct.iter_unpack("<3f", sub["MOVT"]); V = list(V)
        I = list(struct.iter_unpack("<3H", sub["MOVI"]))
        c, s = math.cos(math.radians(15)), math.sin(math.radians(15))
        def to_abs(v):
            x, y = v[0], -v[1]
            return ((POS[0] + c * x - s * y) * 0.96, (POS[2] + s * x + c * y) * 0.96)
        out = []
        for t in I:
            a, b, cc = V[t[0]], V[t[1]], V[t[2]]
            u = [b[k] - a[k] for k in range(3)]; w = [cc[k] - a[k] for k in range(3)]
            n = (u[1] * w[2] - u[2] * w[1], u[2] * w[0] - u[0] * w[2], u[0] * w[1] - u[1] * w[0])
            l = math.sqrt(sum(x * x for x in n))
            if l and abs(n[2]) / l >= 0.6:
                out.append([to_abs(a), to_abs(b), to_abs(cc)])
        return out


def sketch():
    gf = group_files()
    vx, vy, size = VIEW
    S = SK.Sketch(size, size, 53)
    for g, key in GROUPS:
        m = Image.new("L", (SK.N, SK.N), 0)
        d = ImageDraw.Draw(m)
        for tri in floors(gf[g]):
            d.polygon([S.c(x - vx, y - vy) for x, y in tri], fill=255)
        S.layers.append((key, m))
    return S


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Maps")
    img = sketch().render()
    img.save(os.path.join(out, "DalaranSewers.tga"))
    if len(sys.argv) > 2:
        img.resize((512, 512)).save(os.path.join(sys.argv[2], "DalaranSewers_pv.png"))
    print("DalaranSewers")
