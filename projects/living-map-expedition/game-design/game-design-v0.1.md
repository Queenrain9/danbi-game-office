# Playable Game Design Spec v0.1 — Living Map Expedition

## 1. Product Definition
탐험한 타일의 현재 지형을 지도에 기록해 현실을 고정하거나 빈칸으로 남겨 다음 턴에 뒤집히게 하며 Shrine까지 가는 portrait mobile turn-based exploration strategy. 세션 4–6분. 목표 감각은 살아 움직이는 세계의 규칙을 읽고 기록으로 길을 붙잡는 지적 숙련감이다. Non-goals: 실시간 액션, 전투 RPG, 랜덤 로그라이크, 대화 선택 게임.

## 2. Player Fantasy
플레이어는 현실을 기록으로 붙잡는 원정대의 지도 제작자다. 현재 지형과 다음 변화를 읽고 귀한 Ink를 써서 필요한 길만 영구화하며 섬을 이해했다는 만족을 느낀다.

## 3. Core Player Verbs
Scout: 인접 fog tap, tile reveal+scouts_left-1. Record: record seal을 revealed tile에 drag, Ink-1+현재 form 영구 고정. Move: expedition token을 adjacent passable tile로 drag, Stamina cost+position change. Wait: Stamina1을 쓰고 제자리에서 World Shift. Pause: 현재 simulation을 동결한다.

## 4. Core Loop
최대 2 Scout → 필요 시 1 Record → Move 또는 Wait → World Shift → 다음 turn. 6–10 turn 안팎에서 Shrine 도달을 노린다.

## 5. Round / Session Structure
4×4 island 한 판. Camp에서 Stamina9/10, Ink4, Turn1 시작. Turn Planning → Move/Wait Resolution → World Shift → 다음 Turn Planning. Shrine 진입은 success, 비-Shrine에서 entry effect 후 Stamina0 또는 Wait 후 Stamina0은 failure. Retry는 전체 mission state reset.

## 6. Game Rules
16 cells 중 Camp1/Shrine1/mutable14. Path cost1, Marsh cost2, Ridge impassable, Spring cost1+최초 entry Stamina2 회복(max10). Mutable cell은 A/B form을 가진다. 첫 Scout 시 A로 reveal되며 B도 알려진다. Move/Wait 완료 후 revealed+unrecorded+unoccupied mutable tile만 A↔B 한 번 toggle. Occupied tile은 서 있는 동안 shift하지 않는다. Record는 current form을 영구 고정, Ink1, turn당 1회, refund 없음. Scout는 adjacent fog, turn당 2회.

Move valid는 orthogonal adjacent+revealed+passable+affordable. Resolution은 cost 지불→이동→Spring effect→Shrine면 success→아니면 Stamina0 failure→그 외 shift. Shrine은 Stamina1로 들어가 0이어도 success가 우선한다. Wait는 Stamina1 지불→0이면 failure, 아니면 shift.

Success score = 1200 + remaining Stamina×100 + remaining Ink×150 - turn_count×50. Failure score0. Pause는 automatic shift와 입력을 정지. Retry는 mutable tile을 unrevealed/A/unrecorded/unconsumed, party Camp, Stamina9, Ink4, Turn1로 복구한다.

## 7. State Model
Turn Planning: Scout/Record/Move/Wait/Pause. Invalid는 no change. Move/Wait로 exit.
Move Resolution: cost/position/entry effect atomic resolve. Shrine→Result success, non-Shrine stamina0→Result failure, otherwise World Shift.
Wait Resolution: stamina-1; 0→failure, else Shift.
World Shift: eligible tiles toggle once, turn_count+1, then scouts_left2/record_used=false로 Planning.
Result: Retry/finish.

## 8. Interaction Spec
Scout target은 orthogonally adjacent fog mutable tile. Record target은 revealed, unrecorded mutable tile; invalid release는 Ink 소모 없음. Move는 adjacent revealed passable affordable tile만 valid; invalid release는 token 원위치·비용 없음. Drag 중 해당 pointer input이 우선한다. Wait는 stamina>=1에서 atomic. Pause는 current state를 보존한다.

## 9. Content Model
반복 단위는 authored living-island mission. MVP는 4×4 한 개. Mutable pair 구성: Path↔Marsh 5, Path↔Ridge 4, Marsh↔Ridge 3, Path↔Spring 2. 확장 축은 pair, adjacency, Spring, chokepoint, Ink/Stamina pressure.

## 10. Difficulty / Variation
Path↔Marsh로 규칙 학습 → Path↔Ridge chokepoint에서 record/timing 선택 → Marsh↔Ridge와 Path↔Spring 조합으로 Stamina·Wait·귀환로까지 계산. 속도 증가가 아니라 topology/resource pressure로 상승.

## 11. Progression
MVP persistent progression 없음. Success와 best Score만 저장. 이후 island unlock 가능하나 Stamina/Ink 규칙은 meta upgrade로 바꾸지 않는다.

## 12. Economy
Not required. Ink/Stamina는 mission-local tactical resource다.

## 13. Screen Inventory
Expedition Brief, Living Map Gameplay, Expedition Result.

## 14. Screen Flow
Brief → Gameplay Turn Planning → Move/Wait Resolution → World Shift → Planning 반복 → Shrine success Result 또는 Stamina failure Result. Invalid input은 Planning 유지. Pause→Resume 동일 state. Result Retry→full reset.

## 15. Feedback System
Scout는 fog reveal+A/B 정보, Record는 permanent lock+Ink decrement, Move는 terrain cost/position, Spring은 one-time recovery, Shift는 eligible tile toggle, invalid move는 no-state-change reject, Result는 goal/exhaustion 의미를 명확히 전달한다.

## 16. Visual Direction Brief
Portrait mobile의 단일 4×4 island-map view. fog/revealed/current/next/recorded/party가 즉시 구분되고 A/B 변화가 작은 화면에서도 읽혀야 한다. 탐험 일지·양피지 감성과 살아 움직이는 섬의 변형을 결합한다. UI 좌표와 세부 배치는 Wireframe에서 정한다.

## 17. MVP Scope
Island mission 1개, 16 cells(Camp1/Shrine1/mutable14), pair composition 5/4/3/2, terrain4종, Stamina9/10, Ink4, Scout2/turn, Record1/turn, deterministic shift, occupied freeze, Spring one-time recovery, Move/Wait, success/failure/score/result/retry. NOT IN MVP: multiple islands, procedural generation, party members, combat, inventory, upgrades, dialogue, random hidden terrain.

## 18. Test Scenarios
Scout limit와 A/B 공개, Record Ink/turn limit, 정확한 shift 대상, 4 terrain rule, Shrine success priority, Wait exhaustion failure, Retry full reset, authored map solvability를 검증한다.

## 19. Known Risks
기록=현실 고정 규칙의 추상성, A/B 정보 과부하, Record 정답화, Wait 템포 저하, 단일 map 반복성.

## 20. Wireframe Handoff
3 screens, Planning/Move/Wait/Shift/Pause/Result, tile lifecycle flags, Scout/Record/Move/Wait gestures와 invalid/cancel, Stamina/Ink 의미, turn limits, exact shift eligibility, Shrine success/exhaustion failure, Retry full reset을 표현한다. 새 게임 규칙 결정은 남기지 않는다.