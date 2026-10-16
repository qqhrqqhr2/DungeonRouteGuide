-- Search and display controls placed directly on the world map.
local _, ns = ...
local L = ns.L
local controls
ns.worldMapQuery = ""

local function PositionButton(c, x, y, save)
  local container = c.container
  local w = ns.Num(ns.Safe(container.GetWidth, container))
  local h = ns.Num(ns.Safe(container.GetHeight, container))
  if not w or not h or w <= 0 or h <= 0 then return end
  local pos = ns.db.frames.worldMapTools or {}
  x = x or (ns.Num(pos.x) or 0.5) * w
  y = y or (ns.Num(pos.y) or 0) * h
  local mx, my = math.min(20, w / 2), math.min(20, h / 2)
  x, y = math.max(mx, math.min(w - mx, x)), math.max(my, math.min(h - my, y))
  c.button:ClearAllPoints(); c.button:SetPoint("CENTER", container, "BOTTOMLEFT", x, y)
  c.buttonX, c.buttonY = x, y
  if save then ns.db.frames.worldMapTools = {x = x / w, y = y / h} end
end

local function Cursor(c)
  local x, y = ns.Safe(GetCursorPosition)
  x, y = ns.Num(x), ns.Num(y)
  local scale = ns.Num(ns.Safe(c.container.GetEffectiveScale, c.container))
  local left = ns.Num(ns.Safe(c.container.GetLeft, c.container))
  local bottom = ns.Num(ns.Safe(c.container.GetBottom, c.container))
  if x and y and scale and scale > 0 and left and bottom then
    return x / scale - left, y / scale - bottom
  end
end

function ns.WorldMapMatches(d)
  local query = ns.worldMapQuery or ""
  if query == "" then return true end
  for _, value in ipairs({d.name.ko, d.name.en, d.key, d.slug}) do
    local text = ns.Normalize(value)
    if text and text:find(query, 1, true) then return true end
  end
  return false
end

local function FindDungeon()
  local query = ns.worldMapQuery or ""
  if query == "" then return end
  local first
  for _, d in ipairs(ns.Dungeons) do
    if ns.WorldMapMatches(d) then
      first = first or d
      for _, value in ipairs({d.name.ko, d.name.en, d.key, d.slug}) do
        if ns.Normalize(value) == query then return d end
      end
    end
  end
  return first
end

local function OpenSearchRegion()
  local d = FindDungeon()
  if not d then return end
  local e = (ns.db.entrances and ns.db.entrances[d.key]) or d.entrance
  if not e then return end
  local id, x, y = ns.Num(e.map), ns.Num(e.x), ns.Num(e.y)
  if not id or id <= 0 or not x or not y or x < 0 or x > 100 or y < 0 or y > 100 then return end
  local info = ns.Safe(C_Map and C_Map.GetMapInfo, id)
  if not ns.Readable(info) or type(info) ~= "table" then return end
  controls.panel:Hide()
  ns.Safe(WorldMapFrame.SetMapID, WorldMapFrame, id)
  ns.Safe(WorldMapFrame.PanTo, WorldMapFrame, x / 100, y / 100)
end

local function Button(parent, text, width, action)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(width, 22); b:SetText(text); b:SetScript("OnClick", action)
  return b
end

local function Checkbox(parent, y, key, label)
  local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  check:SetSize(24, 24); check:SetPoint("TOPLEFT", 10, y)
  check.label = check:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  check.label:SetPoint("LEFT", check, "RIGHT", 2, 0)
  check.label:SetText(label)
  check.key = key
  check:SetScript("OnClick", function(self)
    ns.db[self.key] = ns.True(ns.Safe(self.GetChecked, self))
    ns.RefreshWorldMap()
  end)
  return check
end

function ns.RefreshWorldMapControls()
  if not controls then return end
  if not controls.panel:IsShown() then return end
  local c = controls
  c.title:SetText(L.WORLD_TOOLS)
  c.show.label:SetText(L.WORLD_SHOW); c.labels.label:SetText(L.WORLD_LABELS); c.levels.label:SetText(L.WORLD_LEVELS)
  for _, check in ipairs({c.show, c.labels, c.levels}) do check:SetChecked(ns.db[check.key]) end
  c.searchLabel:SetText(L.WORLD_SEARCH)
  local count = 0
  for _, d in ipairs(ns.Dungeons) do
    if ns.WorldMapMatches(d) then count = count + 1 end
  end
  c.matchCount = count
  c.count:SetText(count == 0 and L.WORLD_NO_RESULT or L.WORLD_RESULTS:format(count, #ns.Dungeons))
end

function ns.CreateWorldMapControls()
  if controls then return end
  controls = {}
  ns.WorldMapControls = controls
  local c = controls
  local container = WorldMapFrame.ScrollContainer or WorldMapFrame
  c.container = container
  local strata = ns.Str(ns.Safe(WorldMapFrame.GetFrameStrata, WorldMapFrame)) or "HIGH"
  local level = ns.Num(ns.Safe(WorldMapFrame.GetFrameLevel, WorldMapFrame)) or 0
  c.button = CreateFrame("Button", nil, WorldMapFrame)
  c.button:SetSize(24, 24)
  local icon = "Interface\\AddOns\\DungeonRouteGuide\\Media\\icon"
  c.button.icon = c.button:CreateTexture(nil, "ARTWORK")
  c.button.icon:SetTexture(icon)
  c.button.icon:SetAllPoints()
  local highlight = c.button:CreateTexture(nil, "HIGHLIGHT")
  highlight:SetTexture(icon); highlight:SetAllPoints()
  highlight:SetBlendMode("ADD"); highlight:SetAlpha(0.35)
  c.button:RegisterForDrag("LeftButton")
  c.button:SetScript("OnMouseDown", function() c.ignoreClick = nil end)
  c.button:SetScript("OnClick", function()
    if c.ignoreClick then c.ignoreClick = nil; return end
    GameTooltip_Hide()
    if c.panel:IsShown() then c.panel:Hide() else c.panel:Show() end
  end)
  c.button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L.WORLD_TOOLS, 1, 0.82, 0)
    GameTooltip:AddLine(L.ICON_DRAG, 0.6, 0.6, 0.6)
    GameTooltip:Show()
  end)
  c.button:SetScript("OnLeave", GameTooltip_Hide)
  c.button:SetScript("OnDragStart", function(self)
    local x, y = Cursor(c)
    if not x then return end
    PositionButton(c)
    c.dragX, c.dragY = c.buttonX - x, c.buttonY - y
    c.ignoreClick = true; c.panel:Hide(); GameTooltip_Hide()
    self:SetScript("OnUpdate", function()
      local cx, cy = Cursor(c)
      if cx then PositionButton(c, cx + c.dragX, cy + c.dragY) end
    end)
  end)
  c.button:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    PositionButton(c, c.buttonX, c.buttonY, true)
  end)
  c.button:SetScript("OnHide", function(self) self:SetScript("OnUpdate", nil) end)
  c.button:SetScript("OnShow", function() PositionButton(c) end)
  container:HookScript("OnSizeChanged", function() PositionButton(c) end)
  c.button:SetFrameStrata(strata); c.button:SetFrameLevel(level + 500)
  PositionButton(c)
  c.panel = CreateFrame("Frame", nil, WorldMapFrame, "BackdropTemplate")
  c.panel:SetFrameStrata(strata); c.panel:SetFrameLevel(level + 510)
  c.panel:SetClampedToScreen(true); c.panel:EnableMouse(true)
  c.panel:SetPoint("BOTTOMLEFT", c.button, "TOPLEFT", 0, 3)
  c.panel:SetSize(280, 170)
  c.panel:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1})
  c.panel:SetBackdropColor(0.03, 0.03, 0.04, 0.97); c.panel:SetBackdropBorderColor(0.8, 0.65, 0.2, 1)
  c.title = c.panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  c.title:SetPoint("TOPLEFT", 12, -10)
  local close = CreateFrame("Button", nil, c.panel, "UIPanelCloseButton")
  close:SetSize(24, 24); close:SetPoint("TOPRIGHT", 1, 1); close:SetScript("OnClick", function() c.panel:Hide() end)
  c.show = Checkbox(c.panel, -28, "worldMapPins", L.WORLD_SHOW)
  c.labels = Checkbox(c.panel, -50, "worldMapLabels", L.WORLD_LABELS)
  c.levels = Checkbox(c.panel, -72, "worldMapLevels", L.WORLD_LEVELS)
  c.searchLabel = c.panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  c.searchLabel:SetPoint("TOPLEFT", 12, -100)
  c.search = CreateFrame("EditBox", nil, c.panel, "InputBoxTemplate")
  c.search:SetSize(218, 22); c.search:SetPoint("TOPLEFT", 16, -118)
  c.search:SetAutoFocus(false); c.search:SetMaxLetters(64)
  c.clear = Button(c.panel, "X", 24, function() c.search:SetText(""); c.search:SetFocus() end)
  c.clear:SetPoint("LEFT", c.search, "RIGHT", 7, 0)
  c.count = c.panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  c.count:SetPoint("TOPLEFT", 12, -146)
  c.search:SetScript("OnTextChanged", function(self)
    if c.suppress then return end
    ns.worldMapQuery = ns.Normalize(ns.Str(ns.Safe(self.GetText, self))) or ""
    ns.RefreshWorldMap()
  end)
  c.search:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
    OpenSearchRegion()
  end)
  c.search:SetScript("OnEscapePressed", function(self)
    if (ns.worldMapQuery or "") ~= "" then self:SetText("") else c.panel:Hide() end
    self:ClearFocus()
  end)
  c.panel:SetScript("OnShow", function()
    ns.RefreshWorldMapControls()
  end)
  c.panel:SetScript("OnHide", function()
    c.suppress = true; c.search:SetText(""); c.search:ClearFocus(); c.suppress = false
    ns.worldMapQuery = ""; ns.RefreshWorldMap()
  end)
  c.panel:Hide()
  c.button:Show()
end
