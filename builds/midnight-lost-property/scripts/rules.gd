class_name MidnightRules
extends RefCounted

const REQUIRED_CLUES := 2
const CLUES_PER_CASE := Vector2i(3, 5)
const QUESTION_BUDGET := 3
const DECISIONS := ["RETURN", "HOLD", "REPORT"]
const SCORE_CORRECT := 100
const SCORE_FALSE_REPORT := -25
const SCORE_RECKLESS_RETURN := -40
const SCORE_SUPPORTED_REASON := 30
const SCORE_UNNECESSARY_QUESTION := -5
const GRADE_THRESHOLDS := {"S": 330, "A": 280, "B": 220, "C": 0}

static func rule_rul_clues():
	return {"range": [CLUES_PER_CASE.x, CLUES_PER_CASE.y], "decision_minimum": REQUIRED_CLUES}

static func rule_rul_score():
	return {
		"correct": SCORE_CORRECT,
		"false_report": SCORE_FALSE_REPORT,
		"reckless_return": SCORE_RECKLESS_RETURN,
		"supported_reason": SCORE_SUPPORTED_REASON,
		"unnecessary_question": SCORE_UNNECESSARY_QUESTION
	}

static func rule_rul_grades():
	return GRADE_THRESHOLDS.duplicate(true)

static func rule_rul_decisions():
	return DECISIONS.duplicate()

static func rule_rul_principle():
	return "Choose the action supported by evidence, not by claimed ownership."

static func rule_rul_questions():
	return QUESTION_BUDGET

static func grade_for(total_score):
	if total_score >= GRADE_THRESHOLDS["S"]:
		return "S"
	if total_score >= GRADE_THRESHOLDS["A"]:
		return "A"
	if total_score >= GRADE_THRESHOLDS["B"]:
		return "B"
	return "C"

static func score_decision(selected, expected, relation_recorded, questions_used):
	var delta := 0
	if selected == expected:
		delta += SCORE_CORRECT
	elif selected == "REPORT":
		delta += SCORE_FALSE_REPORT
	elif selected == "RETURN":
		delta += SCORE_RECKLESS_RETURN
	else:
		delta += SCORE_FALSE_REPORT
	if relation_recorded:
		delta += SCORE_SUPPORTED_REASON
	if questions_used > 2:
		delta += (questions_used - 2) * SCORE_UNNECESSARY_QUESTION
	return delta
