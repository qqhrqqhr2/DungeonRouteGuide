-- Dungeon Route Guide - "next objective" bar shown inside supported dungeons.
local _, ns = ...
local L, T = ns.L, ns.T
local state = ns.state

local hud

local function SmallBtn(parent, text, w, onClick)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(w, 18)
  b:SetText(text)
  local fs = b:GetFontString()
  if fs and GameFontNormalSmall then fs:SetFontObject(GameFontNormalSmall) end
  b:SetScript("OnClick", onClick)
  return b
end

local function Create()
  hud = CreateFrame("Frame", "DungeonRouteGuideHUD", UIParent, "BackdropTemplate")
  hud:SetSize(340, 62)
  if hud.SetBackdrop then
    hud:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    hud:SetBackdropColor(0, 0, 0, 0.55)
    hud:SetBackdropBorderColor(0.65, 0.52, 0.22, 0.7)
  end
  hud:SetFrameStrata("MEDIUM")
  hud:SetClampedToScreen(true)
  hud:SetMovable(true)
  hud:EnableMouse(true)
  hud:RegisterForDrag("LeftButton")
  hud:SetScript("OnDragStart", function(self) if not ns.db.locked then self:StartMoving() end end)
  hud:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local p, _, rp, x, y = self:GetPoint(1)
    ns.db.frames.hud = { p, rp, x, y }
  end)
  local pos = ns.db.frames.hud
  if pos then hud:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4]) else hud:SetPoint("TOP", 0, -110) end

  hud.mapBtn = SmallBtn(hud, L.BTN_MAP, 42, function() ns.ToggleMap() end)
  hud.mapBtn:SetPoint("TOPRIGHT", -4, -4)
  hud.tellBtn = SmallBtn(hud, L.BTN_ANNOUNCE, 62, function() ns.Announce() end)
  hud.tellBtn:SetPoint("RIGHT", hud.mapBtn, "LEFT", -2, 0)
  ns.Loc(hud.mapBtn, "BTN_MAP"); ns.Loc(hud.tellBtn, "BTN_ANNOUNCE")

  hud.head = hud:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  hud.head:SetPoint("TOPLEFT", 8, -7)
  hud.head:SetPoint("RIGHT", hud.tellBtn, "LEFT", -4, 0)
  hud.head:SetJustifyH("LEFT")
  if hud.head.SetWordWrap then hud.head:SetWordWrap(false) end

  hud.line = hud:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  hud.line:SetPoint("TOPLEFT", 8, -24)
  hud.line:SetPoint("RIGHT", -8, 0)
  hud.line:SetJustifyH("LEFT")
  if hud.line.SetWordWrap then hud.line:SetWordWrap(false) end

  hud.tip = hud:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  hud.tip:SetPoint("TOPLEFT", 8, -42)
  hud.tip:SetPoint("RIGHT", -8, 0)
  hud.tip:SetJustifyH("LEFT")
  hud.tip:SetTextColor(0.85, 0.85, 0.85)
  if hud.tip.SetWordWrap then hud.tip:SetWordWrap(false) end
end

function ns.RefreshHUD()
  local d = state.current
  local show = ns.db and ns.db.hud and d ~= nil
  if not show then
    if hud then hud:Hide() end
    return
  end
  if not hud then Create() end
  local done, total = ns.Counts(d)
  hud.head:SetText(("|cffffd100%s|r  %s"):format(T(d.name), L.PROGRESS:format(done, total)))
  local i, label = state.targetStep, L.TARGET
  if not i or ns.IsDone(d, i) then i, label = ns.NextStep(d), L.NEXT end
  if i then
    local step = d.steps[i]
    hud.line:SetText(("|cffffd100%s:|r %s. %s"):format(label, step.n, T(step.name)))
    hud.tip:SetText(ns.FirstSentence(T(step.tip)))
  else
    hud.line:SetText("|cff55ff55" .. L.DONE_ALL .. "|r")
    hud.tip:SetText("")
  end
  hud:Show()
end
