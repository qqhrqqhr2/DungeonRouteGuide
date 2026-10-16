-- Dungeon entrances on world/continent maps. Detailed maps use the game's pins.
-- Coordinates always come from the entrance's zone; map hierarchy prevents
-- a point from one continent being projected onto an unrelated continent.
local _, ns = ...
local L, T = ns.L, ns.T
local TEMPLATE = "DungeonRouteGuideWorldMapPinTemplate"
local provider
local Pin, Provider = {}, {}
DungeonRouteGuideWorldMapPinMixin = Pin

local function Entrance(d)
  return (ns.db.entrances and ns.db.entrances[d.key]) or d.entrance
end

local function MapInfo(id)
  local info = ns.Safe(C_Map and C_Map.GetMapInfo, id)
  if ns.Readable(info) and type(info) == "table" then return info end
end

local function XY(pos)
  if not ns.Readable(pos) or not pos then return end
  local x, y = ns.Safe(pos.GetXY, pos)
  return ns.Num(x), ns.Num(y)
end

local function OnMap(e, mapID)
  if not e then return end
  local source, x, y = ns.Num(e.map), ns.Num(e.x), ns.Num(e.y)
  if not source or not x or not y or x < 0 or x > 100 or y < 0 or y > 100 then return end
  x, y = x / 100, y / 100
  if source == mapID then return x, y end
  local current, seen, ancestor = source, {}, false
  for _ = 1, 20 do
    if current == mapID then ancestor = true; break end
    if seen[current] then break end
    seen[current] = true
    local info = MapInfo(current)
    current = info and ns.Num(info.parentMapID)
    if not current or current == 0 then break end
  end
  if not ancestor then return end
  local minX, maxX, minY, maxY = ns.Safe(C_Map.GetMapRectOnMap, source, mapID)
  minX, maxX, minY, maxY = ns.Num(minX), ns.Num(maxX), ns.Num(minY), ns.Num(maxY)
  if minX and maxX and minY and maxY and maxX > minX and maxY > minY then
    x, y = minX + x * (maxX - minX), minY + y * (maxY - minY)
  elseif CreateVector2D then
    local continent, world = ns.Safe(C_Map.GetWorldPosFromMapPos, source, CreateVector2D(x, y))
    continent = ns.Num(continent)
    if not continent or not ns.Readable(world) or not world then return end
    local result, pos = ns.Safe(C_Map.GetMapPosFromWorldPos, continent, world, mapID)
    if ns.Num(result) ~= mapID then return end
    x, y = XY(pos)
  else return end
  if x and y and x >= 0 and x <= 1 and y >= 0 and y <= 1 then return x, y end
end

local function Disc(parent, size, r, g, b)
  local t = parent:CreateTexture(nil, "ARTWORK")
  t:SetSize(size, size); t:SetPoint("CENTER"); t:SetColorTexture(r, g, b, 1)
  local mask = parent:CreateMaskTexture()
  mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
  mask:SetAllPoints(t); t:AddMaskTexture(mask)
  return t
end

function Pin:OnLoad()
  self:SetSize(10, 10)
  self:UseFrameLevelType("PIN_FRAME_LEVEL_DUNGEON_ENTRANCE")
  self:SetIgnoreGlobalPinScale(true)
  self:SetScalingLimits(1, 1, 1)
  Disc(self, 11, 0.02, 0.02, 0.02)
  Disc(self, 10, 1, 0.76, 0.12)
  Disc(self, 8.5, 0.08, 0.06, 0.03)
  self.icon = self:CreateTexture(nil, "OVERLAY")
  self.icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8")
  self.icon:SetSize(7.5, 7.5); self.icon:SetPoint("CENTER")
  self.count = self:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  self.count:SetPoint("TOPRIGHT", 1.5, 1.5)
  self.count:SetTextColor(0.3, 0.9, 1)
  self.label = self:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  local font, size, flags = self.label:GetFont()
  self.label:SetFont(font, math.max(11, size or 11), "OUTLINE")
  self.label:SetJustifyH("LEFT")
  self.label:SetShadowColor(0, 0, 0, 1); self.label:SetShadowOffset(1, -1)
  self.labelBg = self:CreateTexture(nil, "BACKGROUND")
  self.labelBg:SetColorTexture(0.02, 0.02, 0.02, 0.85)
  self.labelBg:SetPoint("TOPLEFT", self.label, "TOPLEFT", -4, 3)
  self.labelBg:SetPoint("BOTTOMRIGHT", self.label, "BOTTOMRIGHT", 4, -3)
end

function Pin:OnAcquired(group)
  self:SetMouseClickEnabled(false)
  self:SetMouseMotionEnabled(true)
  self.entries = group.entries
  self.count:SetText(#self.entries > 1 and tostring(#self.entries) or "")
  local text = T(self.entries[1].name)
  if #self.entries > 1 then text = L.WORLD_PIN_GROUP:format(text, #self.entries - 1)
  elseif ns.db.worldMapLevels then text = text .. "\n|cffffffff" .. L.WORLD_PIN_LEVEL:format(self.entries[1].levels or "") .. "|r" end
  self.label:SetWidth(0); self.label:SetText(text)
  self:SetPosition(group.x, group.y)
  self:ApplyCurrentScale()
end

function Pin:ShouldMouseButtonBePassthrough() return true end

function Pin:OnMouseEnter()
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  GameTooltip:SetText("Dungeon Route Guide", 1, 0.82, 0)
  for _, d in ipairs(self.entries) do
    GameTooltip:AddLine(T(d.name) .. "  |cffffffff" .. (d.levels or "") .. "|r", 1, 0.82, 0, true)
    local e = Entrance(d)
    local info = e and MapInfo(e.map)
    GameTooltip:AddLine((info and ns.Str(info.name) or (e and T(e.zone)) or "") .. ("  %.1f, %.1f"):format(e.x, e.y), 0.8, 0.8, 0.8, true)
    if e.note then GameTooltip:AddLine(T(e.note), 0.8, 0.8, 0.8, true) end
  end
  GameTooltip:Show()
end

function Pin:OnMouseLeave() GameTooltip_Hide() end

-- Display-only markers: clicks belong to the map canvas.
function Pin:OnMouseClickAction() end

function Pin:OnReleased()
  self.entries = nil
  if ns.True(ns.Safe(GameTooltip.IsOwned, GameTooltip, self)) then GameTooltip_Hide() end
  MapCanvasPinMixin.OnReleased(self)
end

local function CanvasSize(map)
  local canvas = ns.Safe(map.GetCanvas, map)
  local scale = ns.Num(ns.Safe(map.GetCanvasScale, map)) or 1
  if not canvas or scale <= 0 then return end
  local w, h = ns.Num(ns.Safe(canvas.GetWidth, canvas)), ns.Num(ns.Safe(canvas.GetHeight, canvas))
  if w and h and w > 0 and h > 0 then return w * scale, h * scale end
end

function Provider:RemoveAllData()
  self:GetMap():RemoveAllPinsByTemplate(TEMPLATE)
  self.pins = {}
end

function Provider:RefreshAllData()
  self:RemoveAllData()
  if not ns.db or not ns.db.worldMapPins then return end
  local map = self:GetMap()
  local id = ns.Num(ns.Safe(map.GetMapID, map))
  local info = id and MapInfo(id)
  local kind = info and ns.Num(info.mapType)
  -- Leave the game's zone/city/dungeon pins alone.
  if kind ~= 1 and kind ~= 2 then return end
  local w, h = CanvasSize(map)
  if not w then return end
  local groups = {}
  for _, d in ipairs(ns.Dungeons) do
    local matches = not ns.WorldMapMatches or ns.WorldMapMatches(d)
    local x, y
    if matches then x, y = OnMap(Entrance(d), id) end
    if x then
      local group
      for _, g in ipairs(groups) do
        if ((x - g.x) * w)^2 + ((y - g.y) * h)^2 < 32^2 then group = g; break end
      end
      if not group then group = { x = x, y = y, entries = {} }; groups[#groups + 1] = group end
      group.entries[#group.entries + 1] = d
    end
  end
  for _, group in ipairs(groups) do self.pins[#self.pins + 1] = map:AcquirePin(TEMPLATE, group) end
  self:PlaceLabels()
end

function Provider:PlaceLabels()
  local w, h = CanvasSize(self:GetMap())
  if not w then return end
  local used = {}
  local function Fits(x, y, width, height)
    if x < 3 or y < 3 or x + width > w - 3 or y + height > h - 3 then return false end
    for _, p in ipairs(self.pins or {}) do
      local px, py = p.normalizedX * w, p.normalizedY * h
      if x < px + 18 and x + width > px - 18 and y < py + 18 and y + height > py - 18 then return false end
    end
    for _, r in ipairs(used) do
      if x < r[3] and x + width > r[1] and y < r[4] and y + height > r[2] then return false end
    end
    return true
  end
  for _, pin in ipairs(self.pins or {}) do
    if not ns.db.worldMapLabels then
      pin.label:Hide(); pin.labelBg:Hide()
    else
    local x, y = pin.normalizedX * w, pin.normalizedY * h
    local width = (ns.Num(ns.Safe(pin.label.GetStringWidth, pin.label)) or 100) + 8
    local height = (ns.Num(ns.Safe(pin.label.GetStringHeight, pin.label)) or 26) + 6
    local candidates = { {20, -height/2}, {-20-width, -height/2}, {-width/2, 20}, {-width/2, -20-height}, {20, 20}, {-20-width, 20}, {20, -20-height}, {-20-width, -20-height} }
    local placed
    for _, offset in ipairs(candidates) do
      if Fits(x + offset[1], y + offset[2], width, height) then
        used[#used + 1] = { x + offset[1], y + offset[2], x + offset[1] + width, y + offset[2] + height }
        pin.label:ClearAllPoints(); pin.label:SetPoint("TOPLEFT", pin, "CENTER", offset[1] + 4, -offset[2] - 3)
        placed = true; break
      end
    end
    pin.label:SetShown(placed == true); pin.labelBg:SetShown(placed == true)
    end
  end
end

function Provider:OnCanvasScaleChanged() self:RefreshAllData() end
function Provider:OnCanvasSizeChanged() self:RefreshAllData() end
function Provider:OnHide()
  if ns.WorldMapControls then ns.WorldMapControls.panel:Hide() end
end

function ns.InitWorldMap()
  if provider or not ns.db or not WorldMapFrame or not MapCanvasDataProviderMixin or not MapCanvasPinMixin then return end
  for key, value in pairs(MapCanvasPinMixin) do if Pin[key] == nil then Pin[key] = value end end
  provider = CreateFromMixins(MapCanvasDataProviderMixin, Provider)
  WorldMapFrame:AddDataProvider(provider)
  if ns.CreateWorldMapControls then ns.CreateWorldMapControls() end
  if ns.True(ns.Safe(WorldMapFrame.IsShown, WorldMapFrame)) then provider:RefreshAllData() end
end

function ns.RefreshWorldMap()
  ns.InitWorldMap()
  if ns.RefreshWorldMapControls then ns.RefreshWorldMapControls() end
  if provider and ns.True(ns.Safe(WorldMapFrame.IsShown, WorldMapFrame)) then provider:RefreshAllData() end
end
