# One-Way Wizard — Playable Game Design Spec v0.1

## 1. Product Definition
한 번 시전한 주문이 사라지지 않고 계속 순환하는 모바일 action strategy game. 새 주문은 기존 주문을 Redirect·Split·Merge해 전장을 바꾼다. 3-wave run, 4–6분. 핵심은 과거 행동이 현재 전술 자산으로 남는 것.

## 2. Player Fantasy
주문을 지우는 대신 쌓아가는 마법사. 몇 초 전 내가 만든 궤적이 지금의 함정·방패·연쇄 공격이 되고, 한 화면이 점점 내가 설계한 마법 기계처럼 변한다.

## 3. Core Player Verbs
Move, Aim, Cast Bolt, Redirect, Split, Merge, Pause. Cast는 persistent projectile을 만들고, Redirect/Split/Merge는 이미 존재하는 주문의 미래 궤적을 바꾼다.

## 4. Core Loop
이동·조준 → 주문 발사 → 기존 주문 궤적 관찰 → Redirect/Split/Merge → 적을 누적 궤도에 유도 → wave clear → 살아남은 주문 중 최대3개 carry → 다음 wave.

## 5. Round / Session Structure
3 waves. HP3. Wave start: mana4, redirect2, split1. Projectile cap8, lifetime18s. Mana는 4초마다1 회복(최대4). Wave clear 시 Carry Select; 최대3개를 12s lifetime으로 다음 wave에 유지. Wave3 clear success, HP0 failure.

## 6. Game Rules
Single-screen rectangle. Projectile가 edge를 통과하면 opposite edge에서 same coordinate/direction으로 재진입하며 lifetime은 계속 감소. Wizard/enemies는 wrap하지 않는다. Projectile speed0.22 arena widths/s, damage1, enemy별 hit cooldown0.5s, player-safe.

Cast Bolt는 mana1 소비, cap8이면 reject/no cost. Redirect pulse가 player bolt를 맞히면 charge1 소비 후 impact normal 기준 clockwise90° 회전. Split은 cap<=7일 때 original을 유지하고 mirrored30° child 한 개 생성, charge1 소비. cap8이면 실패/no cost. Two normal bolts collide at angle<=45°면 damage2 empowered bolt 하나로 merge; lifetime=min(max(A,B)+4,18). Empowered는 재merge 불가.

Enemies: Chaser, Drifter, Anchor. Enemy-player contact는 HP-1 + 1.0s invulnerability. Projectiles는 적을 관통한다. Wave roster는 W1 6 Chasers, W2 4 Chasers+3 Drifters, W3 4 Chasers+2 Drifters+2 Anchors. Spawn list exhausted + enemies0이면 clear.

Pause는 모든 timer/motion/regen/spawn을 freeze. Retry는 Wave1 fresh reset.

## 7. State Model
Run Select→Wave Intro→Wave Active. Wave1/2 clear→Carry Select→next Wave Intro. Wave3 clear→Result. HP0→Result. Pause는 Wave Active exact resume/retry/exit.

## 8. Interaction Spec
Move=left-thumb drag. Aim/Cast=right-side drag/release. Bolt valid when mana>0, cooldown clear, cap<8. Redirect/Split는 해당 tool 선택 후 pulse drag/release; miss는 charge 소모 없음. Carry Select는 살아있는 projectile marker tap 최대3. Pause freezes exact state.

## 9. Content Model
Unit은 three-wave arena run. Arena variants: Open, Split Lane(2 pillars), Crossfield(4 pillars). Enemy classes: Chaser/Drifter/Anchor. Projectile classes: Bolt/Empowered. Transformations: Redirect90, Split30, Merge<=45°. Projectile-only toroidal wrap topology. Every wave must be clearable from empty field; carry is advantage, not requirement. Cap8/lifetime18s가 complexity bound.

## 10. Difficulty / Variation
W1 persistence/wrap 학습. W2 Drifter로 crossfire/Redirect 요구. W3 Anchor pressure로 pre-built lane과 Split/Merge 활용. Difficulty는 projectile speed 증가가 아니라 enemy movement와 carry planning으로 상승.

## 11. Progression
One standard run with three sequential arena variants. Best clear/score persist. Score=enemy100 + wave clear150 + final surviving carried projectile50. No stat upgrades.

## 12. Economy
Not required. Mana/Redirect/Split은 run-local tactical resources.

## 13. Screen Inventory
Title / Run Select; How to Play; Wave Arena; Carry Select; Pause Overlay; Run Result.

## 14. Screen Flow
Title→Run Select→Wave Intro→Wave Active→Carry Select→next Wave 또는 Result. HP0→Result. Pause overlays Active. Retry→Wave1 fresh.

## 15. Feedback System
Projectile는 age ring/trail/wrap entry marker로 lifetime과 방향을 보여준다. Cap8 indicator, distinct Redirect/Split/Merge effects, hit/invulnerability, Carry selection ghost/trajectory preview, result summary를 제공한다.

## 16. Visual Direction Brief
Fixed top-down single-screen. Dark quiet floor, high-contrast spell trails. Persistent projectiles remain individually readable through direction arrows, age marks and compact trails. Boundary wrap uses paired edge indicators. Enemy/wizard silhouettes dominate decoration. UI shows HP, mana/charges, cap and wave progress without covering trajectory space.

## 17. MVP Scope + NOT IN MVP
3-wave run, 3 enemy archetypes, 3 arena variants, wrap, lifetime18s, cap8, Bolt, Redirect90, Split30, Merge, mana regen, HP3, Carry Select3, pause/retry/result, best clear/score. NOT IN MVP: >8 projectiles, wall reflection, deckbuilding, elements, bosses, procedural generation, online, permanent upgrades/economy.

## 18. Test Scenarios
Validate wrap without lifetime reset, cap reject/no cost, exact Redirect90, Split30/cap handling, Merge angle/damage/lifetime, 0.5s repeated hit cooldown, HP/contact invulnerability, Carry3→12s reset, zero-carry solvability, exact pause/retry.

## 19. Known Risks
Cap8에도 trail density가 높으면 clutter. Wrap topology가 edge cue 없으면 예측 어려움. Merge tolerance가 넓으면 accidental. Carry Select가 trajectory preview 없으면 bookkeeping. Mana/cap feedback이 약하면 spam처럼 느껴질 수 있음.

## 20. Wireframe Handoff
fun_promise: 모든 주문은 충분히 오래 남아 이후 판단의 재료가 되어야 하며, 플레이어는 자신의 과거 행동으로 살아있는 주문장을 설계한다고 느껴야 한다.
All screens/states, wrap/lifetime/cap, mana, Redirect/Split/Merge, Carry3, enemy archetypes, invalid cases, edge pairing, age/readability, HP/invulnerability, score/wave progress를 표현한다. Pillars는 wizard/enemy만 막고 projectiles는 통과한다. Clear-all/undo는 추가하지 않는다; complexity는 cap8/lifetime18s/Carry Select로만 제한한다.
