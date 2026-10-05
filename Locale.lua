-- Dungeon Route Guide - Locale
local _, ns = ...

ns.locale = (GetLocale and GetLocale() == "koKR") and "ko" or "en"
local isKO = ns.locale == "ko"

-- Picks the localized string out of a {ko=..., en=...} table.
function ns.T(v)
  if type(v) == "table" then return v[ns.locale] or v.en or v.ko or "" end
  return v
end

local S = {
  TITLE           = { "던전 길잡이", "Dungeon Route Guide" },
  NEXT            = { "다음", "Next" },
  TARGET          = { "대상", "Target" },
  DONE_ALL        = { "던전 완료! 수고하셨습니다.", "Dungeon complete!" },
  PROGRESS        = { "진행 %d/%d", "Progress %d/%d" },
  TAB_ROUTE       = { "경로", "Route" },
  TAB_QUEST       = { "퀘스트", "Quests" },
  BTN_LIST        = { "목록", "List" },
  BTN_MENU        = { "설정", "Options" },
  BTN_MAP         = { "지도", "Map" },
  BTN_ANNOUNCE    = { "파티 알림", "Tell party" },
  BTN_CHECK       = { "완료", "Done" },
  BTN_STOP        = { "중지", "Stop" },
  KIND_boss       = { "우두머리", "Boss" },
  KIND_npc        = { "NPC", "NPC" },
  KIND_rare       = { "희귀", "Rare" },
  KIND_object     = { "물건", "Object" },
  KIND_task       = { "할 일", "Task" },
  KIND_fork       = { "갈림길", "Junction" },
  UNCONFIRMED     = { "위치 미확인", "Spot unconfirmed" },
  OUTSIDE         = { "던전 밖", "Outside" },
  LEG_ENTRANCE    = { "입구", "Entrance" },
  LEG_BOSS        = { "우두머리", "Boss" },
  LEG_RARE        = { "희귀 몹", "Rare" },
  LEG_NPC         = { "NPC", "NPC" },
  LEG_QUEST       = { "퀘스트 장소", "Quest spot" },
  LEG_ALT         = { "다른 출현 지점", "Other spawn spots" },
  QUEST_MARK      = { "퀘스트 관련", "Quest related" },
  TAB_NOTES       = { "준비", "Prep" },
  NO_NOTES        = { "준비 사항이 없습니다.", "No notes." },
  NO_MAP          = { "이 던전은 아직 지도 자료가 없습니다.\n오른쪽 목록을 참고하세요.", "No map data for this dungeon yet.\nUse the list on the right." },
  BLANK_MAP       = { "지형 그림 없음 · 상대 위치만 표시", "No terrain art · relative positions only" },
  BTN_CURRENT     = { "현재 던전", "Current" },
  TIP_CURRENT     = { "지금 있는 던전 지도로 돌아갑니다", "Back to the map of the dungeon you are in" },
  SCHEMATIC       = { "약도(직접 그림) · 위치는 참고용", "Hand-drawn sketch · positions approximate" },
  PICK_DUNGEON    = { "던전 선택 (클릭)", "Pick a dungeon (click)" },
  PAGE            = { "지도 %d", "Map %d" },
  OPTIONAL        = { "선택", "Optional" },
  Q_DONE          = { "완료", "Done" },
  Q_ACTIVE        = { "진행 중", "In log" },
  Q_MISSING       = { "미수락", "Not taken" },
  Q_NOTE          = { "클래식 기준 정보입니다. 포에버에서 조건이 다를 수 있어요.", "Based on Classic data; may differ in Forever." },
  NO_QUESTS       = { "이 던전에 등록된 퀘스트가 없습니다.", "No quests listed for this dungeon." },
  NEW_INSTANCE    = { "새 인스턴스를 감지해서 진행을 초기화했습니다.", "New instance detected, progress reset." },
  RESET_SEEN      = { "%s 초기화 확인: 다음 입장 때 처음부터 시작합니다.", "%s was reset: next entry starts a new run." },
  NEW_RUN         = { "새 진행을 시작합니다: %s", "New run started: %s" },
  KILLED          = { "%s 처치 확인 (%d/%d)", "%s defeated (%d/%d)" },
  RARE_ALERT      = { "희귀 몹 발견: %s", "Rare spotted: %s" },
  BROWSE_ONLY     = { "던전 밖에서는 둘러보기용으로 열립니다.", "Outside the dungeon: browse mode." },
  NOT_SUPPORTED   = { "이 던전은 아직 데이터가 없습니다. /drg debug 결과를 알려주세요.", "No data for this dungeon yet. Please report /drg debug." },
  ENTRANCE_START  = { "%s 입구 안내를 시작합니다.", "Guiding you to %s." },
  ENTRANCE_STOP   = { "입구 안내를 끝냈습니다.", "Entrance guide stopped." },
  ENTRANCE_ARRIVE = { "도착! 입구로 들어가세요.", "Arrived! Enter the portal." },
  ENTRANCE_OTHER  = { "%s(으)로 이동하세요", "Travel to %s" },
  ENTRANCE_SET    = { "%s 입구 위치 저장: %.1f, %.1f", "%s entrance saved: %.1f, %.1f" },
  ENTRANCE_NOPOS  = { "현재 위치를 읽을 수 없습니다. (던전 안에서는 불가)", "Cannot read your position (not possible inside dungeons)." },
  ENTRANCE_INSIDE = { "던전 안입니다", "Inside a dungeon" },
  DIST            = { "%s쪽 %d야드", "%s, %d yd" },
  DIR_0 = { "북", "N" }, DIR_1 = { "북서", "NW" }, DIR_2 = { "서", "W" }, DIR_3 = { "남서", "SW" },
  DIR_4 = { "남", "S" }, DIR_5 = { "남동", "SE" }, DIR_6 = { "동", "E" }, DIR_7 = { "북동", "NE" },
  EDIT_ON         = { "표식 위치 편집: 목록에서 단계를 고른 뒤 지도를 왼쪽 클릭=그 자리로 옮기기, 오른쪽 클릭=원래 자리로", "Marker edit: pick a step, then left-click the map = move it there, right-click = back to default" },
  EDIT_OFF        = { "경로 편집 모드 꺼짐", "Edit mode off" },
  EDIT_POINT      = { "%s: 경로점 추가 (%d, %d)", "%s: waypoint added (%d, %d)" },
  EDIT_MARK       = { "%s: 표식 위치 (%d, %d)", "%s: marker moved (%d, %d)" },
  EDIT_CLEAR      = { "%s: 편집 내용을 지웠습니다", "%s: edits cleared" },
  OPT_ALPHA       = { "투명도: %d%%", "Opacity: %d%%" },
  OPT_SIZE        = { "지도 크기: %d", "Map size: %d" },
  OPT_LOCK        = { "창 고정: %s", "Lock window: %s" },
  OPT_AUTO        = { "던전 입장 시 자동 열기: %s", "Auto open in dungeon: %s" },
  OPT_HUD         = { "다음 목표 표시: %s", "Next-objective bar: %s" },
  OPT_RARE        = { "희귀 몹 알림: %s", "Rare alerts: %s" },
  OPT_FADE        = { "전투 중 흐리게: %s", "Fade in combat: %s" },
  OPT_ICON        = { "화면 아이콘: %s", "Screen icon: %s" },
  ICON_LEFT       = { "왼쪽 클릭: 공략 지도 열기/닫기", "Left-click: open/close the route map" },
  ICON_RIGHT      = { "오른쪽 클릭: 입구 안내 시작/끄기", "Right-click: start/stop entrance arrow" },
  ICON_DRAG       = { "끌어서 위치 이동 · /drg icon 으로 숨기기", "Drag to move · /drg icon to hide" },
  OPT_GO          = { "입구 안내 시작", "Guide to entrance" },
  OPT_RESET       = { "진행 초기화", "Reset progress" },
  OPT_EDIT        = { "표식 위치 편집: %s", "Marker edit mode: %s" },
  OPT_EXPORT      = { "편집한 위치 내보내기", "Export marker edits" },
  EXPORT_HINT     = { "Ctrl+A, Ctrl+C 로 복사하세요", "Ctrl+A, Ctrl+C to copy" },
  ON              = { "켜짐", "on" },
  OFF             = { "꺼짐", "off" },
  CLICK_HINT      = { "왼쪽 클릭: 선택 · 오른쪽 클릭: 완료 표시 전환", "Left-click: select · Right-click: toggle done" },
  SOURCE          = { "지도: Atlas (GPL-2.0) · 정보 참고: wowf.io", "Maps: Atlas (GPL-2.0) · Info: wowf.io" },
  RESET_DONE      = { "진행을 초기화했습니다.", "Progress reset." },
  COMBAT_LOCKED   = { "전투 중에는 할 수 없습니다.", "Not available in combat." },
  HELP = {
    "|cff66ccff/drg|r 지도 열기/닫기 · |cff66ccff/drg hud|r 다음 목표 표시\n" ..
    "|cff66ccff/drg next|r 다음 단계 직접 완료 · |cff66ccff/drg undo|r 되돌리기 · |cff66ccff/drg reset|r 진행 초기화\n" ..
    "|cff66ccff/drg go|r 입구 안내 · |cff66ccff/drg go stop|r 안내 끄기 · |cff66ccff/drg entrance set|r 지금 위치를 입구로 저장\n" ..
    "|cff66ccff/drg icon|r 화면 아이콘 보이기/숨기기 · |cff66ccff/drg edit|r 표식 위치 편집 · |cff66ccff/drg export|r 편집 내보내기 · |cff66ccff/drg debug|r 던전 정보 확인",
    "|cff66ccff/drg|r toggle map · |cff66ccff/drg hud|r next-objective bar\n" ..
    "|cff66ccff/drg next|r mark next done · |cff66ccff/drg undo|r undo · |cff66ccff/drg reset|r reset progress\n" ..
    "|cff66ccff/drg go|r guide to entrance · |cff66ccff/drg go stop|r stop · |cff66ccff/drg entrance set|r save current spot as entrance\n" ..
    "|cff66ccff/drg icon|r show/hide icon · |cff66ccff/drg edit|r marker edit · |cff66ccff/drg export|r export edits · |cff66ccff/drg debug|r dungeon info",
  },
}

ns.L = {}
for k, v in pairs(S) do ns.L[k] = isKO and v[1] or v[2] end
setmetatable(ns.L, { __index = function(_, k) return k end })

-- Key binding labels (Bindings.xml)
BINDING_HEADER_DUNGEONROUTEGUIDE = "Dungeon Route Guide"
BINDING_NAME_DUNGEONROUTEGUIDE_TOGGLE = isKO and "던전 길잡이 지도 열기/닫기" or "Toggle route map"
BINDING_NAME_DUNGEONROUTEGUIDE_NEXT = isKO and "다음 단계 완료 표시" or "Mark next step done"
BINDING_NAME_DUNGEONROUTEGUIDE_ANNOUNCE = isKO and "다음 목표 파티에 알리기" or "Tell party the next objective"
