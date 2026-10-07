# Sub-zone names shown in each floor of the Blizzard dungeon maps (floor = wowf
# floor id). From DB2 UiMapAssignment (floor -> WMO groups) + WMOAreaTable names
# (enUS / koKR). Names equal to the dungeon name are left out: they do not tell
# floors apart. Used to switch the shown floor to where the player stands.
AREAS = {
 'deadmines': {
  1: ['Goblin Foundry', '고블린 주물 공장', 'Mast Room', '목재 작업장'],
  2: ['Ironclad Cove', '철갑 동굴', 'Goblin Foundry', '고블린 주물 공장'],
 },
 'gnomeregan': {
  1: ['The Hall of Gears', '톱니바퀴의 전당', 'The Dormitory', '거주 지구', 'The Clean Zone', '정화 지역', 'The Clockwerk Run', '태엽장치 통로'],
  2: ['The Dormitory', '거주 지구', 'Launch Bay', '출격실', 'The Hall of Gears', '톱니바퀴의 전당', 'The Clean Zone', '정화 지역'],
  3: ['Engineering Labs', '기계공학 연구소', 'Launch Bay', '출격실'],
  4: ['Engineering Labs', '기계공학 연구소', "Tinkers' Court", '땜장이 왕실'],
 },
 'blackfathom-deeps': {
  1: ["The Pool of Ask'ar", '아스카르 연못', 'The Drowned Sacellum', '가라앉은 제단'],
  2: ['The Forgotten Pool', '잊혀진 웅덩이', 'Moonshrine Ruins', '달의 제단 폐허', "Aku'mai's Lair", '아쿠마이의 둥지', 'Moonshrine Sanctum', '달의 제단 성소'],
  3: ['The Forgotten Pool', '잊혀진 웅덩이'],
 },
 'uldaman': {
  1: ['Map Chamber', '발굴 지도실', 'Echomok Cavern', '메아리 동굴', 'Hall of the Keepers', '수호자의 전당', 'Temple Hall', '신전 전당', 'Hall of the Crafters', '장인의 전당', 'Dig Three', '제3 발굴지', 'Dig One', '제1 발굴지', 'Dig Two', '제2 발굴지', 'The Stone Vault', '지하 석실'],
  2: ['Hall of the Crafters', '장인의 전당', "Khaz'goroth's Seat", '카즈고로스의 왕좌'],
 },
}
