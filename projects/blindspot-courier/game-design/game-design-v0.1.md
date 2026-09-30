# Blindspot Courier — Playable Game Design Spec v0.1

## 1. Product Definition
모바일 잠입 퍼즐. 감시 생물은 화면에 보이면 얼어붙고 화면 밖이면 다시 감시한다. 카메라를 돌려 사각지대를 만들고 택배를 운반한다.
## 2. Player Fantasy
시선을 조종해 감시 생물을 멈추거나 풀어 주며 보지 않는 공간을 배송 통로로 만드는 배달원.
## 3. Core Player Verbs
회전(camera drag→watcher 상태 재계산), 경로 그리기(node drag→route 변경), 이동(confirm→node 이동), 회수/배송(tap→cargo 변경).
## 4. Core Loop
감시망 읽기→카메라 회전→경로 그리기→이동→안전 지점에서 반복→화물 회수·배송→필수 배송 완료.
## 5. Round / Session Structure
10개 소형 스테이지. intro→planning/movement 반복→result. 스테이지 1–3분, 세션 5–15분.
## 6. Game Rules
R1 보행은 연결 node graph만 사용. R2 watcher는 viewport 안이면 frozen, 완전히 밖이면 active. R3 active watcher만 radius+facing sector+clear LOS에서 감지. R4 camera rotation은 world 위치를 바꾸지 않고 종료 후 watcher 상태를 먼저 재계산. R5 invalid route는 거부되고 위치 불변. R6 이동 중 node마다 detection 판정, 감지 즉시 실패. R7 parcel은 pickup node에서 회수하고 matching destination에서만 배송. R8 모든 required parcel 배송=성공, detection=실패, retry=stage-start snapshot. R9 pause는 정지, restart는 snapshot 복구, 시작 즉시 감지 배치 금지. R10 후반은 static/active-rotation watcher, LOS wall, overlapping sector, multiple parcel을 같은 규칙으로 조합.
## 7. State Model
stage_intro, planning, moving, interaction, success, failure, paused. 변수: camera_angle, courier_node, queued_route, parcel_states, watcher_visible/frozen/facing.
## 8. Interaction Spec
정지 중 camera drag/swipe와 route drawing, parcel/destination tap, pause/retry. 이동 중 route 편집 잠금. invalid input은 상태 불변+즉시 이유 표시.
## 9. Content Model
Stage=node graph+walls+start+watchers+parcels+destinations. Watcher=position/facing/radius/sector/rotation_mode. Parcel=pickup/destination/required. Walkability=graph adjacency, detection=world sector+wall LOS.
## 10. Difficulty / Variation
watcher 수, overlapping sight, wall/LOS, active rotation, parcel 수, route branching. 새 verb 없음.
## 11. Progression
성공 시 다음 스테이지 해금. 실패는 현재 스테이지 재시도. 영구 성장 없음.
## 12. Economy
Not required.
## 13. Screen Inventory
Stage Select, Stage Intro, Gameplay, Stage Result, Pause.
## 14. Screen Flow
Stage Select→Stage Intro→Gameplay(planning↔moving↔interaction)→Result. 성공 Next/Select, 실패 retry. Gameplay↔Pause.
## 15. Feedback System
viewport 진입=freeze, 이탈=wake. route legal/risk preview. detection 시 감지 watcher와 LOS 표시. cargo 상태 지속 표시.
## 16. Visual Direction Brief
탑다운/비스듬한 2D. 화면 경계, watcher, facing, wall, route, parcel 판독성을 장식보다 우선.
## 17. MVP Scope + NOT IN MVP
MVP: 10 stages, camera/watcher rule, LOS walls, routes, parcels, failure/retry/pause/unlock. 제외: combat, enemy removal, economy, growth, online, procedural generation, free joystick, branching story.
## 18. Test Scenarios
성공: watcher A를 offscreen-active로 둔 뒤 감지 sector를 피하는 3-node route, 안전점에서 watcher B를 in-view-freeze, parcel 회수 후 목적지 배송. 실패: active watcher clear LOS sector node 진입→즉시 failure→retry snapshot 복구. LOS: wall이 막으면 무감지, wall 끝을 지나 clear LOS면 감지. Multiple parcel: 하나 배송 후 나머지가 있으면 계속. Pause는 변수 불변, restart는 snapshot 복구.
## 19. Known Risks
visible=frozen의 반직관성, camera/world 회전 혼동, danger preview 강도.
## 20. Wireframe Handoff
fun_promise: 화면을 돌려 '보지 않는 곳'을 의도적으로 만들어야 움직일 수 있다는 역설. 전체 screen/state/gesture/feedback/transition과 static/active-rotation watcher, wall LOS, overlapping sector, multiple parcel variation을 같은 interaction grammar로 전달한다.
