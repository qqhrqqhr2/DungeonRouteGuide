# Dungeon Route Guide

**One-line summary:** WoW Forever dungeon guide: route map with boss order, rares, NPCs and quest spots, automatic boss checks and an arrow to the entrance.

## English

### What it does
WoW Forever has no dungeon maps inside instances. Dungeon Route Guide opens a semi-transparent map as soon as you zone in and shows **where to go next**: the boss order, rares, NPCs and quest spots. Bosses are checked off automatically when they die, and a small bar at the top of the screen always shows the next objective with a one-line tip.

### Features
- **Dungeon minimaps**: bundled map tiles for 18 dungeons and 29 areas; mouse-wheel zoom, drag to pan, and Fit reset
- **Boss card**: click a boss for its 3D model and full loot list
- **Classic dungeons and the new Forever dungeons**, including all four Scarlet Monastery wings; more are added as Forever opens them
- Map markers in the order you clear them: **entrance, boss, rare, NPC, quest spot**, a **!** for quest-related spots and faint circles for **alternate spawn spots** of wandering bosses and rares
- The **next stop glows** on the map; cleared stops turn grey with a check mark
- **Automatic boss checks** (your target, party targets, nameplates, corpses, loot and encounter events), with right-click as a manual fallback
- **Next-objective bar** with the boss's key abilities; target a boss to see its tip; "Tell party" posts the tip to party chat
- **Boss loot**: hover a boss to see its drops; item icons under the tip show the real item tooltip (Shift-click to link)
- **Rare alerts** with a raid warning and sound
- **Quests tab**: done / in your log / not taken for every dungeon quest; all quest entries have Korean names
- **Prep tab**: what to bring and watch out for, plus the entrance coordinates
- **Entrance arrow** outdoors: arrow and distance to the dungeon portal
- Progress resets on its own when you re-enter a cleared dungeon or the instance is reset
- Multi-page maps (Blackfathom Deeps), dungeon picker, adjustable size and opacity, fades in combat
- Draggable screen icon: left-click opens the guide anywhere, right-click starts the entrance arrow
- English and Korean: automatic (game language), or pick one in Options / `/drg lang`

### Commands
- `/drg` - open / close the map (also a key binding)
- `/drg go` - arrow to the entrance of the shown dungeon, `/drg go stop` to stop
- `/drg entrance set` - save where you stand as the entrance (if the default spot is off)
- `/drg next`, `/drg undo`, `/drg reset` - manual progress control
- `/drg hud`, `/drg icon` - show / hide the objective bar and the screen icon
- `/drg edit`, `/drg export` - move a marker that is off and share your edits
- `/drg wing library` - select Library for the current Scarlet Monastery entry; `/drg wing auto` resumes automatic detection
- `/drg debug` - dungeon detection info for bug reports

### Data and credits
- Minimap textures and game geometry: Blizzard Entertainment. See the bundled CREDITS.txt and MINIMAP_SOURCES.txt for acknowledgements.
- Hall of Thanes, Excavation Site, Ruins of Lordaeron and both Dalaran floors have minimaps.
- Wandering bosses and rares can be slightly off the marked spot. Reports are welcome in the comments or on GitHub.

### Support
If the addon helps you: https://buymeacoffee.com/qqhrqqhr2 (in game: Options > Support the addon, or `/drg donate`)

---

## 한국어

### 소개
와우 포에버는 던전 안에서 지도를 볼 수 없습니다. Dungeon Route Guide는 던전에 들어가면 반투명 지도를 띄워 **다음에 어디로 가야 하는지** 보여줍니다. 보스 순서, 희귀 몹, NPC, 퀘스트 장소를 지도에 표시하고, 보스를 잡으면 자동으로 체크합니다. 화면 위쪽 막대에는 늘 다음 목표와 공략 한 줄이 나옵니다.

### 기능
- **던전 미니맵**: 18개 던전·29개 구역의 지도를 포함하며, 휠 확대·축소와 지도 이동, 전체 보기 지원
- **보스 카드**: 보스를 클릭하면 3D 모델과 전리품 전체 목록
- **클래식 던전과 포에버 신규 던전** (붉은십자군 수도원 네 날개 포함). 포에버에 던전이 열리는 대로 계속 추가
- 진행 순서대로 번호가 붙은 표식: **입구, 우두머리, 희귀 몹, NPC, 퀘스트 장소**, 퀘스트 관련 지점의 **!** 표시, 돌아다니는 보스·희귀 몹의 **다른 출현 지점**
- 다음에 갈 곳은 지도에서 **노랗게 빛나고**, 잡은 곳은 회색과 체크 표시
- **보스 자동 체크** (내 대상, 파티원 대상, 이름표, 시체, 전리품, 전투 종료 이벤트). 오른쪽 클릭으로 직접 체크도 가능
- **다음 목표 막대**에 보스 주요 기술 표시, 보스를 대상으로 잡으면 그 보스 팁, "파티 알림"으로 파티 채팅에 공유
- **보스 전리품**: 보스에 마우스를 올리면 드랍 아이템 목록, 팁 아래 아이콘에서 아이템 툴팁 확인 (Shift+클릭으로 채팅 링크)
- **희귀 몹 알림** (경고 문구와 소리)
- **퀘스트 탭**: 모든 퀘스트의 한국어 이름과 완료 / 진행 중 / 미수락 상태 표시
- **준비 탭**: 챙길 것과 주의 사항, 입구 좌표
- **입구 안내 화살표**: 필드에서 던전 입구까지 방향과 거리
- 다 깬 던전에 다시 들어가거나 인스턴스가 초기화되면 진행이 알아서 초기화
- 여러 장 지도(검은심연의 나락), 던전 선택 목록, 크기·투명도 조절, 전투 중 흐리게
- 끌어서 옮기는 화면 아이콘: 왼쪽 클릭으로 어디서나 공략 열기, 오른쪽 클릭으로 입구 안내
- 한국어·영어 지원: 자동(게임 언어) 또는 설정 메뉴·`/drg lang`에서 선택

### 명령어
- `/drg` 또는 `/던전길잡이` - 지도 열기/닫기 (단축키 지정 가능)
- `/drg go` - 보고 있는 던전 입구 안내, `/drg go stop` 안내 끄기
- `/drg entrance set` - 입구 좌표가 틀리면 포털 앞에서 입력해 저장
- `/drg next`, `/drg undo`, `/drg reset` - 진행 직접 조작
- `/drg hud`, `/drg icon` - 다음 목표 막대, 화면 아이콘 보이기/숨기기
- `/drg edit`, `/drg export` - 어긋난 표식 옮기기와 공유
- `/drg wing 도서관` - 현재 수도원 구역을 도서관으로 지정, `/drg wing auto` - 자동 판별로 복귀
- `/drg debug` - 오류 제보용 던전 인식 정보

### 자료와 크레딧
- 미니맵 지형과 텍스처: 블리자드 엔터테인먼트. 자세한 크레딧은 애드온에 포함된 CREDITS.txt와 MINIMAP_SOURCES.txt에 있습니다.
- 영주의 전당·발굴 현장·로데론의 폐허와 달라란 하수도·도시 지도 지원
- 돌아다니는 보스·희귀 몹은 표시 위치와 조금 다를 수 있습니다. 댓글이나 GitHub로 제보해 주세요

### 후원
도움이 되셨다면: https://buymeacoffee.com/qqhrqqhr2 (게임 안에서는 설정 메뉴 > 후원하기 또는 `/drg 후원`)
