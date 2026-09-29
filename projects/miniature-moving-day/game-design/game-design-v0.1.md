# Miniature Moving Day — Playable Game Design Spec v0.1
## 1. Product Definition
Portrait mobile spatial manipulation puzzle. 2–4분. 실제 이동과 회전이 핵심이며 물리 운반·경영은 Non-goal.
## 2. Player Fantasy
좁은 공간을 읽는 숙련 이사 전문가.
## 3. Core Player Verbs
Drag move, two-finger rotate, release/place, inspect.
## 4. Core Loop
목표 확인→집기→이동→회전→통과→배치.
## 5. Round / Session Structure
2~4가구, 2~4분, 모든 목표 충족 시 성공.
## 6. Game Rules
벽/가구 겹침 금지, 목표 85% 이상, 각도 오차 12도, par 기반 별.
## 7. State Model
Brief, idle, held, invalid pose, complete.
## 8. Interaction Spec
한 손 drag, held 상태 두 손 twist, 충돌 clamp, invalid release rollback, valid snap.
## 9. Content Model
방 구조, 문 폭, 가구 형태, 시작/목표 포즈, 장애물, 배치 순서.
## 10. Difficulty / Variation
직사각형/넓은 문→긴 가구/굽은 복도→L자/순서 의존.
## 11. Progression
6 stages sequential unlock.
## 12. Economy
Not required.
## 13. Screen Inventory
Stage Select, Brief, Moving Room, Pause, Result.
## 14. Screen Flow
Select→Brief→Room→Result→Next/Retry.
## 15. Feedback System
Lift shadow, contact outline, snap, haptic, rollback.
## 16. Visual Direction Brief
Fixed dollhouse cutaway, large readable furniture, sparse HUD.
## 17. MVP Scope
6 stages, collision, drag/twist, snap/rollback, undo/reset/scoring. Final art/economy 제외.
## 18. Test Scenarios
회전 통과, 실제 각도 변화, rollback, 순서 퍼즐, 반복 실행.
## 19. Known Risks
멀티터치, 모서리 감각, tolerance, 단순 노동화.
## 20. Wireframe Handoff
모든 화면과 idle/held/collision/valid/placed, drag/twist/clamp/rollback/snap, modal/transition을 표현.
