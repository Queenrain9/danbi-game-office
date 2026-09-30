# Assembly Line Orchestra — Playable Game Design Spec v0.1

## 1. Product Definition
생산 자동화와 리듬 작곡을 동일한 기계 동작으로 결합한 모바일 리듬 자동화 게임.

## 2. Player Fantasy
생산 감독이자 지휘자로서 공장 라인의 실제 동작을 음악으로 조율한다.

## 3. Core Player Verbs
Place, set phase, run, observe, safe-stop, reconfigure. 각 입력은 Edit/Running 상태 규칙을 따른다.

## 4. Core Loop
계약 → 배치/phase → 가동 → 관찰/진단 → 수정 → 생산+리듬 동시 달성.

## 5. Round / Session Structure
8-beat cycle 4회가 한 Run. Edit 요청은 cycle boundary에 적용. 2–4 contracts가 한 세션.

## 6. Game Rules
Directed graph만 따라 item 이동. Activation beat에 input/compatibility/free output이 성립하면 처리, 아니면 wait; 2 beats 초과는 jam/scrap. 성공 activation을 target mask와 비교한다. 32 beats 후 quota, rhythm threshold, jam limit를 모두 만족해야 clear. 실패는 무료 Edit Retry/Reset.

## 7. State Model
Select, Edit, Running, Paused, Success, Failure. 모든 실패 상태는 복구 행동을 가진다.

## 8. Interaction Spec
Edit에서 배치·route·phase·preview. Running에서는 pause와 queued edit만. Result timeline은 사건 원인을 보존한다.

## 9. Content Model
Source/Processor/Router/Output 모듈. Contract는 BPM, module set, directed topology, recipe, quota, target masks, threshold, jam limit. Variation은 tutorial/single-route/branch-route/syncopated/mixed-processor.

## 10. Difficulty / Variation
느린 단일 경로에서 분기·긴 recipe·복수 role mask·높은 quota로 확장. 생산 효율과 음악 타이밍의 충돌이 난도 원천.

## 11. Progression
튜토리얼 2개 후 일반 계약. Mastery stars로 3 tiers, 12 templates 해금. 실패 페널티 없음.

## 12. Economy
Not required.

## 13. Screen Inventory
Contract Select; Factory Setup/Edit; Running Factory; Pause Overlay; Run Result/Diagnostic.

## 14. Screen Flow
Select → Edit → Running ↔ Pause → Result. Failure → Edit/Reset/Select. Success → Next/Replay/Select.

## 15. Feedback System
Playhead tick, mechanical role sound, target hit marker, wait/jam warning, output accent, 조건별 result verdict.

## 16. Visual Direction Brief
한 화면에서 라인 전체가 읽히는 2D/2.5D. 기계 motion과 beat rail로 timing을 표현하고 모바일 판독성을 우선.

## 17. MVP Scope + NOT IN MVP
MVP는 전체 core loop, 5 variation classes, progression을 포함. Live tapping, economy, online, procedural infinity, narrative는 제외.

## 18. Test Scenarios
Success: quota4/.75/0에서 4 outputs, 6/2 hits, 0 jams. Failure: 3 outputs, 5/3 hits, 1 jam. Safe edit, pause, invalid drop, branch routing도 검증.

## 19. Known Risks
최적해 수렴, audio latency, 동시 item 가독성, 과도한 diagnostics.

## 20. Wireframe Handoff
fun_promise: 생산 최적화와 리듬 연주가 같은 배치·타이밍 행동에서 충돌하고 합쳐져야 한다. Wireframe은 전체 screen/state/gesture/feedback/transition/variation을 표현하되 새 게임 규칙을 추가하지 않는다.