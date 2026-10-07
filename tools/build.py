import json, re, os
from anchors import CFG
from texts import TIPS, NOTES
from routes import ROUTES, FROM
from blizmaps import TILES
from floorareas import AREAS
import place as _place

W = json.load(open("wowf.json", encoding="utf-8"))
LOOT = json.load(open("loot.json", encoding="utf-8")) if os.path.exists("loot.json") else {}
# loot boss labels that differ from the guide step names
LOOT_ALIAS = {
 ("wailing-caverns", "돌연변이 요정용"): 7,
 ("deadmines", "스니드의 벌목기"): 3,
 ("scarlet-monastery-graveyard", "무쇠해골"): 3,
 ("scarlet-monastery-graveyard", "잠들지 않는 아즈쉬르"): 3,
 ("scarlet-monastery-graveyard", "타락한 용사"): 3,
}
TRASH = ("일반 몹", "—", "")

def loot_for(slug, stops):
    by_step, trash = {}, []
    for it in LOOT.get(slug, []):
        hit = False
        for b in it["bosses"] or [""]:
            n = LOOT_ALIAS.get((slug, b))
            if n is None:
                for s in stops:
                    nm = s["name"] or ""
                    if nm and (nm == b or (b and b in nm)):
                        n = s["n"]; break
            if n is not None:
                lst = by_step.setdefault(n, [])
                if it["id"] not in lst: lst.append(it["id"])
                hit = True
            elif b in TRASH or True:
                pass
        if not hit and it["id"] not in trash: trash.append(it["id"])
    return by_step, trash
P = json.load(open("placed.json", encoding="utf-8"))
# creature display IDs (classic DB) for the 3D boss preview
DISP = json.load(open("displays.json", encoding="utf-8")) if os.path.exists("displays.json") else {}

# Blizzard world-map pages: wowf % positions are relative to these maps,
# so they are used as they are (1002 x 668 map pixels).
BW, BH = 1002, 668
def bliz_block(slug, ko, en):
    floors = TILES.get(slug)
    if not floors: return None
    if any(f["id"] not in floors or "-client" not in f["img"] for f in ko["floors"]): return None
    multi = len(ko["floors"]) > 1
    efl = {f["id"]: f for f in en["floors"]}
    def px(pos): return (int(round(pos[0] * BW / 100)), int(round(pos[1] * BH / 100)))
    pages, stops, links, start = [], {}, [], None
    for f in ko["floors"]:
        key = str(f["id"])
        pg = {"key": key, "tiles": floors[f["id"]], "areas": AREAS.get(slug, {}).get(f["id"])}
        if multi and f.get("caption"):
            pg["name"] = (f["caption"], efl.get(f["id"], {}).get("caption") or f["caption"])
        pages.append(pg)
        en_pins = {tuple(p["pos"]): p for p in efl.get(f["id"], {}).get("pins", [])}
        for p in f["pins"]:
            xy = px(p["pos"])
            if "stop" in p:
                e = stops.setdefault(p["stop"], {"page": key, "pos": None, "alt": []})
                if p.get("alt"): e["alt"].append(xy)
                else: e["pos"] = xy; e["page"] = key
            elif p["label"] == "입구":
                if start is None: start = (key, xy)
            else:
                enl = en_pins.get(tuple(p["pos"]), {}).get("label") or p["label"]
                links.append((key, xy, p["label"], enl))
    # stops placed by hand on the Atlas map (no wowf pin): Atlas -> wowf % fit
    for (sl, n), (pg, x, y) in FIXED.items():
        if sl != slug or (n in stops and stops[n]["pos"]): continue
        cfg = CFG[slug]; src, dst = [], []
        for (afl, ref, ax, ay) in cfg["anchors"]:
            if afl != 1: continue
            r = _place.ref_pos(ko, 1, ref)
            if r: src.append((ax, ay)); dst.append(r)
        f, _ = _place.fit(src, dst)
        if f is None: continue
        w = f((x, y))
        stops.setdefault(n, {"page": "1", "alt": []})
        stops[n]["pos"] = px((float(w[0]), float(w[1]))); stops[n]["page"] = "1"
    # keep markers apart (they are drawn ~16 px wide)
    placed = []
    for n in sorted(stops):
        e = stops[n]
        if not e["pos"]: continue
        x, y = e["pos"]
        for _ in range(6):
            if not [q for q in placed if q[0] == e["page"] and abs(q[1] - x) < 22 and abs(q[2] - y) < 22]: break
            x += 26
        e["pos"] = (min(BW - 12, x), y)
        placed.append((e["page"], x, y))
    return pages, stops, links, start

ORDER = ["ragefire-chasm", "hall-of-thanes", "wailing-caverns", "deadmines", "ruins-of-lordaeron", "shadowfang-keep",
         "blackfathom-deeps", "stockade", "excavation-site", "dalaran", "gnomeregan", "razorfen-kraul",
         "scarlet-monastery-graveyard", "scarlet-monastery-library", "scarlet-monastery-armory",
         "razorfen-downs", "scarlet-monastery-cathedral", "uldaman"]

META = {
 "ragefire-chasm": dict(key="rfc", ids=[389], match=["성난불길", "Ragefire"], map=1454),
 "wailing-caverns": dict(key="wc", ids=[43], match=["통곡의 동굴", "Wailing Caverns"], map=1413),
 "deadmines": dict(key="dm", ids=[36], match=["죽음의 폐광", "Deadmines"], map=1436),
 "shadowfang-keep": dict(key="sfk", ids=[33], match=["그림자송곳니", "Shadowfang"], map=1421),
 "blackfathom-deeps": dict(key="bfd", ids=[48], match=["검은심연", "Blackfathom"], map=1440),
 "stockade": dict(key="stocks", ids=[34], match=["지하감옥", "Stockade"], map=1453),
 "gnomeregan": dict(key="gnomer", ids=[90], match=["놈리건", "Gnomeregan"], map=1426),
 "razorfen-kraul": dict(key="rfk", ids=[47], match=["가시덩굴 우리", "Razorfen Kraul"], map=1413),
 "razorfen-downs": dict(key="rfd", ids=[129], match=["가시덩굴 구릉", "Razorfen Downs"], map=1413),
 "uldaman": dict(key="ulda", ids=[70], match=["울다만", "Uldaman"], map=1418),
 "scarlet-monastery-graveyard": dict(key="smgy", ids=[189], match=["묘지", "Graveyard"], map=1420,
     subzones=["속죄의 방", "쓸쓸한 회랑", "명예의 무덤", "묘지", "Chamber of Atonement", "Forlorn Cloister", "Honor's Tomb", "Graveyard"]),
 "scarlet-monastery-library": dict(key="smlib", ids=[189], match=["도서관", "Library"], map=1420,
     subzones=["사냥꾼의 회랑", "보물 전시실", "도서관", "Huntsman's Cloister", "Gallery of Treasures", "Athenaeum", "The Athenaeum", "Library"]),
 "scarlet-monastery-armory": dict(key="smarm", ids=[189], match=["무기고", "Armory"], map=1420,
     subzones=["훈련장", "보병 무기고", "십자군 무기고", "용사의 전당", "Training Grounds", "Footman's Armory", "Crusader's Armory", "Hall of Champions", "Armory"]),
 "scarlet-monastery-cathedral": dict(key="smcath", ids=[189], match=["대성당", "Cathedral"], map=1420,
     subzones=["예배당 정원", "십자군 예배당", "대성당", "Chapel Gardens", "Crusader's Chapel", "Cathedral"]),
 "hall-of-thanes": dict(key="thanes", ids=[3065], match=["영주의 전당", "Hall of Thanes"], map=1455, blank=True, sketch="Thanes"),
 "excavation-site": dict(key="excav", ids=[2998], match=["발굴 현장", "Excavation Site"], map=1437, blank=True, sketch="Excavation"),
 "ruins-of-lordaeron": dict(key="rol", ids=[2999], match=["로데론의 폐허", "Ruins of Lordaeron"], map=None, blank=True, sketch="RuinsLordaeron"),
 "dalaran": dict(key="dala", ids=[], match=["달라란", "Dalaran"], map=None, nomap=True),
}
SM_RESET = ["붉은십자군 수도원", "Scarlet Monastery"]

CREDIT = {"CL_RagefireChasm": "Niflheim", "CL_WailingCaverns": "Grimm", "CL_TheDeadmines": "Niflheim",
          "CL_ShadowfangKeep": "worldofwar.net", "CL_BlackfathomDeepsA": "Arith", "CL_BlackfathomDeepsB": "Arith",
          "CL_BlackfathomDeepsC": "Arith", "CL_TheStockade": "wowguru.com", "CL_Gnomeregan": "worldofwar.net",
          "CL_RazorfenKraul": "wowguru.com", "CL_RazorfenDowns": "Niflheim", "CL_SMGraveyard": "Dan Gilbert",
          "CL_SMLibrary": "Dan Gilbert", "CL_SMArmory": "Dan Gilbert", "CL_SMCathedral": "Dan Gilbert", "CL_Uldaman": "Arith"}
# Atlas legend digits printed on the images (and the A entrance letter):
# covered in game so only this addon's numbers are visible.
MASKS = {
 "CL_RagefireChasm": [(379, 14), (400, 268), (212, 292), (157, 433), (222, 455)],
 "CL_WailingCaverns": [(219, 298), (235, 274), (83, 291), (196, 192), (225, 221), (432, 189), (467, 357), (311, 271), (286, 254), (166, 144), (315, 224)],
 "CL_SMGraveyard": [(495, 353), (400, 236), (179, 277), (58, 277), (60, 220), (43, 206)],
 "CL_TheDeadmines": [(62, 100), (112, 282), (209, 232), (190, 377), (252, 291), (281, 180), (405, 171)],
 "CL_Gnomeregan": [(406, 73), (492, 215), (326, 219), (360, 236), (369, 172), (163, 232), (241, 383), (38, 284), (55, 218)],
 "CL_RazorfenDowns": [(25, 122), (270, 188), (396, 141), (447, 245), (102, 338), (116, 270), (210, 353), (171, 308), (193, 132)],
 "CL_RazorfenKraul": [(358, 362), (354, 231), (440, 255), (471, 215), (308, 160), (67, 324), (53, 162), (139, 173), (206, 169), (262, 230)],
 "CL_ShadowfangKeep": [(373, 325), (345, 344), (150, 285), (92, 398), (154, 324), (289, 397), (276, 178), (389, 166), (413, 82), (182, 316)],
 "CL_Uldaman": [(427, 377), (359, 471), (311, 327), (313, 376), (182, 383), (115, 318), (272, 314), (267, 222), (97, 163), (70, 98), (219, 72), (200, 29)],
 "CL_TheStockade": [(256, 347), (258, 161), (149, 224), (217, 243), (295, 277), (368, 180), (420, 246), (470, 272), (93, 172), (130, 233)],
 "CL_SMLibrary": [(13, 148), (129, 399), (455, 353)],
 "CL_SMCathedral": [(374, 486), (314, 84), (257, 34)],
 "CL_SMArmory": [(156, 488), (307, 43)],
 "CL_BlackfathomDeepsA": [(299, 64), (210, 317), (210, 211), (39, 211), (109, 391), (375, 299), (432, 343), (475, 360)],
 "CL_BlackfathomDeepsB": [(90, 62), (132, 80), (58, 194), (32, 314), (104, 355), (192, 373), (454, 397)],
 "CL_BlackfathomDeepsC": [(442, 245)],
}
PAGE_NAMES = {("blackfathom-deeps", "A"): ("1층", "Level 1"), ("blackfathom-deeps", "B"): ("2층", "Level 2"),
              ("blackfathom-deeps", "C"): ("물속", "Underwater")}

# creature IDs for kill detection (names are matched as well)
IDS = {
 "ragefire-chasm": {2: [11517], 5: [11520], 6: [11519], 7: [11518]},
 "wailing-caverns": {1: [3655], 2: [3671], 3: [3669], 4: [3653], 5: [3670], 6: [3674], 7: [5912], 8: [3673], 9: [5775], 11: [3654]},
 "deadmines": {1: [644], 2: [3586], 3: [643, 642], 4: [1763], 6: [646], 7: [645], 8: [647], 9: [639]},
 "shadowfang-keep": {1: [3914], 5: [3886], 6: [3887], 7: [4278], 8: [4279], 9: [4274], 11: [3927], 12: [4275]},
 "blackfathom-deeps": {1: [4887], 3: [4831], 5: [6243], 6: [12902], 7: [4830], 8: [12876], 9: [4832], 11: [4829]},
 "stockade": {1: [1696], 2: [1720], 3: [1666], 4: [1717], 5: [1716], 6: [1663]},
 "gnomeregan": {1: [7361], 2: [7079], 5: [6235], 6: [6229], 7: [6228], 9: [7800]},
 "razorfen-kraul": {1: [6168], 2: [4424], 3: [4428], 4: [4420], 6: [4842], 7: [4422], 8: [4425], 11: [4421]},
 "razorfen-downs": {1: [7355], 2: [7356], 3: [7357], 4: [7354], 5: [8567], 6: [7358]},
 "scarlet-monastery-graveyard": {1: [3983], 3: [6488, 6489, 6490], 4: [4543]},
 "scarlet-monastery-library": {1: [3974], 6: [6487]},
 "scarlet-monastery-armory": {1: [3975]},
 "scarlet-monastery-cathedral": {1: [4542], 2: [3976], 3: [3977]},
 "uldaman": {1: [6910], 2: [6906, 6907, 6908], 3: [7228], 4: [7023], 5: [7206], 6: [7291], 7: [4854], 8: [2748]},
}
# extra placement fixes
FIXED = {("scarlet-monastery-cathedral", 3): ("main", 282, 44)}

def lua_str(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'

def L(ko, en):
    return "{ ko = %s, en = %s }" % (lua_str(ko or en or ""), lua_str(en or ko or ""))

def pt(p):
    return "{ %d, %d }" % (int(p[0]), int(p[1]))

def entrance_info(slug):
    ko = W[slug]["ko"]["entrance"]; en = W[slug]["en"]["entrance"]
    if not ko: return None
    m = re.search(r"\(([\d.]+),\s*([\d.]+)\)", ko)
    if not m: return None
    zko = re.sub(r"^입구\s*", "", ko); zko = re.sub(r"\s*\([\d.,\s]+\).*$", "", zko)
    zen = re.sub(r"^Entrance\s*", "", en or ""); zen = re.sub(r"\s*\([\d.,\s]+\).*$", "", zen)
    return float(m.group(1)), float(m.group(2)), zko, zen

def quest_maps(slug):
    ko = {q["id"]: q for q in W[slug]["ko"]["quests"]}
    en = {q["id"]: q for q in W[slug]["en"]["quests"]}
    out = []
    for qid, q in ko.items():
        e = en.get(qid, {})
        lvl = next((int(re.match(r"(\d+)", t).group(1)) for t in q["meta"] if re.match(r"\d+레벨$", t)), None)
        extra = [t for t in q["meta"] if t.endswith("전용")]
        out.append(dict(id=qid, faction=q["faction"], level=lvl, name=(q["name"], e.get("name") or q["name"]),
                        desc=(q["desc"], e.get("desc") or ""), extra=extra))
    return out

def build():
    lines = ["-- Dungeon Route Guide - dungeon data (generated).",
             "-- Facts (order, positions, quests) referenced from wowf.io guides; tips rewritten for this addon.",
             "-- Maps: Atlas Classic (GPL-2.0). New Forever dungeons have no terrain art: relative positions only.",
             "local _, ns = ...", "", "ns.Dungeons = {"]
    for slug in ORDER:
        ko, en = W[slug]["ko"], W[slug]["en"]; meta = META[slug]
        cfg = CFG.get(slug); pl = P.get(slug)
        lv = re.search(r"(\d+)\D+(\d+)", ko["info"].get("추천 레벨", ""))
        levels = "%s-%s" % lv.groups() if lv else ""
        lines.append("  {")
        lines.append("    key = %s, slug = %s, levels = %s," % (lua_str(meta["key"]), lua_str(slug), lua_str(levels)))
        lines.append("    name = %s," % L(ko["name"], en["name"]))
        lines.append("    instanceIDs = { %s }, nameMatch = { %s }," % (", ".join(map(str, meta["ids"])), ", ".join(lua_str(x) for x in meta["match"])))
        if meta.get("subzones"):
            lines.append("    subzones = { %s }, resetNames = { %s }," % (", ".join(lua_str(x) for x in meta["subzones"]), ", ".join(lua_str(x) for x in SM_RESET)))
        ent = entrance_info(slug)
        if ent and meta.get("map"):
            x, y, zko, zen = ent
            lines.append("    entrance = { map = %d, x = %.1f, y = %.1f, zone = %s }," % (meta["map"], x, y, L(zko, zen)))
        # pages
        pages = []
        if cfg:
            for pk, mf in cfg["pages"].items():
                nm = PAGE_NAMES.get((slug, pk))
                mask = MASKS.get(mf, [])
                areas = []
                if len(cfg["pages"]) > 1:
                    for fl, fpk in cfg["floors"].items():
                        if fpk == pk: areas += [a for a in AREAS.get(slug, {}).get(fl, []) if a not in areas]
                pages.append('{ key = %s, map = %s, credit = %s%s%s }' % (lua_str(pk), lua_str(mf), lua_str("Map: %s · Atlas" % CREDIT.get(mf, "Atlas")),
                             (", name = " + L(*nm)) if nm else "",
                             ((", mask = { %s }" % ", ".join(pt(m) for m in mask)) if mask else "") +
                             ((", areas = { %s }" % ", ".join(lua_str(a) for a in areas)) if areas else "")))
        elif meta.get("blank"):
            pages.append('{ key = "main", map = "%s", schematic = true }' % meta["sketch"])
        lines.append("    pages = { %s }," % ", ".join(pages))
        # positions
        def pos_of(n):
            if (slug, n) in FIXED:
                pg, x, y = FIXED[(slug, n)]; return pg, (x, y), []
            if pl:
                e = pl["stops"].get(str(n))
                if e and e["pos"]: return e["page"], tuple(e["pos"]), [tuple(a) for a in e["alt"]]
                return None, None, []
            if meta.get("blank"):
                for f in ko["floors"]:
                    for p in f["pins"]:
                        if p.get("stop") == n and not p.get("alt"):
                            return "main", (round(p["pos"][0] * 5.12), round(p["pos"][1] * 5.12)), []
            return None, None, []
        def quest_flag(n):
            for f in ko["floors"]:
                for p in f["pins"]:
                    if p.get("stop") == n and not p.get("alt") and p.get("quest"): return True
            return False
        # start (entrance marker) and transition labels
        start = None
        if pl:
            for lab in pl["labels"]:
                if lab["label"] == "입구": start = (lab["page"], lab["pos"])
        elif meta.get("blank"):
            for f in ko["floors"]:
                for p in f["pins"]:
                    if p.get("label") == "입구": start = ("main", (round(p["pos"][0] * 5.12), round(p["pos"][1] * 5.12)))
        if start:
            lines.append("    start = { page = %s, pos = %s }," % (lua_str(start[0]), pt(start[1])))
        if pl:
            labs = []
            en_labels = {}
            for f in en["floors"]:
                for p in f["pins"]:
                    if "label" in p: en_labels[(f["id"], tuple(p["pos"]))] = p["label"]
            ko_floor_labels = []
            for f in ko["floors"]:
                for p in f["pins"]:
                    if "label" in p and p["label"] != "입구": ko_floor_labels.append((f["id"], tuple(p["pos"]), p["label"]))
            for lab in pl["labels"]:
                if lab["label"] == "입구": continue
                enl = None
                for (fl, pos, kl) in ko_floor_labels:
                    if kl == lab["label"] and fl == lab["floor"]: enl = en_labels.get((fl, pos))
                labs.append("{ page = %s, pos = %s, text = %s }" % (lua_str(lab["page"]), pt(lab["pos"]), L(lab["label"], enl or lab["label"])))
            if labs:
                lines.append("    links = {"); lines += ["      " + l + "," for l in labs]; lines.append("    },")
        bz = bliz_block(slug, ko, en)
        if bz:
            bpages, bstops, blinks, bstart = bz
            lines.append("    bliz = {")
            lines.append("      pages = {")
            for pg in bpages:
                tl = ", ".join("{ %s }" % ", ".join(map(str, t)) for t in pg["tiles"])
                nm = (", name = " + L(*pg["name"])) if pg.get("name") else ""
                if pg.get("areas"): nm += ", areas = { %s }" % ", ".join(lua_str(a) for a in pg["areas"])
                lines.append("        { key = %s, tiles = { %s }%s }," % (lua_str(pg["key"]), tl, nm))
            lines.append("      },")
            if bstart: lines.append("      start = { page = %s, pos = %s }," % (lua_str(bstart[0]), pt(bstart[1])))
            if blinks:
                lines.append("      links = {")
                for (pg, xy, a, b) in blinks:
                    lines.append("        { page = %s, pos = %s, text = %s }," % (lua_str(pg), pt(xy), L(a, b)))
                lines.append("      },")
            lines.append("      steps = {")
            for n in sorted(bstops):
                e = bstops[n]
                if not e["pos"]: continue
                al = (", alt = { %s }" % ", ".join(pt(a) for a in e["alt"])) if e["alt"] else ""
                lines.append("        s%d = { page = %s, pos = %s%s }," % (n, lua_str(e["page"]), pt(e["pos"]), al))
            lines.append("      },")
            lines.append("    },")
        loot, trash = loot_for(slug, ko["stops"])
        # steps
        lines.append("    steps = {")
        prev_page = start[0] if start else None
        for s, e in zip(ko["stops"], en["stops"]):
            n = s["n"]; kind = s["kind"] or "boss"
            page, pos, alts = pos_of(n)
            name_ko = s["name"] or ("갈림길" if kind == "fork" else "?")
            name_en = e["name"] or ("Junction" if kind == "fork" else "?")
            tip = TIPS.get(slug, {}).get(n)
            if not tip: tip = (s["desc"][:120], e["desc"][:120])
            optional = s["skip"] or kind in ("rare",)
            fields = ['id = "s%d"' % n, 'n = "%d"' % n, 'kind = "%s"' % kind]
            if optional: fields.append("optional = true")
            if s.get("unconfirmed"): fields.append("unconfirmed = true")
            if s.get("where"):
                fields.append("outside = %s" % L(s["where"], e.get("where") or s["where"]))
            ids = IDS.get(slug, {}).get(n)
            if ids:
                fields.append("npc = { %s }" % ", ".join(map(str, ids)))
                dm = DISP.get(str(ids[0]))
                if dm and dm["models"]: fields.append("model = %d" % dm["models"][0])
            fields.append("name = %s" % L(name_ko, name_en))
            if pos:
                fields.append('page = "%s"' % page)
                fields.append("pos = %s" % pt(pos))
                if alts: fields.append("alt = { %s }" % ", ".join(pt(a) for a in alts))
                if quest_flag(n) or s["quests"]: fields.append("quest = true")
                if not optional and kind != "fork":
                    path = ROUTES.get(slug, {}).get(n)
                    if path is not None: fields.append("path = { %s }" % ", ".join(pt(p) for p in path))
                    fr = FROM.get(slug, {}).get(n)
                    if fr: fields.append("from = %s" % pt(fr))
            if loot.get(n): fields.append("loot = { %s }" % ", ".join(map(str, loot[n])))
            qids = sorted(set(q["id"] for q in s["quests"]))
            if qids: fields.append("quests = { %s }" % ", ".join(map(str, qids)))
            fields.append("tip = %s" % L(*tip))
            lines.append("      { " + ", ".join(fields) + " },")
        lines.append("    },")
        # quests
        qs = quest_maps(slug)
        if qs:
            lines.append("    quests = {")
            for q in qs:
                f = ["id = %d" % q["id"]]
                if q["faction"]: f.append('faction = "%s"' % q["faction"])
                if q["level"]: f.append("level = %d" % q["level"])
                f.append("name = %s" % L(*q["name"]))
                f.append("giver = %s" % L(*q["desc"]))
                lines.append("      { " + ", ".join(f) + " },")
            lines.append("    },")
        if trash:
            lines.append("    trash = { %s }," % ", ".join(map(str, trash)))
        notes = NOTES.get(slug, [])
        if notes:
            lines.append("    notes = { %s }," % ", ".join(L(a, b) for a, b in notes))
        lines.append("  },")
    lines += ["}", "", "ns.DungeonByKey = {}", "for _, d in ipairs(ns.Dungeons) do ns.DungeonByKey[d.key] = d end", ""]
    return "\n".join(lines)

if __name__ == "__main__":
    src = build()
    open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Data.lua"), "w", encoding="utf-8").write(src)
    print(len(src), "bytes")
