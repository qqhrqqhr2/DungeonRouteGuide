-- Dungeon Route Guide - main window: Atlas map pages, route lines, markers
-- (entrance / boss / rare / NPC / quest spot, alternate spawn spots), legend,
-- route / quest / prep tabs, dungeon picker, options menu, route edit mode.
local _, ns = ...
local L, T = ns.L, ns.T
local state = ns.state

local HEADER, PAD, LISTW = 28, 6, 240
local LEGEND_H, FOOT_H, PAGES_H = 16, 14, 22
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

local frame, canvas, overlay, mapTex, noMapText, title, footer, legend, pageBar, list, menu, picker
local lines, markers, alts, links, rows, qrows, pageBtns, masks = {}, {}, {}, {}, {}, {}, {}, {}
local dropdown, currentBtn
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
      GameTooltip:SetText(tip, 1, 1, 1, 1, true)
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
  end
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

local function Scale() return (ns.db.mapSize or 380) / 512 end

local function HasMap(d) return d.pages and #d.pages > 0 end

local function StepTooltip(owner, d, i)
  local step = d.steps[i]
  GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
  GameTooltip:SetText(step.n .. ". " .. T(step.name), 1, 0.82, 0)
  local kind = L["KIND_" .. step.kind] or step.kind
  if step.optional then kind = kind .. " · " .. L.OPTIONAL end
  if step.unconfirmed then kind = kind .. " · " .. L.UNCONFIRMED end
  if step.outside then kind = kind .. " · " .. T(step.outside) end
  GameTooltip:AddLine(kind, 0.7, 0.7, 0.7)
  if step.quest then GameTooltip:AddLine("! " .. L.QUEST_MARK, 1, 0.82, 0) end
  GameTooltip:AddLine(T(step.tip), 1, 1, 1, true)
  GameTooltip:AddLine(L.CLICK_HINT, 0.5, 0.8, 1, true)
  GameTooltip:Show()
end

local function StepClick(d, i, button)
  if button == "RightButton" then
    ns.SetDone(d, i, not ns.IsDone(d, i))
  else
    state.selected = (state.selected == i) and nil or i
    local step = d.steps[i]
    if step.page then state.page, state.pageManual = step.page, true end
    ns.RefreshMap()
  end
end

-- current map page of the viewed dungeon
local function CurrentPage(d)
  if not HasMap(d) then return nil end
  if state.pageDungeon ~= d then state.pageDungeon, state.page, state.pageManual = d, nil, false end
  if state.pageManual and state.page then
    for _, p in ipairs(d.pages) do if p.key == state.page then return p end end
  end
  local i = ns.NextStep(d)
  local want = i and d.steps[i].page
  for _, p in ipairs(d.pages) do if p.key == want then return p end end
  return d.pages[1]
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
      state.viewed = d; state.selected = nil
      picker:Hide(); ns.RefreshMap()
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
  a:SetAlpha(0.6)
  a:SetScript("OnEnter", function(self)
    StepTooltip(self, state.viewed, self.index)
    GameTooltip:AddLine(L.LEG_ALT, 0.8, 0.8, 0.8); GameTooltip:Show()
  end)
  a:SetScript("OnLeave", GameTooltip_Hide)
  alts[k] = a
  return a
end

local function GetLink(k)
  local l = links[k]
  if l then return l end
  l = CreateFrame("Button", nil, overlay)
  l:SetSize(12, 12)
  l:SetFrameLevel(overlay:GetFrameLevel() + 1)
  l.tex = l:CreateTexture(nil, "ARTWORK")
  l.tex:SetAllPoints()
  l.tex:SetColorTexture(CAT.link[1], CAT.link[2], CAT.link[3], 0.85)
  l.tex:SetRotation(math.pi / 4)
  l:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(self.label or "", 1, 1, 1, 1, true); GameTooltip:Show()
  end)
  l:SetScript("OnLeave", GameTooltip_Hide)
  links[k] = l
  return l
end

local function GetLine(k)
  if not lines[k] then lines[k] = overlay:CreateLine(nil, "ARTWORK") end
  return lines[k]
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
  r.tag = r:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  r.tag:SetPoint("RIGHT", -2, 0)
  r.name = r:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  r.name:SetPoint("LEFT", r.num, "RIGHT", 5, 0)
  r.name:SetPoint("RIGHT", r.tag, "LEFT", -4, 0)
  r.name:SetJustifyH("LEFT")
  if r.name.SetWordWrap then r.name:SetWordWrap(false) end
  r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  r:SetScript("OnEnter", function(self) StepTooltip(self, state.viewed, self.index) end)
  r:SetScript("OnLeave", GameTooltip_Hide)
  r:SetScript("OnClick", function(self, button) StepClick(state.viewed, self.index, button) end)
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
end

local function Layout()
  local S = ns.db.mapSize
  local d = state.viewed
  local multi = d and HasMap(d) and #d.pages > 1
  local w = PAD + S + PAD + (ns.db.showList and LISTW or 0)
  local h = HEADER + S + (multi and PAGES_H or 0) + LEGEND_H + FOOT_H + 8
  frame:SetSize(w, h)
  canvas:SetSize(S, S)
  pageBar:SetShown(multi and true or false)
  legend:ClearAllPoints()
  legend:SetPoint("TOPLEFT", canvas, "BOTTOMLEFT", 0, multi and -(PAGES_H + 2) or -3)
  list:SetShown(ns.db.showList)
  list:SetHeight(S + (multi and PAGES_H or 0) + LEGEND_H)
end

local function CreateLegend()
  legend = CreateFrame("Frame", nil, frame)
  legend:SetSize(400, LEGEND_H)
  local x = 0
  for _, key in ipairs({ "entrance", "boss", "rare", "npc", "quest" }) do
    local dot = Circle(legend, "ARTWORK", 9)
    dot:ClearAllPoints(); dot:SetPoint("LEFT", x, 0)
    dot:SetVertexColor(CAT[key][1], CAT[key][2], CAT[key][3], 1)
    local fs = legend:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    fs:SetPoint("LEFT", x + 12, 0)
    fs:SetText(L["LEG_" .. key:upper()])
    x = x + 16 + (fs:GetStringWidth() or 40) + 10
  end
end

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
  currentBtn = Btn(frame, L.BTN_CURRENT, 64, L.TIP_CURRENT, function()
    if state.current then
      state.viewed, state.selected, state.pageManual = state.current, nil, false
      picker:Hide(); ns.RefreshMap()
    end
  end)
  currentBtn:SetPoint("RIGHT", listBtn, "LEFT", -6, 0)
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
  titleBtn:SetScript("OnClick", function() menu:Hide(); picker:SetShown(not picker:IsShown()) end)
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
  noMapText = canvas:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  noMapText:SetPoint("CENTER"); noMapText:SetText(L.NO_MAP)
  overlay = CreateFrame("Frame", nil, canvas)
  overlay:SetAllPoints()
  overlay:SetFrameLevel(canvas:GetFrameLevel() + 2)
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
  entranceMark.text:SetText(L.LEG_ENTRANCE)
  entranceMark.text:SetTextColor(CAT.entrance[1], CAT.entrance[2], CAT.entrance[3])

  -- page buttons (multi-page dungeons)
  pageBar = CreateFrame("Frame", nil, frame)
  pageBar:SetPoint("TOPLEFT", canvas, "BOTTOMLEFT", 0, -2)
  pageBar:SetSize(400, 20)

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
  progressText = list:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  progressText:SetPoint("TOPRIGHT", -4, -4)
  tipText = list:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  tipText:SetJustifyH("LEFT"); tipText:SetJustifyV("TOP")
  tipText:SetWidth(LISTW - 16)
  questNote = list:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  questNote:SetJustifyH("LEFT"); questNote:SetJustifyV("TOP")
  questNote:SetWidth(LISTW - 16)

  CreateMenu()
  CreatePicker()
  frame:SetScript("OnHide", function() if menu then menu:Hide() end; if picker then picker:Hide() end end)
  Layout()
  ns.ApplyAlpha()
end

---------------------------------------------------------------------------
-- refresh
---------------------------------------------------------------------------
local function Place(f, sc, p, dx, dy)
  f:ClearAllPoints()
  f:SetPoint("CENTER", canvas, "TOPLEFT", p[1] * sc + (dx or 0), -p[2] * sc + (dy or 0))
end

local function DrawRoute(d, page, nextIndex, sc)
  local k = 0
  for i, step in ipairs(d.steps) do
    if step.page == page.key then
      local pts = ns.StepSegment(d, i)
      if pts then
        local done = ns.IsDone(d, i)
        local r, g, b, a, w
        if done then r, g, b, a, w = 0.6, 0.6, 0.6, 0.35, 2
        elseif i == nextIndex then r, g, b, a, w = 1, 0.82, 0, 0.95, 4
        else r, g, b, a, w = 1, 1, 1, 0.5, 2.5 end
        for p = 1, #pts - 1 do
          k = k + 1
          local ln = GetLine(k)
          ln:SetColorTexture(r, g, b, a)
          ln:SetThickness(w)
          ln:SetStartPoint("TOPLEFT", canvas, pts[p][1] * sc, -pts[p][2] * sc)
          ln:SetEndPoint("TOPLEFT", canvas, pts[p + 1][1] * sc, -pts[p + 1][2] * sc)
          ln:Show()
        end
      end
    end
  end
  for j = k + 1, #lines do lines[j]:Hide() end
end

local function DrawMarkers(d, page, nextIndex, sc)
  local k, ka = 0, 0
  for i, step in ipairs(d.steps) do
    if step.pos and step.page == page.key and ns.StepVisible(step) then
      local done = ns.IsDone(d, i)
      local cat = Category(step)
      local c = done and CAT.done or CAT[cat]
      -- alternate spawn spots
      for _, ap in ipairs(step.alt or {}) do
        ka = ka + 1
        local a = GetAlt(ka)
        a.index = i
        Place(a, sc, ap)
        a.ring:SetVertexColor(c[1], c[2], c[3], 1)
        a.text:SetText(step.n)
        a:Show()
      end
      k = k + 1
      local m = GetMarker(k)
      m.index = i
      Place(m, sc, ns.StepPos(d, i))
      -- see-through so the map under the marker stays readable
      m.circle:SetVertexColor(c[1], c[2], c[3], step.optional and 0.45 or 0.6)
      if state.selected == i then m.ring:SetVertexColor(1, 1, 1, 0.9) else m.ring:SetVertexColor(0, 0, 0, 0.5) end
      m.text:SetText(step.n)
      m.check:SetShown(done)
      local showBadge = step.quest and not done
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
  if d.start and d.start.page == page.key then
    Place(entranceMark, sc, d.start.pos)
    entranceMark.text:ClearAllPoints()
    if d.start.pos[2] > 470 then
      entranceMark.text:SetPoint("BOTTOM", entranceMark, "TOP", 0, 1)
    else
      entranceMark.text:SetPoint("TOP", entranceMark, "BOTTOM", 0, -1)
    end
    entranceMark:Show()
  else
    entranceMark:Hide()
  end
  local kl = 0
  for _, ln in ipairs(d.links or {}) do
    if ln.page == page.key then
      kl = kl + 1
      local l = GetLink(kl)
      l.label = T(ln.text)
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

local function HideMapLayer()
  for _, t in ipairs(lines) do t:Hide() end
  for _, t in ipairs(markers) do t:Hide() end
  for _, t in ipairs(alts) do t:Hide() end
  for _, t in ipairs(links) do t:Hide() end
  for _, m in ipairs(masks) do m.outer:Hide(); m.inner:Hide() end
  entranceMark:Hide()
end

local function DrawPages(d, page)
  local multi = HasMap(d) and #d.pages > 1
  if not multi then pageBar:Hide(); return end
  pageBar:Show()
  for k, p in ipairs(d.pages) do
    local b = pageBtns[k]
    if not b then
      b = Btn(pageBar, "", 80, nil, function(self)
        state.page, state.pageManual = self.key, true
        ns.RefreshMap()
      end)
      b:SetPoint("LEFT", (k - 1) * 84, 0)
      pageBtns[k] = b
    end
    b.key = p.key
    b:SetText(p.name and T(p.name) or L.PAGE:format(k))
    b:SetAlpha(p == page and 1 or 0.55)
    b:Show()
  end
  for j = #d.pages + 1, #pageBtns do pageBtns[j]:Hide() end
end

local function RowTag(step)
  if step.outside then return L.OUTSIDE end
  if step.unconfirmed and step.kind ~= "fork" then return L.UNCONFIRMED end
  if step.kind == "rare" then return L.KIND_rare end
  if step.optional then return L.OPTIONAL end
  if step.kind ~= "boss" then return L["KIND_" .. step.kind] or "" end
  return ""
end

local function DrawRouteList(d, nextIndex)
  local avail = list:GetHeight() - 26 - 70
  local count = 0
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
      r.num:SetText(step.n)
      r.name:SetText(T(step.name))
      if done then r.name:SetTextColor(0.55, 0.55, 0.55)
      elseif i == nextIndex then r.name:SetTextColor(1, 0.82, 0)
      elseif step.kind == "fork" then r.name:SetTextColor(0.7, 0.7, 0.7)
      elseif step.optional then r.name:SetTextColor(0.82, 0.7, 1)
      else r.name:SetTextColor(1, 1, 1) end
      r.tag:SetText(RowTag(step))
      r.bg:SetShown(state.selected == i)
      r:Show()
    end
  end
  for j = k + 1, #rows do rows[j]:Hide() end
  local i = state.selected or nextIndex
  tipText:ClearAllPoints()
  tipText:SetPoint("TOPLEFT", 4, y - 6)
  tipText:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", -4, 0)
  if i then
    local step = d.steps[i]
    tipText:SetText("|cffffd100" .. step.n .. ". " .. T(step.name) .. "|r\n" .. T(step.tip))
  else
    tipText:SetText("|cff55ff55" .. L.DONE_ALL .. "|r")
  end
  tipText:Show()
  for j = 1, #qrows do qrows[j]:Hide() end
  questNote:Hide()
end

local function DrawQuestList(d)
  for j = 1, #rows do rows[j]:Hide() end
  tipText:Hide()
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
  tipText:ClearAllPoints()
  tipText:SetPoint("TOPLEFT", 4, -30)
  tipText:SetPoint("BOTTOMRIGHT", list, "BOTTOMRIGHT", -4, 0)
  tipText:SetText(#parts > 0 and table.concat(parts, "\n\n") or L.NO_NOTES)
  tipText:Show()
end

function ns.RefreshMap()
  if not frame or not frame:IsShown() then return end
  local d = state.viewed
  if not d then return end
  if frame.layoutFor ~= d then frame.layoutFor = d; Layout() end
  local sc = Scale()
  title:SetText(("%s |cffaaaaaa%s|r"):format(T(d.name), d.levels or ""))
  local away = state.current ~= nil and state.current ~= d
  currentBtn:SetEnabled(away)
  currentBtn:SetAlpha(away and 1 or 0.45)
  local nextIndex = ns.NextStep(d)
  local page = CurrentPage(d)
  if page then
    mapTex:SetTexture(MAP_PATH .. page.map)
    mapTex:Show()
    noMapText:SetShown(false)
    DrawMasks(page, sc)
    for _, ln in ipairs(lines) do ln:Hide() end   -- route lines removed (markers show the order)
    DrawMarkers(d, page, nextIndex, sc)
  else
    mapTex:Hide()
    noMapText:Show()
    HideMapLayer()
  end
  DrawPages(d, page)
  if ns.db.showList then
    local done, total = ns.Counts(d)
    progressText:SetText(L.PROGRESS:format(done, total))
    local tab = ns.db.listTab
    if tab == "quest" then DrawQuestList(d) elseif tab == "notes" then DrawNotes(d) else DrawRouteList(d, nextIndex) end
    tabRoute:SetAlpha((tab ~= "quest" and tab ~= "notes") and 1 or 0.55)
    tabQuest:SetAlpha(tab == "quest" and 1 or 0.55)
    tabNotes:SetAlpha(tab == "notes" and 1 or 0.55)
  end
  local foot
  if page and page.schematic then foot = L.SCHEMATIC .. " · " .. L.SOURCE
  elseif page and page.blank then foot = L.BLANK_MAP .. " · " .. L.SOURCE
  elseif page then foot = (page.credit or "") .. " · " .. L.SOURCE
  else foot = L.SOURCE end
  if state.current ~= d then foot = "|cffaaaaaa" .. L.BROWSE_ONLY .. "|r " .. foot end
  if state.edit then foot = "|cffff5555EDIT|r · " .. foot end
  footer:SetText(foot)
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
  Layout()
  ns.RefreshMap()
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
  if canvas then canvas:EnableMouse(state.edit) end
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
  local x = math.floor((cx / s - canvas:GetLeft()) / sc + 0.5)
  local y = math.floor((canvas:GetTop() - cy / s) / sc + 0.5)
  if button == "RightButton" then
    local r = ns.db.routes[d.key]
    if r then r[step.id] = nil end
    ns.Print(L.EDIT_CLEAR:format(T(step.name)))
  else
    ns.Edits(d, step, true).pos = { x, y }
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
    hint:SetText(L.EXPORT_HINT)
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
