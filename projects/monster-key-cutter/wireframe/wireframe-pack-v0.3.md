# Interaction Wireframe Pack v0.3 — Monster Key Cutter

## Fun Promise
Inspect a strange mechanical lock, shape its matching key by hand, then feel the suspense of physically testing the result.

## Screen Inventory
- K1 Order Board — select an unlocked authored order.
- K2 Workbench — Inspect → Cut → Test → Diagnostic / Replace Confirm. This is the core direct-manipulation screen.
- K3 Result — success/failure, accuracy, score, retry/next/board.
- K4 Pause / Settings — freeze and resume the exact Workbench state.

## Core Interaction
Pin inspection → irreversible tooth cutting → insert-and-rotate physical test → blocked-pin diagnostic → rework or explicit spare-blank replacement.

## Core Rules Preserved
4 pins; tolerance ±0.08; depth 0..1 material removal only; 2 blanks; maximum 3 tests; 180 second timer; success requires all pin errors within tolerance and 75° rotation. Fine filing changes depth in 0.01 steps. Replacement costs the spare blank and 200 score; tests carry the authored 80-point penalty.

## Structural Integrity Repair
The stored pack now contains all 4 declared screens. core_screen=K2 Workbench exists in the actual screens array, all screen-flow references resolve, and the 9 declared UI states are represented across K1–K4.
