# Playable Game Design Spec v0.1 — Crowd Wave

## 1. Product Definition
콘서트 관객 한 명의 박수·점프·라이트를 비트에 맞춰 인접 군중으로 전파하고, 갈림길에서 전파 방향을 선택해 여러 파동을 합류시키는 공간 리듬 체인 게임. Landscape mobile, 3–4분 performance. 정확도 리듬게임보다 파동 경로 선택과 합류가 핵심이다.

## 2. Player Fantasy
거대한 공연장의 한 관객으로 시작해 정확한 한 번의 몸짓이 주변 사람을 깨우고 수백 명의 파동으로 번지는 순간을 지휘한다. 핵심은 정확도 점수 자체가 아니라 언제 어느 이웃에게 파동을 넘겨 더 큰 합류를 만들지 판단하는 것이다.

## 3. Core Player Verbs
- **Pulse** — beat window에서 박수/점프/라이트 버튼 tap → 현재 player node; Play state; requested action matches cue; 정확도 판정 후 성공이면 wave token 생성; 개인 동작과 첫 ring.
- **Route** — 활성 wave가 junction node에 도달했을 때 left/right/straight 방향 swipe → junction outgoing edge; route window open; wave next_edge 확정; 선택 edge가 점등.
- **Merge** — 자동 → 같은 merge node에 merge window 안에 도착한 wave tokens; 2개 이상; tokens 1개 amplified wave로 합쳐지고 chain_power 증가; 큰 crowd crest.
- **Recover** — 다음 cue 입력 → player node; miss/expired wave 이후; 새 wave 시작 가능; 끊긴 이전 chain은 복구되지 않음; 새 작은 pulse.

## 4. Core Loop
곡 구간의 action cue를 읽고 비트에 맞춰 Pulse → wave가 crowd graph를 따라 자동 전파 → junction에서 짧은 Route 선택 → 다른 wave와 시간 맞춰 Merge → 합류 규모가 무대 반응을 키움 → section 종료 시 coverage/merge 목표 판정 → 다음 section 또는 result.

## 5. Round / Session Structure
한 performance는 3 sections, section당 35–55초, 총 3–4분. 각 section은 8–14 Pulse cues와 1–3 junction decisions. Start count-in 2 beats. Section 종료 후 2초 summary. 3 sections 완료 후 performance success/failure. Pause는 음악/beat clock/waves/route windows를 모두 정지하고 resume 시 2-beat count-in 뒤 동일 beat offset에서 재개.

## 6. Game Rules
Beat clock은 authored BPM 90–150의 audio transport 기준이다. cue와 입력 오차 |Δt|≤80ms=Perfect(power2), ≤160ms=Good(power1), 그 밖/무입력/잘못된 action=Miss(no wave). Crowd는 directed graph이며 normal node outgoing1, junction2–3, merge1, stage0. Edge travel은 integer 1–4 beats. 성공 Pulse는 player node에 wave를 만들고 edge travel 뒤 node를 activate한다. Junction route window는 arrival±0.5 beat; swipe가 없으면 authored default edge를 택하고 power를 1 감소(min0), power0은 현재 node만 activate 후 expire한다. 같은 merge node에 0.5 beat 이내 도착한 2+ token은 power=sum(power)+token_count-1로 합쳐진다. Section coverage=unique activated audience/total audience, merge_count를 목표와 비교한다. 3 sections 중 2개 이상 pass면 performance success. Stars: success=1, 3 sections pass=2, 전부 pass+Perfect ratio≥70%=3. Pause는 transport/wave/window를 정지; resume은 2-beat count-in 뒤 동일 offset. Retry는 performance 전체를 reset한다.

## 7. State Model
Select→Brief→Count-In→Play→Section Summary→다음 Count-In 또는 Result. Pause는 Count-In/Play에서 진입하며 Resume/Retry/Select. Result는 Next(success)/Retry/Select.

## 8. Interaction Spec
Pulse는 clap/jump/light tap이며 ±160ms 내 가장 가까운 미판정 cue 하나를 소비한다. Route는 junction window의 left/right/straight semantic edge로 0.08 normalized dimension 이상 swipe; 첫 valid swipe가 lock된다. Route pointer는 그 pointer의 Pulse만 억제하고 다른 finger tap은 허용한다. window 밖 route/이미 lock된 route/무cue tap은 state change 없음.

## 9. Content Model
MVP 6 performances×3 sections. Classes: Single Front, Cross Merge, Action Split, Default Trap, Festival Network. Section schema={directed graph, cues(action,beat), junction semantic edges/default, edge travel_beats, goals, end_beat}. 모든 class는 정의된 state graph를 재사용하며 final two는 prior rules의 조합이다. 모든 section은 Good 이상 reference sequence로 solvable해야 한다.

## 10. Difficulty / Variation
초반은 1 wave와 명확한 junction. 중반은 travel_beats가 다른 두 branch의 merge timing과 action type 구분. 후반은 default route가 손해를 만들고 3 wave lane을 동시에 관리한다. BPM만 올려 난도를 만들지 않으며 graph choice, travel-time synchronization, concurrent route windows를 조합한다.

## 11. Progression
6 performances linear unlock; performance success unlocks next. Best stars and per-section best coverage stored. No stat upgrades.

## 12. Economy
Not required.

## 13. Screen Inventory
Performance Select; Performance Brief; Concert Gameplay; Performance Result.

## 14. Screen Flow
Entry→Select→Brief→Count-In→Play→Section Summary→Count-In(next section) 반복→Result. 2/3 section pass면 success와 next unlock, 아니면 failure. Pause→resume 2-beat count-in/Retry/Select.

## 15. Feedback System
Pulse는 Perfect/Good/Miss와 개인 동작, wave는 연속 ripple, route는 선택 방향/lock, merge는 큰 crest와 stage reaction, summary는 coverage/merge 목표를 보여준다. Power0 wave는 junction에서 명확히 소멸한다.

## 16. Visual Direction Brief
Landscape mobile concert crowd viewed as readable layered audience field. Individual figures can reuse animation, but active wave front, junctions, merge convergence and stage reaction must be legible over spectacle. UI should not become a conventional note highway; beat cues support the spatial crowd graph. Exact positions/layout remain Wireframe responsibility.

## 17. MVP Scope + NOT IN MVP
6 performances × 3 sections, 5 content classes, clap/jump/light cues, Perfect/Good/Miss windows, directed crowd graph, integer beat travel, junction routing, default-route penalty, merge timing, coverage/merge goals, 2-of-3 success, stars, unlock, pause/retry.
NOT IN MVP: free song import, procedural graphs, character collection, currency/shop, online multiplayer, leaderboards, motion controls, free crowd movement, more than 6 MVP performances.

## 18. Test Scenarios
- 100 BPM cue at beat10 tapped +60ms with correct action = Perfect power2 wave.
- Correct cue at +120ms = Good power1; +190ms or wrong action = Miss and no wave.
- Wave on 2-beat edge departing beat10 arrives beat12 and activates destination.
- Junction arrival beat12 accepts route from 11.5–12.5; no route uses default and reduces power by1.
- Two power2 waves arriving merge node at beats20.0 and20.4 merge to power5; arrival20.6 does not merge with 20.0.
- Power1 wave missing route becomes power0, activates junction, then expires without leaving.
- Section coverage0.62/min0.60 and merges1/min1 passes; coverage0.59 fails.
- Sections pass,fail,pass yields performance success 1 star unless higher rating condition met.
- Pause freezes transport/waves and resume count-in does not advance authored beat.

## 19. Known Risks
- Spectacle can obscure route readability
- Concurrent route and rhythm input can overload touch interaction
- Graph authored poorly may make route choice feel cosmetic
- Default-route penalty may feel arbitrary without clear preview
- Repeated audience animations may visually flatten wave scale

## 20. Wireframe Handoff
- fun_promise: 한 번의 리듬 입력이 군중 전체로 커지는 시각적 보상과, 그 파동을 어디로 보낼지 고르는 공간 판단이 동시에 중심이어야 한다.
- Represent Select/Brief/Gameplay/Result plus Count-In, Section Summary, Pause.
- Represent Single Front, Cross Merge, Action Split, Default Trap, Festival Network variations.
- Show clap/jump/light cue timing, wave travel in beat units, junction route window/default penalty, merge window and power result.
- Show active/expired wave, unique-node coverage, merge count, section goals, 2-of-3 performance result and stars.
- Preserve pause/resume 2-beat count-in and retry reset semantics; layout may change but graph/timing rules may not.
