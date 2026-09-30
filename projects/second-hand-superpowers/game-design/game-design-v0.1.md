# Second-Hand Superpowers — Playable Game Design Spec v0.1

## 1. Product Definition
중고 초능력과 결함을 함께 거래하는 모바일 빌드크래프트 로그라이트. 강한 능력 수집보다 결함까지 포함한 거래와 조합 발견이 중심이다.
## 2. Player Fantasy
결함 있는 중고 초능력의 가치를 알아보고 부작용까지 계산해 작동하는 3슬롯 빌드를 만드는 초능력 브로커.
## 3. Core Player Verbs
Inspect listing; trade valid listing; equip owned power; choose equipped power or Pass. Accepted actions mutate explicit state and return immediate feedback.
## 4. Core Loop
시장 확인 → 거래 → 3슬롯 빌드 → 3단계 사건 → 효과/부작용 확인 → 보상/실패 → 다음 시장에서 수정.
## 5. Round / Session Structure
3 contracts per run; each Market→Loadout→3 phases→Result. Start Credits12, Integrity5, capacity6. Pause freezes state; failed run restarts fresh.
## 6. Game Rules
Market offers4 listings. Buy requires credits>=price and capacity; sell unequipped owned power for floor(base/2). Loadout1-3. Each phase has required tag and threshold1-4. Effective strength = strength+1 if another equipped power shares primary tag. Meeting threshold adds Score1, miss removes Integrity1. Each listing carries one side effect with on_use/after_phase/tag_pair timing. Pass removes Integrity1. Phase3 with Score>=2 and Integrity>=1 succeeds and pays4+Score; otherwise run ends. Invalid actions change nothing.
## 7. State Model
RUN_START→MARKET→LOADOUT→INCIDENT_DECISION→RESOLVE. Resolve loops or opens RESULT. PAUSED resumes previous state or quits. RESULT goes next MARKET or RUN_END. RUN_END→fresh RUN_START.
## 8. Interaction Spec
Unaffordable/full/unowned/equipped-sell/empty-start/unequipped-use are rejected with zero mutation. RESOLVE locks gameplay input except pause.
## 9. Content Model
12 powers across Force/Mobility/Sense/Control; 8 side effects across three timing classes; 6+ contract templates of three ordered tag+threshold phases. Slots are logically equivalent; phases strict1→2→3; no spatial adjacency.
## 10. Difficulty / Variation
Contract1 thresholds1-2 repeated tags; Contract2 mixed tags2-3; Contract3 thresholds3-4 and changing tags. Variation is composition, defects, sequences, thresholds—not speed.
## 11. Progression
Success grants Credits and next market; contracts1→3. No permanent stat upgrades; fresh run resets.
## 12. Economy
Credits only. Start12; buy subtracts; sale adds floor(base/2); success adds4+Score; never negative.
## 13. Screen Inventory
Run Start; Market; Listing Detail/Trade Confirmation; Loadout; Incident; Pause Overlay; Contract Result; Run End.
## 14. Screen Flow
Run Start→Market↔Detail→Loadout↔Market→Incident/Resolve×3→Result→next Market; failure/victory→Run End→Run Start. Pause resumes exact state; quit ends run.
## 15. Feedback System
Show credit delta, active tag-pair warning, requirement+threshold, effective-strength comparison, ordered side-effect deltas, invalid reason, terminal cause.
## 16. Visual Direction Brief
Portrait-first worn superpower marketplace and compact incident stage. Tags/defects must read at a glance. No coordinates prescribed.
## 17. MVP Scope + NOT IN MVP
MVP: full 3-contract run, 12 powers, 8 side effects, 6+ templates, 4 tags, trading, capacity6, 3 slots, deterministic resolution, synergy, pause/restart. NOT: real-time combat, free roam, permanent upgrades, online economy, crafting, leveling.
## 18. Test Scenarios
Success: start12, buy Force3 price4 + Force2 price3 =>5; shared tag makes Force3 effective4, clearing thresholds2/3/4; Score3, Integrity5; reward7 =>12. Failure: Integrity2, Sense1 vs threshold3 =>Integrity1, attached Leak -1 =>0 and run end. Invalid price5 purchase with Credits2 changes nothing.
## 19. Known Risks
Cheap dominant combos; stacked effects readability; poor random tag coverage; repeated three-phase abstraction.
## 20. Wireframe Handoff
Fun promise: 결함까지 가격과 빌드의 일부로 받아들이고 예상 밖 조합을 발견해 다음 시장에서 즉시 고쳐 가는 재미. Represent every screen, valid/invalid trade, 3-slot build, tag-pair warning, phase requirement/threshold, ordered resolution, terminal results, pause/resume/quit, and contract1-3 variation. Full transition entry→market→loadout→incident→result→next→victory/failure→replay.
