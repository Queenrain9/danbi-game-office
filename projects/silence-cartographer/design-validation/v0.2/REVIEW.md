# Silence Cartographer — Independent Design Validation v0.2

Status: **PASS**  
Design source: `game-design-v0.2.md` + `expeditions-v0.2.json`  
Validation method: deterministic rule simulation  
Validation strength: **normal**

## Repair verification

The v0.1 blocking defect batch has been addressed.

- Six authored expedition fixtures now exist as Game Design content.
- Every fixture contains topology, resources, predator start/patrol, tie-break semantics and an authored success route.
- Predator behavior now explicitly includes `ReturnToPatrol`; Hunt does not teleport back to Patrol and no longer has an undefined post-Hunt movement phase.
- ROADMAP is present.

## Executed validation

`sim/sim.py` imports the frozen Game Design fixtures and executes the authored success route through the deterministic rule kernel.

All six routes complete without contact/Air failure.

The validation also verifies that M2's authored route uses Hide, M3 uses Clicker, and M6 uses both Hide and Clicker.

## Numerical re-critique

| Mission | Turns | Air left |
| --- | ---: | ---: |
| M1 Basic Echo Maze | 13 | 9 |
| M2 Alcove Crossing | 14 | 9 |
| M3 Remote Decoy | 14 | 10 |
| M4 Branching Hunt | 16 | 10 |
| M5 Return Pressure | 16 | 6 |
| M6 Combined Expedition | 15 | 11 |

M5 has the tightest validated Air margin, matching its Return Pressure purpose. These figures prove authored-content solvability under the frozen rules, not human difficulty.

## Blocking defects

None.

## Known risks retained

- an authored route using a mechanic does not prove that every successful route needs it,
- deterministic predator behavior may still become memorization,
- permanent reveal may make return travel cognitively easier than intended,
- hidden-predator directional cues remain a presentation/human-play question,
- Clicker dominance remains a balance question.

## Verdict

**DESIGN VALIDATION PASS**
