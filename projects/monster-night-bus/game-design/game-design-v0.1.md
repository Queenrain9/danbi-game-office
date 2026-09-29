# Playable Game Design Spec v0.1 — Monster Night Bus

## 1. Product Definition
괴물 심야버스의 승객을 직접 배치하고 목적지를 보존하는 분기 노선을 선택하며 운행 중 좌석 갈등을 재배치로 해결하는 portrait mobile route-management / spatial strategy game. 한 세션 5–7분. 목표 감각은 좁은 차내를 읽고 사람과 노선을 동시에 운영하는 숙련감이다. Non-goals: 실시간 운전 시뮬레이션, 대화 선택 RPG, 복잡한 경영/업그레이드.

## 2. Player Fantasy
플레이어는 괴물 도시의 마지막 심야버스 기사 겸 차장이다. 승객의 체형·습성·목적지를 읽고 누구를 태울지, 어디에 둘지, 어느 분기로 갈지를 연결해 모두를 무사히 내려주는 책임감과 운영 숙련을 느낀다.

## 3. Core Player Verbs
Board는 대기 승객을 seat/standing slot으로 drag한다. Unboard는 출발 전 onboard 승객을 정류장 queue로 되돌린다. Choose Route는 연결된 next stop을 선택·확정한다. Re-seat는 Stop Service 또는 Travel Warning 중 승객을 valid empty slot으로 옮긴다. Respond는 경고된 conflict pair를 2.0초 안 분리해 Comfort 손실을 막는다. 각 성공 입력은 passenger lifecycle, occupancy, next_stop 또는 conflict state를 즉시 변경한다.

## 4. Core Loop
정류장 도착·자동 하차 → 승객 탑승/좌석 배치 → 다음 정류장 분기 선택 → 6–12초 Travel → forbidden pair 경고 시 재배치 → 다음 정류장. 총 5개 Travel segment를 반복한다.

## 5. Round / Session Structure
Comfort 3, Score 0으로 Depot 시작. Depot→Lantern Junction→(Moon Market|Canal Steps)→Old Square→(Cemetery Gate|Clock Tower)→Terminal의 5 segment. Terminal 도착 시 Comfort>=1이면 성공. Travel 중 Comfort 0이면 즉시 실패. Result의 Retry는 전체 세션 state를 초기화한다.

## 6. Game Rules
버스는 seat 6, standing 2. Passenger는 origin stop에서 waiting으로 존재하고 해당 stop 도착 시 조작 가능하다. Valid slot에 drag하면 onboard, 출발 전 queue로 되돌릴 수 있다. Route confirm 후 목적지까지 하차 불가하며 destination 도착 시 자동 하차한다. 남긴 승객은 그 run에서 사라진다.

Trait 규칙: Large는 seat만 사용하며 옆 seat 하나를 예약하고, 옆 자리가 이미 차 있으면 placement invalid. Wet은 seat/standing 가능하며 seat에서 하차하면 WetResidue 1 segment를 남긴다. Spark는 WetResidue seat에 놓을 수 없고 seated Wet과 인접하면 forbidden pair. Howler와 Sleeper가 seat 인접이면 forbidden pair. Sleeper는 seat만 사용한다. WetResidue는 다음 Travel 종료 후 1 감소해 0에서 제거된다.

Route는 현재 stop의 directed edge만 선택 가능하며, 선택한 next stop 이후로 onboard passenger 목적지 하나라도 도달 불가능하면 confirm invalid다.

출발 시 seated adjacency를 scan해 Spark-Wet, Howler-Sleeper pair를 warning queue에 넣는다. 경고는 순차 진행되고 pair마다 2.0초다. 경고 중 둘 중 하나를 valid empty slot으로 이동해 adjacency를 끊으면 해결. Travel 중 새 forbidden adjacency를 만드는 이동은 invalid. deadline까지 conflict가 남으면 Comfort -1이며 그 pair는 해당 segment에서 재감점하지 않는다. Comfort는 회복되지 않는다. Travel은 최소 6초이며 모든 warning이 끝나기 전 도착하지 않는다.

Score는 delivered passenger +100, Terminal success +500, 남은 Comfort당 +200, left-behind passenger당 -50. Success=Terminal+Comfort>=1. Failure=Comfort 0.

Pause는 Travel clock, warning deadline, animation과 passenger input을 모두 정지한다. Retry는 route, passenger manifest, Comfort=3, Score=0, WetResidue=0, conflict history를 전부 초기화한다.

## 7. State Model
Stop Service: arrival/session start 진입. Board/unboard/re-seat/route select/confirm 가능. Valid route confirm 시 Travel. Route choice cancel은 next_stop lock만 해제한다.
Travel: route confirmed 진입. travel_elapsed와 queue가 진행된다. Active warning이 없으면 valid re-seat 가능. 6초 경과+queue empty면 arrival. Comfort 0이면 Result failure.
Travel Warning: queued pair 활성화 시 진입. warned passenger 재배치 가능. pair 분리 또는 2.0초 expiry로 종료. expiry unresolved면 Comfort -1. 다음 warning 또는 Travel로 복귀.
Result: Terminal success 또는 Comfort 0 진입. Retry/finish. Retry는 Stop Service/Depot 초기 state로 간다.

## 8. Interaction Spec
Passenger drag의 valid 기준은 empty slot+trait hard rules다. Stop Service에서는 forbidden adjacency 자체는 허용하되 conflict로 표시한다. Invalid release는 source로 복귀하고 state 값은 변하지 않는다. Route select는 edge+destination reachability를 모두 만족해야 confirm된다. Travel re-seat는 hard rules에 더해 new forbidden adjacency 생성도 금지한다. Drag 중 해당 pointer가 우선이며 다른 passenger 입력은 받지 않는다. Pause 성공 입력은 simulation clocks를 정지한다.

## 9. Content Model
반복 단위는 night-route passenger manifest. MVP graph는 8개 stop이고 authored waiting count는 Depot2/Junction3/Market2/Canal2/Old Square3/Cemetery1/Tower1=14명이다. 한 run에서는 두 branch 중 하나씩 방문해 11명을 조우한다. 확장 축은 origin, destination, trait, branch pressure, seat-conflict composition, bus capacity다.

## 10. Difficulty / Variation
초반은 단일 특성과 넉넉한 공간. 중반은 destination이 branch를 제한하고 Large가 공간을 잠근다. 후반은 WetResidue+Spark, Howler-Sleeper가 겹쳐 현재 좌석과 다음 하차를 함께 계산하게 한다. 속도만 높이지 않는다.

## 11. Progression
MVP에는 영구 성장 불필요. best Score와 success만 저장. 이후 mission/버스/trait 해금은 확장 가능하나 v0.1 규칙과 분리한다.

## 12. Economy
Not required. Score는 결과 평가 전용이며 소비되지 않는다.

## 13. Screen Inventory
Night Route Brief, Bus Route Gameplay, Run Result.

## 14. Screen Flow
Brief → Gameplay/Stop Service ↔ Travel ↔ Travel Warning → 다음 Stop Service 반복 → Terminal success Result. Comfort 0→failure Result. Route confirm 전 cancel 가능. Pause는 Gameplay overlay state이며 동일 timer/state로 Resume. Retry는 Depot부터 전 reset.

## 15. Feedback System
Boarding은 eligibility/snap/occupancy feedback. Invalid는 reject+no state change. Route invalid는 stranded destination을 식별. Conflict Warning은 정확한 pair와 2.0초 window를 알린다. Resolve는 Comfort 유지, expiry는 Comfort -1. Arrival은 자동 하차와 WetResidue 생성을 알려준다.

## 16. Visual Direction Brief
Portrait mobile. 길게 읽히는 버스 내부 cutaway가 중심이며 passenger silhouette, seat occupancy, adjacency가 즉시 판독되어야 한다. Route 정보는 current/next/destination 관계를 명확히 전달하되 gameplay를 가리지 않는다. 야간 네온과 실내등, 체형 중심 괴물 디자인. UI 좌표/패널 배치는 Wireframe 책임이다.

## 17. MVP Scope
Night Route 1개, 8 unique stops, run당 6 stop 방문/5 Travel. seat6+standing2. Large/Wet/Spark/Howler/Sleeper 5 traits. Authored passengers 14명, run당 11명 조우. Comfort 3, WetResidue, 2 forbidden adjacency types, 2.0초 sequential warning, reachability route constraint, boarding/unboarding, scoring, Result/Retry 포함. NOT IN MVP: persistent economy, upgrades, multiple missions, random generation, dialogue choices, combat, steering, extra traits.

## 18. Test Scenarios
첫 Travel 시작 가능성, hard-invalid 3종, warning resolve/no penalty, warning expiry/Comfort-1, route reachability invalid, Comfort 3→0 reachable failure, Terminal success 후 complete Retry reset을 검증한다.

## 19. Known Risks
작은 adjacency 판독, trait icon overload, destination constraint가 선택을 자동화할 위험, warning이 반응게임처럼 느껴질 위험, authored manifest가 unavoidable loss를 만들 위험.

## 20. Wireframe Handoff
3 screens, Stop Service/Travel/Travel Warning/Pause, seat6+standing2 occupancy, Large reservation, WetResidue, forbidden pair, passenger drag/unboard, route select/confirm/cancel, reachability invalid reason, 2.0초 warning/resolution/expiry, Comfort transition, arrival auto-disembark, Terminal success, Retry reset을 모두 표현한다. 새 게임 규칙 결정은 남기지 않는다.