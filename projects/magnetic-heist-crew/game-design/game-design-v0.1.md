# Magnetic Heist Crew — Playable Game Design Spec v0.1

## 1. Product Definition
서로 다른 자석 장비를 가진 세 명의 도둑을 전환하며 금속 물체·전리품·경비의 위치를 밀고 당겨, 같은 물리 규칙으로 길을 열고 시야를 피하고 전리품을 Exit까지 넘기는 landscape mobile physics stealth / squad tactics game. MVP는 8개 mission, 4–7분. 핵심은 자력 하나가 이동·은폐·운반을 모두 해결한다는 점이다.

## 2. Player Fantasy
플레이어는 공간 자체를 바꾸는 도둑 팀의 현장 리더다. 한 번의 자력 조작으로 장애물, 동료, 경비, 전리품의 관계를 바꿔 즉석 해법을 만든다.

## 3. Core Player Verbs
Switch Crew, Move, Aim Magnet, Pulse Attract/Repel, Pass Loot, Hide, Pause. 모든 자력 입력은 target/force preview 후 commit되며 charge, object pose, noise, guard state를 바꾼다.

## 4. Core Loop
도둑 위치 잡기 → 자력 preview → 물체/경비/동료/loot 재배치 → noise와 sightline 반응 읽기 → relay transport → Exit까지 연쇄 이동. 같은 magnet rule이 routing, concealment, transport를 묶는다.

## 5. Round / Session Structure
8 authored missions. 3 thieves, 1–3 loot, 1–3 guards, 6–12 magnetic objects, one Exit. Each thief starts charge6/carry1. 모든 required loot가 Exit에 secured되고 uncaptured thief 한 명 이상이 Exit에 있으면 success. Alarm3 또는 three thieves captured면 failure.

## 6. Game Rules
2D top-down normalized workspace. Thief magnet range0.28. Clear straight line-of-force required. Light moves0.18, Medium0.12, Heavy0.07 normalized distance; Runner/Tech affect Light/Medium, Bruiser also Heavy. Target stops0.01 before static collider. Moving target may push at most one Light object; second chain collision stops both.

Every magnet pulse costs1 charge and emits mass-scaled noise at final position. Guards inside noise radius switch to Investigate for 2 Resolve steps unless already Pursuing visible thief. New noise retargets. Guard magnetic displacement >0.05 gives alarm+1.

Guard view cone range0.22, half-angle35°, blocked by wall or opaque crate. Patrol/Investigate/Pursue are deterministic. After every committed Move/Magnet/Hide exactly one Guard Resolve occurs; Switch and Drop do not. Hidden in cover means invisible until exiting cover or using magnet. Capture occurs if guard ends Resolve within0.035 of visible thief; carried loot drops.

Loot auto-pickup at Move end within0.04 with free slot. Drop is adjacent<=0.06 and no Resolve. Secured loot entering Exit becomes immutable. Success is all required loot secured + one uncaptured thief in Exit. Failure alarm3 or all captured. Retry full reset.

## 7. State Model
Heist Select→Brief→Active. Move/Magnet/Hide→Guard Resolve→Active/Result. Switch/Drop stay Active. Pause resumes exact Active state. Result allows Next/Retry/Select.

## 8. Interaction Spec
Move=drag active thief within navmesh. Switch=portrait tap uncaptured thief, no Guard Resolve. Magnet=drag/release valid magnetic target within range/clear line/mass capacity/charge>0; invalid spends nothing. Hide only inside cover and unseen. Drop Loot is two-step tap and blocks movement until resolved/cancelled.

## 9. Content Model
Crew roles: Runner, Tech, Bruiser. Mission classes: Route Opening, Guard Manipulation, Relay Theft, Cover Reconfiguration, Combined Vault. Topology is navmesh + walls + cover zones + Exit + magnetic colliders + guard patrol paths/cones. Variation axes include guard/loot/object counts, Heavy objects, cover, doors, patrol intersections, alternate routes. Every mission must have a validated success sequence under 6 charges/thief and alarm<3.

## 10. Difficulty / Variation
Early crate routing + one guard. Mid adds Tech doors and relay theft. Then opaque crates double as movable cover. Late adds Heavy objects + multiple sightlines; direct guard displacement remains emergency tool due alarm cost. Difficulty rises through topology and role combination, not speed.

## 11. Progression
8 missions linear unlock. Rating 1=success, 2=alarm<=1, 3=alarm0 and remaining total magnet charge>=8. No stat upgrades.

## 12. Economy
Not required. Charge and alarm are mission-local.

## 13. Screen Inventory
Heist Select / Case Board; Heist Brief; Heist Gameplay; Mission Result.

## 14. Screen Flow
Select→Brief→Active↔Guard Resolve→Result. Success→Next/Retry/Select. Alarm3/all captured→failure Result. Pause overlays Active and returns exactly.

## 15. Feedback System
Magnet preview shows force vector, mass class, collision stop and endpoint. Noise shows radius. Guard cones/states, alarm strikes, loot carry/relay/secure, capture/loot drop, invalid targets and result ratings must be distinct.

## 16. Visual Direction Brief
Landscape top-down compact heist room. Space is the puzzle. Magnetic objects, guards, cover, doors, crew, loot and Exit need clean silhouettes. Prediction must match physics so the game feels tactical, not random. UI coordinates remain Wireframe responsibility.

## 17. MVP Scope + NOT IN MVP
8 missions, 3 thieves, 1–3 guards/loot, 6–12 magnetic objects. Move commits, switch, attract/repel, mass classes, collision stops, one-chain push, guard displacement/noise/AI, cover Hide, Tech doors, loot relay, charge6, alarm3, capture, pause/retry, unlock/rating. NOT IN MVP: simultaneous real-time squad control, combat, procedural levels, deeper physics stacking, destructible walls, upgrades/economy, online co-op.

## 18. Test Scenarios
Validate Light/Medium/Heavy compatibility, collision stop, guard displacement alarm, noise Investigate, opaque sight blocking, capture+loot drop, relay, Exit success, alarm/all-captured failures, full Retry reset.

## 19. Known Risks
Preview mismatch can make physics feel random. Guard displacement may dominate if alarm too weak. Frozen action commits can feel board-game-like. Three-role switching may overload mobile. Chain-stop behavior needs strong feedback.

## 20. Wireframe Handoff
fun_promise: 하나의 자력 규칙으로 이동·은폐·전리품 운반을 모두 해결하며 방 자체를 재구성하는 것이 핵심 재미다.
All four screens and Active/Guard Resolve/Pause/Result states. Crew role differences, Move/Switch/Magnet/Hide/Drop semantics, range/line/mass/collision preview, guard Patrol/Investigate/Pursue, noise/view/alarm/capture, loot relay/secure, Exit success, failures, Retry and rating/unlock must all be represented without inventing separate special powers.
