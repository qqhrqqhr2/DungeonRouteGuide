-- Dungeon Route Guide - main window: map pages (Blizzard map art or Atlas), markers
-- (entrance / boss / rare / NPC / quest spot, alternate spawn spots), legend,
-- route / quest / prep tabs, dungeon picker, options menu, route edit mode.
local _, ns = ...
local L, T = ns.L, ns.T
local state = ns.state

local HEADER, PAD, LISTW = 28, 6, 240
local LEGEND_H, FOOT_H = 16, 14
local MAP_PATH = "Interface\\AddOns\\DungeonRouteGuide\\Maps\\"
local MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local CHECK = "Interface\\RaidFrame\\ReadyCheck-Ready"

-- marker colours by category
local CAT = {
  entrance = { 0.30, 0.85, 0.45 },
  boss     = { 0.78, 0.14, 0.10 },
  rare     = { 0.66, 0.30, 0.90 },
  npc      = { 0.20, 0.50, 0.95 },
  quest    = { 0.95, 0.76, 0.10 },
  done     = { 0.38, 0.38, 0.38 },
  link     = { 0.70, 0.70, 0.70 },
}
local function Category(step)
  if step.kind == "object" or step.kind == "task" then return "quest" end
  return CAT[step.kind] and step.kind or "boss"
end

local frame, canvas, overlay, mapTex, noMapText, title, footer, legend, list, menu, picker
local markers, alts, links, rows, qrows, masks, tiles = {}, {}, {}, {}, {}, {}, {}
local floorBtn, floorNext, floorList, floorRows = nil, nil, nil, {}
local dropdown, currentBtn
local card, PlaceCard, CreateCard, DrawCard, CreateFloorPicker
local CARD_W = 232
local lootBar, lootLabel, lootBtns = nil, nil, {}
local trashBtns = {}
local TRASH_ICON = "Interface\\Icons\\INV_Misc_Bag_10"
local entranceMark, tabRoute, tabQuest, tabNotes, progressText, tipText, questNote

---------------------------------------------------------------------------
-- helpers
---------------------------------------------------------------------------
local function Backdrop(f, a)
  if not f.SetBackdrop then return end
  f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
  f:SetBackdropColor(0.04, 0.04, 0.05, a or 0.88)
  f:SetBackdropBorderColor(0.65, 0.52, 0.22, 0.9)
end

local function Btn(parent, text, w, tip, onClick)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(w, 20)
  b:SetText(text)
  local fs = b:GetFontString()
  if fs and GameFontNormalSmall then fs:SetFontObject(GameFontNormalSmall) end
  b:SetScript("OnClick", onClick)
  if tip then
    b:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_TOP")
      GameTooltip:SetText(type(tip) == "function" and tip() or tip, 1, 1, 1, 1, true)
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
  end
  return b
end

-- Buttons whose label changes with the language grow to fit their text.
local fitBtns = {}
local function FitBtn(b)
  local fs = b:GetFontString()
  local sw = fs and fs:GetStringWidth() or 0
  b:SetWidth(math.max(b.minW or 20, math.floor(sw + 14)))
end
local function Fit(b, minW)
  b.minW = minW
  fitBtns[#fitBtns + 1] = b
  FitBtn(b)
  return b
end

local function Circle(parent, layer, size, sub)
  local t = parent:CreateTexture(nil, layer, nil, sub)
  t:SetSize(size, size)
  t:SetPoint("CENTER")
  t:SetColorTexture(1, 1, 1, 1)
  if parent.CreateMaskTexture then
    local m = parent:CreateMaskTexture()
    m:SetTexture(MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    m:SetAllPoints(t)
    t:AddMaskTexture(m)
  end
  return t
end

-- Map styles: "blizzard" = the game's own dungeon map art (4 x 3 tiles of
-- 256 px read from the client by file ID; the wowf positions fit it as they
-- are), "atlas" = the bundled Atlas images. Atlas is used for dungeons
-- without Blizzard art, or when the client has none of a page's tile files.
local BVIEW = { 8, 8, 986, 652 }    -- shown part of the 1002 x 668 map (frame trimmed)
local AVIEW = { 0, 0, 512, 512 }
local blizFailed = {}

local function UseBliz(d)
  return (d and d.bliz and ns.db.mapStyle ~= "atlas" and not blizFailed[d.key]) and true or false
end
-- Dungeons without any map: the steps as a flow chart in route order
-- (snake layout on the 512 x 512 canvas), so the map area still guides.
local function FlowGeo(d)
  if d.flowGeo then return d.flowGeo end
  local order = {}
  for i, s in ipairs(d.steps) do
    if s.kind ~= "fork" then order[#order + 1] = i end
  end
  local n = #order
  local cols = (n <= 3) and math.max(1, n) or 3
  local rows = math.max(1, math.ceil(n / cols))
  local steps = {}
  for k, i in ipairs(order) do
    local r, c = math.floor((k - 1) / cols), (k - 1) % cols
    if r % 2 == 1 then c = cols - 1 - c end            -- snake: every other row runs back
    steps[d.steps[i].id] = { page = "flow", pos = { math.floor(512 * (c + 1) / (cols + 1)), math.floor(60 + 400 * (r + 0.5) / rows) } }
  end
  d.flowGeo = { pages = { { key = "flow", flow = true, colW = 512 / (cols + 1) } }, steps = steps, order = order }
  return d.flowGeo
end

local function Geo(d)
  if UseBliz(d) then return d.bliz end
  if not (d.pages and #d.pages > 0) then return FlowGeo(d) end
  return d
end
local function HasMap(d) local g = Geo(d); return g.pages and #g.pages > 0 end
local function ViewOf(page)
  if page and page.view then return page.view end
  return (page and page.tiles) and BVIEW or AVIEW
end

-- page, position and alternate spots of a step in the shown map style
local function StepGeo(d, i)
  local step = d.steps[i]
  local e = ns.Edits(d, step)
  local g0 = Geo(d)
  if g0 ~= d then
    local g = g0.steps and g0.steps[step.id]
    if not g then return nil end
    return g.page, (g0 == d.bliz and e and e.bpos) or g.pos, g.alt
  end
  if not step.pos then return nil end
  return step.page, (e and e.pos) or step.pos, step.alt
end
ns.StepGeo = StepGeo

-- map pixels -> screen pixels for the page being drawn
local view = AVIEW
local function Scale() return (ns.db.mapSize or 380) / view[4] end

local function StepTooltip(owner, d, i)
  local step = d.steps[i]
  GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
  GameTooltip:SetText(ns.StepTitle(d, i), 1, 0.82, 0)
  local kind = L["KIND_" .. step.kind] or step.kind
  if step.optional then kind = kind .. " · " .. L.OPTIONAL end
  if step.unconfirmed then kind = kind .. " · " .. L.UNCONFIRMED end
  if step.outside then kind = kind .. " · " .. T(step.outside) end
  GameTooltip:AddLine(kind, 0.7, 0.7, 0.7)
  if step.quest then GameTooltip:AddLine("! " .. L.QUEST_MARK, 1, 0.82, 0) end
  GameTooltip:AddLine(T(step.tip), 1, 1, 1, true)
  if step.loot and #step.loot > 0 then
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L.LOOT, 1, 0.82, 0)
    for k, id in ipairs(step.loot) do
      if k > 12 then GameTooltip:AddLine(("+%d"):format(#step.loot - 12), 0.7, 0.7, 0.7); break end
      local name, _, q, icon = ns.ItemInfo(id)
      local tex = icon and ("|T" .. icon .. ":14:14|t ") or ""
      GameTooltip:AddLine(tex .. (name and (ns.QualityHex(q) .. name .. "|r") or ("|cff888888#" .. id .. " " .. L.LOADING .. "|r")))
    end
  end
  GameTooltip:AddLine(L.CLICK_HINT, 0.5, 0.8, 1, true)
  GameTooltip:Show()
end

local function StepClick(d, i, button)
  if button == "RightButton" then
    ns.SetDone(d, i, not ns.IsDone(d, i))
  else
    state.selected = (state.selected == i) and nil or i
    state.cardTrash = nil
    local pg = StepGeo(d, i)
    if pg then state.page, state.pageManual = pg, true end
    ns.RefreshMap()
  end
end

-- current map page of the viewed dungeon
local function PageHasArea(p, area)
  if not area or not p.areas then return false end
  if not p.areaSet then
    p.areaSet = {}
    for _, a in ipairs(p.areas) do
      local n = ns.Normalize(a)
      if n then p.areaSet[n] = true end
    end
  end
  return p.areaSet[area] == true
end

local function PageByKey(g, key)
  if not key then return nil end
  for _, p in ipairs(g.pages) do if p.key == key then return p end end
end

local function CurrentPage(d)
  if not HasMap(d) then return nil end
  local g = Geo(d)
  if state.pageDungeon ~= d or state.pageGeo ~= g then
    state.pageDungeon, state.pageGeo, state.page, state.pageManual = d, g, nil, false
  end
  local here = (d == state.current) and #g.pages > 1
  -- walked into another known area: drop a floor picked by hand
  if here and state.areaChanged then
    state.areaChanged = nil
    for _, p in ipairs(g.pages) do
      if PageHasArea(p, state.area) then state.pageManual = false; break end
    end
  end
  if state.pageManual and state.page then
    local p = PageByKey(g, state.page)
    if p then return p end
  end
  if here then
    -- the boss / NPC in your target is on its floor
    local p = state.targetStep and PageByKey(g, (StepGeo(d, state.targetStep)))
    if p then return p end
    -- the floor whose areas include the sub-zone you stand in; when several
    -- floors share the name, the one with the next objective, else the one
    -- already on screen
    local fits = {}
    for _, q in ipairs(g.pages) do
      if PageHasArea(q, state.area) then fits[#fits + 1] = q end
    end
    if #fits > 0 then
      local ni = ns.NextStep(d)
      local want = ni and StepGeo(d, ni)
      for _, q in ipairs(fits) do if q.key == want then return q end end
      for _, q in ipairs(fits) do if q.key == state.shownPage then return q end end
      return fits[1]
    end
  end
  local i = ns.NextStep(d)
  local want = i and StepGeo(d, i)
  for _, p in ipairs(g.pages) do if p.key == want then return p end end
  return g.pages[1]
end

---------------------------------------------------------------------------
-- options menu
---------------------------------------------------------------------------
local ALPHAS = { 1, 0.9, 0.75, 0.6, 0.45 }
local SIZES = { 300, 380, 460, 540, 620 }
local function Cycle(values, current)
  for k, v in ipairs(values) do
    if math.abs(v - current) < 0.001 then return values[k % #values + 1] end
  end
  return values[1]
end

local MENU = {
  function() return L.OPT_ALPHA:format(math.floor(ns.db.alpha * 100 + 0.5)) end,
  function() ns.db.alpha = Cycle(ALPHAS, ns.db.alpha); ns.ApplyAlpha() end,
  function() return L.OPT_SIZE:format(ns.db.mapSize) end,
  function() ns.db.mapSize = Cycle(SIZES, ns.db.mapSize); ns.RebuildMap() end,
  function() return L.OPT_LOCK:format(ns.OnOff(ns.db.locked)) end,
  function() ns.db.locked = not ns.db.locked end,
  function() return L.OPT_AUTO:format(ns.OnOff(ns.db.autoOpen)) end,
  function() ns.db.autoOpen = not ns.db.autoOpen end,
  function() return L.OPT_HUD:format(ns.OnOff(ns.db.hud)) end,
  function() ns.db.hud = not ns.db.hud; ns.RefreshHUD() end,
  function() return L.OPT_RARE:format(ns.OnOff(ns.db.rareAlert)) end,
  function() ns.db.rareAlert = not ns.db.rareAlert end,
  function() return L.OPT_FADE:format(ns.OnOff(ns.db.combatFade)) end,
  function() ns.db.combatFade = not ns.db.combatFade; ns.ApplyAlpha() end,
  function() return L.OPT_MAPSTYLE:format(ns.db.mapStyle == "atlas" and L.MAP_ATLAS or L.MAP_BLIZ) end,
  function() ns.SetMapStyle(ns.db.mapStyle == "atlas" and "blizzard" or "atlas") end,
  function() return L.OPT_LANG:format(L["LANG_" .. (ns.db.lang or "auto")]) end,
  function() ns.ChangeLanguage() end,
  function() return L.OPT_ICON:format(ns.OnOff(ns.db.showIcon)) end,
  function() ns.SetIconShown(not ns.db.showIcon) end,
  function() return L.OPT_GO end,
  function() ns.StartEntrance(state.viewed); menu:Hide() end,
  function() return L.OPT_RESET end,
  function() ns.ResetProgress(state.viewed) end,
  function() return L.OPT_EDIT:format(ns.OnOff(state.edit)) end,
  function() ns.SetEditMode(not state.edit) end,
  function() return L.OPT_EXPORT end,
  function() ns.ShowExport(); menu:Hide() end,
}

if ns.DONATE_URL ~= "" then
  MENU[#MENU + 1] = function() return L.OPT_DONATE end
  MENU[#MENU + 1] = function() ns.ShowDonate(); menu:Hide() end
end

local function RefreshMenu()
  if not menu or not menu:IsShown() then return end
  for k, b in ipairs(menu.buttons) do b:SetText(MENU[k * 2 - 1]()) end
end

local function CreateMenu()
  menu = CreateFrame("Frame", nil, frame, "BackdropTemplate")
  Backdrop(menu, 0.96)
  menu:SetFrameStrata("DIALOG")
  menu:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -HEADER)
  menu.buttons = {}
  local count = #MENU / 2
  menu:SetSize(220, count * 22 + 8)
  for k = 1, count do
    local b = Btn(menu, "", 208, nil, function() MENU[k * 2](); RefreshMenu(); ns.RefreshAll() end)
    b:SetPoint("TOPLEFT", 6, -4 - (k - 1) * 22)
    menu.buttons[k] = b
  end
  menu:SetScript("OnShow", RefreshMenu)
  menu:Hide()
end

---------------------------------------------------------------------------
-- dungeon picker (click the title)
---------------------------------------------------------------------------
local function CreatePicker()
  picker = CreateFrame("Frame", nil, frame, "BackdropTemplate")
  Backdrop(picker, 0.97)
  picker:SetFrameStrata("DIALOG")
  picker:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
  local n = #ns.Dungeons
  picker:SetSize(250, n * 20 + 8)
  picker.buttons = {}
  for k, d in ipairs(ns.Dungeons) do
    local b = CreateFrame("Button", nil, picker)
    b:SetSize(238, 20)
    b:SetPoint("TOPLEFT", 6, -4 - (k - 1) * 20)
    local hl = b:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.1)
    b.text = b:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    b.text:SetPoint("LEFT", 4, 0)
    b.lv = b:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    b.lv:SetPoint("RIGHT", -4, 0)
    b:SetScript("OnClick", function()
      state.viewed = d; state.selected, state.cardTrash = nil, nil
      picker:Hide(); if floorList then floorList:Hide() end; ns.RefreshMap()
    end)
    picker.buttons[k] = b
  end
  picker:SetScript("OnShow", function()
    for k, d in ipairs(ns.Dungeons) do
      local b = picker.buttons[k]
      b.text:SetText((d == state.current and "|cff55ff55> |r" or "") .. T(d.name))
      b.lv:SetText(d.levels or "")
      if d == state.viewed then b.text:SetTextColor(1, 0.82, 0) else b.text:SetTextColor(1, 1, 1) end
    end
  end)
  picker:Hide()
end

---------------------------------------------------------------------------
-- map widgets
---------------------------------------------------------------------------
local function GetMarker(k)
  local m = markers[k]
  if m then return m end
  m = CreateFrame("Button", nil, overlay)
  m:SetSize(16, 16)
  m:SetFrameLevel(overlay:GetFrameLevel() + 4)
  m.glow = Circle(m, "BACKGROUND", 26)
  m.glow:SetVertexColor(1, 0.82, 0, 0.55)
  m.glow:SetBlendMode("ADD")
  if m.glow.CreateAnimationGroup then
    local ag = m.glow:CreateAnimationGroup()
    local a = ag:CreateAnimation("Alpha")
    a:SetFromAlpha(1); a:SetToAlpha(0.25); a:SetDuration(0.7)
    ag:SetLooping("BOUNCE")
    m.pulse = ag
  end
  m.ring = Circle(m, "BORDER", 17)
  m.circle = Circle(m, "ARTWORK", 14)
  m.text = m:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  m.text:SetPoint("CENTER", 0, 0)
  m.icon = m:CreateTexture(nil, "OVERLAY")
  m.icon:SetSize(11, 11); m.icon:SetPoint("CENTER", 0, 0)
  m.label = m:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  m.label:SetPoint("TOP", m, "BOTTOM", 0, -3)
  m.label:Hide()
  m.badge = Circle(m, "OVERLAY", 8, 1)
  m.badge:ClearAllPoints(); m.badge:SetPoint("TOPRIGHT", 3, 3)
  m.badge:SetVertexColor(1, 0.82, 0, 1)
  m.badgeText = m:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  m.badgeText:SetPoint("CENTER", m.badge, "CENTER", 0, 0)
  m.badgeText:SetText("!"); m.badgeText:SetTextColor(0, 0, 0)
  m.check = m:CreateTexture(nil, "OVERLAY", nil, 3)
  m.check:SetTexture(CHECK)
  m.check:SetSize(12, 12)
  m.check:SetPoint("BOTTOMRIGHT", 5, -4)
  m:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  m:SetScript("OnEnter", function(self) StepTooltip(self, state.viewed, self.index) end)
  m:SetScript("OnLeave", GameTooltip_Hide)
  m:SetScript("OnClick", function(self, button) StepClick(state.viewed, self.index, button) end)
  markers[k] = m
  return m
end

local function GetAlt(k)
  local a = alts[k]
  if a then return a end
  a = CreateFrame("Button", nil, overlay)
  a:SetSize(11, 11)
  a:SetFrameLevel(overlay:GetFrameLevel() + 2)
  a.ring = Circle(a, "BORDER", 11)
  a.inner = Circle(a, "ARTWORK", 8)
  a.inner:SetVertexColor(0, 0, 0, 0.3)
  a.text = a:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  a.text:SetPoint("CENTER", 0, 0)
  a.icon = a:CreateTexture(nil, "OVERLAY")
  a.icon:SetSize(8, 8); a.icon:SetPoint("CENTER", 0, 0)
  a:SetAlpha(0.6)
  a:SetScript("OnEnter", function(self)
    StepTooltip(self, state.viewed, self.index)
    GameTooltip:AddLine(L.LEG_ALT, 0.8, 0.8, 0.8); GameTooltip:Show()
  end)
  a:SetScript("OnLeave", GameTooltip_Hide)
  alts[k] = a
  return a
end

-- Way to another map area (floor): arrow button with the area name under it;
-- clicking shows that area's map.
local LINK_ICON = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up"
local function GetLink(k)
  local l = links[k]
  if l then return l end
  l = CreateFrame("Button", nil, overlay)
  l:SetSize(18, 18)
  l:SetFrameLevel(overlay:GetFrameLevel() + 3)
  l.bg = Circle(l, "BACKGROUND", 18)
  l.bg:SetVertexColor(0.05, 0.05, 0.08, 0.75)
  l.tex = l:CreateTexture(nil, "ARTWORK")
  l.tex:SetSize(22, 22); l.tex:SetPoint("CENTER")
  l.tex:SetTexture(LINK_ICON)
  l.name = l:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  l.name:SetPoint("TOP", l, "BOTTOM", 0, -1)
  l.name:SetTextColor(0.55, 0.85, 1)
  l.nameBg = l:CreateTexture(nil, "BORDER")
  l.nameBg:SetColorTexture(0, 0, 0, 0.6)
  l.nameBg:SetPoint("TOPLEFT", l.name, "TOPLEFT", -3, 1)
  l.nameBg:SetPoint("BOTTOMRIGHT", l.name, "BOTTOMRIGHT", 3, -1)
  l:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(self.label or "", 1, 1, 1, 1, true)
    if self.toPage then GameTooltip:AddLine(L.LINK_CLICK, 0.5, 0.8, 1) end
    GameTooltip:Show()
  end)
  l:SetScript("OnLeave", GameTooltip_Hide)
  l:SetScript("OnClick", function(self)
    if not self.toPage then return end
    state.page, state.pageManual = self.toPage, true
    GameTooltip_Hide(); ns.RefreshMap()
  end)
  links[k] = l
  return l
end

---------------------------------------------------------------------------
-- list panel widgets
---------------------------------------------------------------------------
local function GetRow(k)
  local r = rows[k]
  if r then return r end
  r = CreateFrame("Button", nil, list)
  r:SetSize(LISTW - 12, 17)
  r.hl = r:CreateTexture(nil, "HIGHLIGHT"); r.hl:SetAllPoints(); r.hl:SetColorTexture(1, 1, 1, 0.08)
  r.bg = r:CreateTexture(nil, "BACKGROUND"); r.bg:SetAllPoints(); r.bg:SetColorTexture(1, 0.82, 0, 0.12)
  r.dot = Circle(r, "ARTWORK", 8)
  r.dot:ClearAllPoints(); r.dot:SetPoint("LEFT", 4, 0)
  r.check = r:CreateTexture(nil, "OVERLAY")
  r.check:SetTexture(CHECK); r.check:SetSize(14, 14); r.check:SetPoint("LEFT", 1, 0)
  r.num = r:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  r.num:SetPoint("LEFT", 14, 0); r.num:SetWidth(18); r.num:SetJustifyH("RIGHT")
  r.kicon = r:CreateTexture(nil, "ARTWORK")
  r.kicon:SetSize(13, 13); r.kicon:SetPoint("RIGHT", r.num, "RIGHT", 1, 0)
  r.tag = r:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  r.tag:SetPoint("RIGHT", -2, 0)
  r.name = r:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  r.name:SetPoint("LEFT", r.num, "RIGHT", 5, 0)
  r.name:SetPoint("RIGHT", r.tag, "LEFT", -4, 0)
  r.name:SetJustifyH("LEFT")
  if r.name.SetWordWrap then r.name:SetWordWrap(false) end
  r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  r:SetScript("OnEnter", function(self)
    if self.group then
      local g = state.viewed.trashGroups[self.group]
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(T(g.name), 1, 0.82, 0)
      GameTooltip:AddLine(L.TRASH_ROW_TIP, 1, 1, 1, true)
      GameTooltip:Show()
    else
      StepTooltip(self, state.viewed, self.index)
    end
  end)
  r:SetScript("OnLeave", GameTooltip_Hide)
  r:SetScript("OnClick", function(self, button)
    if self.group then
      -- trash / off-route mob drops: list under the tip and in the card
      state.selected = nil
      state.cardTrash = (state.cardTrash == self.group) and nil or self.group
      ns.RefreshMap()
    else
      StepClick(state.viewed, self.index, button)
    end
  end)
  rows[k] = r
  return r
end

local function GetQuestRow(k)
  local r = qrows[k]
  if r then return r end
  r = CreateFrame("Frame", nil, list)
  r:SetSize(LISTW - 12, 30)
  r:EnableMouse(true)
  r.name = r:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  r.name:SetPoint("TOPLEFT", 2, 0); r.name:SetPoint("TOPRIGHT", -52, 0)
  r.name:SetJustifyH("LEFT")
  if r.name.SetWordWrap then r.name:SetWordWrap(false) end
  r.status = r:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  r.status:SetPoint("TOPRIGHT", -2, 0)
  r.giver = r:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  r.giver:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 6, -2); r.giver:SetPoint("RIGHT", -2, 0)
  r.giver:SetJustifyH("LEFT")
  if r.giver.SetWordWrap then r.giver:SetWordWrap(false) end
  r:SetScript("OnEnter", function(self)
    if not self.q then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(T(self.q.name), 1, 0.82, 0)
    if self.q.level then GameTooltip:AddLine(("Lv %d"):format(self.q.level), 0.7, 0.7, 0.7) end
    GameTooltip:AddLine(T(self.q.giver), 1, 1, 1, true)
    GameTooltip:Show()
  end)
  r:SetScript("OnLeave", GameTooltip_Hide)
  qrows[k] = r
  return r
end

local function QuestStatus(id)
  if ns.True(ns.Safe(C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted, id))
    or ns.True(ns.Safe(IsQuestFlaggedCompleted, id)) then return "done" end
  if ns.True(ns.Safe(C_QuestLog and C_QuestLog.IsOnQuest, id)) then return "active" end
  return "missing"
end
ns.QuestStatus = QuestStatus

local function SetTab(tab) ns.db.listTab = tab; ns.RefreshMap() end

---------------------------------------------------------------------------
-- layout
---------------------------------------------------------------------------
local function SavePosition()
  local p, _, rp, x, y = frame:GetPoint(1)
  ns.db.frames.map = { p, rp, x, y }
  if card and card:IsShown() then PlaceCard() end
end

local function Layout()
  local S = ns.db.mapSize
  local d = state.viewed
  local v = ViewOf(d and CurrentPage(d))
  local CW = math.floor(S * v[3] / v[4] + 0.5)
  local w = PAD + CW + PAD + (ns.db.showList and LISTW or 0)
  local h = HEADER + S + LEGEND_H + FOOT_H + 8
  frame:SetSize(w, h)
  canvas:SetSize(CW, S)
  legend:ClearAllPoints()
  legend:SetPoint("TOPLEFT", canvas, "BOTTOMLEFT", 0, -3)
  list:SetShown(ns.db.showList)
  list:SetHeight(S + LEGEND_H)
end

local legendItems = {}
local function LayoutLegend()
  local x = 0
  for _, it in ipairs(legendItems) do
    it.dot:ClearAllPoints(); it.dot:SetPoint("LEFT", x, 0)
    it.fs:ClearAllPoints(); it.fs:SetPoint("LEFT", x + 12, 0)
    it.fs:SetText(L["LEG_" .. it.key:upper()])
    x = x + 16 + (it.fs:GetStringWidth() or 40) + 10
  end
end

local function CreateLegend()
  legend = CreateFrame("Frame", nil, frame)
  legend:SetSize(400, LEGEND_H)
  for _, key in ipairs({ "entrance", "boss", "rare", "npc", "quest" }) do
    local dot = Circle(legend, "ARTWORK", 9)
    dot:SetVertexColor(CAT[key][1], CAT[key][2], CAT[key][3], 1)
    local fs = legend:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    legendItems[#legendItems + 1] = { key = key, dot = dot, fs = fs }
  end
  LayoutLegend()
end

function ns.OnLanguageChanged()
  for _, b in ipairs(fitBtns) do FitBtn(b) end
  if legend then LayoutLegend() end
  if ns.RefreshAll then ns.RefreshAll() end
end

---------------------------------------------------------------------------
-- area picker: dungeons with several maps (floors / wings) get a dropdown
-- in the map corner, and a "next objective is in ..." jump link.
---------------------------------------------------------------------------
local function PageName(p, k) return p.name and T(p.name) or L.PAGE:format(k) end

local function DarkBackdrop(f, a)
  if not f.SetBackdrop then return end
  f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
  f:SetBackdropColor(0, 0, 0, a)
  f:SetBackdropBorderColor(0.65, 0.52, 0.22, 0.9)
end

function CreateFloorPicker()
  floorBtn = CreateFrame("Button", nil, frame, "BackdropTemplate")
  floorBtn:SetFrameLevel(overlay:GetFrameLevel() + 10)
  floorBtn:SetPoint("TOPLEFT", canvas, "TOPLEFT", 4, -4)
  floorBtn:SetHeight(20)
  DarkBackdrop(floorBtn, 0.78)
  local arrow = floorBtn:CreateTexture(nil, "ARTWORK")
  arrow:SetTexture("Interface\\Buttons\\Arrow-Down-Up")
  arrow:SetSize(14, 14); arrow:SetPoint("RIGHT", -4, -2)
  floorBtn.text = floorBtn:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  floorBtn.text:SetPoint("LEFT", 6, 0)
  if floorBtn.text.SetWordWrap then floorBtn.text:SetWordWrap(false) end
  local hl = floorBtn:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.08)
  floorBtn:SetScript("OnClick", function() menu:Hide(); picker:Hide(); floorList:SetShown(not floorList:IsShown()) end)
  floorBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText(L.AREA_TIP:format(self.count or 0), 1, 1, 1, 1, true); GameTooltip:Show()
  end)
  floorBtn:SetScript("OnLeave", GameTooltip_Hide)

  floorNext = CreateFrame("Button", nil, frame, "BackdropTemplate")
  floorNext:SetFrameLevel(overlay:GetFrameLevel() + 10)
  floorNext:SetPoint("TOPLEFT", floorBtn, "BOTTOMLEFT", 0, -2)
  floorNext:SetHeight(16)
  DarkBackdrop(floorNext, 0.6)
  if floorNext.SetBackdropBorderColor then floorNext:SetBackdropBorderColor(1, 0.82, 0, 0.6) end
  floorNext.text = floorNext:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  floorNext.text:SetPoint("LEFT", 5, 0)
  if floorNext.text.SetWordWrap then floorNext.text:SetWordWrap(false) end
  local nhl = floorNext:CreateTexture(nil, "HIGHLIGHT"); nhl:SetAllPoints(); nhl:SetColorTexture(1, 0.82, 0, 0.12)
  floorNext:SetScript("OnClick", function(self)
    state.page, state.pageManual = self.key, true
    floorList:Hide(); ns.RefreshMap()
  end)

  floorList = CreateFrame("Frame", nil, frame, "BackdropTemplate")
  Backdrop(floorList, 0.96)
  floorList:SetFrameStrata("DIALOG")
  floorList:SetPoint("TOPLEFT", floorBtn, "BOTTOMLEFT", 0, -2)
  floorList:Hide()
  floorBtn:Hide(); floorNext:Hide()
end

local function FloorRow(k)
  local r = floorRows[k]
  if r then return r end
  r = CreateFrame("Button", nil, floorList)
  r:SetHeight(18)
  local hl = r:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.1)
  r.tag = r:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  r.tag:SetPoint("RIGHT", -4, 0)
  r.text = r:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  r.text:SetPoint("LEFT", 4, 0); r.text:SetPoint("RIGHT", r.tag, "LEFT", -6, 0)
  r.text:SetJustifyH("LEFT")
  if r.text.SetWordWrap then r.text:SetWordWrap(false) end
  r:SetScript("OnClick", function(self)
    state.page, state.pageManual = self.key, true
    floorList:Hide(); ns.RefreshMap()
  end)
  floorRows[k] = r
  return r
end

-- route steps still to do per page, and the page of the next objective
local function FloorInfo(d)
  local left, nextPage = {}, nil
  local ni = ns.NextStep(d)
  for i, step in ipairs(d.steps) do
    local pg = StepGeo(d, i)
    if pg and ns.IsMain(step) and not ns.IsDone(d, i) then left[pg] = (left[pg] or 0) + 1 end
    if i == ni then nextPage = pg end
  end
  return left, nextPage
end

local function DrawFloors(d, page)
  local pages = Geo(d).pages or {}
  if #pages < 2 or not page then
    floorBtn:Hide(); floorNext:Hide(); floorList:Hide()
    return
  end
  if floorList.d ~= d then floorList:Hide(); floorList.d = d end
  local left, nextPage = FloorInfo(d)
  local idx, nextName = 1, nil
  for k, p in ipairs(pages) do
    if p == page then idx = k end
    if p.key == nextPage then nextName = PageName(p, k) end
  end
  local cw = math.floor(ns.db.mapSize * view[3] / view[4] + 0.5)
  floorBtn.count = #pages
  floorBtn.text:SetText(("|cffffd100%s|r  %s"):format(L.AREA:format(idx, #pages), PageName(page, idx)))
  floorBtn:SetWidth(math.min(cw - 8, math.floor((floorBtn.text:GetStringWidth() or 100) + 30)))
  floorBtn:Show()
  if nextName and nextPage ~= page.key then
    floorNext.key = nextPage
    floorNext.text:SetText(L.NEXT_AREA:format(nextName))
    floorNext:SetWidth(math.min(cw - 8, math.floor((floorNext.text:GetStringWidth() or 100) + 12)))
    floorNext:Show()
  else
    floorNext:Hide()
  end
  local w = math.max(200, floorBtn:GetWidth() or 0)
  for k, p in ipairs(pages) do
    local r = FloorRow(k)
    r.key = p.key
    r:SetWidth(w - 12)
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", 6, -4 - (k - 1) * 18)
    r.text:SetText(k .. ". " .. PageName(p, k))
    if p == page then r.text:SetTextColor(1, 0.82, 0) else r.text:SetTextColor(1, 1, 1) end
    local tag = {}
    if p.key == nextPage then tag[#tag + 1] = "|cffffd100" .. L.AREA_NEXT .. "|r" end
    if left[p.key] then tag[#tag + 1] = L.AREA_LEFT:format(left[p.key]) end
    r.tag:SetText(table.concat(tag, " · "))
    r:Show()
  end
  for j = #pages + 1, #floorRows do floorRows[j]:Hide() end
  floorList:SetSize(w, #pages * 18 + 8)
end

-- for the test harness
function ns.AreaWidgets() return floorBtn, floorNext, floorList, floorRows end

local function Create()
  frame = CreateFrame("Frame", "DungeonRouteGuideFrame", UIParent, "BackdropTemplate")
  Backdrop(frame)
  frame:SetFrameStrata("MEDIUM")
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function(self) if not ns.db.locked then self:StartMoving() end end)
  frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); SavePosition() end)
  local pos = ns.db.frames.map
  if pos then frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4]) else frame:SetPoint("CENTER", 200, 40) end
  -- Not registered in UISpecialFrames: ESC must not close the map, only the X button.

  -- header
  local close = Btn(frame, "X", 22, nil, function() frame:Hide() end)
  close:SetPoint("TOPRIGHT", -PAD, -4)
  local menuBtn = Btn(frame, L.BTN_MENU, 44, nil, function() picker:Hide(); menu:SetShown(not menu:IsShown()) end)
  menuBtn:SetPoint("RIGHT", close, "LEFT", -2, 0)
  local listBtn = Btn(frame, L.BTN_LIST, 40, nil, function() ns.db.showList = not ns.db.showList; Layout(); ns.RefreshMap() end)
  listBtn:SetPoint("RIGHT", menuBtn, "LEFT", -2, 0)
  -- "current dungeon" button: back to the map of the dungeon you are in
  currentBtn = Btn(frame, L.BTN_CURRENT, 64, function() return L.TIP_CURRENT end, function()
    if state.current then
      state.viewed, state.selected, state.pageManual = state.current, nil, false
      picker:Hide(); ns.RefreshMap()
    end
  end)
  currentBtn:SetPoint("RIGHT", listBtn, "LEFT", -6, 0)
  ns.Loc(menuBtn, "BTN_MENU"); ns.Loc(listBtn, "BTN_LIST"); ns.Loc(currentBtn, "BTN_CURRENT")
  Fit(menuBtn, 40); Fit(listBtn, 36); Fit(currentBtn, 52)
  -- dungeon dropdown
  local titleBtn = CreateFrame("Button", nil, frame, "BackdropTemplate")
  dropdown = titleBtn
  titleBtn:SetPoint("TOPLEFT", PAD, -4)
  titleBtn:SetPoint("RIGHT", currentBtn, "LEFT", -6, 0)
  titleBtn:SetHeight(20)
  if titleBtn.SetBackdrop then
    titleBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    titleBtn:SetBackdropColor(0, 0, 0, 0.6)
    titleBtn:SetBackdropBorderColor(0.65, 0.52, 0.22, 0.9)
  end
  local arrow = titleBtn:CreateTexture(nil, "ARTWORK")
  arrow:SetTexture("Interface\\Buttons\\Arrow-Down-Up")
  arrow:SetSize(14, 14)
  arrow:SetPoint("RIGHT", -4, -2)
  local thl = titleBtn:CreateTexture(nil, "HIGHLIGHT"); thl:SetAllPoints(); thl:SetColorTexture(1, 1, 1, 0.08)
  title = titleBtn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  title:SetPoint("LEFT", 6, 0)
  title:SetPoint("RIGHT", arrow, "LEFT", -4, 0)
  title:SetJustifyH("LEFT")
  if title.SetWordWrap then title:SetWordWrap(false) end
  titleBtn:SetScript("OnClick", function() menu:Hide(); floorList:Hide(); picker:SetShown(not picker:IsShown()) end)
  titleBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText(L.PICK_DUNGEON, 1, 1, 1); GameTooltip:Show()
  end)
  titleBtn:SetScript("OnLeave", GameTooltip_Hide)

  -- map
  canvas = CreateFrame("Frame", nil, frame)
  canvas:SetPoint("TOPLEFT", PAD, -HEADER)
  local bg = canvas:CreateTexture(nil, "BACKGROUND", nil, -1)
  bg:SetAllPoints(); bg:SetColorTexture(0, 0, 0, 0.5)
  mapTex = canvas:CreateTexture(nil, "BACKGROUND")
  mapTex:SetAllPoints()
  for k = 1, 12 do tiles[k] = canvas:CreateTexture(nil, "BACKGROUND") end
  noMapText = canvas:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  noMapText:SetPoint("CENTER"); ns.Loc(noMapText, "NO_MAP")
  overlay = CreateFrame("Frame", nil, canvas)
  overlay:SetAllPoints()
  overlay:SetFrameLevel(canvas:GetFrameLevel() + 2)
  -- The canvas takes mouse input (edit clicks), so it must also forward
  -- drags to the window or the map area could not be used to move it.
  canvas:EnableMouse(true)
  canvas:RegisterForDrag("LeftButton")
  canvas:SetScript("OnDragStart", function() if not ns.db.locked then frame:StartMoving() end end)
  canvas:SetScript("OnDragStop", function() frame:StopMovingOrSizing(); SavePosition() end)
  canvas:SetScript("OnMouseUp", function(_, button) ns.EditClick(button) end)

  entranceMark = CreateFrame("Frame", nil, overlay)
  entranceMark:SetSize(15, 15)
  entranceMark:SetFrameLevel(overlay:GetFrameLevel() + 3)
  local ering = Circle(entranceMark, "BORDER", 15)
  ering:SetVertexColor(CAT.entrance[1], CAT.entrance[2], CAT.entrance[3], 1)
  local einner = Circle(entranceMark, "ARTWORK", 9)
  einner:SetVertexColor(0.05, 0.15, 0.05, 0.5)
  entranceMark.text = entranceMark:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  entranceMark.text:SetPoint("TOP", entranceMark, "BOTTOM", 0, -1)
  ns.Loc(entranceMark.text, "LEG_ENTRANCE")
  entranceMark.text:SetTextColor(CAT.entrance[1], CAT.entrance[2], CAT.entrance[3])

  CreateFloorPicker()

  CreateLegend()
  footer = frame:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  footer:SetPoint("BOTTOMLEFT", PAD, 4)
  footer:SetPoint("BOTTOMRIGHT", -PAD, 4)
  footer:SetJustifyH("LEFT")
  if footer.SetWordWrap then footer:SetWordWrap(false) end

  -- list
  list = CreateFrame("Frame", nil, frame)
  list:SetPoint("TOPLEFT", canvas, "TOPRIGHT", PAD, 0)
  list:SetWidth(LISTW - PAD)
  tabRoute = Btn(list, L.TAB_ROUTE, 54, nil, function() SetTab("route") end)
  tabRoute:SetPoint("TOPLEFT", 0, 0)
  tabQuest = Btn(list, L.TAB_QUEST, 58, nil, function() SetTab("quest") end)
  tabQuest:SetPoint("LEFT", tabRoute, "RIGHT", 2, 0)
  tabNotes = Btn(list, L.TAB_NOTES, 50, nil, function() SetTab("notes") end)
  tabNotes:SetPoint("LEFT", tabQuest, "RIGHT", 2, 0)
  ns.Loc(tabRoute, "TAB_ROUTE"); ns.Loc(tabQuest, "TAB_QUEST"); ns.Loc(tabNotes, "TAB_NOTES")
  Fit(tabRoute, 40); Fit(tabQuest, 40); Fit(tabNotes, 36)
  progressText = list:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  progressText:SetPoint("TOPRIGHT", -4, -4)
  tipText = list:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  tipText:SetJustifyH("LEFT"); tipText:SetJustifyV("TOP")
  tipText:SetWidth(LISTW - 16)
  -- item icons of the selected / next boss (bottom of the list panel)
  lootBar = CreateFrame("Frame", nil, list)
  lootBar:SetPoint("BOTTOMLEFT", 0, 0)
  lootBar:SetSize(LISTW - PAD, 62)
  lootLabel = lootBar:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  lootLabel:SetPoint("TOPLEFT", 4, 0)
  if lootBar.EnableMouseWheel then lootBar:EnableMouseWheel(true) end
  lootBar:SetScript("OnMouseWheel", function(self, delta)
    if (self.maxOffset or 0) == 0 then return end
    self.offset = math.max(0, math.min(self.maxOffset, (self.offset or 0) - delta))
    ns.RefreshMap()
  end)
  questNote = list:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  questNote:SetJustifyH("LEFT"); questNote:SetJustifyV("TOP")
  questNote:SetWidth(LISTW - 16)

  CreateMenu()
  CreatePicker()
  CreateCard()
  frame:SetScript("OnHide", function()
    if menu then menu:Hide() end
    if picker then picker:Hide() end
    if floorList then floorList:Hide() end
  end)
  Layout()
  ns.ApplyAlpha()
end


---------------------------------------------------------------------------
-- boss card: 3D model and the full loot list of the selected step
---------------------------------------------------------------------------
local function LootOnEnter(self)
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  if not pcall(GameTooltip.SetItemByID, GameTooltip, self.id) then
    GameTooltip:SetHyperlink("item:" .. self.id)
  end
  if self.from == "world" then
    GameTooltip:AddLine(L.SRC_WORLD, 0.75, 0.75, 0.75, true)
  elseif type(self.from) == "table" then
    GameTooltip:AddLine(L.SRC_FROM, 1, 0.82, 0)
    for _, s in ipairs(self.from) do
      GameTooltip:AddDoubleLine(T(s.n), ("%.1f%%"):format(s.r), 1, 1, 1, 0.75, 0.75, 0.75)
    end
  end
  GameTooltip:AddLine(L.LOOT_HINT, 0.5, 0.8, 1)
  GameTooltip:Show()
end

-- one line naming where a trash item comes from
local function SourceText(from)
  if from == "world" then return L.SRC_WORLD end
  if type(from) ~= "table" or not from[1] then return nil end
  local s = ("%s %.1f%%"):format(T(from[1].n), from[1].r)
  if #from > 1 then s = s .. " " .. L.SRC_MORE:format(#from - 1) end
  return s
end

local function LootOnClick(self)
  local _, link = ns.ItemInfo(self.id)
  if link and IsModifiedClick and IsModifiedClick("CHATLINK") and ChatEdit_InsertLink then ChatEdit_InsertLink(link)
  elseif link and HandleModifiedItemClick then HandleModifiedItemClick(link) end
end

local function QualityBorder(t, q)
  local c = q and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]
  if c then t:SetColorTexture(c.r, c.g, c.b, 0.9) else t:SetColorTexture(0, 0, 0, 0) end
end

local cardRows = {}
local MODEL_H = 170

local function CardRow(k)
  local r = cardRows[k]
  if r then return r end
  r = CreateFrame("Button", nil, card.content)
  r:SetSize(CARD_W - 40, 20)
  r.icon = r:CreateTexture(nil, "ARTWORK")
  r.icon:SetSize(18, 18); r.icon:SetPoint("LEFT", 1, 0)
  r.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  r.border = r:CreateTexture(nil, "BACKGROUND")
  r.border:SetPoint("TOPLEFT", r.icon, "TOPLEFT", -1, 1); r.border:SetPoint("BOTTOMRIGHT", r.icon, "BOTTOMRIGHT", 1, -1)
  r.name = r:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  r.name:SetPoint("LEFT", r.icon, "RIGHT", 5, 0); r.name:SetPoint("RIGHT", -2, 0)
  r.name:SetJustifyH("LEFT")
  if r.name.SetWordWrap then r.name:SetWordWrap(false) end
  r.src = r:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  r.src:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -1); r.src:SetPoint("RIGHT", -2, 0)
  r.src:SetJustifyH("LEFT")
  if r.src.SetWordWrap then r.src:SetWordWrap(false) end
  local hl = r:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.08)
  r:RegisterForClicks("LeftButtonUp")
  r:SetScript("OnEnter", LootOnEnter)
  r:SetScript("OnLeave", GameTooltip_Hide)
  r:SetScript("OnClick", LootOnClick)
  cardRows[k] = r
  return r
end

local function ModelCall(m, method, ...)
  if not m[method] then return false end
  return (pcall(m[method], m, ...))
end

local function ModelRotate(self)
  local x = GetCursorPosition()
  self.rot = (self.rot or 0) + (x - (self.dragX or x)) * 0.012
  self.dragX = x
  ModelCall(self, "SetRotation", self.rot)
end

function CreateCard()
  card = CreateFrame("Frame", nil, frame, "BackdropTemplate")
  Backdrop(card, 0.92)
  card:SetWidth(CARD_W)
  card:EnableMouse(true)
  local close = Btn(card, "X", 22, nil, function() state.selected, state.cardTrash = nil, nil; ns.RefreshMap() end)
  close:SetPoint("TOPRIGHT", -4, -4)
  card.title = card:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  card.title:SetPoint("TOPLEFT", 8, -8); card.title:SetPoint("RIGHT", close, "LEFT", -4, 0)
  card.title:SetJustifyH("LEFT")
  if card.title.SetWordWrap then card.title:SetWordWrap(false) end
  card.kind = card:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  card.kind:SetPoint("TOPLEFT", card.title, "BOTTOMLEFT", 0, -3)
  local mbg = card:CreateTexture(nil, "BACKGROUND", nil, 1)
  mbg:SetPoint("TOPLEFT", 6, -44); mbg:SetPoint("TOPRIGHT", -6, -44); mbg:SetHeight(MODEL_H)
  mbg:SetColorTexture(0, 0, 0, 0.45)
  card.mbg = mbg
  local m = CreateFrame("PlayerModel", nil, card)
  m:SetAllPoints(mbg)
  m:EnableMouse(true)
  if m.EnableMouseWheel then m:EnableMouseWheel(true) end
  m:SetScript("OnMouseDown", function(self, button)
    if button == "RightButton" then
      self.rot, self.zoom = 0.5, 1
      ModelCall(self, "SetRotation", self.rot); ModelCall(self, "SetCamDistanceScale", self.zoom)
    else
      self.dragX = GetCursorPosition()
      self:SetScript("OnUpdate", ModelRotate)
    end
  end)
  m:SetScript("OnMouseUp", function(self) self:SetScript("OnUpdate", nil) end)
  m:SetScript("OnHide", function(self) self:SetScript("OnUpdate", nil) end)
  m:SetScript("OnMouseWheel", function(self, delta)
    self.zoom = math.max(0.4, math.min(2.5, (self.zoom or 1) - delta * 0.1))
    ModelCall(self, "SetCamDistanceScale", self.zoom)
  end)
  m:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP"); GameTooltip:SetText(L.MODEL_HINT, 1, 1, 1, 1, true); GameTooltip:Show()
  end)
  m:SetScript("OnLeave", GameTooltip_Hide)
  card.model = m
  card.noModel = card:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  card.noModel:SetPoint("CENTER", mbg, "CENTER")
  ns.Loc(card.noModel, "NO_MODEL")
  card.lootLabel = card:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  card.lootLabel:SetPoint("TOPLEFT", mbg, "BOTTOMLEFT", 2, -8)
  -- item list scrolls (mouse wheel / scroll bar) when it is longer than the card
  card.scroll = CreateFrame("ScrollFrame", nil, card, "UIPanelScrollFrameTemplate")
  card.content = CreateFrame("Frame", nil, card.scroll)
  card.content:SetSize(CARD_W - 40, 10)
  card.scroll:SetScrollChild(card.content)
  -- loading bar for item data still on its way from the server
  local lb = CreateFrame("StatusBar", nil, card)
  lb:SetPoint("BOTTOMLEFT", 8, 7); lb:SetPoint("BOTTOMRIGHT", -8, 7)
  lb:SetHeight(12)
  lb:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  lb:SetStatusBarColor(0.25, 0.6, 1)
  lb:SetMinMaxValues(0, 1)
  local lbg = lb:CreateTexture(nil, "BACKGROUND"); lbg:SetAllPoints(); lbg:SetColorTexture(0, 0, 0, 0.6)
  lb.text = lb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  lb.text:SetPoint("CENTER")
  lb:Hide()
  card.loadBar = lb
  card.more = card.content:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  card.more:SetJustifyH("LEFT")
  card:SetScript("OnShow", function() card.modelFor = nil end)
  card:Hide()
end

function PlaceCard()
  card:ClearAllPoints()
  local right = frame:GetRight() or 0
  local screen = (UIParent and UIParent:GetRight()) or (GetScreenWidth and GetScreenWidth()) or 1e6
  if right + CARD_W + 4 > screen then
    card:SetPoint("TOPRIGHT", frame, "TOPLEFT", -2, 0)
  else
    card:SetPoint("TOPLEFT", frame, "TOPRIGHT", 2, 0)
  end
  card:SetHeight(frame:GetHeight())
end

local function SetCardModel(step)
  local m = card.model
  local id = step.model or (step.npc and step.npc[1])
  if card.modelFor == id then return end   -- keep the angle the player turned it to
  card.modelFor = id
  m.rot, m.zoom = 0.5, 1
  m:Show()   -- a hidden model frame may ignore the new model
  ModelCall(m, "ClearModel")
  local ok = false
  if step.model then ok = ModelCall(m, "SetDisplayInfo", step.model) end
  if not ok and step.npc then ok = ModelCall(m, "SetCreature", step.npc[1]) end
  if ok then
    ModelCall(m, "SetPortraitZoom", 0)
    ModelCall(m, "SetCamDistanceScale", m.zoom)
    ModelCall(m, "SetRotation", m.rot)
  end
  m:SetShown(ok)
  card.noModel:SetShown(not ok)
end

-- Item rows of the card: the selected step's drops, or a trash group's
-- (Prep tab) without the model.
function DrawCard(d)
  local i = state.selected
  local step = i and d.steps[i]
  local group = state.cardTrash and d.trashGroups and d.trashGroups[state.cardTrash]
  if state.cardTrash and not group then state.cardTrash = nil end
  if not group and (not step or not (step.model or step.npc or (step.loot and #step.loot > 0))) then
    card:Hide(); card.modelFor = nil
    return
  end
  card:Show()
  PlaceCard()
  local ids, top
  if group then
    card.title:SetText(T(group.name))
    card.kind:SetText(group.trash and L.TRASH_ALL or L.TRASH_NAMED)
    card.mbg:Hide(); card.model:Hide(); card.noModel:Hide(); card.modelFor = nil
    card.lootLabel:ClearAllPoints(); card.lootLabel:SetPoint("TOPLEFT", 10, -44)
    card.lootLabel:SetText(L.LOOT .. (" (%d)"):format(#group.loot))
    ids, top = group.loot, 44
  else
    card.title:SetText(ns.StepTitle(d, i))
    local kind = L["KIND_" .. step.kind] or step.kind
    if step.optional then kind = kind .. " · " .. L.OPTIONAL end
    card.kind:SetText(kind)
    card.mbg:Show()
    SetCardModel(step)
    card.lootLabel:ClearAllPoints(); card.lootLabel:SetPoint("TOPLEFT", card.mbg, "BOTTOMLEFT", 2, -8)
    card.lootLabel:SetText(L.LOOT .. ((step.loot and #step.loot > 0) and (" (%d)"):format(#step.loot) or ""))
    ids, top = step.loot or {}, 44 + MODEL_H
  end
  local from = group and group.from
  local rowH = from and 30 or 21
  local settled, total, missing = ns.ItemProgress(ids)
  local loading = settled < total
  if loading then
    card.loadBar:SetMinMaxValues(0, total)
    card.loadBar:SetValue(settled)
    card.loadBar.text:SetText(L.ITEMS_LOADING:format(settled, total))
    card.loadBar:Show()
    -- keep ticking: items that never answer turn "missing" after a while
    if not card.ticking and C_Timer and C_Timer.After then
      card.ticking = true
      C_Timer.After(1, function() card.ticking = false; if card:IsShown() then ns.RefreshMap() end end)
    end
  else
    card.loadBar:Hide()
  end
  card.scroll:ClearAllPoints()
  card.scroll:SetPoint("TOPLEFT", card.lootLabel, "BOTTOMLEFT", -2, -4)
  card.scroll:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -28, loading and 24 or 8)
  -- a different list starts at the top again
  local listKey = group and ("g" .. tostring(group)) or ("s" .. tostring(step))
  if card.listKey ~= listKey then
    card.listKey = listKey
    if card.scroll.SetVerticalScroll then card.scroll:SetVerticalScroll(0) end
  end
  local shown = 0
  for k, id in ipairs(ids) do
    local r = CardRow(k)
    r.id = id
    r.from = from and from[id]
    local st = SourceText(r.from)
    r:SetHeight(rowH)
    r.name:ClearAllPoints()
    r.name:SetPoint(st and "TOPLEFT" or "LEFT", r.icon, st and "TOPRIGHT" or "RIGHT", 5, st and 2 or 0)
    r.name:SetPoint("RIGHT", -2, 0)
    r.src:SetText(st or "")
    r.src:SetShown(st ~= nil)
    local name, _, q, icon = ns.ItemInfo(id)
    r.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    QualityBorder(r.border, q)
    local missingItem = not name and ns.ItemState(id) == "missing"
    r.name:SetText(name and (ns.QualityHex(q) .. name .. "|r")
      or ("|cff888888#" .. id .. " " .. (missingItem and L.ITEM_MISSING or L.LOADING) .. "|r"))
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", card.content, "TOPLEFT", 0, -(k - 1) * rowH)
    r:Show()
    shown = k
  end
  for j = shown + 1, #cardRows do cardRows[j]:Hide() end
  card.more:ClearAllPoints()
  card.more:SetPoint("TOPLEFT", card.content, "TOPLEFT", 2, -2 - shown * rowH)
  card.more:SetText(#ids == 0 and L.NO_LOOT or (missing > 0 and L.ITEMS_MISSING:format(missing) or ""))
  card.content:SetHeight(math.max(10, shown * rowH + (missing > 0 and 18 or 4)))
end

---------------------------------------------------------------------------
-- refresh
---------------------------------------------------------------------------
local function Place(f, sc, p, dx, dy)
  f:ClearAllPoints()
  f:SetPoint("CENTER", canvas, "TOPLEFT", (p[1] - view[1]) * sc + (dx or 0), -(p[2] - view[2]) * sc + (dy or 0))
end

local function DrawMarkers(d, page, nextIndex, sc)
  local k, ka = 0, 0
  local g = Geo(d)
  for i, step in ipairs(d.steps) do
    local spage, spos, salt = StepGeo(d, i)
    if spos and spage == page.key and ns.StepVisible(step) then
      local done = ns.IsDone(d, i)
      local cat = Category(step)
      local c = done and CAT.done or CAT[cat]
      -- alternate spawn spots
      for _, ap in ipairs(salt or {}) do
        ka = ka + 1
        local a = GetAlt(ka)
        a.index = i
        Place(a, sc, ap)
        a.ring:SetVertexColor(c[1], c[2], c[3], 1)
        local abn, aic = ns.BossNumber(d, i), ns.KindIcon(step)
        a.text:SetText(abn and tostring(abn) or "")
        if not abn and aic then a.icon:SetTexture(aic); a.icon:Show() else a.icon:Hide() end
        a:Show()
      end
      k = k + 1
      local m = GetMarker(k)
      m.index = i
      Place(m, sc, spos)
      if page.flow then
        -- names wrap within their column so neighbours do not overlap
        m.label:SetWidth(math.max(40, page.colW * sc - 8))
        if m.label.SetWordWrap then m.label:SetWordWrap(true) end
        m.label:SetText(T(step.name)); m.label:Show()
      else
        m.label:Hide()
      end
      -- see-through so the map under the marker stays readable
      m.circle:SetVertexColor(c[1], c[2], c[3], step.optional and 0.45 or 0.6)
      if state.selected == i then m.ring:SetVertexColor(1, 1, 1, 0.9) else m.ring:SetVertexColor(0, 0, 0, 0.5) end
      local bn, ic = ns.BossNumber(d, i), ns.KindIcon(step)
      m.text:SetText(bn and tostring(bn) or "")
      if not bn and ic then m.icon:SetTexture(ic); m.icon:Show() else m.icon:Hide() end
      m.check:SetShown(done)
      local showBadge = step.quest and not done and step.kind ~= "object" and step.kind ~= "task"
      m.badge:SetShown(showBadge); m.badgeText:SetShown(showBadge)
      local isNext = (i == nextIndex) or (state.targetStep == i and state.current == d)
      m.glow:SetShown(isNext)
      if m.pulse then if isNext then m.pulse:Play() else m.pulse:Stop() end end
      m:Show()
    end
  end
  for j = k + 1, #markers do markers[j]:Hide() end
  for j = ka + 1, #alts do alts[j]:Hide() end
  -- entrance and floor links
  if g.start and g.start.page == page.key then
    Place(entranceMark, sc, g.start.pos)
    entranceMark.text:ClearAllPoints()
    if (g.start.pos[2] - view[2]) / view[4] > 0.92 then
      entranceMark.text:SetPoint("BOTTOM", entranceMark, "TOP", 0, 1)
    else
      entranceMark.text:SetPoint("TOP", entranceMark, "BOTTOM", 0, -1)
    end
    entranceMark:Show()
  else
    entranceMark:Hide()
  end
  local kl = 0
  for _, ln in ipairs(g.links or {}) do
    if ln.page == page.key then
      kl = kl + 1
      local l = GetLink(kl)
      l.label = T(ln.text)
      l.toPage = ln.toPage
      l.name:SetText(ln.to and T(ln.to) or "")
      Place(l, sc, ln.pos)
      l:Show()
    end
  end
  for j = kl + 1, #links do links[j]:Hide() end
end

-- Atlas prints its own legend numbers on the images; cover them so only
-- this addon's numbers (which follow the Forever route order) are visible.
local function DrawMasks(page, sc)
  local k = 0
  for _, p in ipairs(page.mask or {}) do
    k = k + 1
    local m = masks[k]
    if not m then
      m = { outer = canvas:CreateTexture(nil, "BACKGROUND", nil, 2), inner = canvas:CreateTexture(nil, "BACKGROUND", nil, 3) }
      for _, t in ipairs({ m.outer, m.inner }) do
        t:SetColorTexture(1, 1, 1, 1)
        if canvas.CreateMaskTexture then
          local mk = canvas:CreateMaskTexture()
          mk:SetTexture(MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
          mk:SetAllPoints(t)
          t:AddMaskTexture(mk)
        end
      end
      m.outer:SetVertexColor(0.08, 0.07, 0.06, 0.45)
      m.inner:SetVertexColor(0.08, 0.07, 0.06, 0.85)
      masks[k] = m
    end
    m.outer:SetSize(24 * sc, 24 * sc); m.inner:SetSize(17 * sc, 17 * sc)
    for _, t in ipairs({ m.outer, m.inner }) do
      t:ClearAllPoints()
      t:SetPoint("CENTER", canvas, "TOPLEFT", p[1] * sc, -p[2] * sc)
      t:Show()
    end
  end
  for j = k + 1, #masks do masks[j].outer:Hide(); masks[j].inner:Hide() end
end

-- Blizzard map: pick the first tile set the client has (some maps moved to
-- other file IDs between client versions). nil = none of them loads.
-- Minimap pages (page.grid): 512 px tiles at absolute minimap positions.
local function TileSet(page)
  if page.set ~= nil then return page.set or nil end
  page.set = false
  if page.img then page.set = page.img; return page.set end      -- bundled image
  if page.grid then
    local first = page.grid.tiles[1]
    local ok, loaded = pcall(tiles[1].SetTexture, tiles[1], first and first[1])
    if first and ok and loaded ~= false then page.set = page.grid end
    return page.set or nil
  end
  for _, set in ipairs(page.tiles) do
    local ok, loaded = pcall(tiles[1].SetTexture, tiles[1], set[1])
    if ok and loaded ~= false then page.set = set; break end
  end
  return page.set or nil
end

local function DrawTiles(page, sc)
  local set = page and (page.tiles or page.grid or page.img) and TileSet(page)
  local n = 0
  local function put(file, tx, ty, size)
    local x0, x1 = math.max(tx, view[1]), math.min(tx + size, view[1] + view[3])
    local y0, y1 = math.max(ty, view[2]), math.min(ty + size, view[2] + view[4])
    if x1 <= x0 or y1 <= y0 then return end
    n = n + 1
    local t = tiles[n]
    if not t then t = canvas:CreateTexture(nil, "BACKGROUND"); tiles[n] = t end
    t:SetTexture(file)
    t:SetTexCoord((x0 - tx) / size, (x1 - tx) / size, (y0 - ty) / size, (y1 - ty) / size)
    t:ClearAllPoints()
    t:SetPoint("TOPLEFT", canvas, "TOPLEFT", (x0 - view[1]) * sc, -(y0 - view[2]) * sc)
    t:SetSize((x1 - x0) * sc, (y1 - y0) * sc)
    t:Show()
  end
  if set and page.img then
    put(MAP_PATH .. page.img[1], page.img[2], page.img[3], page.img[4])
  elseif set and page.grid then
    local size = page.grid.size or 512
    for _, g in ipairs(page.grid.tiles) do put(g[1], g[2] * size, g[3] * size, size) end
  elseif set then
    for k = 1, 12 do put(set[k], ((k - 1) % 4) * 256, math.floor((k - 1) / 4) * 256, 256) end
  end
  for k = n + 1, #tiles do tiles[k]:Hide() end
  return set ~= nil
end

local flowLines = {}
local function DrawFlowLines(d, page, sc)
  local k = 0
  if page and page.flow then
    local g = Geo(d)
    local prev
    for _, i in ipairs(g.order or {}) do
      local s = g.steps[d.steps[i].id]
      if s and ns.StepVisible(d.steps[i]) then
        if prev then
          k = k + 1
          local ln = flowLines[k]
          if not ln then ln = overlay:CreateLine(nil, "BACKGROUND"); flowLines[k] = ln end
          ln:SetThickness(2)
          ln:SetColorTexture(0.7, 0.7, 0.7, 0.45)
          ln:SetStartPoint("TOPLEFT", canvas, prev[1] * sc, -prev[2] * sc)
          ln:SetEndPoint("TOPLEFT", canvas, s.pos[1] * sc, -s.pos[2] * sc)
          ln:Show()
        end
        prev = s.pos
      end
    end
  end
  for j = k + 1, #flowLines do flowLines[j]:Hide() end
end

local function HideMapLayer()
  for _, t in ipairs(markers) do t:Hide() end
  for _, t in ipairs(alts) do t:Hide() end
  for _, t in ipairs(links) do t:Hide() end
  for _, m in ipairs(masks) do m.outer:Hide(); m.inner:Hide() end
  entranceMark:Hide()
end

local function RowTag(step, d, i)
  if step.outside then return L.OUTSIDE end
  if step.unconfirmed and step.kind ~= "fork" then return L.UNCONFIRMED end
  if step.kind == "rare" then return L.KIND_rare end
  if step.optional then return L.OPTIONAL end
  if step.kind ~= "boss" then return L["KIND_" .. step.kind] or "" end
  return ""
end

local function GetLootBtn(k)
  local b = lootBtns[k]
  if b then return b end
  b = CreateFrame("Button", nil, lootBar)
  b:SetSize(22, 22)
  b.icon = b:CreateTexture(nil, "ARTWORK"); b.icon:SetAllPoints()
  b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  -- quality frame sits behind the icon so only a 1px edge shows
  b.border = b:CreateTexture(nil, "BACKGROUND")
  b.border:SetPoint("TOPLEFT", -1, 1); b.border:SetPoint("BOTTOMRIGHT", 1, -1)
  b.border:SetColorTexture(1, 1, 1, 0)
  local hl = b:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.25)
  b:RegisterForClicks("LeftButtonUp")
  b:SetScript("OnEnter", LootOnEnter)
  b:SetScript("OnLeave", GameTooltip_Hide)
  b:SetScript("OnClick", LootOnClick)
  lootBtns[k] = b
  return b
end

-- Show item icons for ids (nil hides the bar). Returns the bar height used.
local lootFrom   -- sources of the items in the bar (trash groups)
-- Two rows of icons; longer lists scroll a row per mouse-wheel step.
local function DrawLoot(ids, label, from)
  lootFrom = from
  if not ids or #ids == 0 then lootBar:Hide(); return 0 end
  lootBar:Show()
  local perRow = math.floor((LISTW - PAD) / 24)
  local maxBtn = perRow * 2
  if lootBar.ids ~= ids then lootBar.ids, lootBar.offset = ids, 0 end
  local maxOffset = math.max(0, math.ceil(#ids / perRow) - 2)
  lootBar.offset = math.max(0, math.min(lootBar.offset or 0, maxOffset))
  lootBar.maxOffset = maxOffset
  local first = lootBar.offset * perRow
  if maxOffset > 0 then
    label = ("%s |cff999999(%d · %s %d/%d)|r"):format(label, #ids, L.WHEEL, lootBar.offset + 1, maxOffset + 1)
  end
  local settled, total = ns.ItemProgress(ids)
  if settled < total then label = label .. (" |cff66b3ff%s|r"):format(L.ITEMS_LOADING:format(settled, total)) end
  lootLabel:SetText(label)
  for k = 1, maxBtn do
    local id = ids[first + k]
    if not id then break end
    local b = GetLootBtn(k)
    b.id = id
    b.from = lootFrom and lootFrom[id]
    local _, _, q, icon = ns.ItemInfo(id)
    b.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    QualityBorder(b.border, q)
    b:ClearAllPoints()
    local row, col = math.floor((k - 1) / perRow), (k - 1) % perRow
    b:SetPoint("TOPLEFT", lootBar, "TOPLEFT", 2 + col * 24, -14 - row * 24)
    b:Show()
  end
  for j = math.min(#ids - first, maxBtn) + 1, #lootBtns do lootBtns[j]:Hide() end
  local rows_ = math.min(2, math.ceil(#ids / perRow))
  lootBar:SetHeight(14 + rows_ * 24)
  return 14 + rows_ * 24 + 4
end

local function HideTrashBtns() for _, b in ipairs(trashBtns) do b:Hide() end end

local function DrawRouteList(d, nextIndex)
  HideTrashBtns()
  local avail = list:GetHeight() - 26 - 70
  local groups = d.trashGroups or {}
  local count = #groups
  for _, step in ipairs(d.steps) do if ns.StepVisible(step) then count = count + 1 end end
  local rowH = math.max(13, math.min(17, math.floor(avail / math.max(1, count))))
  local y, k = -26, 0
  for i, step in ipairs(d.steps) do
    if ns.StepVisible(step) then
      k = k + 1
      local r = GetRow(k)
      r.index = i
      r:SetHeight(rowH)
      r:ClearAllPoints()
      r:SetPoint("TOPLEFT", 0, y)
      y = y - rowH
      local done = ns.IsDone(d, i)
      r.check:SetShown(done)
      local c = CAT[Category(step)]
      r.dot:SetVertexColor(c[1], c[2], c[3], 1)
      r.dot:SetShown(not done and step.kind ~= "fork")
      local rbn, ric = ns.BossNumber(d, i), ns.KindIcon(step)
      r.num:SetText(rbn and tostring(rbn) or "")
      if not rbn and ric then r.kicon:SetTexture(ric); r.kicon:Show() else r.kicon:Hide() end
      r.name:SetText(T(step.name))
      if done then r.name:SetTextColor(0.55, 0.55, 0.55)
      elseif i == nextIndex then r.name:SetTextColor(1, 0.82, 0)
      elseif step.kind == "fork" then r.name:SetTextColor(0.7, 0.7, 0.7)
      elseif step.optional then r.name:SetTextColor(0.82, 0.7, 1)
      else r.name:SetTextColor(1, 1, 1) end
      r.group = nil
      r.tag:SetText(RowTag(step, d, i))
      r.bg:SetShown(state.selected == i)
      r:Show()
    end
  end
  -- trash mobs (and named mobs off the route) at the end of the route
  for gk, g in ipairs(groups) do
    k = k + 1
    local r = GetRow(k)
    r.index, r.group = nil, gk
    r:SetHeight(rowH)
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", 0, y)
    y = y - rowH
    r.check:Hide()
    r.dot:SetVertexColor(0.6, 0.6, 0.6, 1); r.dot:Show()
    r.num:SetText("")
    r.kicon:SetTexture(TRASH_ICON); r.kicon:Show()
    r.name:SetText(T(g.name))
    r.name:SetTextColor(0.8, 0.8, 0.8)
    r.tag:SetText(L.LOOT .. " " .. #g.loot)
    r.bg:SetShown(state.cardTrash == gk)
    r:Show()
  end
  for j = k + 1, #rows do rows[j]:Hide() end
  local tg = state.cardTrash and groups[state.cardTrash]
  if tg then
    local used = DrawLoot(tg.loot, L.LOOT .. " · " .. T(tg.name), tg.from)
    tipText:ClearAllPoints()
    tipText:SetPoint("TOPLEFT", 4, y - 6)
    tipText:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", -4, used)
    tipText:SetText("|cffffd100" .. T(tg.name) .. "|r\n" .. L.TRASH_TIP:format(#tg.loot))
    tipText:Show()
    for j = 1, #qrows do qrows[j]:Hide() end
    questNote:Hide()
    return
  end
  local i = state.selected or nextIndex
  local step = i and d.steps[i]
  local used = DrawLoot(step and step.loot, L.LOOT .. (step and (" · " .. T(step.name)) or ""))
  tipText:ClearAllPoints()
  tipText:SetPoint("TOPLEFT", 4, y - 6)
  tipText:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", -4, used)
  if i then
    local step = d.steps[i]
    tipText:SetText("|cffffd100" .. ns.StepTitle(d, i) .. "|r\n" .. T(step.tip))
  else
    tipText:SetText("|cff55ff55" .. L.DONE_ALL .. "|r")
  end
  tipText:Show()
  for j = 1, #qrows do qrows[j]:Hide() end
  questNote:Hide()
end

local function DrawQuestList(d)
  HideTrashBtns()
  for j = 1, #rows do rows[j]:Hide() end
  tipText:Hide()
  DrawLoot(nil)
  local y, k = -26, 0
  local maxRows = math.floor((list:GetHeight() - 60) / 31)
  for _, q in ipairs(d.quests or {}) do
    if ns.StepVisible(q) and k < maxRows then
      k = k + 1
      local r = GetQuestRow(k)
      r.q = q
      r:ClearAllPoints()
      r:SetPoint("TOPLEFT", 0, y)
      y = y - 31
      local st = QuestStatus(q.id)
      r.name:SetText(T(q.name))
      if st == "done" then r.status:SetText("|cff55ff55" .. L.Q_DONE .. "|r")
      elseif st == "active" then r.status:SetText("|cffffd100" .. L.Q_ACTIVE .. "|r")
      else r.status:SetText("|cff999999" .. L.Q_MISSING .. "|r") end
      r.giver:SetText(T(q.giver))
      r:Show()
    end
  end
  for j = k + 1, #qrows do qrows[j]:Hide() end
  questNote:ClearAllPoints()
  questNote:SetPoint("TOPLEFT", 4, y - 6)
  questNote:SetText(k == 0 and L.NO_QUESTS or L.Q_NOTE)
  questNote:Show()
end

local function DrawNotes(d)
  for j = 1, #rows do rows[j]:Hide() end
  for j = 1, #qrows do qrows[j]:Hide() end
  questNote:Hide()
  local parts = {}
  for _, n in ipairs(d.notes or {}) do parts[#parts + 1] = "• " .. T(n) end
  if d.entrance then
    parts[#parts + 1] = ("|cff4fd96f%s|r %s (%.1f, %.1f)"):format(L.LEG_ENTRANCE, T(d.entrance.zone), d.entrance.x, d.entrance.y)
  end
  DrawLoot(nil)
  -- drops of mobs that are not route steps, one button per source; the
  -- list opens in the card next to the window
  local groups = d.trashGroups or {}
  local used = 0
  for k = #groups, 1, -1 do
    local g = groups[k]
    local b = trashBtns[k]
    if not b then
      b = Btn(list, "", LISTW - PAD - 4, nil, function(self)
        state.selected = nil
        state.cardTrash = (state.cardTrash == self.index) and nil or self.index
        ns.RefreshMap()
      end)
      trashBtns[k] = b
    end
    b.index = k
    b:SetText(("%s · %s %d"):format(T(g.name), L.LOOT, #g.loot))
    b:ClearAllPoints()
    b:SetPoint("BOTTOMLEFT", list, "BOTTOMLEFT", 0, used)
    b:SetAlpha(state.cardTrash == k and 1 or 0.85)
    b:Show()
    used = used + 22
  end
  for j = #groups + 1, #trashBtns do trashBtns[j]:Hide() end
  if #groups > 0 then used = used + 4 end
  tipText:ClearAllPoints()
  tipText:SetPoint("TOPLEFT", 4, -30)
  tipText:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", -4, used)
  tipText:SetText(#parts > 0 and table.concat(parts, "\n\n") or L.NO_NOTES)
  tipText:Show()
end

function ns.RefreshMap()
  if not frame or not frame:IsShown() then return end
  local d = state.viewed
  if not d then return end
  local nextIndex = ns.NextStep(d)
  local page = CurrentPage(d)
  -- Blizzard art missing from this client: fall back to Atlas for the dungeon
  if page and (page.tiles or page.grid) and not TileSet(page) then
    blizFailed[d.key] = true
    page = CurrentPage(d)
  end
  view = ViewOf(page)
  state.shownPage = page and page.key
  local sig = tostring(d) .. tostring(view) .. tostring(ns.db.mapSize) .. tostring(ns.db.showList)
  if frame.layoutSig ~= sig then frame.layoutSig = sig; Layout() end
  local sc = Scale()
  title:SetText(("%s |cffaaaaaa%s|r"):format(T(d.name), d.levels or ""))
  local away = state.current ~= nil and state.current ~= d
  currentBtn:SetEnabled(away)
  currentBtn:SetAlpha(away and 1 or 0.45)
  if page then
    if page.flow then
      mapTex:Hide()
      DrawTiles(nil)
    elseif page.tiles or page.grid or page.img then
      mapTex:Hide()
      DrawTiles(page, sc)
    else
      DrawTiles(nil)
      mapTex:SetTexture(MAP_PATH .. page.map)
      mapTex:Show()
    end
    noMapText:SetShown(false)
    DrawMasks(page, sc)
    DrawMarkers(d, page, nextIndex, sc)
    DrawFlowLines(d, page, sc)
  else
    mapTex:Hide()
    DrawTiles(nil)
    noMapText:Show()
    HideMapLayer()
    DrawFlowLines(d, nil, sc)
  end
  DrawFloors(d, page)
  if ns.db.showList then
    local done, total = ns.Counts(d)
    progressText:SetText(("|TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:12:12|t %d/%d"):format(done, total))
    local tab = ns.db.listTab
    if tab == "quest" then DrawQuestList(d) elseif tab == "notes" then DrawNotes(d) else DrawRouteList(d, nextIndex) end
    tabRoute:SetAlpha((tab ~= "quest" and tab ~= "notes") and 1 or 0.55)
    tabQuest:SetAlpha(tab == "quest" and 1 or 0.55)
    tabNotes:SetAlpha(tab == "notes" and 1 or 0.55)
  end
  -- Only notes that matter while playing (credits live in CREDITS.txt).
  local parts = {}
  if state.edit then parts[#parts + 1] = "|cffff5555EDIT|r" end
  if state.current ~= d then parts[#parts + 1] = L.BROWSE_ONLY end
  if page and page.schematic then parts[#parts + 1] = L.SCHEMATIC end
  if page and page.flow then parts[#parts + 1] = L.FLOW_ONLY end
  if page and page.approx then parts[#parts + 1] = L.APPROX end
  if page and page.tiles and d.bliz and d.bliz.preview then parts[#parts + 1] = L.PREVIEW_MAP end
  footer:SetText(table.concat(parts, " · "))
  DrawCard(d)
  RefreshMenu()
end

function ns.ApplyAlpha()
  if not frame then return end
  local a = ns.db.alpha
  if state.inCombat and ns.db.combatFade then a = math.min(a, ns.db.combatAlpha) end
  frame:SetAlpha(a)
end

function ns.RebuildMap()
  if not frame then return end
  frame.layoutSig = nil
  Layout()
  ns.RefreshMap()
end

function ns.SetMapStyle(style)
  ns.db.mapStyle = (style == "atlas") and "atlas" or "blizzard"
  for k in pairs(blizFailed) do blizFailed[k] = nil end
  for _, d in ipairs(ns.Dungeons) do
    for _, p in ipairs(d.bliz and d.bliz.pages or {}) do p.set = nil end
  end
  ns.Print(L.MAPSTYLE_SET:format(ns.db.mapStyle == "atlas" and L.MAP_ATLAS or L.MAP_BLIZ))
  ns.RebuildMap()
end

function ns.ShowMap(d, auto)
  if not frame then Create() end
  state.viewed = d or state.viewed or state.current or (ns.SuggestDungeon and ns.SuggestDungeon()) or ns.Dungeons[1]
  frame.autoShown = auto and true or false
  frame:Show()
  ns.RefreshMap()
end

function ns.HideMapIfAuto()
  if frame and frame:IsShown() and frame.autoShown then frame:Hide() end
end

function ns.ToggleMap()
  if frame and frame:IsShown() then frame:Hide() else ns.ShowMap(state.current or state.viewed) end
end

function ns.CycleViewed(dir)
  local all = ns.Dungeons
  local idx = 1
  for k, d in ipairs(all) do if d == state.viewed then idx = k end end
  idx = (idx - 1 + dir) % #all + 1
  state.viewed = all[idx]
  state.selected = nil
  ns.RefreshMap()
end

---------------------------------------------------------------------------
-- route edit mode
---------------------------------------------------------------------------
function ns.SetEditMode(on)
  state.edit = on and true or false
  if on and (not frame or not frame:IsShown()) then ns.ShowMap(state.viewed or state.current) end
  ns.Print(state.edit and L.EDIT_ON or L.EDIT_OFF)
  ns.RefreshMap()
end

function ns.EditClick(button)
  if not state.edit then return end
  local d = state.viewed
  local i = state.selected or ns.NextStep(d)
  if not d or not i then return end
  local step = d.steps[i]
  local cx, cy = GetCursorPosition()
  local s = canvas:GetEffectiveScale()
  local sc = Scale()
  local x = math.floor((cx / s - canvas:GetLeft()) / sc + view[1] + 0.5)
  local y = math.floor((canvas:GetTop() - cy / s) / sc + view[2] + 0.5)
  if not (d.pages and #d.pages > 0) and not UseBliz(d) then return end   -- flow chart
  local field = UseBliz(d) and "bpos" or "pos"
  if button == "RightButton" then
    local e = ns.Edits(d, step)
    if e then e[field] = nil end
    ns.Print(L.EDIT_CLEAR:format(T(step.name)))
  else
    ns.Edits(d, step, true)[field] = { x, y }
    ns.Print(L.EDIT_MARK:format(T(step.name), x, y))
  end
  ns.RefreshMap()
end

local exportFrame
function ns.ShowExport()
  local out = {}
  for _, d in ipairs(ns.Dungeons) do
    local r = ns.db.routes[d.key]
    if r then
      for _, step in ipairs(d.steps) do
        local e = r[step.id]
        if e then
          local parts = {}
          if e.pos then parts[#parts + 1] = ("pos = { %d, %d }"):format(e.pos[1], e.pos[2]) end
          if e.bpos then parts[#parts + 1] = ("bliz = { %d, %d }"):format(e.bpos[1], e.bpos[2]) end
          if e.path then
            local pts = {}
            for _, p in ipairs(e.path) do pts[#pts + 1] = ("{ %d, %d }"):format(p[1], p[2]) end
            parts[#parts + 1] = "path = { " .. table.concat(pts, ", ") .. " }"
          end
          out[#out + 1] = ("-- %s / %s\n%s"):format(d.key, step.id, table.concat(parts, ",\n"))
        end
      end
    end
  end
  local text = #out > 0 and table.concat(out, "\n\n") or "-- no edits"
  if not exportFrame then
    exportFrame = CreateFrame("Frame", "DungeonRouteGuideExport", UIParent, "BackdropTemplate")
    Backdrop(exportFrame, 0.95)
    exportFrame:SetSize(440, 280)
    exportFrame:SetPoint("CENTER")
    exportFrame:SetFrameStrata("DIALOG")
    exportFrame:EnableMouse(true)
    local hint = exportFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    hint:SetPoint("TOPLEFT", 8, -8)
    ns.Loc(hint, "EXPORT_HINT")
    local close = Btn(exportFrame, "X", 22, nil, function() exportFrame:Hide() end)
    close:SetPoint("TOPRIGHT", -6, -4)
    local scroll = CreateFrame("ScrollFrame", nil, exportFrame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 8, -28)
    scroll:SetPoint("BOTTOMRIGHT", -28, 8)
    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetFontObject(ChatFontNormal)
    edit:SetWidth(390)
    edit:SetAutoFocus(false)
    edit:SetScript("OnEscapePressed", function() exportFrame:Hide() end)
    scroll:SetScrollChild(edit)
    exportFrame.edit = edit
    if UISpecialFrames then tinsert(UISpecialFrames, "DungeonRouteGuideExport") end
  end
  exportFrame.edit:SetText(text)
  exportFrame:Show()
  exportFrame.edit:SetFocus()
  exportFrame.edit:HighlightText()
end

-- donation link: WoW cannot open a browser, so show the address to copy
local donateFrame
function ns.ShowDonate()
  if ns.DONATE_URL == "" then return end
  if not donateFrame then
    donateFrame = CreateFrame("Frame", "DungeonRouteGuideDonate", UIParent, "BackdropTemplate")
    Backdrop(donateFrame, 0.96)
    donateFrame:SetSize(380, 112)
    donateFrame:SetPoint("CENTER", 0, 120)
    donateFrame:SetFrameStrata("DIALOG")
    donateFrame:EnableMouse(true)
    local logo = donateFrame:CreateTexture(nil, "ARTWORK")
    logo:SetTexture("Interface\\AddOns\\DungeonRouteGuide\\Media\\icon")
    logo:SetSize(40, 40); logo:SetPoint("TOPLEFT", 10, -10)
    local text = donateFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    text:SetPoint("TOPLEFT", logo, "TOPRIGHT", 8, 0); text:SetPoint("RIGHT", -30, 0)
    text:SetJustifyH("LEFT")
    ns.Loc(text, "DONATE_TEXT")
    local close = Btn(donateFrame, "X", 22, nil, function() donateFrame:Hide() end)
    close:SetPoint("TOPRIGHT", -6, -6)
    local box = CreateFrame("EditBox", nil, donateFrame, "InputBoxTemplate")
    box:SetSize(340, 22)
    box:SetPoint("BOTTOM", 0, 14)
    box:SetAutoFocus(false)
    box:SetFontObject(ChatFontNormal)
    -- keep the address intact if the player types into the box
    box:SetScript("OnTextChanged", function(self, user) if user then self:SetText(ns.DONATE_URL); self:HighlightText() end end)
    box:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    box:SetScript("OnEscapePressed", function() donateFrame:Hide() end)
    donateFrame.box = box
    if UISpecialFrames then tinsert(UISpecialFrames, "DungeonRouteGuideDonate") end
  end
  donateFrame.box:SetText(ns.DONATE_URL)
  donateFrame:Show()
  donateFrame.box:SetFocus()
  donateFrame.box:HighlightText()
end
