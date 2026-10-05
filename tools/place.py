import json, numpy as np
from anchors import CFG

W = json.load(open("wowf.json", encoding="utf-8"))

def floor_pins(ko, fl):
    for f in ko["floors"]:
        if f["id"] == fl: return f["pins"]
    return []

def ref_pos(ko, fl, ref):
    pins = floor_pins(ko, fl)
    if ref == "entrance":
        for p in pins:
            if p.get("label") == "입구": return p["pos"]
        return None
    if isinstance(ref, str) and "@" in ref:
        n, xy = ref.split("@"); x, y = map(float, xy.split(","))
        return [x, y]
    for p in pins:
        if p.get("stop") == ref and not p.get("alt"): return p["pos"]
    return None

def fit(src, dst):
    src, dst = np.array(src, float), np.array(dst, float)
    n = len(src)
    if n >= 3:
        A = np.hstack([src, np.ones((n, 1))])
        M, *_ = np.linalg.lstsq(A, dst, rcond=None)      # 3x2
        return lambda p: np.array([p[0], p[1], 1.0]) @ M, M[:2]
    if n == 2:
        # similarity via complex numbers
        s = src[:, 0] + 1j * src[:, 1]; d = dst[:, 0] + 1j * dst[:, 1]
        a = (d[1] - d[0]) / (s[1] - s[0]); b = d[0] - a * s[0]
        lin = np.array([[a.real, a.imag], [-a.imag, a.real]])
        return (lambda p: (lambda z: np.array([z.real, z.imag]))(a * (p[0] + 1j * p[1]) + b)), lin
    return None, None

def solve(slug):
    cfg = CFG[slug]; ko = W[slug]["ko"]
    floors = sorted(set(cfg["floors"]))
    tf, report, lins = {}, {}, {}
    for fl in floors:
        src, dst, names = [], [], []
        for (afl, ref, x, y) in cfg["anchors"]:
            if afl != fl: continue
            p = ref_pos(ko, fl, ref)
            if p is None: print("  !! missing anchor", slug, fl, ref); continue
            src.append(p); dst.append((x, y)); names.append(ref)
        f, lin = fit(src, dst)
        tf[fl] = (f, src, dst, names); lins[fl] = lin
    # floors with a single anchor borrow the linear part of the best-fitted floor
    best = None
    for fl in floors:
        if len(tf[fl][1]) >= 3: best = lins[fl]; break
    if best is None:
        for fl in floors:
            if lins[fl] is not None: best = lins[fl]; break
    for fl in floors:
        f, src, dst, names = tf[fl]
        if f is None and len(src) == 1 and best is not None:
            s0, d0 = np.array(src[0]), np.array(dst[0])
            tf[fl] = ((lambda p, s0=s0, d0=d0: d0 + (np.array(p) - s0) @ best), src, dst, names)
    # local residual correction (inverse-distance weighted) so points near an
    # anchor follow that anchor's Atlas position.
    for fl in floors:
        f, src, dst, names = tf[fl]
        if f is None or len(src) < 3: continue
        resid = [np.array(d, float) - f(s) for s, d in zip(src, dst)]
        def g(p, f=f, src=src, resid=resid):
            p = np.array(p, float); base = f(p)
            w = np.array([1.0 / (np.linalg.norm(p - np.array(s)) ** 2 + 4.0) for s in src])
            return base + (w[:, None] * np.array(resid)).sum(0) / w.sum()
        tf[fl] = (g, src, dst, names)
    for fl in floors:
        f, src, dst, names = tf[fl]
        if f is None: continue
        res = [(n, round(float(np.linalg.norm(f(s) - np.array(d))), 1)) for s, d, n in zip(src, dst, names)]
        report[fl] = res
    return tf, report

def place(slug):
    cfg = CFG[slug]; ko = W[slug]["ko"]
    tf, report = solve(slug)
    anchored = {(afl, ref): (x, y) for (afl, ref, x, y) in cfg["anchors"]}
    out = {"stops": {}, "labels": [], "report": report}
    for f in ko["floors"]:
        fl = f["id"]; page = cfg["floors"].get(fl)
        func = tf.get(fl, (None,))[0]
        for p in f["pins"]:
            if "stop" in p:
                n = p["stop"]
                akey = "%d@%s,%s" % (n, p["pos"][0], p["pos"][1])
                if not p["alt"] and (fl, n) in anchored: xy = anchored[(fl, n)]
                elif p["alt"] and (fl, akey) in anchored: xy = anchored[(fl, akey)]
                elif func: xy = tuple(float(v) for v in func(p["pos"]))
                else: continue
                xy = (int(round(min(505, max(7, xy[0])))), int(round(min(505, max(7, xy[1])))))
                e = out["stops"].setdefault(n, {"page": page, "pos": None, "alt": [], "quest": False})
                if p["alt"]: e["alt"].append(xy)
                else: e["pos"] = xy; e["quest"] = p.get("quest", False); e["page"] = page
            else:
                lab = p["label"]
                if lab == "입구" and (fl, "entrance") in anchored: xy = anchored[(fl, "entrance")]
                elif func: xy = tuple(int(round(float(v))) for v in func(p["pos"]))
                else: continue
                out["labels"].append({"page": page, "floor": fl, "label": lab, "pos": (int(xy[0]), int(xy[1]))})
    for n, (page, x, y) in cfg.get("fixed", {}).items():
        out["stops"][n] = {"page": page, "pos": (x, y), "alt": [], "quest": False, "fixed": True}
    for n, alts in cfg.get("altfix", {}).items():
        if n in out["stops"] or str(n) in out["stops"]:
            out["stops"][n]["alt"] = [tuple(a) for a in alts]
    placed = []
    for n in sorted(out["stops"], key=int):
        e = out["stops"][n]
        if not e["pos"]: continue
        x, y = e["pos"]
        for _ in range(6):
            clash = [q for q in placed if q[0] == e["page"] and abs(q[1] - x) < 16 and abs(q[2] - y) < 16]
            if not clash: break
            x += 18
        e["pos"] = (min(505, x), y)
        placed.append((e["page"], x, y))
    return out

if __name__ == "__main__":
    allp = {}
    for slug in CFG:
        r = place(slug); allp[slug] = r
        print(slug, {fl: v for fl, v in r["report"].items()})
    json.dump(allp, open("placed.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
