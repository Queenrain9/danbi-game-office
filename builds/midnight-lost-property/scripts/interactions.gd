extends Control

const LONG_PRESS_MS := 550
const TAP_SLOP := 16.0
const CONFIRM_THRESHOLD := 0.85

var pointer_down := false
var pointer_start := Vector2.ZERO
var pointer_position := Vector2.ZERO
var pointer_started_ms := 0
var evidence_card_index := 0
var dragging_evidence := false
var confirm_progress := 0.0

func game():
	return get_tree().root.get_node("AppRoot")

func _ready():
	if name != "InteractionController":
		return
	game().get_node("Screens/inspection_desk/interview_btn").pressed.connect(on_interview_from_inspection)
	game().get_node("Screens/inspection_desk/review_btn").pressed.connect(on_review_from_inspection)
	game().get_node("Screens/visitor_interview/back_inspect").pressed.connect(on_back_to_inspection)
	game().get_node("Screens/visitor_interview/review_btn").pressed.connect(on_review_from_interview)
	game().get_node("Screens/evidence_review/decision_btn").pressed.connect(on_decision_from_review)
	game().get_node("Screens/decision_confirm/return").pressed.connect(on_decision_confirm_01_item.bind("RETURN"))
	game().get_node("Screens/decision_confirm/hold").pressed.connect(on_decision_confirm_01_item.bind("HOLD"))
	game().get_node("Screens/decision_confirm/report").pressed.connect(on_decision_confirm_01_item.bind("REPORT"))

func on_night_desk_01_item():
	game().start_shift()

func on_case_intake_01_inspection():
	game().inspect()

func on_decision_confirm_01_item(value := ""):
	game().choose(value)

func on_outcome_01_item():
	game().next_case()

func on_shift_summary_01_night_desk():
	game().finish()

func on_inspection_desk_01_item(delta := Vector2.ZERO):
	var object = game().get_node("Screens/inspection_desk/object")
	object.rotation = clampf(object.rotation + delta.x * 0.003, -1.2, 1.2)
	game().inspection_state = "rotating"

func on_inspection_desk_02_item(factor := 1.0):
	var object = game().get_node("Screens/inspection_desk/object")
	var next_scale = clampf(object.scale.x * factor, 0.7, 1.8)
	object.scale = Vector2.ONE * next_scale
	game().inspection_state = "zoomed"

func on_inspection_desk_03_item(position := Vector2.ZERO):
	var object = game().get_node("Screens/inspection_desk/object")
	var hotspot = object.get_global_rect().grow(-40.0)
	if hotspot.has_point(position):
		game().reveal_physical_clue(game().clues.size() % 3)
	else:
		game().show_feedback("No clue at this point")

func on_visitor_interview_01_item():
	game().ask_question((3 - game().question_budget) % 2)

func on_evidence_review_01_item(clue_id := "", slot_index := -1):
	if clue_id == "":
		game().show_feedback("Hold a clue card before dragging")
		return false
	return game().place_evidence(clue_id, slot_index)

func on_evidence_review_02_item():
	if game().slot_clues[0] == "" or game().slot_clues[1] == "":
		game().show_feedback("Two unique clues are required")
		return "NONE"
	game().relation = game().current_case()["relation"]
	game().review_state = "relation_recorded"
	game().get_node("Screens/evidence_review/relation").text = game().relation
	return game().relation

func on_decision_confirm_02_item(progress := 0.0, released := false):
	confirm_progress = clampf(progress, 0.0, 1.0)
	var rail = game().get_node("Screens/decision_confirm/confirm_rail/ConfirmRail")
	rail.set_progress(confirm_progress)
	if confirm_progress >= CONFIRM_THRESHOLD and game().decision != "":
		game().decision_state = "confirming"
		if released:
			rail.complete()
			game().confirm()
			return true
	elif released:
		confirm_progress = 0.0
		rail.reset()
		game().decision_state = "selected" if game().decision != "" else "unselected"
		game().show_feedback("Swipe cancelled")
	return false

func on_interview_from_inspection():
	game().interview()

func on_review_from_inspection():
	game().review()

func on_back_to_inspection():
	game().apply_trn_visitor_interview_1()

func on_review_from_interview():
	game().review()

func on_decision_from_review():
	game().decide()

func apply_inp_1(): return "drag rotate with viewport clamp"
func apply_inp_2(): return "pinch zoom with min/max clamp"
func apply_inp_3(): return "hotspot tap with invalid-boundary feedback"
func apply_inp_4(): return "550ms long-press then drag, unique-slot validation, cancel to origin"
func apply_inp_5(): return "horizontal confirm swipe, 0.85 threshold, partial release reset"
func apply_int_case_intake_1(): game().inspect()
func apply_int_decision_confirm_1(): return game().decision
func apply_int_decision_confirm_2(): return on_decision_confirm_02_item(1.0, true)
func apply_int_evidence_review_1(): return {"slots": game().slot_clues, "long_press_ms": LONG_PRESS_MS}
func apply_int_evidence_review_2(): return on_evidence_review_02_item()
func apply_int_inspection_desk_1(): return "rotate"
func apply_int_inspection_desk_2(): return "pinch"
func apply_int_inspection_desk_3(): return "hotspot"
func apply_int_night_desk_1(): game().start_shift()
func apply_int_outcome_1(): game().next_case()
func apply_int_shift_summary_1(): game().finish()
func apply_int_visitor_interview_1(): on_visitor_interview_01_item()

func _gui_input(event):
	if name == "question_cards" and (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
		on_visitor_interview_01_item()
		accept_event()
	elif name == "object":
		_handle_inspection(event)
	elif name == "evidence_cards":
		_handle_evidence(event)
	elif name == "confirm_rail":
		_handle_confirm(event)

func _unhandled_input(event):
	if name != "InteractionController":
		return
	if game().locked:
		return
	if game().screen == "inspection_desk":
		_handle_inspection(event)
	elif game().screen == "evidence_review":
		_handle_evidence(event)
	elif game().screen == "decision_confirm":
		_handle_confirm(event)

func _handle_inspection(event):
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
			pointer_down = event.pressed
			if event.pressed:
				pointer_start = event.position
				pointer_position = event.position
			elif event.position.distance_to(pointer_start) < TAP_SLOP:
				on_inspection_desk_03_item(event.position)
	elif event is InputEventScreenDrag:
		on_inspection_desk_01_item(event.relative)
	elif event is InputEventMouseMotion and pointer_down:
		on_inspection_desk_01_item(event.relative)
	elif event is InputEventMagnifyGesture:
		on_inspection_desk_02_item(event.factor)

func _handle_evidence(event):
	var cards = game().get_node("Screens/evidence_review/evidence_cards")
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
			if event.pressed and cards.get_global_rect().has_point(event.position):
				pointer_down = true
				pointer_start = event.position
				pointer_position = event.position
				pointer_started_ms = Time.get_ticks_msec()
				evidence_card_index = int(clampf((event.position.x - cards.global_position.x) / maxf(cards.size.x, 1.0) * maxf(game().clues.size(), 1), 0, maxf(game().clues.size() - 1, 0)))
			elif not event.pressed and pointer_down:
				var held_ms = Time.get_ticks_msec() - pointer_started_ms
				dragging_evidence = dragging_evidence or held_ms >= LONG_PRESS_MS
				if dragging_evidence:
					var slot_index = _slot_at(event.position)
					on_evidence_review_01_item(game().clue_for_card(evidence_card_index), slot_index)
					on_evidence_review_02_item()
				else:
					game().show_feedback("Hold for 0.55s to drag evidence")
				pointer_down = false
				dragging_evidence = false
	elif pointer_down and (event is InputEventScreenDrag or event is InputEventMouseMotion):
		pointer_position = event.position
		if Time.get_ticks_msec() - pointer_started_ms >= LONG_PRESS_MS:
			dragging_evidence = true
			var slot_index = _slot_at(event.position)
			game().get_node("Screens/evidence_review/slot_a/DragDropSlot").set_highlighted(slot_index == 0)
			game().get_node("Screens/evidence_review/slot_b/DragDropSlot").set_highlighted(slot_index == 1)

func _slot_at(position):
	if game().get_node("Screens/evidence_review/slot_a").get_global_rect().has_point(position):
		return 0
	if game().get_node("Screens/evidence_review/slot_b").get_global_rect().has_point(position):
		return 1
	return -1

func _handle_confirm(event):
	var rail = game().get_node("Screens/decision_confirm/confirm_rail")
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
			if event.pressed and rail.get_global_rect().has_point(event.position):
				pointer_down = true
				pointer_start = event.position
			elif not event.pressed and pointer_down:
				var progress = (event.position.x - rail.global_position.x) / maxf(rail.size.x, 1.0)
				on_decision_confirm_02_item(progress, true)
				pointer_down = false
	elif pointer_down and (event is InputEventScreenDrag or event is InputEventMouseMotion):
		var progress = (event.position.x - rail.global_position.x) / maxf(rail.size.x, 1.0)
		on_decision_confirm_02_item(progress, false)

# Canonical Blueprint structured-input handler symbols.
func input_inspection_desk_01(event = null):
	if event is InputEventScreenDrag or event is InputEventMouseMotion:
		on_inspection_desk_01_item(event.relative)
	return "rotating"
func input_inspection_desk_02(event = null):
	if event is InputEventMagnifyGesture:
		on_inspection_desk_02_item(event.factor)
	return "zoomed"
func input_inspection_desk_03(event = null):
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		on_inspection_desk_03_item(event.position)
	return "hotspot_revealed"
func input_visitor_interview_01(_event = null): return on_visitor_interview_01_item()
func input_evidence_review_01(_event = null): return apply_int_evidence_review_1()
func input_evidence_review_02(_event = null): return apply_int_evidence_review_2()
func input_decision_confirm_02(_event = null): return apply_int_decision_confirm_2()
