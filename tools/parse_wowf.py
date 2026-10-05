import re, json, glob, os
from bs4 import BeautifulSoup

KIND = {"우두머리": "boss", "희귀 몹": "rare", "NPC": "npc", "Boss": "boss", "Rare": "rare",
        "물건": "object", "Object": "object", "해야 할 일": "task", "Objective": "task", "갈림길": "fork", "Fork": "fork"}
SKIP = ("건너뛰어도 됨", "skippable", "Skippable", "Optional")
UNCONF = ("지도 위치 미확인", "location not confirmed on the map")

def pct(style):
    m = re.search(r'left:([\d.]+)%;top:([\d.]+)%', style or "")
    return (float(m.group(1)), float(m.group(2))) if m else None

def parse(path):
    soup = BeautifulSoup(open(path, encoding="utf-8").read(), "html.parser")
    out = {}
    h1 = soup.find("h1"); out["name"] = h1.get_text(strip=True) if h1 else None
    dl = h1.find_parent().find_parent().find_next("dl") if h1 else None
    info = {}
    if dl:
        for div in dl.find_all("div"):
            dt, dd = div.find("dt"), div.find("dd")
            if dt and dd: info[dt.get_text(strip=True)] = dd.get_text(" ", strip=True)
    out["info"] = info
    # entrance line
    ent = None
    for sp in soup.find_all("span"):
        t = sp.get_text(" ", strip=True)
        if (t.startswith("입구 ") or t.startswith("Entrance ")) and "(" in t and len(t) < 200:
            ent = t; break
    out["entrance"] = ent
    # intro paragraph
    # floors & pins
    floors = []
    for fig in soup.select('figure[id^="map-floor-"]'):
        fl = {"id": int(fig["id"].split("-")[-1]), "img": None, "pins": []}
        img = fig.find("img"); fl["img"] = img["src"] if img else None
        cap = fig.find("figcaption")
        fl["caption"] = cap.get_text(" ", strip=True) if cap else None
        for el in fig.select("[style*='left:']"):
            p = pct(el.get("style"))
            if not p: continue
            cls = " ".join(el.get("class", []))
            href = el.get("href", "")
            num = re.match(r"#stop-(\d+)", href)
            text = el.get_text(" ", strip=True)
            if num:
                alt = "opacity-55" in cls
                quest = bool(el.find(string="!"))
                fl["pins"].append({"stop": int(num.group(1)), "pos": p, "alt": alt, "quest": quest})
            else:
                fl["pins"].append({"label": text, "pos": p})
        floors.append(fl)
    # floor tab names (buttons/links to #map-floor-N)
    tabs = {}
    for a in soup.select('a[href^="#map-floor-"]'):
        tabs[int(a["href"].split("-")[-1])] = a.get_text(" ", strip=True)
    for fl in floors: fl["tab"] = tabs.get(fl["id"])
    out["floors"] = floors
    # stops
    stops = []
    for li in soup.select('li[id^="stop-"]'):
        n = int(li["id"].split("-")[1])
        body = li.find("div")
        ps = body.find_all("p", recursive=False)
        head = ps[0]
        spans = [s.get_text(" ", strip=True) for s in head.find_all("span", recursive=False)]
        st = {"n": n, "level": None, "name": None, "en": None, "kind": None, "skip": False, "where": None}
        rest = []
        for t in spans:
            m = re.match(r"(?:레벨|Level|Lv)\.?\s*(\d+)", t)
            if m and st["level"] is None: st["level"] = int(m.group(1)); continue
            if t in KIND: st["kind"] = KIND[t]; continue
            if t in SKIP: st["skip"] = True; continue
            if t in UNCONF: st["unconfirmed"] = True; continue
            if t.startswith("던전 밖") or t.startswith("Outside"): st["where"] = t; continue
            rest.append(t)
        if rest: st["name"] = rest[0]
        if len(rest) > 1: st["en"] = rest[1]
        st["extra"] = rest[2:]
        st["desc"] = ps[1].get_text(" ", strip=True) if len(ps) > 1 else ""
        st["quests"] = []
        for a in li.select('a[href*="#quest-"]'):
            q = int(a["href"].split("#quest-")[1])
            line = a.find_parent("li")
            st["quests"].append({"id": q, "text": (line or a).get_text(" ", strip=True)})
        st["drops"] = [a["href"].split("#")[1] for a in li.select('a[href*="/dungeons/"]') if "#" in a["href"] and "#quest-" not in a["href"]]
        stops.append(st)
    out["stops"] = stops
    # quests section
    quests = []
    for h2 in soup.find_all("h2"):
        if h2.get_text(strip=True).startswith(("던전 퀘스트", "Dungeon quests", "Dungeon Quests")):
            sec = h2.find_parent("section")
            for li in sec.select("ul > li"):
                a = li.find("a", href=re.compile("#quest-"))
                if not a: continue
                q = {"id": int(a["href"].split("#quest-")[1]), "name": a.get_text(strip=True)}
                p0 = a.find_parent("p")
                spans = [s.get_text(" ", strip=True) for s in p0.find_all("span")]
                q["meta"] = [t for t in spans if t != "!"]
                q["faction"] = "Horde" if ("호드" in q["meta"] or "Horde" in q["meta"]) else ("Alliance" if ("얼라이언스" in q["meta"] or "Alliance" in q["meta"]) else None)
                ps = li.find_all("p")
                q["desc"] = ps[1].get_text(" ", strip=True) if len(ps) > 1 else ""
                quests.append(q)
    out["quests"] = quests
    # prep notes
    notes = []
    for h2 in soup.find_all("h2"):
        if h2.get_text(strip=True).startswith(("준비", "Before")):
            sec = h2.find_parent("section")
            notes = [li.get_text(" ", strip=True) for li in sec.select("li")]
    out["notes"] = notes
    return out

data = {}
for f in sorted(glob.glob("wowf/*.html")):
    base = os.path.basename(f)
    if base.endswith(".en.html"): continue
    slug = base[:-5]
    ko = parse(f)
    en = parse(f"wowf/{slug}.en.html")
    data[slug] = {"ko": ko, "en": en}
json.dump(data, open("wowf.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
for slug, d in data.items():
    ko = d["ko"]
    print(slug, ko["name"], "|", d["en"]["name"], "|", ko["info"].get("추천 레벨"), "| floors", [(f["id"], f["tab"], len(f["pins"])) for f in ko["floors"]], "| stops", len(ko["stops"]), "| quests", len(ko["quests"]))
