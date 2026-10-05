-- Dungeon Route Guide - arrow to a dungeon entrance (outdoors only).
-- Outside instances the game exposes the player's map position and facing,
-- so this is real navigation; inside dungeons it switches itself off.
local _, ns = ...
local L, T = ns.L, ns.T
local state = ns.state

local ARROW = "Interface\\Minimap\\MinimapArrow"
local f, target, acc = nil, nil, 0

local function Entrance(d)
  return (ns.db.entrances and ns.db.entrances[d.key]) or d.entrance
end

local function PlayerMapPos()
  local map = ns.Num(ns.Safe(C_Map.GetBestMapForUnit, "player"))
  if not map then return end
  local pos = ns.Safe(C_Map.GetPlayerMapPosition, map, "player")
  if not pos then return end
  local x, y = ns.Safe(pos.GetXY, pos)
  x, y = ns.Num(x), ns.Num(y)
  if not x or not y or (x == 0 and y == 0) then return end
  return map, x, y
end

local function WorldPos(map, x, y)
  if not CreateVector2D then return end
  local cont, wp = ns.Safe(C_Map.GetWorldPosFromMapPos, map, CreateVector2D(x, y))
  if not wp then return end
  return ns.Num(cont), wp
end

-- Target position expressed on the player's current map (0..1, may exceed).
local function TargetOnMap(map, e)
  if e.map == map then return e.x / 100, e.y / 100 end
  local cont, wp = WorldPos(e.map, e.x / 100, e.y / 100)
  if not wp then return end
  local _, mp = ns.Safe(C_Map.GetMapPosFromWorldPos, cont, wp, map)
  if not mp then return end
  local x, y = ns.Safe(mp.GetXY, mp)
  return ns.Num(x), ns.Num(y), cont
end

local function ZoneName(map)
  local info = ns.Safe(C_Map.GetMapInfo, map)
  return info and ns.Str(info.name) or tostring(map)
end

local function Update()
  local d = target
  if not d then return end
  local _, itype = ns.InstanceInfo()
  if itype and itype ~= "none" then
    f.arrow:Hide()
    f.text:SetText(L.ENTRANCE_INSIDE)
    return
  end
  local e = Entrance(d)
  local map, px, py = PlayerMapPos()
  if not map then
    f.arrow:Hide()
    f.text:SetText(T(e.zone) .. ("\n%.1f, %.1f"):format(e.x, e.y))
    return
  end
  local tx, ty = TargetOnMap(map, e)
  local pcont = WorldPos(map, px, py)
  local tcont = WorldPos(e.map, e.x / 100, e.y / 100)
  if not tx or (pcont and tcont and pcont ~= tcont) then
    f.arrow:Hide()
    f.text:SetText(L.ENTRANCE_OTHER:format(T(e.zone)))
    return
  end
  local w, h = ns.Safe(C_Map.GetMapWorldSize, map)
  w, h = ns.Num(w), ns.Num(h)
  if not w or not h or w == 0 or h == 0 then w, h = 1500, 1000 end
  local east, south = (tx - px) * w, (ty - py) * h
  local dist = math.sqrt(east * east + south * south)
  if dist < 12 then
    f.arrow:Hide()
    f.text:SetText("|cff55ff55" .. L.ENTRANCE_ARRIVE .. "|r")
    return
  end
  -- Angle counter-clockwise from north, same convention as GetPlayerFacing.
  local angle = math.atan2(-east, -south)
  local facing = ns.Num(ns.Safe(GetPlayerFacing))
  if facing then
    f.arrow:SetRotation(angle - facing)
    f.arrow:Show()
  else
    f.arrow:Hide()
  end
  local idx = math.floor((angle % (2 * math.pi)) / (2 * math.pi) * 8 + 0.5) % 8
  f.text:SetText(L.DIST:format(L["DIR_" .. idx], math.floor(dist + 0.5)))
end

local function Create()
  f = CreateFrame("Frame", "DungeonRouteGuideArrow", UIParent, "BackdropTemplate")
  f:SetSize(170, 112)
  if f.SetBackdrop then
    f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    f:SetBackdropColor(0, 0, 0, 0.5)
    f:SetBackdropBorderColor(0.65, 0.52, 0.22, 0.7)
  end
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local p, _, rp, x, y = self:GetPoint(1)
    ns.db.frames.arrow = { p, rp, x, y }
  end)
  local pos = ns.db.frames.arrow
  if pos then f:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4]) else f:SetPoint("TOP", 0, -190) end
  f.title = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  f.title:SetPoint("TOP", 0, -5)
  f.arrow = f:CreateTexture(nil, "ARTWORK")
  f.arrow:SetTexture(ARROW)
  f.arrow:SetSize(48, 48)
  f.arrow:SetPoint("TOP", 0, -20)
  f.text = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  f.text:SetPoint("TOP", f.arrow, "BOTTOM", 0, -2)
  f.text:SetWidth(160)
  local stop = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  stop:SetSize(20, 16)
  stop:SetText("X")
  stop:SetPoint("TOPRIGHT", -2, -2)
  stop:SetScript("OnClick", function() ns.StopEntrance() end)
  f:SetScript("OnUpdate", function(_, elapsed)
    acc = acc + elapsed
    if acc < 0.1 then return end
    acc = 0
    local ok, err = pcall(Update)
    if not ok and ns.db.debug then ns.Print(err) end
  end)
end

function ns.StartEntrance(d)
  d = d or state.viewed or state.current or ns.Dungeons[1]
  if not d then return end
  if not f then Create() end
  target = d
  f.title:SetText(T(d.name))
  f:Show()
  local e = Entrance(d)
  ns.Print(L.ENTRANCE_START:format(T(d.name)) .. " " .. T(e.zone) .. (" %.1f, %.1f"):format(e.x, e.y))
  if e.note then ns.Print(T(e.note)) end
end

function ns.StopEntrance(quiet)
  target = nil
  if f then f:Hide() end
  if not quiet then ns.Print(L.ENTRANCE_STOP) end
end

function ns.EntranceActive()
  return target ~= nil
end

function ns.StopEntranceIfInside()
  if target then ns.StopEntrance(true) end
end

function ns.SaveEntranceHere(d)
  d = d or target or state.viewed
  if not d then return end
  local _, itype = ns.InstanceInfo()
  local map, x, y = PlayerMapPos()
  if (itype and itype ~= "none") or not map then ns.Print(L.ENTRANCE_NOPOS); return end
  ns.db.entrances[d.key] = { map = map, x = x * 100, y = y * 100, zone = { ko = ZoneName(map), en = ZoneName(map) } }
  ns.Print(L.ENTRANCE_SET:format(T(d.name), x * 100, y * 100))
end
