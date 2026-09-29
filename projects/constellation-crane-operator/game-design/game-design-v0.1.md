# Playable Game Design Spec v0.1 — Constellation Crane Operator

## 1. Product Definition
밤하늘 공사장에서 크레인 붐·와이어·별 조각의 흔들림을 직접 제어해 연결 노드에 별을 걸고 별자리를 완성하는 모바일 공간 조립 퍼즐. Portrait mobile physics/spatial assembly puzzle. Session 3–6 minutes. Non-goals: 3D free camera, Continuous z-depth physics, Procedural constellations, Crane upgrades, Currency/shop, Narrative dialogue, Online leaderboard, More than one crane.

## 2. Player Fantasy
플레이어는 밤하늘을 건설하는 크레인 기사다. 무거운 별을 훅에 걸어 진자 흔들림을 죽이고 정확한 깊이 레이어와 연결 노드에 안착시키며, 거대한 기계로 섬세한 별자리를 조립하는 숙련감을 느낀다.

## 3. Core Player Verbs
- **Rotate Boom** — input: horizontal drag on boom control; target: crane boom; condition: Rigging/Hoisting/Positioning; state change: boom_angle changes within mission limits; feedback: boom and projected hook arc update.
- **Adjust Cable** — input: vertical drag on cable control; target: winch; condition: Rigging/Hoisting/Positioning; state change: cable_length changes; feedback: hook height/depth projection updates.
- **Hook Star** — input: tap hook when overlap condition valid; target: unplaced star piece; condition: Rigging; hook not carrying; state change: star attaches to hook; state Hoisting; feedback: magnetic latch/haptic.
- **Damp Swing** — input: press-and-hold brake; target: carried star; condition: Hoisting/Positioning; state change: angular velocity multiplied by 0.55 per 0.5s tick; brake_heat +1 per tick; feedback: swing visibly settles; heat rises.
- **Place Star** — input: tap Lock; target: active constellation node; condition: Positioning and snap criteria valid; state change: star detached and node filled; next piece or result; feedback: constellation link lights.

## 4. Core Loop
다음 별 조각과 목표 node 확인 → boom/cable로 빈 별에 hook 접근 → Hook → 운반 중 회전·와이어 조절과 brake로 swing 제어 → 목표 node의 layer/거리/속도 조건에 맞춰 Lock → 별자리의 다음 node 반복 → 전 node 완성 또는 충돌/시간 초과.

## 5. Round / Session Structure
MVP는 10개 construction contract. 각 contract는 3~7 star pieces와 1~3 depth layers를 가진다. Contract 시작 시 90초, Integrity 3, Brake Heat 0. 모든 required nodes를 채우면 success. Timer 0 또는 Integrity 0이면 failure. 각 piece는 Rigging→Hoisting→Positioning→Locked를 거친다. Result에서 Retry/Next/Home. 평균 3–6분.

## 6. Game Rules
```json
{
  "coordinate": "Gameplay simulation uses 2D normalized crane workspace: x horizontal [-1,1], y vertical [0,1]. Depth is discrete layer integer 0=near,1=mid,2=far; not continuous z.",
  "boom": {
    "angle": "-65°..65° from vertical mast axis",
    "sampling": "control drag maps continuously; physics sampled fixed 60Hz",
    "hook_x": "derived by authored crane kinematic function from boom angle and cable; implementation may solve kinematics but node validity uses normalized hook/star center coordinates"
  },
  "cable": {
    "length": "normalized 0.15..0.85 of workspace height",
    "sampling": "continuous input, fixed 60Hz physics"
  },
  "star": {
    "radius": "piece-specific normalized radius 0.04..0.09 of workspace width",
    "swing_angle": "angle in degrees between cable vector and world-down axis",
    "angular_velocity": "degrees/sec sampled at 60Hz",
    "carried_center": "star center in normalized workspace"
  },
  "hook": {
    "valid": "hook center lies within star radius+0.025 normalized units AND relative hook-star speed<=0.35 normalized units/sec AND star is unplaced",
    "invalid": "otherwise tap has no state change"
  },
  "nodes": {
    "snap_radius": 0.07,
    "speed_limit": 0.18,
    "swing_limit_deg": 8,
    "layer_match": "carried star depth_layer equals node required_layer",
    "valid_lock": "center distance<=0.07 normalized units AND star center speed<=0.18 units/sec AND abs(swing_angle)<=8° AND layer match"
  },
  "depth": {
    "change": "Each star has fixed depth_layer authored per piece; crane depth selector tap cycles available layer only while hook empty. Hook can attach only stars in selected layer. Carrying star locks selector.",
    "result": "Node requires exact layer."
  },
  "brake": {
    "heat_max": 6,
    "tick_seconds": 0.5,
    "effect": "while held, every 0.5s angular velocity*=0.55 and heat+1",
    "cooling": "when not held heat-1 every 1.0s to min0",
    "overheat": "at heat6 brake disables until heat<=3; crane controls remain active"
  },
  "collision": {
    "hazards": "authored no-go circular zones with center/radius in normalized workspace; active only in contracts class Obstacle",
    "judgment": "carried star circle overlaps hazard circle when center distance < sum radii",
    "result": "Integrity-1, active star returns to its pickup spawn, hook becomes empty, brake heat resets0, timer continues; 1.0s grace disables further collision then Rigging",
    "terminal": "Integrity reaches0 -> failure"
  },
  "timer": {
    "start": "first gameplay input after contract load",
    "duration_seconds": 90,
    "continues": "Rigging/Hoisting/Positioning and collision grace",
    "pause": "stops in Pause and Result only"
  },
  "success": "all required nodes filled before timer0 and Integrity>0",
  "failure": "timer reaches0 or Integrity reaches0",
  "score": "success: remaining_seconds*10 + Integrity*250 + max(0,600-total_brake_ticks*10). failure=0.",
  "reset": "Retry resets timer90, Integrity3, all stars to spawn/unplaced, nodes empty, selected depth0, heat0, hook empty."
}
```

## 7. State Model
- **Contract Select** — enter: Home/Result Next; allowed: select unlocked contract, Home; variables: ; exit: select; failure/cancel: none; next: Contract Brief.
- **Contract Brief** — enter: contract select; allowed: Start, Back; variables: ; exit: Start/Back; failure/cancel: none; next: Rigging/Contract Select.
- **Rigging** — enter: Start, piece locked, or collision recovery complete; allowed: Rotate Boom, Adjust Cable, Depth Select, Hook Star, Pause; variables: timer, integrity, hook, selected layer; exit: valid Hook; failure/cancel: timer0; next: Hoisting/Result.
- **Hoisting** — enter: star hooked; allowed: Rotate Boom, Adjust Cable, Damp Swing, Pause; variables: carried pose/velocity/heat; exit: carried star enters target node snap radius; failure/cancel: collision/timer; next: Positioning/Rigging/Result.
- **Positioning** — enter: center distance<=0.07 from target node; allowed: Rotate Boom, Adjust Cable, Damp Swing, Lock, Pause; variables: distance, speed, swing, layer, heat; exit: leave radius or valid Lock; failure/cancel: collision/timer; next: Hoisting/Rigging/Result.
- **Collision Grace** — enter: nonterminal collision; allowed: Pause; variables: grace_remaining=1.0s, timer; exit: 1s elapsed; failure/cancel: timer0 or integrity0; next: Rigging/Result.
- **Result** — enter: all nodes filled/timer0/integrity0; allowed: Retry, Next if success, Home; variables: ; exit: choice; failure/cancel: none; next: Rigging/Contract Select/Home.

## 8. Interaction Spec
```json
{
  "boom": "Horizontal drag owns pointer; angle clamps -65..65. Release keeps angle.",
  "cable": "Vertical drag owns pointer; length clamps 0.15..0.85. Release keeps length.",
  "depth": "Tap cycles 0..contract max layer only with empty hook; carrying disables.",
  "hook": "Atomic tap; valid overlap+relative speed+layer required. Invalid tap changes nothing.",
  "brake": "Hold; ticks every 0.5s. At heat6 further ticks do nothing until passive cooling reaches3. Releasing begins cooling.",
  "lock": "Atomic tap in Positioning. Valid iff distance/speed/swing/layer all pass; invalid Lock changes nothing and shows failed criteria.",
  "priority": "Only one crane manipulation pointer at once; Lock/Hook ignored during active drag. Pause overrides. Collision resolution overrides all gameplay input."
}
```

## 9. Content Model
```json
{
  "unit": "constellation construction contract",
  "classes": [
    {
      "type": "Open-Sky Assembly",
      "rules": "No hazards, one depth layer; teaches hook/swing/snap."
    },
    {
      "type": "Layered Assembly",
      "rules": "2–3 depth layers; empty-hook depth selection and exact node layer matching."
    },
    {
      "type": "Obstacle Rig",
      "rules": "No-go circular hazards; collision causes Integrity loss and star reset with 1s grace."
    },
    {
      "type": "Heat Management",
      "rules": "Long carries/node precision require brake use under heat6 lockout/cool-to3 rule."
    },
    {
      "type": "Sequenced Structure",
      "rules": "Nodes have authored prerequisite graph; only nodes whose prerequisites are filled become active targets. Lock on inactive node is invalid."
    }
  ],
  "topology": "Constellation is a directed acyclic prerequisite graph of 3–7 nodes. A star piece maps one-to-one to a node and fixed depth layer. Hazards are circles in normalized workspace; screen placement is Wireframe/art responsibility.",
  "variation_axes": [
    "node count",
    "prerequisite graph",
    "depth layers",
    "star radius",
    "spawn positions",
    "node positions",
    "hazard circles",
    "required precision pressure"
  ],
  "mvp_count": "10 contracts covering all five classes; contracts may combine classes after introduction."
}
```

## 10. Difficulty / Variation
1–2 Open-Sky, 3–4 add brake heat and smaller stars, 5–6 add depth layers, 7–8 add obstacle rigs, 9–10 combine prerequisite sequences+3 layers+hazards+heat. Difficulty grows through topology, depth and control-resource combinations rather than faster base physics.

## 11. Progression
10 contracts unlock linearly on success. Each stores best score and 1–3 stars: 1=success, 2=score>=900, 3=score>=1250. Ratings do not alter crane physics.

## 12. Economy
Not required. Integrity and Brake Heat are contract-local resources.

## 13. Screen Inventory
- Skyyard Home / Contract Select
- Contract Brief
- Crane Gameplay
- Contract Result

## 14. Screen Flow
Home/Select→Brief→Gameplay Rigging→Hoisting↔Positioning→Locked next piece/Rigging; collision→Collision Grace→Rigging; all nodes→success Result; timer0/integrity0→failure Result. Success Next unlocks next Brief. Pause resumes exact state/timer.

## 15. Feedback System
```json
{
  "hook": "valid proximity/speed/layer cue + latch",
  "swing": "cable/star motion plus swing threshold cue",
  "brake": "heat ticks/overheat/cooling",
  "position": "node indicates distance/speed/swing/layer criteria independently",
  "lock": "link lights and piece becomes fixed",
  "collision": "impact+Integrity loss+star reset+1s grace",
  "timer": "last 15s urgency",
  "progression": "rating/unlock"
}
```

## 16. Visual Direction Brief
Portrait mobile, fixed side-view sky construction stage with discrete depth layers visually separable but not perspective-measured. Crane, cable, carried star, target node and hazards dominate. Glowing constellation lines communicate completed prerequisite structure. Motion must remain readable against restrained night sky. UI coordinates remain Wireframe responsibility.

## 17. MVP Scope
10 authored contracts covering Open-Sky, Layered, Obstacle, Heat Management, Sequenced Structure; 3–7 pieces/contract; up to 3 depth layers; normalized 2D physics at 60Hz; boom/cable controls, Hook, brake heat, Positioning criteria, Lock, circular hazards, Integrity3, timer90s, prerequisite graph, score/rating, linear unlock, pause/retry.
NOT IN MVP: 3D free camera, Continuous z-depth physics, Procedural constellations, Crane upgrades, Currency/shop, Narrative dialogue, Online leaderboard, More than one crane.

## 18. Test Scenarios
- Hook succeeds only within radius+0.025, relative speed<=0.35 and matching selected layer.
- Valid Lock requires distance<=0.07, speed<=0.18, swing<=8°, exact layer; each invalid criterion leaves state unchanged.
- Brake at 0 reaches heat6 after six 0.5s ticks, disables, then re-enables only after cooling to3.
- Hazard overlap deducts exactly 1 Integrity, resets active star/hook, keeps timer running and enters 1s grace.
- Three collisions reach Integrity0 failure; timer0 independently reaches failure.
- Filling all required nodes reaches success and prerequisite-inactive nodes reject Lock.
- Pause freezes timer and physics; Retry fully resets contract.
- All five content classes and combined late contracts require no new interaction rules.

## 19. Known Risks
- Physics can feel imprecise if visual motion diverges from numeric snap criteria
- Two-axis crane control plus brake may overload one-handed mobile play
- Discrete depth must be visually obvious without looking like a separate puzzle mode
- Obstacle collision may feel punitive during high swing
- Late combined contracts risk clutter around target/hazard/prerequisite feedback

## 20. Wireframe Handoff
- Represent all 4 screen types and Rigging/Hoisting/Positioning/Collision Grace/Pause/Result states.
- Represent Open-Sky, Layered, Obstacle, Heat, Sequenced content variations and late combined contracts.
- Show boom angle, cable length, selected depth, hook validity, carried swing/speed and brake heat states without inventing thresholds.
- Show Positioning criteria separately: distance<=0.07, speed<=0.18, swing<=8°, exact layer; invalid Lock feedback.
- Show circular hazard collision→Integrity-1→star reset→1s grace and Integrity0 terminal failure.
- Show prerequisite node inactive/active/filled states and one-to-one piece mapping.
- Show 90s timer, success/failure Result, 1–3 rating, unlock Next, Retry full reset.
