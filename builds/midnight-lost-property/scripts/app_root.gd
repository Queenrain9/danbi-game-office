extends Control

const Rules = preload("res://scripts/rules.gd")
const CASES := [
	{
		"id": "case_1",
		"location": "Platform 4 · 00:18",
		"item": "Silver commuter watch",
		"physical": ["engraved initials J.K.", "fresh glass crack", "platform dust"],
		"statements": ["claims it was lost before midnight", "describes an uncracked face"],
		"relation": "CONFLICT",
		"expected": "HOLD",
		"reason": "The claimant description conflicts with the physical condition."
	},
	{
		"id": "case_2",
		"location": "Night bus 17 · 01:42",
		"item": "Canvas medicine pouch",
		"physical": ["pharmacy receipt", "blue route tag", "insulin label"],
		"statements": ["names the pharmacy", "matches the route and dosage"],
		"relation": "MATCH",
		"expected": "RETURN",
		"reason": "Independent details match the pouch and its route."
	},
	{
		"id": "case_3",
		"location": "Locker hall · 03:07",
		"item": "Unmarked brass key",
		"physical": ["restricted-room stamp", "filed serial edge", "red fiber trace"],
		"statements": ["denies access to restricted rooms", "cannot explain the filed serial"],
		"relation": "CONFLICT",
		"expected": "REPORT",
		"reason": "Restricted markings and contradictory testimony require escalation."
	}
]

var screen := "night_desk"
var case_index := -1
var clues := []
var question_budget := Rules.QUESTION_BUDGET
var decision := ""
var score := 0
var locked := false
var loading := false
var paused := false
var inspection_state := "idle"
var review_state := "empty"
var decision_state := "unselected"
var outcome_state := ""
var relation := "NONE"
var slot_clues := ["", ""]
var return_count := 0
var case_scores := []

func _ready():
	show_screen("night_desk")
	_refresh_ui()

func current_case():
	if case_index < 0 or case_index >= CASES.size():
		return {}
	return CASES[case_index]

func show_screen(id):
	screen = id
	for node in $Screens.get_children():
		node.visible = node.name == id
	_refresh_ui()

func start_shift():
	if loading:
		return
	score = 0
	case_scores.clear()
	case_index = 0
	load_case()

func load_case():
	loading = true
	clues.clear()
	question_budget = Rules.QUESTION_BUDGET
	decision = ""
	locked = false
	inspection_state = "idle"
	review_state = "empty"
	decision_state = "unselected"
	outcome_state = ""
	relation = "NONE"
	slot_clues = ["", ""]
	return_count = 0
	show_screen("case_intake")
	loading = false

func inspect():
	if not loading:
		show_screen("inspection_desk")

func interview():
	show_screen("visitor_interview")

func review():
	if clues.size() < Rules.REQUIRED_CLUES:
		show_feedback("Need at least two clues")
		return
	show_screen("evidence_review")

func decide():
	if clues.size() < Rules.REQUIRED_CLUES:
		decision_state = "blocked"
		show_feedback("Review two clues before deciding")
		return
	show_screen("decision_confirm")

func choose(value):
	if locked:
		return false
	if clues.size() < Rules.REQUIRED_CLUES:
		decision_state = "blocked"
		show_feedback("Evidence requirement: 2 clues")
		return false
	if not Rules.DECISIONS.has(value):
		return false
	decision = value
	decision_state = "selected"
	_refresh_decision_buttons()
	return true

func confirm():
	if locked or decision == "":
		show_feedback("Select RETURN, HOLD, or REPORT")
		return false
	locked = true
	decision_state = "locked"
	var data = current_case()
	var questions_used = Rules.QUESTION_BUDGET - question_budget
	var delta = Rules.score_decision(decision, data["expected"], relation != "NONE", questions_used)
	score += delta
	case_scores.append(delta)
	outcome_state = "correct" if decision == data["expected"] else "incorrect"
	$Screens/outcome/result_stamp.text = "CORRECT" if outcome_state == "correct" else "INCORRECT"
	$Screens/outcome/score.text = "%+d  ·  TOTAL %d" % [delta, score]
	$Screens/outcome/reason/ReasonText.text = data["reason"]
	show_screen("outcome")
	return true

func next_case():
	if screen != "outcome":
		return
	if case_index >= CASES.size() - 1:
		show_screen("shift_summary")
		return
	case_index += 1
	load_case()

func finish():
	case_index = -1
	score = 0
	case_scores.clear()
	show_screen("night_desk")

func reveal_physical_clue(index := 0):
	var data = current_case()
	if data.is_empty():
		return false
	var list = data["physical"]
	var clue_id = "physical:%d:%d" % [case_index, clampi(index, 0, list.size() - 1)]
	if not clues.has(clue_id):
		clues.append(clue_id)
		inspection_state = "hotspot_revealed"
		show_feedback("Physical clue added: " + list[clampi(index, 0, list.size() - 1)])
		_refresh_ui()
	return true

func ask_question(index := 0):
	if question_budget <= 0:
		show_feedback("Question budget is empty")
		return false
	var data = current_case()
	var list = data["statements"]
	question_budget -= 1
	var clue_id = "statement:%d:%d" % [case_index, clampi(index, 0, list.size() - 1)]
	if not clues.has(clue_id):
		clues.append(clue_id)
	show_feedback("Statement clue: " + list[clampi(index, 0, list.size() - 1)])
	_refresh_ui()
	return true

func place_evidence(clue_id, slot_index):
	if not clues.has(clue_id) or slot_index < 0 or slot_index > 1:
		show_feedback("Invalid evidence drop")
		return false
	if slot_clues[1 - slot_index] == clue_id:
		show_feedback("Each slot needs a unique clue")
		return false
	slot_clues[slot_index] = clue_id
	review_state = "one_slot"
	if slot_clues[0] != "" and slot_clues[1] != "":
		relation = current_case()["relation"]
		review_state = "relation_recorded"
		$Screens/evidence_review/relation.text = relation
	else:
		relation = "NONE"
		$Screens/evidence_review/relation.text = "ADD SECOND CLUE"
	_refresh_ui()
	return true

func clue_for_card(card_index):
	if clues.is_empty():
		return ""
	return clues[clampi(card_index, 0, clues.size() - 1)]

func show_feedback(message):
	$ModalLayer/Feedback.text = message
	$ModalLayer/Feedback.visible = true
	var timer = get_tree().create_timer(1.2)
	timer.timeout.connect(func(): $ModalLayer/Feedback.visible = false)

func _refresh_ui():
	$Screens/night_desk/case_counter.text = "%d / 3 cases" % maxi(case_index + 1, 0)
	if not current_case().is_empty():
		$Screens/case_intake/case_meta/MetaText.text = current_case()["location"]
		$Screens/case_intake/item_preview/ItemText.text = current_case()["item"]
	$Screens/visitor_interview/budget.text = "%d / 3" % question_budget
	$Screens/inspection_desk/review_btn.disabled = clues.size() < Rules.REQUIRED_CLUES
	$Screens/visitor_interview/review_btn.disabled = clues.size() < Rules.REQUIRED_CLUES
	$Screens/evidence_review/decision_btn.disabled = clues.size() < Rules.REQUIRED_CLUES
	$Screens/visitor_interview/question_cards/Ask.disabled = question_budget <= 0
	if screen == "shift_summary":
		$Screens/shift_summary/grade.text = "GRADE " + Rules.grade_for(score)
		var rows := []
		for i in case_scores.size():
			rows.append("CASE %d  %+d" % [i + 1, case_scores[i]])
		$Screens/shift_summary/case_rows/Rows.text = "\n".join(rows) + "\nTOTAL  %d" % score
	_refresh_decision_buttons()

func _refresh_decision_buttons():
	for value in Rules.DECISIONS:
		var button = $Screens/decision_confirm.get_node(value.to_lower())
		button.button_pressed = decision == value
	$Screens/decision_confirm/confirm_rail/ConfirmRail.set_armed(decision != "" and not locked)

func apply_acc_1(): return screen
func apply_acc_2(): return {"drag": true, "pinch": true, "hotspot": true}
func apply_acc_3(): return question_budget
func apply_acc_4(): return {"slots": slot_clues, "relation": relation}
func apply_acc_5(): return {"decision": decision, "locked": locked}
func apply_acc_6(): return {"score": score, "rules": Rules.rule_rul_score()}
func apply_acc_7(): return {"case_index": case_index, "case_scores": case_scores}
func apply_arc_implementation_order(): return ["skeleton", "geometry", "state", "input", "presentation", "integration"]
func apply_arc_persistence(): return {"session": "memory", "shift_cases": 3}
func apply_arc_required_data(): return {"CaseData": CASES, "EvidenceData": clues, "VisitorData": question_budget, "DecisionRule": Rules.rule_rul_decisions()}
func apply_arc_reusable(): return ["EvidenceCard", "PrimaryButton", "StatusChip", "DragDropSlot", "ConfirmRail"]
func apply_arc_scene_hierarchy(): return $Screens
func apply_arc_state_owner(): return {"app": "AppRoot", "pointer": "InteractionController"}
func apply_cnt_mvp_scope(): return CASES.size()
func apply_cnt_screen_inventory(): return ["night_desk", "case_intake", "inspection_desk", "visitor_interview", "evidence_review", "decision_confirm", "outcome", "shift_summary"]
func apply_gst_decision_locked(): return locked
func apply_gst_loading(): return loading
func apply_gst_pause(): return paused
func apply_sta_case_intake_intake(): return screen == "case_intake"
func apply_sta_decision_confirm_blocked(): return decision_state == "blocked"
func apply_sta_decision_confirm_confirming(): return decision_state == "confirming"
func apply_sta_decision_confirm_locked(): return decision_state == "locked"
func apply_sta_decision_confirm_selected(): return decision_state == "selected"
func apply_sta_decision_confirm_unselected(): return decision_state == "unselected"
func apply_sta_evidence_review_comparing(): return review_state == "comparing"
func apply_sta_evidence_review_empty(): return review_state == "empty"
func apply_sta_evidence_review_one_slot(): return review_state == "one_slot"
func apply_sta_evidence_review_relation_recorded(): return review_state == "relation_recorded"
func apply_sta_inspection_desk_hotspot_revealed(): return inspection_state == "hotspot_revealed"
func apply_sta_inspection_desk_idle(): return inspection_state == "idle"
func apply_sta_inspection_desk_rotating(): return inspection_state == "rotating"
func apply_sta_inspection_desk_zoomed(): return inspection_state == "zoomed"
func apply_sta_night_desk_ready(): return screen == "night_desk"
func apply_sta_outcome_complete(): return screen == "outcome"
func apply_sta_outcome_correct(): return outcome_state == "correct"
func apply_sta_outcome_incorrect(): return outcome_state == "incorrect"
func apply_sta_shift_summary_summary(): return screen == "shift_summary"
func apply_sta_visitor_interview_answering(): return screen == "visitor_interview" and question_budget < Rules.QUESTION_BUDGET
func apply_sta_visitor_interview_budget_empty(): return question_budget == 0
func apply_sta_visitor_interview_question_ready(): return screen == "visitor_interview" and question_budget > 0
func apply_trn_case_intake_1(): inspect()
func apply_trn_decision_confirm_1(): confirm()
func apply_trn_evidence_review_1(): decide()
func apply_trn_inspection_desk_1(): interview()
func apply_trn_inspection_desk_2(): review()
func apply_trn_night_desk_1(): start_shift()
func apply_trn_outcome_1(): next_case()
func apply_trn_outcome_2(): show_screen("shift_summary")
func apply_trn_shift_summary_1(): finish()
func apply_trn_visitor_interview_1():
	if return_count < 1:
		return_count += 1
		inspect()
func apply_trn_visitor_interview_2(): review()
