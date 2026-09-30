# Interaction Wireframe Pack v0.3 — Echo Thief

## Overview
Portrait mobile stealth-puzzle wireframe for the full MVP. **Fun promise:** sound is tactical ammunition: capture it, drag it into the museum, and immediately see deterministic guard logic bend around that placement.

## Coverage
Five required screens: S1 Mission Select, S2 Mission Brief, S3 Museum Gameplay, S4 Pause Overlay, S5 Mission Result. Core play covers Planning/Infiltration, Observe/Record/Throw/Move/Steal/Escape, two-token inventory, sound propagation and priority, Patrol/Investigate/Return, detection/Caught, carried-target escape, pause/retry, linear unlock, and early/late mission variation.

## Interaction hierarchy
The museum world dominates S3. Tap acts in the world, holds perform authored timed interactions, and stored sounds are dragged directly from the two-slot rack onto valid floor tiles. Predictive throw/propagation feedback makes sound placement understandable before commitment. Token drag suppresses movement; active Record/Steal locks movement; Caught overrides active holds.

## Implementation boundary
This pack fixes UX behavior, logical hit regions, visible states and rule feedback only. Godot scene/node/script architecture remains the Implementation Blueprint's responsibility.
