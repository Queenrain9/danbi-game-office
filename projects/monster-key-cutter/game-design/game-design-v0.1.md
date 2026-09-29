# Playable Game Design Spec v0.1 — Monster Key Cutter

## 1. Product Definition
Portrait mobile precision craft puzzle, 1–2분. 핀을 읽고 금속을 직접 제거해 정확한 열쇠를 만든다. Non-goals: 자동 제작, 선택지형 상점, CNC 시뮬레이터.
## 2. Player Fantasy
괴물 거리의 정밀 열쇠공으로 관찰과 손기술을 익힌다.
## 3. Core Player Verbs
Lens inspect, coarse/fine file, insert, arc rotate. 절삭은 비가역 상태변화.
## 4. Core Loop
관찰→절삭→테스트→진단→재가공.
## 5. Round / Session Structure
4핀, blank 2, test 3회, 180초 한도.
## 6. Game Rules
Tolerance ±0.08, depth 0..1, material removal only. 모든 pin error가 tolerance 이내이고 75° 회전하면 성공.
## 7. State Model
Inspect→Cut→Test→Result 또는 Diagnostic→Cut.
## 8. Interaction Spec
44pt tooth target, file drag/lift cancel, fine 0.01 step, insert snap, arc rotate, outside target no cut.
## 9. Content Model
Order 단위; pin profile/tolerance/material/wear/keyway 축. MVP 12 authored profiles.
## 10. Difficulty / Variation
넓은 tolerance→높이차/마모→재질/핀수. Speed-only 금지.
## 11. Progression
12 주문 순차 해금과 최고 정확도.
## 12. Economy
Not required.
## 13. Screen Inventory
Order Board, Workbench, Result, Pause.
## 14. Screen Flow
Board→Inspect→Cut→Test↔Diagnostic→Result.
## 15. Feedback System
Pin ticks, shavings/scrape, torque resistance, success turn, overcut warning.
## 16. Visual Direction Brief
Portrait, 큰 cross-section, 하단 tool rail, finger-safe 확대, 금속 작업대.
## 17. MVP Scope
4핀, 2 blanks, lens, two files, depth model, test/diagnostic, 12 profiles. NOT IN MVP: economy/narrative/decor/multi-material.
## 18. Test Scenarios
20초 내 first cut, tolerance feedback 일치, overcut 이해, diagnostic 80%, 60–120초 주문.
## 19. Known Risks
Finger occlusion, pixel-luck precision, over-helpful diagnostic, irreversible frustration.
## 20. Wireframe Handoff
모든 state와 lens/file/insert/rotate gesture, invalid target, overcut, replacement, blocked feedback, counters.