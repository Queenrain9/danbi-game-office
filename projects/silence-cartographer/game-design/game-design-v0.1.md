# Silence Cartographer — Playable Game Design Spec v0.1

## 1. Product Definition
완전히 어두운 동굴에서 소리를 내야만 주변 지형이 드러나지만 그 소리를 들은 포식자도 움직이는 portrait mobile 턴제 음향 잠입 탐험 게임. MVP는 6개 expedition, 각 3–6분. 핵심은 정보 획득과 위치 노출이 같은 행동이라는 갈등이다. Non-goals: real-time combat, free analog movement, light/torch management, procedural caves.

## 2. Player Fantasy
플레이어는 빛 없이 동굴을 기록하는 탐사 지도 제작자다. 얼마나 크게, 언제, 어디서 소리를 낼지 결정해 보이지 않는 길을 조금씩 확정하고 포식자의 반응을 이용해 Relic을 회수한 뒤 살아서 돌아온다.

## 3. Core Player Verbs
Move: revealed adjacent tile로 swipe, Air-1, predator 1 step. Ping: 짧게 tap, player 중심 radius3 reveal, hearing5. Knock: 0.6초 hold/release, radius5 reveal, hearing8. Throw Clicker: revealed target graph distance<=4에 drag, Clicker-1/Air-1, target 중심 reveal2/hearing7. Hide: Alcove에서 tap, Air-1, 다음 predator step의 same-tile contact만 무효. Pause: simulation freeze.

## 4. Core Loop
소리로 미지 지형을 산다 → 포식자가 어느 소리 위치를 쫓는지 읽는다 → 공개된 통로로 이동/숨기 → Air가 줄고 predator가 한 칸 움직인다 → 다음 미지 구간에서 다시 sound choice → Relic 획득 → 영구적으로 공개된 지도를 이용하되 바뀐 predator 위치와 남은 Air를 고려해 Entrance로 귀환.

## 5. Round / Session Structure
6 authored expeditions. 각 mission은 Entrance, Relic, 1 predator, 16–26 walkable tiles. Start 시 Air22–30, Clicker0–2, Start+인접1만 reveal. Relic tile 진입 시 relic_collected=true. 그 상태로 Entrance에 재진입하면 success. Air0 또는 predator contact면 failure. Retry는 mission-local state를 전부 reset.

## 6. Game Rules
동굴은 orthogonal tile graph이며 movement/sound 모두 shortest-path graph step을 쓴다. Unrevealed tile은 진입 불가. Sound reveal은 wall까지 보이게 하지만 wall을 넘어 확장하지 않는다. 모든 accepted gameplay action은 정확히 Air1을 쓰고 predator를 정확히 1 step 진행시킨다. 무료 Wait는 없다.

Ping: origin player, reveal3/hearing5. Knock: origin player, reveal5/hearing8. Clicker: origin target tile, reveal2/hearing7, throw range4, 1 charge 소비. Predator가 sound origin까지 hearing radius 안이면 즉시 Hunt(target=origin, steps=3)로 retarget되고 같은 action의 predator step부터 적용된다.

Predator Patrol은 authored cyclic path를 1 node/action. Hunt는 target으로 가는 shortest path를 1 edge/action, 동률은 authored tie_break index가 낮은 neighbor. target 도달 또는 3 steps 후 Patrol로 복귀한다. 새 sound를 들으면 target/steps를 덮어쓴다. Predator가 action resolution 끝에 player와 same tile이고 hidden_for_resolution=false면 failure.

Hide는 Alcove에서만 valid하며 그 action의 predator step 한 번만 contact를 무효화하고 즉시 해제된다. Relic pickup 뒤 Entrance 진입 success는 같은 Move로 Air가0이 되어도 failure보다 먼저 판정한다.

Pause에는 real-time timer가 없으며 모든 state를 freeze. Retry는 positions, reveal, Air, Clickers, Relic, predator AI를 authored defaults로 복구한다.

## 7. State Model
Mission Select → Brief → Exploration. Sound action은 Echo Resolve → Predator Resolve, Move/Hide는 Predator Resolve. Resolve 후 contact/success/Air failure를 판정해 Exploration 또는 Result로 간다. Pause는 Exploration/Echo Resolve에서 exact return state로 복귀하거나 Retry/Select 가능. Result에서 success는 Next/Retry/Select, failure는 Retry/Select.

## 8. Interaction Spec
Move는 cardinal swipe이며 revealed+walkable adjacent tile만 valid. Ping은 Sound control <0.6s tap, Knock은 >=0.6s hold 후 release; control 밖으로 drag-off하면 Knock cancel/no cost. Clicker는 revealed walkable target, graph distance<=4, charge>0일 때만 valid; invalid release는 snap back/no cost. Hide는 current tile=Alcove에서만 valid. Continuous gesture가 활성 중이면 다른 gameplay input은 받지 않는다.

## 9. Content Model
Content unit은 authored cave expedition. MVP content classes: Basic Echo Maze, Alcove Crossing, Remote Decoy, Branching Hunt, Return Pressure, Combined Expedition. Mission topology는 16–26 walkable nodes, Entrance1, Relic1, Alcove1–3, cyclic patrol path, optional branches/chokepoints, per-node tie_break index. Variation axes는 topology, patrol, Air22–30, Clickers0–2, Alcoves1–3, Relic depth, sound-needed reveal gaps. 각 mission은 deterministic rules로 실제 success route가 검증돼야 한다.

## 10. Difficulty / Variation
M1 Ping/Knock only. M2 Alcove. M3 Clicker. M4 branching shortest paths/tie-break reading. M5 깊은 Relic과 tighter Air로 return pressure. M6 combines all. 난도는 timer speed가 아니라 topology, sound radius choice, predator route, finite Air/Clicker 조합으로 오른다.

## 11. Progression
6 missions linear unlock. Success면 next unlock. Grade: C=success, B=remaining Air>=start25%, A>=start40%. Best grade 저장. Upgrade로 core rule은 바꾸지 않는다.

## 12. Economy
Not required. Air/Clickers는 mission-local tactical resources, grade는 소비하지 않는다.

## 13. Screen Inventory
Expedition Select / Cave Atlas; Mission Brief; Cave Exploration; Mission Result.

## 14. Screen Flow
Game Entry → Select → Brief → Exploration. Sound→Echo Resolve→Predator Resolve→Exploration/Result. Move/Hide→Predator Resolve→Exploration/Result. Relic pickup은 같은 Exploration에서 objective만 Return으로 변경. Success/failure Result→Next/Retry/Select. Pause는 overlay state이며 exact state resume.

## 15. Feedback System
Sound마다 다른 echo wave/audio/haptic. Heard predator는 exact tile이 unrevealed면 방향 cue만 제공. Move는 position/Air feedback. Hide는 one-resolution protection을 명확히 표시. Predator는 revealed tile에서만 exact position. Relic은 Return objective 전환. Result는 remaining Air와 grade를 표시한다.

## 16. Visual Direction Brief
Portrait top-down cave map. Darkness와 expanding echo contour가 주인공이며 revealed floor/wall/Alcove/Entrance/Relic이 빠르게 구분되어야 한다. Unrevealed predator exact position은 숨기고 sound response는 방향으로만 전달한다. Air/Clicker/objective는 cave를 가리지 않는 보조 정보다. 좌표/패널 layout은 Wireframe 책임.

## 17. MVP Scope + NOT IN MVP
6 authored expeditions, 16–26 walkable tiles each, one Entrance/Relic/predator, Alcove1–3. Ping3/5, Knock5/8, Clicker2/7 range4, Air22–30, Clickers0–2, deterministic Patrol/Hunt, one-step Hide, permanent reveal, Relic return, contact/Air failure, pause/retry, unlock/grade. NOT IN MVP: multiple predators, real-time movement, combat, torch system, procedural generation, crafting, persistent upgrades, dialogue, online modes.

## 18. Test Scenarios
Ping vs Knock hearing/reveal 차이, Clicker remote retarget, three-step deterministic Hunt, Alcove one-step protection, Relic return success priority at Air0, contact/Air failure reachability, Retry full reset, no zero-cost waiting strategy, all six content classes using only defined rules를 검증한다.

## 19. Known Risks
Permanent reveal로 후반 긴장이 빨리 줄 수 있음. Air가 단순 timer처럼 느껴질 수 있음. Deterministic predator가 암기화될 수 있음. Hidden predator cue가 규칙보다 많은 정보를 줄 위험. Clicker가 너무 강하면 local sound choice가 약화될 수 있음.

## 20. Wireframe Handoff
fun_promise: 소리는 지도를 보여주는 동시에 포식자에게 위험한 위치 정보를 준다. '보기'와 '들키기'가 같은 입력이어야 한다.
4 screen types와 Exploration/Echo Resolve/Predator Resolve/Pause/Result states를 표현한다. Basic Echo/Alcove/Remote Decoy/Branching Hunt/Return Pressure/Combined variation을 모두 커버한다. Unrevealed/revealed, exact predator visibility, Move/Ping/Knock/Clicker/Hide gesture와 invalid/cancel/priority, Air/Clicker costs, sound radii, Hunt3/tie-break/retarget/Patrol return, Relic objective change, success priority, contact/Air failure, Pause/Retry reset을 표현한다. 무료 Wait나 정보-위험 교환을 제거하는 새 규칙을 추가하지 않는다.
