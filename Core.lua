-- Dungeon Route Guide - core: saved data, dungeon detection, progress,
-- automatic kill detection, rare alerts, slash commands.
local ADDON, ns = ...
local L, T = ns.L, ns.T

ns.state = {
  current = nil,    -- dungeon the player is inside (nil outside)
  viewed = nil,     -- dungeon shown in the window
  selected = nil,   -- step index selected in the list (for tips / edit mode)
  targetStep = nil, -- step index matching the current target
  rareSeen = {},
  edit = false,
  inCombat = false,
}
local state = ns.state

local DEFAULTS = {
  alpha = 0.9, combatFade = true, combatAlpha = 0.35,
  mapSize = 380, showList = true, listTab = "route",
  locked = false, autoOpen = true, hud = true, rareAlert = true, showIcon = true,
  routes = {}, entrances = {}, frames = {},
}

local function ApplyDefaults(db, defaults)
  for k, v in pairs(defaults) do
    if db[k] == nil then
      if type(v) == "table" then db[k] = {}; ApplyDefaults(db[k], v) else db[k] = v end
    elseif type(v) == "table" and type(db[k]) == "table" then
      ApplyDefaults(db[k], v)
    end
  end
end

function ns.InitDB()
  DungeonRouteGuideDB = DungeonRouteGuideDB or {}
  ApplyDefaults(DungeonRouteGuideDB, DEFAULTS)
  DungeonRouteGuideCharDB = DungeonRouteGuideCharDB or {}
  DungeonRouteGuideCharDB.progress = DungeonRouteGuideCharDB.progress or { done = {}, lastSeen = 0 }
  ns.db = DungeonRouteGuideDB
  ns.char = DungeonRouteGuideCharDB
end

---------------------------------------------------------------------------
-- Step helpers (with user route edits applied)
---------------------------------------------------------------------------
local function Edits(d, step, create)
  local r = ns.db.routes[d.key]
  if not r and create then r = {}; ns.db.routes[d.key] = r end
  if not r then return end
  local e = r[step.id]
  if not e and create then e = {}; r[step.id] = e end
  return e
end
ns.Edits = Edits

function ns.StepPos(d, i)
  local step = d.steps[i]
  local e = Edits(d, step)
  return (e and e.pos) or step.pos
end

-- Steps that form the route (and the "next" objective): not optional, not
-- a junction note. Bosses among them count toward progress.
function ns.IsMain(step)
  return not step.optional and step.kind ~= "fork" and ns.StepVisible(step)
end

function ns.Counts_IsBoss(step)
  return step.kind == "boss" and not step.optional and ns.StepVisible(step)
end

function ns.StepVisible(step)
  if not step.faction then return true end
  local f = ns.Str(ns.Safe(UnitFactionGroup, "player"))
  return not f or f == step.faction
end

-- Points of the route segment that ends at step i: origin, waypoints, pos.
function ns.StepSegment(d, i)
  local step = d.steps[i]
  if not ns.IsMain(step) or not step.pos then return nil end
  local origin = step.from
  if not origin then
    for j = i - 1, 1, -1 do
      local s = d.steps[j]
      if ns.IsMain(s) and s.pos then
        if s.page == step.page then origin = ns.StepPos(d, j) end
        break
      end
    end
  end
  if not origin and d.start and d.start.page == step.page then
    local first = true
    for j = 1, i - 1 do
      local s = d.steps[j]
      if ns.IsMain(s) and s.pos then first = false; break end
    end
    if first then origin = d.start.pos end
  end
  if not origin then return nil end
  local e = Edits(d, step)
  local path = (e and e.path) or step.path or {}
  local pts = { origin }
  for _, p in ipairs(path) do pts[#pts + 1] = p end
  pts[#pts + 1] = ns.StepPos(d, i)
  return pts
end

---------------------------------------------------------------------------
-- Progress
---------------------------------------------------------------------------
local function Progress(d)
  local p = ns.char.progress
  if p.key ~= d.key then
    p.key = d.key; p.done = {}; p.history = {}; p.lastSeen = time()
  end
  return p
end

function ns.IsDone(d, i)
  local p = ns.char.progress
  return p.key == d.key and p.done[d.steps[i].id] == true
end

function ns.Counts(d)
  local total, done = 0, 0
  for i, step in ipairs(d.steps) do
    if ns.Counts_IsBoss(step) then
      total = total + 1
      if ns.IsDone(d, i) then done = done + 1 end
    end
  end
  return done, total
end

function ns.NextStep(d)
  if not d then return end
  local done, total = ns.Counts(d)
  if total > 0 and done >= total then return end
  for i, step in ipairs(d.steps) do
    if ns.IsMain(step) and not ns.IsDone(d, i) then return i end
  end
end

function ns.SetDone(d, i, value, auto)
  local p = Progress(d)
  local step = d.steps[i]
  if (p.done[step.id] == true) == (value and true or false) then return end
  p.done[step.id] = value and true or nil
  p.lastSeen = time()
  if value then
    p.history = p.history or {}
    p.history[#p.history + 1] = step.id
  end
  if value then
    -- Non-boss steps (talks, objects, tasks) before a defeated boss are
    -- behind the group already.
    if step.kind == "boss" then
      for j = 1, i - 1 do
        local s = d.steps[j]
        if s.kind ~= "boss" and s.kind ~= "rare" and not s.optional then p.done[s.id] = true end
      end
    end
    if auto then
      local done, total = ns.Counts(d)
      ns.Print(L.KILLED:format(T(step.name), done, total))
      if done >= total then ns.Print("|cff55ff55" .. L.DONE_ALL .. "|r") end
    end
  end
  ns.RefreshAll()
end

function ns.ResetProgress(d)
  d = d or state.current or state.viewed
  if not d then return end
  local p = ns.char.progress
  p.key = d.key; p.done = {}; p.lastSeen = time()
  state.rareSeen = {}
  ns.Print(L.RESET_DONE)
  ns.RefreshAll()
end

function ns.MarkNext()
  local d = state.current or state.viewed
  local i = ns.NextStep(d)
  if i then ns.SetDone(d, i, true) end
end

-- Undo the most recently checked step (falls back to the last one in order).
function ns.Undo()
  local d = state.current or state.viewed
  if not d then return end
  local p = ns.char.progress
  if p.key == d.key and p.history then
    while #p.history > 0 do
      local id = table.remove(p.history)
      for i, step in ipairs(d.steps) do
        if step.id == id and ns.IsDone(d, i) then ns.SetDone(d, i, false); return end
      end
    end
  end
  for i = #d.steps, 1, -1 do
    if ns.IsDone(d, i) then ns.SetDone(d, i, false); return end
  end
end

---------------------------------------------------------------------------
-- Dungeon detection
---------------------------------------------------------------------------
local function ListHas(list, value)
  if not list or not value then return false end
  for _, v in ipairs(list) do if v == value then return true end end
  return false
end

local function NameMatches(d, name)
  if not name or not d.nameMatch then return false end
  for _, frag in ipairs(d.nameMatch) do
    if name:find(frag, 1, true) then return true end
  end
  return false
end

function ns.InstanceInfo()
  local name, itype, _, _, _, _, _, iid = ns.Safe(GetInstanceInfo)
  return ns.Str(name), ns.Str(itype), ns.Num(iid)
end

function ns.DetectDungeon()
  local name, itype, iid = ns.InstanceInfo()
  if not itype or itype == "none" then return nil end
  local byID, byName = {}, {}
  for _, d in ipairs(ns.Dungeons) do
    if ListHas(d.instanceIDs, iid) then byID[#byID + 1] = d end
    if NameMatches(d, name) then byName[#byName + 1] = d end
  end
  if #byName == 1 then return byName[1] end
  local list = #byID > 0 and byID or byName
  if #list <= 1 then return list[1] end
  -- Several wings share one instance: decide by sub-zone.
  local zones = { ns.Str(ns.Safe(GetSubZoneText)), ns.Str(ns.Safe(GetMinimapZoneText)), ns.Str(ns.Safe(GetZoneText)) }
  for _, d in ipairs(list) do
    for _, z in ipairs(zones) do
      if z and z ~= "" and ListHas(d.subzones, z) then return d end
    end
  end
  if state.current and ListHas(list, state.current) then return state.current end
  return list[1]
end

local function EnterDungeon(d)
  local p = ns.char.progress
  local stale = (time() - (p.lastSeen or 0)) > 30 * 60
  local finished = false
  if p.key == d.key then
    local done, total = ns.Counts(d)
    finished = total > 0 and done >= total
  end
  if p.key ~= d.key or stale or finished then
    p.key = d.key; p.done = {}; p.zone = nil
    state.rareSeen = {}
    ns.Print(L.NEW_RUN:format(T(d.name)))
  end
  p.lastSeen = time()
  state.current = d
  state.viewed = d
  state.selected = nil
  if ns.StopEntranceIfInside then ns.StopEntranceIfInside() end
  if ns.db.autoOpen and ns.ShowMap then ns.ShowMap(d, true) end
end

local function LeaveDungeon()
  ns.char.progress.lastSeen = time()
  state.current = nil
  state.targetStep = nil
  if ns.HideMapIfAuto then ns.HideMapIfAuto() end
end

function ns.UpdateLocation()
  local d = ns.DetectDungeon()
  if d ~= state.current then
    if state.current and not d then LeaveDungeon()
    elseif d then EnterDungeon(d) end
  end
  if not d then
    local _, itype = ns.InstanceInfo()
    if itype == "party" and not state.warnedUnknown then
      state.warnedUnknown = true
      ns.Print(L.NOT_SUPPORTED)
    end
  else
    state.warnedUnknown = nil
  end
  ns.RefreshAll()
end

---------------------------------------------------------------------------
-- Instance reset message ("<dungeon> has been reset.") seen in chat while
-- outside: forget that dungeon's progress so the next entry starts fresh.
---------------------------------------------------------------------------
local resetPattern
local function ResetPattern()
  if resetPattern ~= nil then return resetPattern end
  resetPattern = false
  local g = ns.Str(INSTANCE_RESET_SUCCESS)
  if g then
    g = g:gsub("|1[^;]*;[^;]*;", "\1")           -- Korean particle switch
    g = g:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
    g = g:gsub("%%%%s", "(.+)"):gsub("\1", ".-")
    resetPattern = "^" .. g .. "$"
  end
  return resetPattern
end

local function DungeonsInText(text)
  local found = {}
  for _, d in ipairs(ns.Dungeons) do
    local names = { d.name.ko, d.name.en }
    for _, n in ipairs(d.resetNames or {}) do names[#names + 1] = n end
    for _, n in ipairs(names) do
      if n and text:find(n, 1, true) then found[#found + 1] = d; break end
    end
  end
  return found
end

local function OnSystemMessage(msg)
  msg = ns.Str(msg)
  if not msg then return end
  local list
  local pat = ResetPattern()
  if pat then
    local name = msg:match(pat)
    if name then list = DungeonsInText(name) end
  elseif msg:find("초기화되었습니다", 1, true) or msg:find("has been reset", 1, true) then
    list = DungeonsInText(msg)
  end
  if not list or #list == 0 then return end
  local p = ns.char.progress
  for _, d in ipairs(list) do
    if p.key == d.key then p.done = {}; p.zone = nil; p.lastSeen = 0 end
  end
  ns.Print(L.RESET_SEEN:format(T(list[1].name)))
  ns.RefreshAll()
end

---------------------------------------------------------------------------
-- Kill detection
---------------------------------------------------------------------------
local function StepByNpc(d, npc)
  if not d or not npc then return end
  for i, step in ipairs(d.steps) do
    if step.npc then
      for _, id in ipairs(step.npc) do if id == npc then return i, step end end
    end
  end
end
ns.StepByNpc = StepByNpc

local function StepByName(d, name)
  local n = ns.Normalize(name)
  if not d or not n then return end
  for i, step in ipairs(d.steps) do
    for _, v in pairs(step.name) do
      if ns.Normalize(v) == n then return i, step end
    end
  end
end

local function Killed(npc, name)
  local d = state.current
  local i, step = StepByNpc(d, npc)
  if not i and name then i, step = StepByName(d, name) end
  if i and (step.kind == "boss" or step.kind == "rare") and not ns.IsDone(d, i) then ns.SetDone(d, i, true, true) end
end

local function CheckUnitDeath(unit)
  if not state.current then return end
  if not ns.True(ns.Safe(UnitIsDead, unit)) then return end
  Killed(ns.UnitNpcID(unit), ns.Str(ns.Safe(UnitName, unit)))
end

-- A creature from a different instance copy means the dungeon was reset:
-- start the run over even if we re-entered within 30 minutes.
local function NoteInstance(unit)
  local d = state.current
  if not d then return end
  local zone = ns.InstanceUIDFromGUID(ns.Safe(UnitGUID, unit))
  if not zone then return end
  local p = ns.char.progress
  if p.key ~= d.key then return end
  if p.zone and p.zone ~= zone then
    local any = false
    for _ in pairs(p.done) do any = true; break end
    p.done = {}
    state.rareSeen = {}
    if any then ns.Print(L.NEW_INSTANCE) end
    p.zone = zone
    ns.RefreshAll()
  else
    p.zone = zone
  end
end
ns.NoteInstance = NoteInstance

local WATCH_UNITS = { target = true, focus = true, mouseover = true }
local function Watched(unit)
  unit = ns.Str(unit)
  if not unit then return false end
  return WATCH_UNITS[unit] or unit:find("^nameplate%d") or unit:find("^boss%d")
end

-- Units worth re-checking when a fight ends: a boss may die while nobody
-- has it as target, so sweep everything the client still exposes.
local function SweepDeaths()
  if not state.current then return end
  CheckUnitDeath("target"); CheckUnitDeath("focus"); CheckUnitDeath("mouseover")
  for k = 1, 4 do CheckUnitDeath("party" .. k .. "target") end
  for k = 1, 5 do CheckUnitDeath("boss" .. k) end
  for k = 1, 40 do CheckUnitDeath("nameplate" .. k) end
end
ns.SweepDeaths = SweepDeaths

local function CheckLoot()
  if not state.current then return end
  local n = ns.Num(ns.Safe(GetNumLootItems))
  if not n or n < 1 or n > 100 then return end
  for slot = 1, n do
    local sources = { ns.Safe(GetLootSourceInfo, slot) }
    for k = 1, #sources, 2 do Killed(ns.NpcIDFromGUID(sources[k])) end
  end
end

local function OnEncounter(name, success)
  if not state.current then return end
  if success ~= nil and ns.Num(success) ~= 1 then return end
  local i, step = StepByName(state.current, name)
  if i and (step.kind == "boss" or step.kind == "rare") and not ns.IsDone(state.current, i) then ns.SetDone(state.current, i, true, true) end
end

---------------------------------------------------------------------------
-- Rare alerts / target tips
---------------------------------------------------------------------------
local function RareAlert(unit)
  if not ns.db.rareAlert or not state.current then return end
  local npc = ns.UnitNpcID(unit)
  if not npc or state.rareSeen[npc] then return end
  local _, step = StepByNpc(state.current, npc)
  local isRare = step and step.kind == "rare"
  if not isRare then
    local c = ns.Str(ns.Safe(UnitClassification, unit))
    isRare = (c == "rare" or c == "rareelite") and not ns.True(ns.Safe(UnitIsDead, unit))
  end
  if not isRare then return end
  state.rareSeen[npc] = true
  local name = step and T(step.name) or ns.Str(ns.Safe(UnitName, unit)) or "?"
  local msg = L.RARE_ALERT:format(name)
  ns.Print("|cffff80ff" .. msg .. "|r")
  if RaidNotice_AddMessage and RaidWarningFrame and ChatTypeInfo then
    ns.Safe(RaidNotice_AddMessage, RaidWarningFrame, msg, ChatTypeInfo["RAID_WARNING"])
  end
  ns.Safe(PlaySound, (SOUNDKIT and SOUNDKIT.RAID_WARNING) or 8959, "Master")
end

local function UpdateTarget()
  NoteInstance("target")
  local i = state.current and StepByNpc(state.current, ns.UnitNpcID("target"))
  if not i and state.current then i = StepByName(state.current, ns.Str(ns.Safe(UnitName, "target"))) end
  state.targetStep = i
  CheckUnitDeath("target")
  if ns.RefreshHUD then ns.RefreshHUD() end
end

---------------------------------------------------------------------------
-- Party call-out
---------------------------------------------------------------------------
function ns.Announce()
  local d = state.current or state.viewed
  if not d then return end
  local i = state.targetStep
  if not i or state.current ~= d or ns.IsDone(d, i) then i = ns.NextStep(d) end
  if not i then return end
  local step = d.steps[i]
  local msg = ("[%s] %s %s: %s"):format(L.TITLE, step.n, T(step.name), ns.FirstSentence(T(step.tip)))
  if #msg > 250 then msg = msg:sub(1, 247) .. "..." end
  local inInstanceGroup = LE_PARTY_CATEGORY_INSTANCE and ns.True(ns.Safe(IsInGroup, LE_PARTY_CATEGORY_INSTANCE))
  local channel = inInstanceGroup and "INSTANCE_CHAT" or (ns.True(ns.Safe(IsInGroup)) and "PARTY") or nil
  if not channel then ns.Print(msg); return end
  local send = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
  local ok = pcall(send, msg, channel)
  if not ok then ns.Print(msg) end
end

---------------------------------------------------------------------------
-- Refresh fan-out
---------------------------------------------------------------------------
function ns.RefreshAll()
  if ns.RefreshMap then ns.RefreshMap() end
  if ns.RefreshHUD then ns.RefreshHUD() end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local ev = CreateFrame("Frame")
local EVENTS = {
  "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_LOGOUT", "PLAYER_ENTERING_WORLD",
  "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS",
  "PLAYER_TARGET_CHANGED", "UNIT_HEALTH", "NAME_PLATE_UNIT_ADDED",
  "LOOT_OPENED", "ENCOUNTER_END", "BOSS_KILL", "UPDATE_MOUSEOVER_UNIT", "UNIT_TARGET", "CHAT_MSG_SYSTEM", "GET_ITEM_INFO_RECEIVED",
  "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
}
for _, e in ipairs(EVENTS) do pcall(ev.RegisterEvent, ev, e) end

local handlers = {}
handlers.ADDON_LOADED = function(name)
  if name == ADDON then ns.InitDB() end
end
handlers.PLAYER_LOGIN = function()
  if not ns.db then ns.InitDB() end
  ns.ready = true
  if ns.CreateIcon then ns.CreateIcon() end
  if C_Timer and C_Timer.NewTicker then
    C_Timer.NewTicker(30, function()
      if state.current then ns.char.progress.lastSeen = time() end
    end)
  end
end
handlers.PLAYER_LOGOUT = function()
  if state.current and ns.char then ns.char.progress.lastSeen = time() end
end
handlers.PLAYER_ENTERING_WORLD = function() ns.UpdateLocation() end
handlers.ZONE_CHANGED_NEW_AREA = handlers.PLAYER_ENTERING_WORLD
handlers.ZONE_CHANGED = function() if state.current then ns.UpdateLocation() end end
handlers.ZONE_CHANGED_INDOORS = handlers.ZONE_CHANGED
handlers.PLAYER_TARGET_CHANGED = UpdateTarget
handlers.UNIT_HEALTH = function(unit) if state.current and Watched(unit) then CheckUnitDeath(unit) end end
handlers.NAME_PLATE_UNIT_ADDED = function(unit) NoteInstance(unit); RareAlert(unit); CheckUnitDeath(unit) end
handlers.LOOT_OPENED = CheckLoot
local itemRefreshQueued = false
handlers.GET_ITEM_INFO_RECEIVED = function()
  if itemRefreshQueued or not (C_Timer and C_Timer.After) then return end
  itemRefreshQueued = true
  C_Timer.After(0.3, function() itemRefreshQueued = false; if ns.RefreshMap then ns.RefreshMap() end end)
end
handlers.CHAT_MSG_SYSTEM = OnSystemMessage
handlers.UPDATE_MOUSEOVER_UNIT = function() NoteInstance("mouseover"); CheckUnitDeath("mouseover") end
handlers.UNIT_TARGET = function(unit)
  unit = ns.Str(unit)
  if state.current and unit and unit:find("^party%d$") then CheckUnitDeath(unit .. "target") end
end
handlers.ENCOUNTER_END = function(_, name, _, _, success) OnEncounter(name, success) end
handlers.BOSS_KILL = function(_, name) OnEncounter(name, nil) end
handlers.PLAYER_REGEN_DISABLED = function()
  state.inCombat = true
  if ns.ApplyAlpha then ns.ApplyAlpha() end
end
handlers.PLAYER_REGEN_ENABLED = function()
  state.inCombat = false
  if ns.ApplyAlpha then ns.ApplyAlpha() end
  SweepDeaths()
  if C_Timer and C_Timer.After then C_Timer.After(1.5, SweepDeaths) end
end

ev:SetScript("OnEvent", function(_, event, ...)
  if not ns.db and event ~= "ADDON_LOADED" then return end
  local h = handlers[event]
  if h then
    local ok, err = pcall(h, ...)
    if not ok and ns.db and ns.db.debug then ns.Print("|cffff5555" .. event .. ": " .. tostring(err) .. "|r") end
  end
end)

---------------------------------------------------------------------------
-- Slash commands & key bindings
---------------------------------------------------------------------------
function DungeonRouteGuide_Toggle() if ns.ToggleMap then ns.ToggleMap() end end
function DungeonRouteGuide_MarkNext() ns.MarkNext() end
function DungeonRouteGuide_Announce() ns.Announce() end

local function Debug()
  local name, itype, iid = ns.InstanceInfo()
  ns.Print(("instance: %s / type: %s / id: %s"):format(tostring(name), tostring(itype), tostring(iid)))
  ns.Print(("zone: %s / sub: %s / minimap: %s"):format(tostring(ns.Str(ns.Safe(GetZoneText))),
    tostring(ns.Str(ns.Safe(GetSubZoneText))), tostring(ns.Str(ns.Safe(GetMinimapZoneText)))))
  local d = ns.DetectDungeon()
  ns.Print("detected: " .. (d and T(d.name) or "-"))
  local npc = ns.UnitNpcID("target")
  if npc then ns.Print(("target npc: %d %s"):format(npc, tostring(ns.Str(ns.Safe(UnitName, "target"))))) end
end

SLASH_DUNGEONROUTEGUIDE1 = "/drg"
SLASH_DUNGEONROUTEGUIDE2 = "/dungeonroute"
SLASH_DUNGEONROUTEGUIDE3 = "/던전길잡이"
SlashCmdList.DUNGEONROUTEGUIDE = function(msg)
  if not ns.db then ns.InitDB() end
  msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
  local cmd, rest = msg:match("^(%S*)%s*(.-)$")
  if cmd == "" then ns.ToggleMap()
  elseif cmd == "hud" then ns.db.hud = not ns.db.hud; ns.RefreshHUD()
  elseif cmd == "next" or cmd == "skip" then ns.MarkNext()
  elseif cmd == "undo" then ns.Undo()
  elseif cmd == "reset" then ns.ResetProgress()
  elseif cmd == "lock" then ns.db.locked = not ns.db.locked; ns.RefreshAll()
  elseif cmd == "alpha" then
    local v = tonumber(rest); if v then ns.db.alpha = math.max(0.2, math.min(1, v > 1 and v / 100 or v)); ns.ApplyAlpha() end
  elseif cmd == "size" then
    local v = tonumber(rest); if v then ns.db.mapSize = math.max(240, math.min(800, v)); ns.RebuildMap() end
  elseif cmd == "auto" then ns.db.autoOpen = not ns.db.autoOpen; ns.Print(L.OPT_AUTO:format(ns.OnOff(ns.db.autoOpen)))
  elseif cmd == "icon" then ns.SetIconShown(not ns.db.showIcon); ns.Print(L.OPT_ICON:format(ns.OnOff(ns.db.showIcon)))
  elseif cmd == "rare" then ns.db.rareAlert = not ns.db.rareAlert; ns.Print(L.OPT_RARE:format(ns.OnOff(ns.db.rareAlert)))
  elseif cmd == "go" then
    if rest == "stop" or rest == "off" then ns.StopEntrance() else ns.StartEntrance(ns.DungeonByKey[rest] or state.viewed) end
  elseif cmd == "entrance" and rest == "set" then ns.SaveEntranceHere()
  elseif cmd == "entrance" and rest == "clear" then
    if state.viewed then ns.db.entrances[state.viewed.key] = nil end
  elseif cmd == "edit" then ns.SetEditMode(not state.edit)
  elseif cmd == "export" then ns.ShowExport()
  elseif cmd == "debug" then Debug()
  elseif cmd == "verbose" then ns.db.debug = not ns.db.debug; ns.Print("debug " .. ns.OnOff(ns.db.debug))
  else
    ns.Print(L.HELP)
  end
end
