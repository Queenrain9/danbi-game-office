# Interaction Wireframe Pack v0.2 — Candle Creature Keeper
Portrait mobile greybox translating the approved heat→shape→cool→fit loop without changing rules.

## Flow
Case Select → Creature Care (Brief/Care/Overheat/Fit/Correction) → Creature Result → next creature; after three resolved creatures → Case Result. Pause is an overlay that freezes all simulation.

## Core Screen
Creature Care reserves the left/center workbench for five independently hittable body regions, the upper-right for the habitat target, a thin status HUD, and a bottom tool dock. Heat, shape, cool and place are direct-manipulation gestures. Shape has input priority over tools, tools over placement. Multitouch is disabled.

## State presentation
Heat 50–89 is visibly soft/glossy and shapeable; 80+ adds warning feedback; 90+ for one second triggers overheat. Below 25 is matte/locked. Failed fit highlights exact mismatching required regions and exposes the 20-second correction timer.

## Developer handoff
Gameplay state owns region heat/form/lock, integrity, tests and timers. UI sends commands and renders state. Passive cooling is -5/sec; plate cooling -25/sec; heat is +20/sec near or +10/sec mid, with Case 3 adjacent-region 25% transfer. Pause freezes all timers.

## Acceptance
Greybox passes when all approved screens, gestures, thresholds, invalid-input returns, fit correction, terminal failure paths and retry/pause behavior can be observed without reopening the Game Design document.
