-- Dungeon Route Guide - Locale
local _, ns = ...

-- ns.locale ("ko" / "en") is chosen by ns.SetLanguage below: "auto" follows
-- the game client, or the player can force Korean or English.
ns.locale = (GetLocale and GetLocale() == "koKR") and "ko" or "en"

-- Picks the localized string out of a {ko=..., en=...} table.
function ns.T(v)
  if type(v) == "table" then return v[ns.locale] or v.en or v.ko or "" end
  return v
end

local S = {
  WING_PENDING    = { "수도원 구역을 아직 판별하지 못했습니다. 현재 구역을 선택하거나 구역명이 갱신될 때까지 기다려 주세요.", "The monastery wing is not identified yet. Choose your current wing or wait for the zone name to update." },
  WING_TITLE      = { "수도원: 현재 구역 선택", "Monastery: choose your current wing" },
  WING_WAIT       = { "구역명이 확인되면 자동으로 지도가 열립니다.", "The map opens automatically when the wing is identified." },
  WING_MANUAL     = { "현재 구역 선택: %s (이번 입장 동안 유지). /drg wing auto 로 자동 판별로 돌아갑니다.", "Current wing: %s (until the next entry). Use /drg wing auto to resume detection." },
  WING_HELP       = { "/drg wing 도서관 · 묘지 · 무기고 · 대성당 또는 auto", "/drg wing library · graveyard · armory · cathedral, or auto" },
  MAP_FIT         = { "전체", "Fit" },
  MAP_ZOOM_TIP    = { "휠: 확대·축소 / 확대 후 지도 끌기: 이동 / 이 버튼: 전체 보기", "Wheel: zoom / Drag while zoomed: pan / Click this button: fit map" },
  MAP_CLASSIC_SUPPLEMENT = { "이 구역은 공식 클래식 클라이언트의 미니맵으로 보완했습니다. 현재 파일의 타일 번호와 건물 배치 좌표가 일치하는지 확인했습니다.", "Supplemented with official Classic client minimaps. Map tile coordinates and WMO placements match the current client." },
  MAP_NORTH_UP    = { "북 ↑", "N ↑" },
  MAP_GUIDE_UP    = { "방향 고정", "Fixed orientation" },
  MAP_NORTH_TIP   = { "북쪽이 위인 고정 지도입니다. 미니맵 회전 옵션이 켜져 있으면 미니맵과 화면 방향이 달라질 수 있습니다.", "Fixed north-up map. With minimap rotation enabled, the minimap can face a different direction." },
  MAP_GUIDE_TIP   = { "방향이 고정된 지도입니다. 미니맵 회전 설정을 사용하면 화면 방향이 다를 수 있습니다.", "Fixed map orientation. With minimap rotation enabled, the minimap can face a different direction." },
  PARTIAL_MINIMAP = { "일부 미니맵 타일 누락", "Some minimap tiles unavailable" },
  UNAVAILABLE_MINIMAP = { "지도를 불러오지 못했습니다.\n목록에서 다른 구역을 선택해 주세요.", "The map could not be loaded.\nSelect another area from the list." },
  PIN_CANDIDATES  = { "무작위 출현 후보 위치입니다. 선택하면 다른 후보 지점도 표시합니다. 실제 출현 지점은 게임에서 확인하세요.", "Possible random spawn locations. Select to show alternative spots. Check the active spawn in game." },
  TITLE           = { "던전 길잡이", "Dungeon Route Guide" },
  NEXT            = { "다음", "Next" },
  TARGET          = { "대상", "Target" },
  DONE_ALL        = { "던전 완료! 수고하셨습니다.", "Dungeon complete!" },
  PROGRESS        = { "진행 %d/%d", "Bosses %d/%d" },
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
  FLOW_ONLY       = { "미니맵 자료가 없어 진행 순서만 표시", "No minimap data yet: route order only" },
  SCHEMATIC       = { "위치는 참고용", "Sketch map, positions approximate" },
  LEGACY_MAP = { "구버전 미니맵 · 층 배치 확인 필요", "Legacy minimap - verify floor layout" },
  APPROX          = { "표식 위치 추정 · 확인 필요", "Estimated markers - review required" },
  LOOT            = { "전리품", "Loot" },
  TRASH_LOOT      = { "일반 몹 드랍", "Trash drops" },
  TRASH_ALL       = { "던전 일반 몹이 떨구는 아이템", "Dropped by the dungeon's trash mobs" },
  TRASH_NAMED     = { "경로 밖 네임드 몹", "Named mob off the route" },
  TRASH_ROW_TIP   = { "클릭: 이 몹들이 떨구는 아이템 보기", "Click: show what these mobs drop" },
  TRASH_TIP       = { "아이템 %d개. 아래 아이콘이나 옆 카드에서 아이템마다 떨구는 몹과 확률을 볼 수 있어요.", "%d items. Hover the icons below or see the card for the mob and chance of each." },
  WHEEL           = { "휠", "wheel" },
  PREVIEW_MAP     = { "게임 공식 지도 미리보기 (표식은 약도에)", "Official game map preview (markers are on the sketch)" },
  SCAN_NONE       = { "지도 정보를 읽을 수 없습니다. 던전 밖에서 다시 해 보세요.", "Map info is not readable here. Try again outside a dungeon." },
  SCAN_HIT        = { "공식 지도 %d: %s (종류 %d, 그림 조각 %d개)", "Official map %d: %s (type %d, %d art tiles)" },
  SCAN_DONE       = { "공식 지도 %d개를 찾았습니다. 원본 지도가 없던 던전은 설정 > 지도 그림 '블리자드 원본'에서 미리 볼 수 있어요.", "Found %d official maps. Dungeons without one before can preview them with Options > Map art: Blizzard." },
  ITEMS_LOADING   = { "아이템 정보 불러오는 중 %d/%d", "Loading item info %d/%d" },
  ITEM_MISSING    = { "(이 게임에 없는 아이템)", "(not in this game)" },
  ITEMS_MISSING   = { "%d개는 이 게임 버전에 없는 아이템입니다.", "%d item(s) do not exist in this game version." },
  SRC_WORLD       = { "던전의 모든 몹 · 낮은 확률", "Any mob in the dungeon · low chance" },
  SRC_FROM        = { "떨구는 몹", "Dropped by" },
  SRC_MORE        = { "외 %d", "+%d more" },
  LOADING         = { "불러오는 중…", "Loading…" },
  LOOT_HINT       = { "Shift+클릭: 채팅에 링크", "Shift-click: link in chat" },
  OPT_LANG        = { "언어: %s", "Language: %s" },
  OPT_MAPSTYLE    = { "지도 그림: %s", "Map art: %s" },
  MAP_BLIZ        = { "미니맵 조합", "Minimap tiles" },
  MAP_ATLAS       = { "Atlas", "Atlas" },
  MAPSTYLE_SET    = { "지도 그림: %s", "Map art: %s" },
  MODEL_HINT      = { "끌기: 회전 · 휠: 확대/축소 · 오른쪽 클릭: 처음 각도", "Drag: rotate · Wheel: zoom · Right-click: reset" },
  NO_MODEL        = { "3D 모델 정보 없음", "No 3D model" },
  NO_LOOT         = { "등록된 전리품이 없습니다.", "No loot listed." },
  LANG_auto       = { "자동", "Auto" },
  LANG_ko         = { "한국어", "한국어 (Korean)" },
  LANG_en         = { "English (영어)", "English" },
  PICK_DUNGEON    = { "던전 선택 (클릭)", "Pick a dungeon (click)" },
  PAGE            = { "지도 %d", "Map %d" },
  AREA            = { "지역 %d/%d", "Area %d/%d" },
  AREA_TIP        = { "이 던전은 지역(지도)이 %d곳입니다. 눌러서 다른 지역 보기", "This dungeon has %d areas (maps). Click to view another" },
  NEXT_AREA       = { "다음 목표 → %s", "Next objective → %s" },
  AREA_NEXT       = { "다음", "next" },
  AREA_LEFT       = { "남은 %d", "%d left" },
  LINK_CLICK      = { "클릭: 이 지역 지도 보기", "Click: show this area's map" },
  OPTIONAL        = { "선택", "Optional" },
  SKIPPED         = { "건너뜀", "Skipped" },
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
  BROWSE_ONLY     = { "둘러보기 중 (지금 있는 던전이 아님)", "Browsing (not the dungeon you are in)" },
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
  OPT_DONATE      = { "|cffff7799후원하기|r", "|cffff7799Support the addon|r" },
  DONATE_TEXT     = { "던전 길잡이가 도움이 됐다면 후원으로 응원해 주세요!\n아래 주소를 Ctrl+C로 복사해 웹 브라우저에 붙여 넣으세요.",
                      "If Dungeon Route Guide helps you, you can support it here.\nCopy the link with Ctrl+C and paste it into your web browser." },
  ON              = { "켜짐", "on" },
  OFF             = { "꺼짐", "off" },
  CLICK_HINT      = { "왼쪽 클릭: 선택 · 오른쪽 클릭: 완료 표시 전환", "Left-click: select · Right-click: toggle done" },
  SOURCE          = { "던전 공략 길잡이", "Dungeon route guide" },
  RESET_DONE      = { "진행을 초기화했습니다.", "Progress reset." },
  COMBAT_LOCKED   = { "전투 중에는 할 수 없습니다.", "Not available in combat." },
  HELP = {
    "|cff66ccff/drg|r 지도 열기/닫기 · |cff66ccff/drg hud|r 다음 목표 표시\n" ..
    "|cff66ccff/drg next|r 다음 단계 직접 완료 · |cff66ccff/drg undo|r 되돌리기 · |cff66ccff/drg reset|r 진행 초기화\n" ..
    "|cff66ccff/drg go|r 입구 안내 · |cff66ccff/drg go stop|r 안내 끄기 · |cff66ccff/drg entrance set|r 지금 위치를 입구로 저장\n" ..
    "|cff66ccff/drg lang|r 언어 (auto · ko · en) · |cff66ccff/drg map|r 미니맵 다시 불러오기 · |cff66ccff/drg icon|r 화면 아이콘 보이기/숨기기 · |cff66ccff/drg edit|r 표식 위치 편집 · |cff66ccff/drg export|r 편집 내보내기 · |cff66ccff/drg debug|r 던전 정보 확인",
    "|cff66ccff/drg|r toggle map · |cff66ccff/drg hud|r next-objective bar\n" ..
    "|cff66ccff/drg next|r mark next done · |cff66ccff/drg undo|r undo · |cff66ccff/drg reset|r reset progress\n" ..
    "|cff66ccff/drg go|r guide to entrance · |cff66ccff/drg go stop|r stop · |cff66ccff/drg entrance set|r save current spot as entrance\n" ..
    "|cff66ccff/drg lang|r language (auto · ko · en) · |cff66ccff/drg map|r reload minimap · |cff66ccff/drg icon|r show/hide icon · |cff66ccff/drg edit|r marker edit · |cff66ccff/drg export|r export edits · |cff66ccff/drg debug|r dungeon info",
  },
}

ns.L = setmetatable({}, { __index = function(_, k) return k end })
ns.locWidgets = {}

-- Set a widget's text from a locale key and keep it in sync on language change.
function ns.Loc(widget, key)
  widget:SetText(ns.L[key])
  ns.locWidgets[#ns.locWidgets + 1] = { w = widget, key = key }
  return widget
end

function ns.ResolveLocale(setting)
  if setting == "ko" or setting == "en" then return setting end
  return (GetLocale and GetLocale() == "koKR") and "ko" or "en"
end

function ns.SetLanguage(setting)
  ns.langSetting = (setting == "ko" or setting == "en") and setting or "auto"
  ns.locale = ns.ResolveLocale(ns.langSetting)
  local ko = ns.locale == "ko"
  for k, v in pairs(S) do rawset(ns.L, k, ko and v[1] or v[2]) end
  -- Key binding labels (Bindings.xml)
  BINDING_HEADER_DUNGEONROUTEGUIDE = "Dungeon Route Guide"
  BINDING_NAME_DUNGEONROUTEGUIDE_TOGGLE = ko and "던전 길잡이 지도 열기/닫기" or "Toggle route map"
  BINDING_NAME_DUNGEONROUTEGUIDE_NEXT = ko and "다음 단계 완료 표시" or "Mark next step done"
  BINDING_NAME_DUNGEONROUTEGUIDE_ANNOUNCE = ko and "다음 목표 파티에 알리기" or "Tell party the next objective"
  for _, e in ipairs(ns.locWidgets) do pcall(e.w.SetText, e.w, ns.L[e.key]) end
  if ns.OnLanguageChanged then ns.OnLanguageChanged() end
end

ns.SetLanguage("auto")
