extends Control
var drag_start=Vector2.ZERO; var dragging=false; var long_press_start=0; var pinch_start=0.0
func g(): return get_parent()
func on_night_desk_01_item(): g().start_shift()
func on_case_intake_01_inspection(): g().inspect()
func on_decision_confirm_01_item(): pass
func on_outcome_01_item(): g().next_case()
func on_shift_summary_01_night_desk(): g().finish()
func on_inspection_desk_01_item(delta=Vector2.ZERO): var o=g().get_node("Screens/inspection_desk/object"); o.rotation=clampf(o.rotation+delta.x*.003,-1.2,1.2)
func on_inspection_desk_02_item(factor=1.0): var o=g().get_node("Screens/inspection_desk/object"); o.scale=Vector2.ONE*clampf(o.scale.x*factor,.7,1.8)
func on_inspection_desk_03_item(pos=Vector2.ZERO): var o=g().get_node("Screens/inspection_desk/object"); if o.get_global_rect().grow(-40).has_point(pos) and not g().clues.has("physical"): g().clues.append("physical")
func on_visitor_interview_01_item(): if g().question_budget>0: g().question_budget-=1; if not g().clues.has("statement"): g().clues.append("statement")
func on_evidence_review_01_item(): return "long-press drag"
func on_evidence_review_02_item(): return "match" if g().clues.size()>=2 else "none"
func on_decision_confirm_02_item(progress=1.0): if progress>=.85:g().confirm()
func apply_inp_1(): return "drag rotate"
func apply_inp_2(): return "pinch zoom"
func apply_inp_3(): return "hotspot tap"
func apply_inp_4(): return "long-press drag evidence"
func apply_inp_5(): return "horizontal confirm swipe"
func apply_int_case_intake_1(): g().inspect()
func apply_int_decision_confirm_1(): return g().decision
func apply_int_decision_confirm_2(): g().confirm()
func apply_int_evidence_review_1(): return on_evidence_review_01_item()
func apply_int_evidence_review_2(): return on_evidence_review_02_item()
func apply_int_inspection_desk_1(): return "rotate"
func apply_int_inspection_desk_2(): return "pinch"
func apply_int_inspection_desk_3(): return "hotspot"
func apply_int_night_desk_1(): g().start_shift()
func apply_int_outcome_1(): g().next_case()
func apply_int_shift_summary_1(): g().finish()
func apply_int_visitor_interview_1(): on_visitor_interview_01_item()
func _unhandled_input(e):
 if g().screen=="inspection_desk":
  if e is InputEventScreenTouch:
   dragging=e.pressed; drag_start=e.position
   if not e.pressed and e.position.distance_to(drag_start)<14:on_inspection_desk_03_item(e.position)
  elif e is InputEventScreenDrag and dragging:on_inspection_desk_01_item(e.relative)
  elif e is InputEventMagnifyGesture:on_inspection_desk_02_item(e.factor)
 elif g().screen=="decision_confirm" and e is InputEventScreenDrag:
  var rail=g().get_node("Screens/decision_confirm/confirm_rail").get_global_rect()
  if rail.has_point(e.position):on_decision_confirm_02_item((e.position.x-rail.position.x)/rail.size.x)
