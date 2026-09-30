# Playable Game Design Spec v0.1 — Borrowed Bodyguards

## 1. Product Definition
지나가는 시민 행동을 잠시 빌려 연쇄적으로 위협을 막는 landscape mobile crowd tactics. 핵심은 유닛 소유가 아니라 군중을 순간적으로 이어 쓰는 전술이다.

## 2. Player Fantasy
평범한 군중 사이를 옮겨 다니며 한 시민으로 문을 닫고, 다른 시민으로 장애물을 밀고, 다시 다음 시민으로 넘어가 VIP를 지킨다.

## 3. Core Player Verbs
Borrow/Transfer=시민 tap, Move=destination drag, Push=adjacent swipe, Operate=adjacent door/switch tap. 모든 valid input은 host/route/prop/barrier 상태를 바꾼다.

## 4. Core Loop
3초 threat warning 관찰 → 시민 Borrow/Transfer → Move/Push/Operate → threat resolve 차단 → VIP checkpoint → 다음 wave → exit.

## 5. Round / Session Structure
8 stages. Stage당 3–5 waves, 3–5 checkpoints, 3–6분. Planning Grace3s, Warning3s, Resolve, Recovery1s. VIP 1 edge/sec, HP2. 두 hit failure.

## 6. Game Rules
공간은 authored undirected graph 8–20 nodes. Adjacent=1 edge, Transfer=shortest distance≤2 edges. Occupied node는 이동을 막는다. VIP는 ordered checkpoint 후 exit를 향해 shortest open path를 사용하며 tie는 authored edge priority.
Borrow 성공 시 새 host, 이전 host는 현재 node에서 patrol 복귀. Move는 open path를 2 edges/sec. Push는 adjacent target을 authored direction의 빈 다음 node로 1 node 이동. Operate는 adjacent barrier edge toggle.
Runner는 resolve spawn 후 3 edges/sec로 VIP를 최대4s chase, contact hit. Projectile은 authored lane을 resolve 순간 strike하되 closed barrier가 source-to-VIP lane을 끊으면 block. Crowd Surge는 corridor occupants를 1 edge 밀며 VIP가 hazard node로 밀리면 hit. Hit=HP-1+threat 제거+Recovery1s. HP0 failure, exit+HP>0 success. Pause freezes all. Retry resets world/HP2/wave0.

## 7. State Model
Select→Brief→Planning→Warning→Resolve→Recovery 반복→Result. Pause exact return. Projectile/Surge resolve는 atomic input lock, Runner chase 중에는 play verbs 가능.

## 8. Interaction Spec
Tap citizen=Borrow/Transfer(≤2 edges). Drag node=Move. Swipe push direction은 authored direction과 dot≥0.7. Adjacent interactable tap=Operate. Priority: Pause > atomic Resolve > drag/swipe > tap. Invalid는 state change 없음.

## 9. Content Model
Classes: Runner Intercept, Projectile Lane, Crowd Surge, Relay Gap, Combined Escort. Schema: graph, ordered checkpoints+exit, civilian patrols, pushable props, door edges, hazard nodes, typed waves. 8 stages에서 base threats 각각≥2, Relay Gap≥2, Combined≥2.

## 10. Difficulty / Variation
단일 Runner→Projectile timing→Surge occupancy→넓은 relay gap→threat 조합. 속도보다 graph branching과 필요한 relay/obstacle 조합으로 증가.

## 11. Progression
8 stages linear unlock. 1 star success, 2 HP2 success, 3 HP2+모든 checkpoints. Stars는 규칙 변경 없음.

## 12. Economy
Not required.

## 13. Screen Inventory
Stage Select, Stage Brief, Escort Gameplay, Stage Result.

## 14. Screen Flow
Entry→Select→Brief→Planning→Warning→Resolve→Recovery→다음 wave→success/failure Result. Pause exact resume, Retry full reset, Success Next→next Brief.

## 15. Feedback System
Threat source/path/lane/corridor telegraph, current host와 ≤2-edge 후보 relay pulse, invalid range/occupancy/adjacency feedback, VIP path+HP, blocked/deflected/hit 결과.

## 16. Visual Direction Brief
Landscape top-down/3-quarter compact street diorama. VIP, host, transfer candidates, threat telegraph, doors/props, route가 한눈에 읽혀야 한다. UI 좌표는 Wireframe 책임.

## 17. MVP Scope + NOT IN MVP
8 stages, graph8–20, checkpoints3–5, waves3–5, HP2, Warning3s/Recovery1s, Borrow/Move/Push/Operate/Transfer, 2-edge relay, 5 content classes, pause/retry/unlock/stars.
NOT IN MVP: permanent guards, combat, civilian death, procedural maps, economy/upgrades, dialogue, online, >8 stages.

## 18. Test Scenarios
2-edge Transfer 성공+old host patrol. Closed door projectile block. Runner max4s chase 중 inputs 가능/contact HP2→1. Surge→hazard hit. 두 번째 hit failure. HP2 exit success/unlock. Pause exact clock resume. Combined는 기존 rules만 사용.

## 19. Known Risks
군중 transfer 판독성, relay 연타화, 실시간 과부하, graph/화면 거리 불일치, surge animation/판정 불일치.

## 20. Wireframe Handoff
fun_promise: 소유한 유닛을 지휘하는 것이 아니라 시민 행동을 짧게 빌리고 점유를 연쇄 전달해 즉석 경호망을 만드는 감각을 최우선으로 한다.
4 screen types와 Planning/Warning/Resolve/Recovery/Pause/Result, <=2-edge relay, old-host patrol, Move/Push/Operate, Runner/Projectile/Surge/Relay Gap/Combined, Warning3s/Runner4s/Recovery1s, HP2→0, checkpoint/occupancy/reroute, invalid feedback, Resolve lock/Runner exception을 표현한다. Wireframe은 graph adjacency/transfer/threat/HP 규칙을 바꾸지 않는다.
