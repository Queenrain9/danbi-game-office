# Pocket Canal Keeper — Playable Game Design Spec v0.1

## 1. Product Definition
Portrait mobile traffic puzzle/management. 6~10분 세션. 미니어처 운하의 물리 장치를 직접 조작해 배 흐름을 안전하게 푼다. Non-goals: 자유 물리, 도시건설, 경제.
## 2. Player Fantasy
작은 수상도시의 수문지기. 네트워크와 장치 순서를 읽어 막힘을 푸는 관제 숙련감.
## 3. Core Player Verbs
Gate arc drag, bridge circular drag, lock vertical drag, signal tap, boat inspect.
## 4. Core Loop
흐름 관찰 → 목적지/trait 확인 → 장치 조작 → 구간 진입 관찰 → 충돌/막힘 예측 → 순서 수정 → 전원 도착.
## 5. Round / Session Structure
2~4분 stage, 3~6 boats. 2~3 stages가 한 세션. Result에서 Retry/Next.
## 6. Game Rules
Segment graph 기반 deterministic 이동. narrow protected segment는 한 배만 점유. unsafe command는 strike/reject. 3 strikes 또는 45s timeout 실패. 성공/no-strike/par-ops 3-star.
## 7. State Model
stage_brief, running, device_busy, warning, paused, result.
## 8. Interaction Spec
Lever arc drag, wheel circular drag, lock vertical drag, buoy tap, boat tap. hit-test, snap/cancel, interlock rejection 포함.
## 9. Content Model
Stage 데이터 = canal graph, devices, spawn schedule, boat traits/destinations, water bands, constraints, par. MVP 6개.
## 10. Difficulty / Variation
단일 수문 → 회전교/양방향 → lock/trait/priority. 속도가 아니라 의존성과 순서로 난도 상승.
## 11. Progression
6 stages 순차 unlock. 별은 숙련 목표.
## 12. Economy
Not required.
## 13. Screen Inventory
Stage Select, Stage Brief, Canal Board, Boat Inspect Popover, Pause Overlay, Stage Result.
## 14. Screen Flow
Select → Brief → Board ↔ Busy/Warning/Inspect → Result → Retry/Next.
## 15. Feedback System
Gate/water arrows, gear/bridge state, water gauge, red protected zone, dock pulse, device sounds/haptics.
## 16. Visual Direction Brief
Portrait fixed oblique tabletop canal. 전체 graph와 boats 동시 판독, device handles 44dp 이상, 최소 HUD.
## 17. MVP Scope
6 stages, graph movement, four device interactions, occupancy/safety, inspect, result/stars, full replay loop.
## 18. Test Scenarios
Gate-only Stage1, shared-segment safety, occupied bridge interlock, unsafe lock rejection, replay reset.
## 19. Known Risks
small-screen overlap, rule overload, over-automation, graph deadlock/state sync.
## 20. Wireframe Handoff
Canal graph/protected zones, all gesture hit areas, busy/warning/paused/result variants, inspect/path, invalid/collision/timeout/success transitions를 반드시 표현한다.
