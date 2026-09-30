# Playable Game Design Spec v0.1 — One Room Time Loop

## 1. Product Definition
같은 60초가 반복되는 원룸에서 이전 루프의 내 행동을 유령처럼 재생해 현재의 나와 협동시키며 동시에 여러 조건을 완성하는 시간 협동 퍼즐. Landscape mobile, 10 authored rooms, 60-second immutable replay loops. 핵심은 타임라인 편집이 아니라 직접 행동한 과거의 내가 다음 루프의 동료가 되는 경험이다.

## 2. Player Fantasy
혼자지만 매 루프마다 과거의 자신을 동료로 남겨 스위치 유지, 문 통과, 물건 운반을 시간축에 분업하고 불가능한 동시 조건을 해결한다.

## 3. Core Player Verbs
Move, Interact, Carry, Commit Loop, Reset Attempt. 입력·조건·state change·feedback은 구조화 Core Player Verbs를 따른다.

## 4. Core Loop
Observe goal → act for up to 60s → Commit immutable track → room resets → replay all prior ghosts from t=0 while current self performs next role → satisfy simultaneous goal → Result.

## 5. Round / Session Structure
Each level has 60.0s loops and budget 2–4. Nonfinal Commit/60s stores track and resets world. Goal checked each 0.05s tick. Final loop ending false fails. Retry clears all tracks. Average 3–7 min.

## 6. Game Rules
Fixed step 0.05s, 20Hz recording, move speed 2.4 room-units/sec, interaction range 0.8. Ghosts replay exact transforms without collision and recorded actions re-check world preconditions. Tick order is movement → ghost actions by track id → current action → plates → timers/doors/sockets → goal. Hold plates, toggles, 3–8s timed buttons, linked doors, single-owner carryables and 0.6-range sockets follow the structured Game Rules. Goal is an authored boolean expression evaluated every tick. Success freezes immediately; final loop false at 60s fails. Pause freezes all simulation; Retry clears tracks.

## 7. State Model
Select → Brief → Live Loop ↔ Loop Reset, with Pause overlay and terminal Result. No state lacks an outgoing path.

## 8. Interaction Spec
Interact uses nearest eligible anchor within 0.8; ties use authored priority then stable id. Invalid Interact changes nothing. End Loop commits on nonfinal loops and fails immediately on the final loop. Pause overrides gameplay input.

## 9. Content Model
10 rooms: Simultaneous Hold, Door Relay, Object Handoff, Timed Overlap, Composite Chain. Rooms define walkable/solid polygons, anchors, goal zones and explicit control-output links. Every authored level must have a validated solution.

## 10. Difficulty / Variation
1–2 simultaneous plates; 3–4 door relay; 5–6 carry/socket; 7–8 timed overlap; 9–10 combine 3–4 tracks. Difficulty grows through temporal dependency depth, not shorter loops.

## 11. Progression
10 levels unlock linearly on success. Store best loops_used. Stars: 1=success, 2=at/below authored par_loops, 3=par_loops with zero ghost action misses. Stars do not change rules.

## 12. Economy
Not required. Loop budget is level-local.

## 13. Screen Inventory
Level Select; Level Brief; Time-Loop Gameplay; Level Result.

## 14. Screen Flow
Entry→Select→Brief→Live Loop. Nonfinal Commit/60s→Loop Reset→next Live Loop. Goal true→success Result. Final loop false→failure Result. Pause exact-resume; Retry clears tracks.

## 15. Feedback System
0–60s timeline with per-track lanes/action markers; stable ghost tint/index; success pulse versus missed-action pulse; exact linked-state response; rewind on Commit; causal freeze on success; false goal predicates on failure without revealing solution.

## 16. Visual Direction Brief
Landscape mobile fixed top-down/three-quarter single room; whole rule-relevant room visible without scrolling. Current self dominant; up to 3 ghosts use stable tint/index and restrained trails. Timeline supports causality, not programming. UI coordinates are Wireframe responsibility.

## 17. MVP Scope + NOT IN MVP
10 authored rooms; 60s loop; budget2–4; up to 3 committed ghosts; 20Hz deterministic tracks; Move/Interact/Carry/Commit/Reset; plates, toggles, timed buttons, doors, carryables, sockets, goal zones; five content classes; pause/retry; unlock/stars.
NOT IN MVP: editable timeline, live rewind, >3 committed ghosts, physics-heavy objects, combat, procedural levels, economy/shop, online sharing, multi-room levels.

## 18. Test Scenarios
Ghost plate t10–30 enables current door crossing t15. Same-tick ghost/current toggle resolves ghost first. Owned carryable makes ghost pickup miss without stopping replay. Early End pads idle. Pause freezes all clocks. Goal true succeeds immediately. Final-loop false fails; Retry clears tracks.

## 19. Known Risks
Three-ghost readability, cross-device deterministic replay, missed-action causality, door grace readability, composite trial-and-error.

## 20. Wireframe Handoff
fun_promise: 직접 했던 immutable 과거 행동과 협동하는 것이 핵심이며 editable automation처럼 보이면 안 된다.
MVP 전체에서 four screens, Live/Reset/Pause/Result states, current+3 ghosts, timeline/action markers, all object states, five content classes, validity/miss/ownership/timers, Commit/60s reset, early-end padding, final failure, Retry and immediate success freeze를 표현한다.
