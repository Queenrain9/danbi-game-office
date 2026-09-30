# Build Farm B6 Static Verification

Game: Parcel X-Ray Night Shift
Wireframe: v0.2

## Gates
- B0: project.godot, main.tscn, complete Game Design and Wireframe snapshots present.
- B1: AppRoot/ShiftController/CaseRouter/HUDLayer/OverlayLayer hierarchy present; ShiftState, CaseData, HazardEvaluator, GestureRouter responsibilities split from presentation.
- B2: 4/4 core interactions exact in static implementation.
  - Rotate: touch/mouse drag on parcel changes actual parcel rotation/scale/inner offset; drag threshold and input lock apply; tap suppressed after drag.
  - Slice Scan: touch/mouse gesture starts on right rail; VSlider maps 0..100 to slice depth; scan plane and visible internal shapes update; classification disables scan.
  - Evidence Pin: tap hit-tests currently visible internal objects after scan activation; max 4; empty tap/pin limit return immediate feedback; pins are coordinate/object-bound and toggleable.
  - Classify: parcel drag enters classification mode, actual parcel follows pointer, lane global rect hit-test determines valid release, valid release tween-snaps and locks input, invalid release tween-returns to table.
- B3: Hub, Intake, Inspection, Classification Result, Shift Summary, Rule Manual overlay, Pause overlay are navigable. Rule Manual/Pause block background without destroying inspection state. Pause quit has confirmation.
- B4: 10 fixed ParcelCase records, 8 randomly selected per Shift, 6 primitive kinds (metal, foam, cell, cable, tool, decoy), 3 hazard outcomes/rules represented by HazardEvaluator.
- B5: Hub -> Intake -> Inspect -> Result -> next case x8 -> Summary -> Hub. begin_shift resets shift state; reset_case_state clears transient case state.
- B6: static path/reference/coverage review completed.

## Acceptance Criteria
1. Seven inventory screens/overlays navigable: PASS.
2. Rotate/scan/pin/classify coexist with explicit priority/preconditions: PASS (static).
3. Invalid lane release returns parcel to table: PASS, tween return in _finish_classification.
4. Rule Manual blocks background input: PASS, full-rect MOUSE_FILTER_STOP overlay.
5. Valid lane release locks gameplay until result: PASS, input_locked before snap/evaluate.
6. Eight processed cases reach Summary: PASS, ShiftState.SHIFT_SIZE=8 and advance guard.

Interaction coverage: 4/4 exact, 0/4 partial, 0/4 missing.

Runtime QA pending: no Godot runtime runner is available in this Build Farm execution, so device/runtime behavior is not claimed as tested.
