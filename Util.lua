-- Dungeon Route Guide - helpers
-- The Forever client can hand out "secret" values (issecretvalue) for some
-- unit/combat data. Every read from the game goes through these guards so a
-- restricted value is treated as "unknown" instead of raising an error.
local _, ns = ...

local function pass(ok, ...)
  if ok then return ... end
end

function ns.Safe(fn, ...)
  if type(fn) ~= "function" then return end
  return pass(pcall(fn, ...))
end

function ns.Readable(v)
  if v == nil then return false end
  if issecretvalue then
    local ok, secret = pcall(issecretvalue, v)
    if not ok or secret then return false end
  end
  if canaccessvalue then
    local ok, can = pcall(canaccessvalue, v)
    if not ok or not can then return false end
  end
  return true
end

function ns.Str(v)
  if ns.Readable(v) and type(v) == "string" then return v end
end

function ns.Num(v)
  if ns.Readable(v) and type(v) == "number" and v == v then return v end
end

function ns.True(v)
  return ns.Readable(v) and v == true
end

function ns.NpcIDFromGUID(guid)
  guid = ns.Str(guid)
  if not guid then return end
  local kind, id = guid:match("^(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)")
  if kind == "Creature" or kind == "Vehicle" then return tonumber(id) end
end

-- Creature GUID: Creature-0-server-map-zoneUID-npcID-spawnUID.
-- zoneUID identifies one copy of an instance, so it changes after a reset.
function ns.InstanceUIDFromGUID(guid)
  guid = ns.Str(guid)
  if not guid then return end
  local kind, zone = guid:match("^(%a+)%-%d+%-%d+%-%d+%-(%d+)%-%d+")
  if kind == "Creature" or kind == "Vehicle" then return zone end
end

function ns.UnitNpcID(unit)
  return ns.NpcIDFromGUID(ns.Safe(UnitGUID, unit))
end

-- Lower-case, no spaces/punctuation: used to compare encounter names.
function ns.Normalize(s)
  s = ns.Str(s)
  if not s then return end
  return (s:lower():gsub("[%s%p]", ""))
end

function ns.Print(msg)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccff[DRG]|r " .. tostring(msg))
  end
end

function ns.OnOff(v)
  return v and ("|cff55ff55" .. ns.L.ON .. "|r") or ("|cffff5555" .. ns.L.OFF .. "|r")
end

function ns.InCombat()
  return ns.True(ns.Safe(InCombatLockdown))
end

-- Item data comes from the game client (names, icons, quality follow the
-- game language). Returns name, link, quality, icon; name is nil until the
-- client has the item cached (GET_ITEM_INFO_RECEIVED refreshes the UI).
function ns.ItemInfo(id)
  local getInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  local name, link, quality, _, _, _, _, _, _, icon = ns.Safe(getInfo, id)
  if not icon then icon = ns.Safe((C_Item and C_Item.GetItemIconByID) or GetItemIcon, id) end
  if not name then ns.Safe(C_Item and C_Item.RequestLoadItemDataByID, id) end
  if not ns.Readable(icon) or (type(icon) ~= "number" and type(icon) ~= "string") then icon = nil end
  return ns.Str(name), ns.Str(link), ns.Num(quality), icon
end

function ns.QualityHex(q)
  local c = q and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]
  if c and c.hex then return c.hex end
  return "|cffffffff"
end

-- First sentence of a tip, for party call-outs.
function ns.FirstSentence(s)
  if type(s) ~= "string" then return "" end
  local first = s:match("^(.-[%.!?])%s") or s
  return first
end
