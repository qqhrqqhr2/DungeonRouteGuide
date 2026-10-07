-- Minimal WoW API stubs to smoke-test Dungeon Route Guide outside the game.
local ADDON_DIR = ...
local chat = {}
local function mock(name)
  local o = { _name = name, _shown = false, _points = { { "CENTER", nil, "CENTER", 0, 0 } }, _scripts = {} }
  return setmetatable(o, { __index = function(t, k)
    local f = rawget(_G, "MOCK_" .. k)
    if f then return f end
    return function() return nil end
  end })
end
MOCK_Show = function(s) s._shown = true; if s._scripts.OnShow then s._scripts.OnShow(s) end end
MOCK_Hide = function(s) s._shown = false; if s._scripts.OnHide then s._scripts.OnHide(s) end end
MOCK_SetShown = function(s, v) if v then s:Show() else s:Hide() end end
MOCK_IsShown = function(s) return s._shown end
MOCK_SetScript = function(s, k, f) s._scripts[k] = f end
MOCK_GetScript = function(s, k) return s._scripts[k] end
MOCK_GetPoint = function(s, i) local p = s._points[i or 1]; if p then return p[1], p[2], p[3], p[4], p[5] end end
MOCK_SetPoint = function(s, ...) s._points[#s._points + 1] = { ... } end
MOCK_ClearAllPoints = function(s) s._points = {} end
MOCK_GetNumPoints = function(s) return #s._points end
MOCK_GetScale = function() return 1 end
MOCK_GetAlpha = function() return 1 end
MOCK_GetZoom = function() return 2 end
MOCK_GetZoomLevels = function() return 6 end
MOCK_GetEffectiveScale = function() return 1 end
MOCK_GetLeft = function() return 100 end
MOCK_GetTop = function() return 600 end
MOCK_GetHeight = function() return 420 end
MOCK_GetStringWidth = function() return 40 end
MOCK_GetFrameLevel = function() return 1 end
MOCK_SetText = function(s, t) s._text = t end
MOCK_GetText = function(s) return s._text end
MOCK_GetFontString = function(s) local fs = rawget(s, "_fs") or mock("fs"); rawset(s, "_fs", fs); return fs end
MOCK_CreateTexture = function() return mock("tex") end
MOCK_CreateMaskTexture = function() return mock("mask") end
MOCK_CreateFontString = function() return mock("fs") end
MOCK_CreateLine = function() return mock("line") end
MOCK_CreateAnimationGroup = function() return mock("ag") end
MOCK_CreateAnimation = function() return mock("anim") end
MOCK_RegisterEvent = function(s, e) local t = rawget(s, "_events") or {}; rawset(s, "_events", t); t[e] = true end
MOCK_GetXY = function(s) return s.x, s.y end
-- textures: remember what was set; file IDs listed in MISSING do not load
TEXSET = {}
MISSING = {}
MOCK_SetTexture = function(s, f) rawset(s, "_tex", f); TEXSET[f] = true; return not MISSING[f] end
MOCK_SetSize = function(s, w, h) rawset(s, "_w", w); rawset(s, "_h", h) end
MOCK_SetDisplayInfo = function(s, id) rawset(s, "_display", id) end

local frames = {}
function CreateFrame(kind, name, parent, template)
  local f = mock(name or kind)
  frames[#frames + 1] = f
  if name then _G[name] = f end
  return f
end
UIParent = mock("UIParent"); UIParent._shown = true
Minimap = mock("Minimap")
GameTooltip = mock("GameTooltip")
GameTooltip_Hide = function() end
DEFAULT_CHAT_FRAME = { AddMessage = function(_, m) chat[#chat + 1] = m; print("CHAT: " .. m) end }
UISpecialFrames = {}
tinsert = table.insert
SlashCmdList = {}
INSTANCE_RESET_SUCCESS = (LOCALE == "enUS") and "%s has been reset." or "%s|1이;가; 초기화되었습니다."
RESETMSG = (LOCALE == "enUS") and "Ragefire Chasm has been reset." or "성난불길 협곡이 초기화되었습니다."
RESETFAIL = (LOCALE == "enUS") and "Cannot reset Wailing Caverns. There are players still inside the instance." or "통곡의 동굴을 초기화할 수 없습니다. 인스턴스 안에 플레이어가 있습니다."
GetLocale = function() return LOCALE or "koKR" end
time = os.time
C_Timer = { NewTicker = function() end, After = function(_, f) f() end }
GetCursorPosition = function() return 300, 400 end
IsShiftKeyDown = function() return SHIFT end
InCombatLockdown = function() return false end
UnitLevel = function() return PLEVEL or 20 end
UnitFactionGroup = function() return FACTION or "Horde" end
PlaySound = function() end
RaidNotice_AddMessage = function(_, m) print("RAIDWARN: " .. m) end
RaidWarningFrame = {}
ChatTypeInfo = { RAID_WARNING = {} }
SOUNDKIT = { RAID_WARNING = 8959 }
IsInGroup = function() return INGROUP end
LE_PARTY_CATEGORY_INSTANCE = 2
SendChatMessage = function(m, ch) print("SEND[" .. ch .. "]: " .. m) end
CreateVector2D = function(x, y) return setmetatable({ x = x, y = y }, { __index = { GetXY = function(s) return s.x, s.y end } }) end

INSTANCE = { nil, "none", nil, nil, nil, nil, nil, 0 }
GetInstanceInfo = function() return unpack(INSTANCE, 1, 8) end
SUBZONE = ""
GetSubZoneText = function() return SUBZONE end
GetMinimapZoneText = function() return SUBZONE end
GetZoneText = function() return "zone" end
UNITS = {}
UnitGUID = function(u) return UNITS[u] and UNITS[u].guid end
UnitIsDead = function(u) return UNITS[u] and UNITS[u].dead or false end
UnitName = function(u) return UNITS[u] and UNITS[u].name end
UnitClassification = function(u) return UNITS[u] and UNITS[u].class or "normal" end
SECRET = {}
issecretvalue = function(v) return SECRET[v] == true end
GetNumLootItems = function() return LOOTN or 0 end
GetLootSourceInfo = function(slot) return LOOTSRC and LOOTSRC[slot], 1 end
QUESTS = { [5723] = "done", [5728] = "active" }
C_QuestLog = {
  IsQuestFlaggedCompleted = function(id) return QUESTS[id] == "done" end,
  IsOnQuest = function(id) return QUESTS[id] == "active" end,
}
-- outdoor map stubs: player in Orgrimmar 1454 at (50,50); facing west
C_Map = {
  GetBestMapForUnit = function() return PMAP end,
  GetPlayerMapPosition = function(map) if PMAP then return CreateVector2D(PX, PY) end end,
  GetWorldPosFromMapPos = function(map, v) return 1, CreateVector2D(v.x * 1000, v.y * 1000) end,
  GetMapPosFromWorldPos = function(cont, wp, map) return map, CreateVector2D(wp.x / 1000, wp.y / 1000) end,
  GetMapWorldSize = function() return 1000, 700 end,
  GetMapInfo = function(id) return { name = "Map" .. id } end,
}
GetPlayerFacing = function() return FACING end
C_Item = {
  GetItemInfo = function(id) if id % 2 == 0 then return "Item" .. id, "|cff0070dd|Hitem:" .. id .. "|h[Item]|h|r", 3, 20, 15, "Armor", "Cloth", 1, "INVTYPE_WAIST", 133000 + id end end,
  GetItemIconByID = function(id) return 134400 end,
  RequestLoadItemDataByID = function(id) REQUESTED = (REQUESTED or 0) + 1 end,
}
ITEM_QUALITY_COLORS = { [3] = { r = 0, g = 0.44, b = 0.87, hex = "|cff0070dd" } }

-- load addon files in toc order
local ns = {}
local toc = io.open(ADDON_DIR .. "/DungeonRouteGuide.toc"):read("*a")
for file in toc:gmatch("\n([%w_]+%.lua)") do
  local chunk = assert(loadfile(ADDON_DIR .. "/" .. file))
  chunk("DungeonRouteGuide", ns)
end

local evframe
for _, f in ipairs(frames) do local ev = rawget(f, "_events"); if ev and ev.PLAYER_LOGIN then evframe = f end end
local function Fire(e, ...) evframe._scripts.OnEvent(evframe, e, ...) end
local function Slash(s) print("> /drg " .. s); SlashCmdList.DUNGEONROUTEGUIDE(s) end
local function Check(cond, msg) if not cond then error("CHECK FAILED: " .. msg, 2) end print("ok  " .. msg) end

Fire("ADDON_LOADED", "DungeonRouteGuide")
Fire("PLAYER_LOGIN")
ns.db.debug = true
Fire("PLAYER_ENTERING_WORLD")
Check(ns.state.current == nil, "outside: no dungeon")

-- screen icon outside a dungeon: opens level-appropriate guide
Check(DungeonRouteGuideIcon ~= nil and DungeonRouteGuideIcon:IsShown(), "icon created and shown")
DungeonRouteGuideIcon._scripts.OnEnter(DungeonRouteGuideIcon)
DungeonRouteGuideIcon._scripts.OnClick(DungeonRouteGuideIcon, "LeftButton")
Check(DungeonRouteGuideFrame:IsShown() and ns.state.viewed.key == "wc", "icon opens WC for level 20")
DungeonRouteGuideIcon._scripts.OnClick(DungeonRouteGuideIcon, "LeftButton")
Check(not DungeonRouteGuideFrame:IsShown(), "icon closes map")
DungeonRouteGuideIcon._scripts.OnClick(DungeonRouteGuideIcon, "RightButton")
Check(ns.EntranceActive(), "icon right-click starts entrance guide")
DungeonRouteGuideIcon._scripts.OnClick(DungeonRouteGuideIcon, "RightButton")
Check(not ns.EntranceActive(), "icon right-click stops entrance guide")
Slash("icon"); Check(not DungeonRouteGuideIcon:IsShown(), "/drg icon hides")
Slash("icon"); Check(DungeonRouteGuideIcon:IsShown(), "/drg icon shows")
ns.state.viewed = nil

-- every dungeon / tab renders without errors (outside, browse mode)
for _, tab in ipairs({ "route", "quest", "notes" }) do
  ns.db.listTab = tab
  for _, dd in ipairs(ns.Dungeons) do ns.ShowMap(dd); ns.RefreshMap() end
end
Check(#ns.Dungeons == 18, "18 dungeons loaded")
local wcd = ns.DungeonByKey.wc
Check(wcd.steps[3].loot and #wcd.steps[3].loot > 0, "Cobrahn has loot")
ns.ShowMap(wcd); ns.state.selected = 3; ns.db.listTab = "route"; ns.RefreshMap()
Check((REQUESTED or 0) > 0, "uncached items requested from the client")
Fire("GET_ITEM_INFO_RECEIVED", 6460, true)
ns.db.listTab = "notes"; ns.RefreshMap()
Check(wcd.trash and #wcd.trash > 0, "trash loot listed")
ns.state.selected = nil
-- boss card: 3D model of the selected boss
local model
for _, f in ipairs(frames) do if f._name == "PlayerModel" then model = f end end
Check(model ~= nil, "boss card model created")
ns.state.selected = 3; ns.RefreshMap()
Check(rawget(model, "_display") == wcd.steps[3].model and wcd.steps[3].model ~= nil, "Cobrahn 3D model shown")
Check(ns.state.pageGeo == wcd, "WC uses Atlas (no Blizzard positions)")
local bfd = ns.DungeonByKey.bfd
ns.ShowMap(bfd); ns.db.listTab = "route"; ns.RefreshMap()
Check(#bfd.pages == 3, "BFD has 3 Atlas pages")
Check(bfd.bliz and #bfd.bliz.pages == 3 and ns.state.pageGeo == bfd.bliz, "BFD shows 3 Blizzard pages")
Check(TEXSET[bfd.bliz.pages[1].tiles[1][1]], "Blizzard tiles set by file ID")
ns.state.page, ns.state.pageManual = "3", true; ns.RefreshMap()
-- area dropdown for dungeons with several maps
local gn = ns.DungeonByKey.gnomer
ns.ShowMap(gn); ns.state.page, ns.state.pageManual = "4", true; ns.RefreshMap()
local fb, fn, fl, frows = ns.AreaWidgets()
Check(fb:IsShown() and fb.text._text:find("4/4") ~= nil, "area dropdown shows 4/4")
Check(fn:IsShown() and fn.key == "1", "next-objective link points to area 1")
fb._scripts.OnClick(fb); Check(fl:IsShown(), "area list opens")
frows[2]._scripts.OnClick(frows[2]); Check(ns.state.page == "2" and not fl:IsShown(), "pick area 2")
fn._scripts.OnClick(fn); Check(ns.state.page == "1" and not fn:IsShown(), "jump to next objective area")
-- floor link: area name under the arrow, click opens that area
ns.state.page, ns.state.pageManual = "1", true; ns.RefreshMap()
local lk
for _, f in ipairs(frames) do if rawget(f, "toPage") == "2" and f:IsShown() then lk = f end end
Check(lk and lk.name._text == (ns.locale == "ko" and "거주 지구" or "The Dormitory"), "link shows where it leads")
lk._scripts.OnClick(lk); Check(ns.state.page == "2", "clicking a link opens that area")
ns.ShowMap(ns.DungeonByKey.rfc); ns.RefreshMap()
Check(not fb:IsShown(), "single-map dungeon: no dropdown")
-- floor follows the sub-zone you stand in
INSTANCE = { "놈리건", "party", 1, "", 5, 0, false, 90 }
SUBZONE = "톱니바퀴의 전당"
Fire("PLAYER_ENTERING_WORLD")
Check(ns.state.current == gn and ns.state.shownPage == "1", "Gnomeregan: Hall of Gears -> area 1")
SUBZONE = "땜장이 왕실"; Fire("ZONE_CHANGED_INDOORS")
Check(ns.state.shownPage == "4", "Tinkers' Court -> area 4")
ns.state.page, ns.state.pageManual = "2", true; ns.RefreshMap()
Check(ns.state.shownPage == "2", "picked by hand stays")
SUBZONE = "출격실"; Fire("ZONE_CHANGED_INDOORS")
Check(ns.state.shownPage == "2" or ns.state.shownPage == "3", "Launch Bay (areas 2/3) -> one of them")
SUBZONE = "Echomok"; Fire("ZONE_CHANGED_INDOORS")
INSTANCE = { nil, "none", nil, nil, nil, nil, nil, 0 }; SUBZONE = ""
Fire("ZONE_CHANGED_NEW_AREA")
DungeonRouteGuideFrame:Hide()
-- client without the art: falls back to Atlas
local smgy = ns.DungeonByKey.smgy
for _, set in ipairs(smgy.bliz.pages[1].tiles) do MISSING[set[1]] = true end
Slash("map blizzard")
ns.ShowMap(smgy); ns.RefreshMap()
Check(ns.state.pageGeo == smgy, "missing Blizzard art -> Atlas")
for _, set in ipairs(smgy.bliz.pages[1].tiles) do MISSING[set[1]] = nil end
MISSING[smgy.bliz.pages[1].tiles[1][1]] = true
Slash("map blizzard")
ns.ShowMap(smgy); ns.RefreshMap()
Check(ns.state.pageGeo == smgy.bliz and smgy.bliz.pages[1].set == smgy.bliz.pages[1].tiles[2], "second tile set used when the first is missing")
MISSING = {}
ns.ShowMap(ns.DungeonByKey.dala); ns.RefreshMap()
Check(#ns.DungeonByKey.dala.pages == 0, "Dalaran list-only")
DungeonRouteGuideFrame:Hide()
ns.state.viewed = nil

-- enter RFC
INSTANCE = { "성난불길 협곡", "party", 1, "", 5, 0, false, 389 }
Fire("PLAYER_ENTERING_WORLD")
Check(ns.state.current and ns.state.current.key == "rfc", "RFC detected by instance id")
Check(DungeonRouteGuideFrame:IsShown(), "map auto-opened")
Check(DungeonRouteGuideHUD:IsShown(), "HUD shown")
local d = ns.state.current
local OGG, CORPSE, TAR, BAZ, JER = 2, 3, 5, 6, 7
Check(ns.NextStep(d) == OGG, "next = Oggleflint (junction notes skipped)")
local _, tot = ns.Counts(d); Check(tot == 4, "4 bosses counted")

UNITS.target = { guid = "Creature-0-1-2-3-11517-00001", dead = true, name = "오글플린트" }
Fire("PLAYER_TARGET_CHANGED")
Check(ns.IsDone(d, OGG), "Oggleflint auto-checked via dead target")
Check(ns.NextStep(d) == CORPSE, "next = quest corpse")
Fire("ENCOUNTER_END", 1444, "욕망의 타라가만", 1, 5, 1)
Check(ns.IsDone(d, TAR), "Taragaman via ENCOUNTER_END name")
Check(ns.IsDone(d, CORPSE), "corpse auto-completed after later boss")
local secretGuid = "Creature-0-1-2-3-11518-00009"
SECRET[secretGuid] = true
UNITS.nameplate3 = { guid = secretGuid, dead = true }
Fire("UNIT_HEALTH", "nameplate3")
Check(not ns.IsDone(d, JER), "secret GUID ignored")
-- name-only detection (unknown id)
UNITS.nameplate4 = { guid = "Creature-0-1-2-3-99999-1", dead = true, name = "기원사 제로쉬" }
Fire("UNIT_HEALTH", "nameplate4")
Check(ns.IsDone(d, JER), "Jergosh detected by name")
Check((DungeonRouteGuideHUD.line._text:find("바잘란") or DungeonRouteGuideHUD.line._text:find("Bazzalan")) ~= nil, "HUD shows next: Bazzalan")

-- skipped boss: the next objective moves past it
local rfk = ns.DungeonByKey.rfk
ns.char.progress = { key = "rfk", done = { s2 = true, s3 = true, s4 = true }, history = { "s2", "s3", "s4" }, lastSeen = time() }
Check(ns.NextStep(rfk) == 10, "skipped Roogug: next = nearest step ahead (Heralath)")
Check(ns.IsSkipped(rfk, 1), "Roogug marked skipped")
-- out of order: Agathelos (far west) first -> next is what is near him
ns.char.progress = { key = "rfk", done = {}, history = {}, lastSeen = time() }
ns.SetDone(rfk, 7, true)
Check(not ns.IsDone(rfk, 6) or rfk.steps[6].kind == "rare", "out-of-order kill does not tick far steps")
Check(ns.NextStep(rfk) == 11 or ns.NextStep(rfk) == 8, "next after Agathelos is a nearby step")
Check(ns.NextStep(rfk) ~= 1, "not sent back to boss 1")
ns.char.progress = { key = "rfk", done = { s2 = true, s3 = true, s4 = true, s7 = true, s9 = true, s10 = true, s11 = true }, lastSeen = time() }
Check(ns.NextStep(rfk) == 1, "after the last boss the skipped one comes back")
ns.char.progress = { key = "rfc", done = { s2 = true, s5 = true, s7 = true, s3 = true }, lastSeen = time() }
Slash("next"); Check(ns.IsDone(d, BAZ), "/drg next")
Slash("undo"); Check(not ns.IsDone(d, BAZ), "/drg undo")
INGROUP = true
Slash(""); Check(not DungeonRouteGuideFrame:IsShown(), "toggle hides")
Slash(""); Check(DungeonRouteGuideFrame:IsShown(), "toggle shows")
ns.Announce()
UNITS.target = nil
UNITS.party2target = { guid = "Creature-0-1-2-3-11519-00042", dead = true }
Fire("PLAYER_REGEN_DISABLED"); Fire("PLAYER_REGEN_ENABLED")
Check(ns.IsDone(d, BAZ), "Bazzalan caught by combat-end sweep")
Slash("undo"); UNITS.party2target = nil
UNITS.mouseover = { guid = "Creature-0-1-2-3-11519-00042", dead = true }
Fire("UPDATE_MOUSEOVER_UNIT")
Check(ns.IsDone(d, BAZ), "Bazzalan caught by mouseover corpse")
Slash("undo"); UNITS.mouseover = nil
Slash("size 460"); Slash("alpha 50"); Check(ns.db.alpha == 0.5, "alpha 50 -> 0.5")
Slash("edit")
ns.state.selected = BAZ
ns.EditClick("LeftButton")
Check(ns.db.routes.rfc.s6.bpos[1] == math.floor((300 - 100) / (460 / 652) + 8 + 0.5), "edit moves marker (Blizzard map)")
Slash("export")
ns.EditClick("RightButton")
Check(ns.db.routes.rfc.s6.bpos == nil, "edit clear")
Slash("map atlas")
Check(ns.state.pageGeo == d, "/drg map atlas")
ns.EditClick("LeftButton")
Check(ns.db.routes.rfc.s6.pos[1] == math.floor((300 - 100) / (460 / 512) + 0.5), "edit moves marker (Atlas)")
ns.EditClick("RightButton")
Slash("map blizzard")
Check(ns.state.pageGeo == d.bliz, "/drg map blizzard")
Slash("edit")
ns.db.listTab = "quest"; ns.RefreshMap()
ns.db.listTab = "notes"; ns.RefreshMap()
ns.db.listTab = "route"
ns.CycleViewed(1); Check(ns.state.viewed.key == "thanes", "cycle to next dungeon")
ns.CycleViewed(-1)
Slash("reset")
Slash("debug")
Slash("donate"); Check(DungeonRouteGuideDonate:IsShown() and DungeonRouteGuideDonate.box._text == ns.DONATE_URL, "/drg donate shows the link")
DungeonRouteGuideDonate:Hide()

for _ = 1, 6 do Slash("next") end; local dn, tt = ns.Counts(d); Check(dn == tt, "run finished")
INSTANCE = { nil, "none", nil, nil, nil, nil, nil, 0 }
Fire("ZONE_CHANGED_NEW_AREA")
Check(ns.state.current == nil, "left dungeon")
INSTANCE = { "성난불길 협곡", "party", 1, "", 5, 0, false, 389 }
Fire("PLAYER_ENTERING_WORLD")
Check(select(1, ns.Counts(d)) == 0, "finished run resets on re-entry")
UNITS.target = { guid = "Creature-0-1-389-777-11517-1", dead = true }
Fire("PLAYER_TARGET_CHANGED")
Check(ns.IsDone(d, OGG), "boss done in copy 777")
INSTANCE = { nil, "none", nil, nil, nil, nil, nil, 0 }; Fire("ZONE_CHANGED_NEW_AREA")
INSTANCE = { "성난불길 협곡", "party", 1, "", 5, 0, false, 389 }; Fire("PLAYER_ENTERING_WORLD")
Check(ns.IsDone(d, OGG), "partial run kept on quick re-entry")
UNITS.nameplate5 = { guid = "Creature-0-1-389-777-9999-2" }
Fire("NAME_PLATE_UNIT_ADDED", "nameplate5")
Check(ns.IsDone(d, OGG), "same instance copy keeps progress")
UNITS.nameplate6 = { guid = "Creature-0-1-389-888-9999-3" }
Fire("NAME_PLATE_UNIT_ADDED", "nameplate6")
Check(not ns.IsDone(d, OGG), "new instance copy resets progress")
UNITS.target = { guid = "Creature-0-1-389-888-11517-1", dead = true }
Fire("PLAYER_TARGET_CHANGED")
UNITS.target = nil
INSTANCE = { nil, "none", nil, nil, nil, nil, nil, 0 }
Fire("ZONE_CHANGED_NEW_AREA")
Check(ns.IsDone(d, OGG), "progress kept after leaving")
Fire("CHAT_MSG_SYSTEM", RESETMSG)
Check(not ns.IsDone(d, OGG), "reset message clears progress")
Fire("CHAT_MSG_SYSTEM", RESETFAIL)
Check(not DungeonRouteGuideHUD:IsShown(), "HUD hidden outside")

-- SM wings by sub-zone
FACTION = "Alliance"
INSTANCE = { "붉은십자군 수도원", "party", 1, "", 5, 0, false, 189 }
SUBZONE = "명예의 무덤"
Fire("PLAYER_ENTERING_WORLD")
Check(ns.state.current and ns.state.current.key == "smgy", "SM graveyard detected")
local _, total = ns.Counts(ns.state.current)
Check(total == 2, "graveyard bosses = 2")
UNITS.nameplate1 = { guid = "Creature-0-1-2-3-6490-0001", class = "rare" }
Fire("NAME_PLATE_UNIT_ADDED", "nameplate1")
Check(ns.state.rareSeen[6490], "rare alert fired")
INSTANCE = { nil, "none", nil, nil, nil, nil, nil, 0 }; Fire("ZONE_CHANGED_NEW_AREA")
SUBZONE = "십자군 예배당"
INSTANCE = { "붉은십자군 수도원", "party", 1, "", 5, 0, false, 189 }; Fire("PLAYER_ENTERING_WORLD")
Check(ns.state.current and ns.state.current.key == "smcath", "SM cathedral detected")
INSTANCE = { nil, "none", nil, nil, nil, nil, nil, 0 }; Fire("ZONE_CHANGED_NEW_AREA")
INSTANCE = { "검은심연의 나락", "party", 1, "", 5, 0, false, 48 }; Fire("PLAYER_ENTERING_WORLD")
Check(ns.state.current and ns.state.current.key == "bfd", "BFD detected")
INSTANCE = { nil, "none", nil, nil, nil, nil, nil, 0 }; Fire("ZONE_CHANGED_NEW_AREA")

-- entrance arrow outdoors
FACING = 0; PMAP = 1454; PX, PY = 0.62, 0.49
ns.StartEntrance(ns.DungeonByKey.rfc)
local arrow = DungeonRouteGuideArrow
arrow._scripts.OnUpdate(arrow, 1)
print("arrow text: " .. tostring(arrow.text._text))
Check((arrow.text._text:find("서") or arrow.text._text:find("W,")) ~= nil, "entrance is to the west")
Slash("entrance set")
Check(math.abs(ns.db.entrances.rfc.x - 62) < 0.01, "entrance saved")
Slash("go stop")
Slash("help")
-- language switching
ns.ShowMap(ns.DungeonByKey.wc)
Slash("lang en"); Check(ns.locale == "en" and ns.L.TAB_ROUTE == "Route" and ns.T(ns.DungeonByKey.wc.name) == "Wailing Caverns", "switch to English")
Slash("lang ko"); Check(ns.locale == "ko" and ns.L.TAB_ROUTE == "경로", "switch to Korean")
Slash("lang"); Check(ns.db.lang == "en", "cycle ko -> en")
Slash("lang auto"); Check(ns.db.lang == "auto", "back to auto")
print("\nALL CHECKS PASSED")
