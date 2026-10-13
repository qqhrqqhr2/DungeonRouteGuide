-- Sub-zone names shown on each floor (game DB2 UiMapAssignment + WMOAreaTable,
-- enUS / koKR), so the shown floor follows where the player stands.
-- Kept apart from MinimapData.lua (generated) and added only where a page has
-- no area list of its own. A name on two floors is resolved by the next
-- objective (see CurrentPage in MapFrame.lua).
local _, ns = ...

local AREAS = {
  dm = {
    mines = { "Goblin Foundry", "고블린 주물 공장", "Mast Room", "목재 작업장" },
    cove = { "Ironclad Cove", "철갑 동굴" },
  },
  gnomer = {
    upper = { "The Hall of Gears", "톱니바퀴의 전당", "The Dormitory", "거주 지구", "The Clean Zone", "정화 지역", "The Clockwerk Run", "태엽장치 통로" },
    workshop = { "The Dormitory", "거주 지구", "Launch Bay", "출격실" },
    launch = { "Engineering Labs", "기계공학 연구소", "Launch Bay", "출격실" },
    court = { "Tinkers' Court", "땜장이 왕실" },
  },
  bfd = {
    pool = { "The Pool of Ask'ar", "아스카르 연못", "The Drowned Sacellum", "가라앉은 제단" },
    sanctum = { "The Forgotten Pool", "잊혀진 웅덩이", "Moonshrine Ruins", "달의 제단 폐허", "Aku'mai's Lair", "아쿠마이의 둥지", "Moonshrine Sanctum", "달의 제단 성소" },
  },
  ulda = {
    keepers = { "Map Chamber", "발굴 지도실", "Echomok Cavern", "메아리 동굴", "Hall of the Keepers", "수호자의 전당", "Temple Hall", "신전 전당", "Dig Three", "제3 발굴지", "Dig One", "제1 발굴지", "Dig Two", "제2 발굴지", "The Stone Vault", "지하 석실" },
    seat = { "Khaz'goroth's Seat", "카즈고로스의 왕좌" },
  },
}

for _, d in ipairs(ns.Dungeons or {}) do
  local byPage = AREAS[d.key]
  if byPage and d.bliz and d.bliz.pages then
    for _, p in ipairs(d.bliz.pages) do
      if not p.areas and byPage[p.key] then p.areas = byPage[p.key] end
    end
  end
end
