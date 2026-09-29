# Playable Game Design Spec v0.1 — Candle Creature Keeper

## 1. Product Definition
촛농 생물을 가열·변형·냉각해 habitat에 맞추는 portrait mobile transformation puzzle. 4–6분/case. Non-goals: free sculpting, breeding, idle care.
## 2. Player Fantasy
열과 재질을 읽고 생물을 다치지 않게 정확한 형태로 돌보는 사육사.
## 3. Core Player Verbs
Heat=source drag/hold; Shape=soft region drag; Cool=plate drag/hold; Place=habitat drag.
## 4. Core Loop
목표 확인→가열→변형→냉각 lock→fit→correction→다음 creature.
## 5. Round / Session Structure
Case당 3 creatures, creature당 3 tests. Fail 후 20s correction grace. Integrity0/3rd fail/grace0 terminal.
## 6. Game Rules
5 regions, heat0–100. 50–89 shapeable, 80 warning, 90+ 1초면 integrity-1/form reset/heat70. Passive -5/sec, plate -25/sec. Below25 lock, reheat50 unlock. 3 forms/region. Fit exact required indices. Pause freezes all.
## 7. State Model
Brief→Care↔Overheat→Fit→Result/Correction; 3 resolved→Case Result. Retry resets case.
## 8. Interaction Spec
Single touch. Closest region heat. Shape only50–89, release snaps nearest form, return-before-release cancels. Plate one region. Shape>tool>place priority.
## 9. Content Model
3 cases/9 creatures/species1/5 regions/3 forms/3 habitats. Authored form-index requirements.
## 10. Difficulty / Variation
Required region count→starting locks→adjacent 25% heat interaction. Speed-only 금지.
## 11. Progression
3 cases unlock+journal stars; upgrades 없음.
## 12. Economy
Not required.
## 13. Screen Inventory
Case Select, Creature Care, Creature Result Overlay, Case Result, Pause.
## 14. Screen Flow
Select→Brief→Care→Fit→Result/correction→3 creatures→Case Result. Terminal failure도 Result. Pause overlay.
## 15. Feedback System
Gloss/droop, shape snap, matte lock, overheat shimmer, exact mismatch flash + audio/haptic.
## 16. Visual Direction Brief
Portrait close-up workbench, creature 중심, 5 regions 판독. Dark lab/warm flame/cool plate. 좌표는 Wireframe 책임.
## 17. MVP Scope
3 cases, 9 creatures, 1 species, 5 regions, 3 forms each, 3 habitats와 닫힌 heat/shape/cool/fit/correction rules.
## 18. Test Scenarios
Threshold 인지, predictable snap, overheat reaction, exact correction, 9 puzzle 반복성.
## 19. Known Risks
단계형 형태, 상태 혼동, finger occlusion, grace stress, content repetition.
## 20. Wireframe Handoff
확정된 state/gesture/threshold feedback/error/transition만 표현하고 새 규칙을 만들지 않는다.