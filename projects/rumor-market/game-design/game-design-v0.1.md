# Rumor Market — Playable Game Design Spec v0.1
## 1. Product Definition
소문을 한 사람에게 흘리고 결정론적 관계망 파장으로 시장·행동·관계를 바꾸는 5일 정보 전략 게임.
## 2. Player Fantasy
욕구와 관계를 읽어 한 문장으로 마을을 움직이는 소문 설계자.
## 3. Core Player Verbs
Observe(tap NPC/shop→known info); Seed(select rumor+NPC, Influence>=1→Influence-1/active rumor); Advance(confirm→propagation/effects); Inspect(result→causal ledger, no mutation).
## 4. Core Loop
관찰→소문 선택→NPC seed→최대2-hop 전파/변형→가격·행동·관계 변화→목표 확인→다음 날 설계.
## 5. Round / Session Structure
5일. Planning→Seeding→Propagation→Result. Influence3, Reputation3, hand4, 하루 최대1 seed. Day5 objective2개 모두 true=success. Reputation0=즉시 fail. Pause exact resume; Retry day1 reset.
## 6. Game Rules
Directed edge trust0-3/type friend-rival-customer-supplier; trust>=1만 전파. Rumor=subject/claim(price,desire,reputation)/polarity/truth/potency1-3/source. Acceptance=potency+interest0-2+source_trust0-2-skepticism0-2; >=3 accept. Deterministic breadth-first max2 hops; accepter는 highest-trust eligible edge 하나로 forward, tie=stable NPC id, duplicate recipient 금지. False rumor가 rival edge를 건너면 polarity 1회만 flip; truthful은 flip 없음. Price=potency*10% next-day modifier; desire=action priority ±potency; reputation=attitude ±potency capped -3..3. False rumor가 named subject 또는 source_trust2 witness에 닿으면 effects 후 expose: Reputation-1, temporary price/desire 제거, attitude 유지. Influence start3; seed-1; end-day+1 cap3; 신규 objective+1 cap3. Invalid=zero mutation. Influence0은 no-seed 가능.
## 7. State Model
SCENARIO_START→PLANNING→SEEDING(or no-seed)→PROPAGATION→RESULT→next PLANNING/RUN_END. Reputation0→RUN_END. PAUSED→previous/quit. RUN_END→clean retry.
## 8. Interaction Spec
Planning inspection non-mutating; seed confirm만 resource 소비; propagation은 atomic hop 사이 pause 외 input lock; invalid target/unowned/Influence0 seed/second seed zero mutation; Result inspect non-mutating.
## 9. Content Model
Scenario=6-8 NPC(skepticism/interests/actions/attitudes)+directed typed trust edges+rumor fragments+shops(owner/base/temp modifier)+exactly2 measurable objectives. Topology가 판정에 직접 관여.
## 10. Difficulty / Variation
초반 sparse6/potency2-3/명확한 interests; 후반7-8/rival/mixed skepticism/potency1-3/indirect second-hop objectives. 속도 압박 없음.
## 11. Progression
3 scenarios 선형 unlock; scenario 내부 day1→5+objective states; permanent upgrades 없음.
## 12. Economy
Influence only: start3, seed-1, end-day+1 cap3, 신규 objective+1 cap3. Reputation=failure meter.
## 13. Screen Inventory
Scenario Select; Brief; Town Planning; Rumor Detail; Seed Confirmation; Propagation; Day Result/Causal Ledger; Pause; Run Result.
## 14. Screen Flow
Select→Brief→Planning↔Detail→Confirm→Propagation→Result→next Planning. No-seed→Propagation. Day5/Reputation0→Run Result. Pause exact resume; Retry day1.
## 15. Feedback System
Before: interests/trust/type/price/objectives. During: accept/reject/chosen edge/rival flip/exposure. After: exact deltas/objectives/Influence/Reputation/causal path. Invalid exact reason.
## 16. Visual Direction Brief
Portrait compact town information board. NPC/shop identity stable; relationship/rumor overlays contextual. 6-8 actors 비교와 causal readability 우선; 좌표 미확정.
## 17. MVP Scope + NOT IN MVP
MVP=3 scenarios, 6-8 NPC, 5 days, 3 claims, true/false, deterministic2-hop, rival mutation, price/action/attitude, resources, objectives, pause/retry, ledger. NOT=free-text rumor, generated dialogue, multiplayer, open-world, combat, permanent upgrades, multiple seeds/day, hidden random rolls.
## 18. Test Scenarios
Success: potency3 negative price rumor A accept→trust3 shopkeeper B→-30% next day; day5 both goals true/Reputation>=1. Failure: Reputation1 false reputation rumor reaches named subject→exposure→0. Mutation: false negative desire rival-cross→positive once. Rejection score2 stops. No-seed Influence0→end-day1. Invalid second seed zero mutation.
## 19. Known Risks
2-hop readability; over-predictable forwarding; exposure clarity; one-day effect visibility; unreachable objective pairs—scenario reachability validation required.
## 20. Wireframe Handoff
fun_promise: 한 사람에게 흘린 소문이 관계망에서 받아들여지고 때로 뒤집히며 가격·관계·행동을 바꾸는 파장을 예측하고 이용하는 재미. 9 screens/states, no-seed, exposure failure, day5 outcome, pause/retry를 표현. Directed trust, acceptance inputs, deterministic forward, 2-hop limit, one-time rival flip 보존. Feedback=accept→forward/mutation→effect→exposure. 새 random rule 금지.