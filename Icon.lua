-- Dungeon Route Guide - on-screen icon to open the guide anywhere.
-- Left-click: open/close the route map (works outside dungeons too).
-- Right-click: start/stop the arrow to the shown dungeon's entrance.
-- Drag: move the icon (position is saved).
local _, ns = ...
local L, T = ns.L, ns.T
local state = ns.state

local ICON = "Interface\\Icons\\INV_Misc_Map_01"
local BORDER = "Interface\\Minimap\\MiniMap-TrackingBorder"
local MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"

local btn

-- Dungeon that fits the character's level, used when browsing outside.
function ns.SuggestDungeon()
  local level = ns.Num(ns.Safe(UnitLevel, "player")) or 1
  local inRange, inDist, upcoming, upLo, last
  for _, d in ipairs(ns.Dungeons) do
    local lo, hi = (d.levels or ""):match("(%d+)%D+(%d+)")
    lo, hi = tonumber(lo), tonumber(hi)
    if lo and hi then
      last = d
      if level >= lo and level <= hi then
        local dist = math.abs(level - (lo + hi) / 2)
        if not inDist or dist < inDist then inRange, inDist = d, dist end
      elseif level < lo and (not upLo or lo < upLo) then
        upcoming, upLo = d, lo
      end
    end
  end
  return inRange or upcoming or last or ns.Dungeons[1]
end

local function Tooltip(self)
  GameTooltip:SetOwner(self, "ANCHOR_LEFT")
  GameTooltip:SetText(L.TITLE, 1, 0.82, 0)
  local d = state.current or state.viewed or ns.SuggestDungeon()
  if d then GameTooltip:AddLine(T(d.name) .. "  " .. (d.levels or ""), 1, 1, 1) end
  GameTooltip:AddLine(L.ICON_LEFT, 0.6, 0.85, 1)
  GameTooltip:AddLine(L.ICON_RIGHT, 0.6, 0.85, 1)
  GameTooltip:AddLine(L.ICON_DRAG, 0.6, 0.6, 0.6)
  GameTooltip:Show()
end

local function OnClick(_, button)
  if button == "RightButton" then
    if ns.EntranceActive() then
      ns.StopEntrance()
    else
      ns.StartEntrance(state.viewed or ns.SuggestDungeon())
    end
  else
    if not state.current and not state.viewed then state.viewed = ns.SuggestDungeon() end
    ns.ToggleMap()
  end
end

function ns.CreateIcon()
  if btn then return btn end
  btn = CreateFrame("Button", "DungeonRouteGuideIcon", UIParent)
  btn:SetSize(36, 36)
  btn:SetFrameStrata("MEDIUM")
  btn:SetClampedToScreen(true)
  btn:SetMovable(true)
  btn:EnableMouse(true)
  btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  btn:RegisterForDrag("LeftButton")

  local bg = btn:CreateTexture(nil, "BACKGROUND")
  bg:SetSize(26, 26)
  bg:SetPoint("CENTER")
  bg:SetColorTexture(0, 0, 0, 0.6)
  local icon = btn:CreateTexture(nil, "ARTWORK")
  icon:SetTexture(ICON)
  icon:SetSize(24, 24)
  icon:SetPoint("CENTER")
  if btn.CreateMaskTexture then
    for _, t in ipairs({ bg, icon }) do
      local m = btn:CreateMaskTexture()
      m:SetTexture(MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
      m:SetAllPoints(t)
      t:AddMaskTexture(m)
    end
  end
  local border = btn:CreateTexture(nil, "OVERLAY")
  border:SetTexture(BORDER)
  border:SetSize(60, 60)
  border:SetPoint("TOPLEFT", -2, 2)
  local hl = btn:CreateTexture(nil, "HIGHLIGHT")
  hl:SetSize(28, 28)
  hl:SetPoint("CENTER")
  hl:SetColorTexture(1, 1, 1, 0.15)
  btn.icon = icon

  local pos = ns.db.frames.icon
  if pos then btn:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4]) else btn:SetPoint("RIGHT", UIParent, "RIGHT", -260, 120) end

  btn:SetScript("OnDragStart", function(self) self:StartMoving() end)
  btn:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local p, _, rp, x, y = self:GetPoint(1)
    ns.db.frames.icon = { p, rp, x, y }
  end)
  btn:SetScript("OnClick", OnClick)
  btn:SetScript("OnEnter", Tooltip)
  btn:SetScript("OnLeave", GameTooltip_Hide)
  btn:SetShown(ns.db.showIcon)
  return btn
end

function ns.SetIconShown(show)
  ns.db.showIcon = show and true or false
  ns.CreateIcon():SetShown(ns.db.showIcon)
end
