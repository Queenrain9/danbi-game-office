# Playable Game Design Spec v0.1 — Moon Crane Dispatcher
## 1. Product Definition
달빛 항구의 종이학 크레인 4관절을 직접 접고 펼쳐 화물별 제약과 장애물을 통과해 목적지에 내려놓는 모바일 공간 물류 퍼즐. Portrait mobile spatial logistics puzzle. Non-goals: freeform construction, 3D depth switching, management sim.
## 2. Player Fantasy
달빛 항구의 종이학 크레인 기사로서 좁은 지붕과 골목 사이를 읽고 화물을 안전하게 옮기는 정교한 숙련감을 느낀다.
## 3. Core Player Verbs
Fold/Extend, Grab/Release, Brake, Reset. 각 input/target/condition/state change/feedback은 structured spec과 동일하다.
## 4. Core Loop
Job 규칙 확인 → 관절 drag로 pickup 정렬 → Grab → 장애물과 cargo constraint를 보며 운송 → Brake로 흔들림 억제 → drop zone Release → 별 판정 → 다음 Job. Contract당 3 Jobs.
## 5. Round / Session Structure
MVP 4 Contracts×3 Jobs=12 Jobs. Job 45–90초, Contract 4–6분. Job Brief→Planning→Carrying→Delivery Check→Result. hard collision 또는 Stability 0은 Failure→Retry. 세 Job 성공 시 다음 Contract unlock.
## 6. Game Rules
4 joints: neck ±70°, wings ±55°, leg -45°~65°, max100°/sec. Pickup radius0.045 normalized width, Grab/Release speed≤0.08. Standard/Fragile/Oversize/Lantern 규칙, Stability/Brake/collision/delivery/star/reset/pause/retry는 structured game_rules에 명시된 수치와 순서를 따른다.
## 7. State Model
Job Brief→Planning→Carrying→Delivery Check→Job Result; collision/Stability0→Failure; third success→Contract Result. 모든 state의 allowed/exit/next는 structured state_model과 동일하다.
## 8. Interaction Spec
Joint delta clamp/reject, max two touches, Grab/Release validity, Brake coexistence, Reset confirm/cancel을 적용한다.
## 9. Content Model
MVP cargo 4종과 obstacle/hazard 4종(Wall/Roof, Arch Gap, Swing Gate, Moon Draft), 4 Contract tier, 공통 Job schema를 사용한다. 각 유형의 고유 rule/state 차이는 structured content_model에 정의돼 있다.
## 10. Difficulty / Variation
Contract1은 reach/clearance, 2는 Fragile+Draft, 3은 Oversize+Swing Gate, 4는 Lantern tilt와 기존 hazard 조합. 속도만이 아니라 cargo rule과 topology 조합으로 상승.
## 11. Progression
4 Contracts linear unlock. 이전 Contract 3 Jobs 완료 시 다음 unlock. Stars는 mastery/replay 기록만 하며 물리 stat을 강화하지 않는다.
## 12. Economy
Not required. Brake/Stability는 Job-local resource이고 stars는 currency가 아니다.
## 13. Screen Inventory
Harbor Contract Select, Contract Brief, Job Brief, Crane Gameplay, Job Failure, Job Result, Contract Result
## 14. Screen Flow
Contract Select→Brief→Job Brief→Planning→Carrying→Delivery Check→Job Result→next Job; third success→Contract Result→next Contract. Failure→Retry/quit. Pause는 Planning/Carrying 위에서 exact resume. Replay는 same Job clean state.
## 15. Feedback System
Joint, Grab, instability, collision, Brake, delivery, dynamic hazard 각각 distinct feedback을 사용한다.
## 16. Visual Direction Brief
Portrait 2.5D paper-harbor diorama. Crane/cargo play plane, obstacle silhouettes, clearance, joint identity, cargo danger state가 작은 화면에서 즉시 읽혀야 한다. UI 좌표·패널 크기·정확한 camera framing은 Wireframe에서 결정한다.
## 17. MVP Scope
4 Contracts, 12 authored Jobs, 4 cargo classes, 4-joint crane, 4 obstacle/hazard classes, Stability/Brake/timer/stars, linear unlock/replay. 최종 polygon layout/par time/art variant는 editable content data이며 새로운 rule type은 추가하지 않는다. NOT IN MVP: Freeform crane construction, 3D depth switching, Multiple cranes, Persistent currency/upgrades, Procedural levels, Dialogue branches, Online leaderboards.
## 18. Test Scenarios
4 joints range/blocked delta works / Standard pickup-delivery succeeds / Fragile >18° can drain to failure / Lantern >25° drains and recovers safe / Oversize fails a clearance Standard passes / Swing Gate collision reachable / Moon Draft changes swing with pre-warning / Brake reaches0 then recovers / Reset restores state +10 sec / All 4 Contracts progress/unlock / Pause preserves exact state
## 19. Known Risks
Two-finger control may be demanding / Collision rejection may feel sticky / Swing model predictability tuning / Hazard-vs-player failure attribution / 12 Jobs need topology variety
## 20. Wireframe Handoff
All 7 screen types + locked/unlocked Contract states / All 4 cargo class gameplay states / Planning/Carrying/instability/Delivery/Failure/Pause/Reset-confirm states / Joint drag including two-touch, Grab/Release valid-invalid, Brake hold/resource / Wall/Arch/Swing Gate/Moon Draft including Draft pre-warning / Stability drain/recovery, collision failure, delivery rejects, stars / No new cargo/hazard rule to be invented