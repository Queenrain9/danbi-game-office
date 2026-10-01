extends RefCounted
class_name ParcelRules

const CORRECT := 100
const CRITICAL_ISOLATE := 150
const WRONG_PASS := -180
const WRONG_OTHER := -80
const FALSE_PIN := -5
const EFFICIENT_BONUS := 20
const SCAN_SOFT_TARGET := 4

func rule_rul_combo(correct_streak: int = 0) -> int:
	return 10 if correct_streak >= 3 else 0

func rule_rul_failure(critical_misses: int = 0) -> Dictionary:
	return {"immediate_failure": false, "grade_cap": "C" if critical_misses >= 2 else ""}

func rule_rul_hazard_01(parcel: Dictionary = {}) -> bool:
	return bool(parcel.get("metal_dense", false)) and not bool(parcel.get("padding", false)) and float(parcel.get("edge_distance_percent", 100.0)) <= 10.0

func rule_rul_hazard_02(parcel: Dictionary = {}) -> bool:
	return int(parcel.get("dense_objects", 0)) >= 2 and bool(parcel.get("cable_connected", false)) and bool(parcel.get("power_cell_contact", false))

func rule_rul_hazard_03(parcel: Dictionary = {}) -> bool:
	return not rule_rul_hazard_01(parcel) and not rule_rul_hazard_02(parcel)

func expected_lane(parcel: Dictionary) -> String:
	if rule_rul_hazard_02(parcel):
		return "ISOLATE"
	if rule_rul_hazard_01(parcel):
		return "REPACK"
	return "PASS"

func rule_rul_scan_budget(scan_count: int = 0) -> Dictionary:
	return {
		"soft_target": SCAN_SOFT_TARGET,
		"hard_limit": null,
		"over_budget": max(0, scan_count - SCAN_SOFT_TARGET),
		"efficiency_penalty": -5 * max(0, scan_count - SCAN_SOFT_TARGET)
	}

func rule_rul_scoring_correct() -> int:
	return CORRECT

func rule_rul_scoring_critical_isolate() -> int:
	return CRITICAL_ISOLATE

func rule_rul_scoring_efficient_bonus(scan_reversals: int = 0) -> int:
	return EFFICIENT_BONUS if scan_reversals <= 3 else 0

func rule_rul_scoring_false_pin() -> int:
	return FALSE_PIN

func rule_rul_scoring_wrong_other() -> int:
	return WRONG_OTHER

func rule_rul_scoring_wrong_pass() -> int:
	return WRONG_PASS

func score_classification(parcel: Dictionary, selected_lane: String, false_pin_count: int, scan_count: int, scan_reversals: int, streak_before: int) -> Dictionary:
	var correct_lane := expected_lane(parcel)
	var correct := selected_lane == correct_lane
	var critical_miss := selected_lane == "PASS" and correct_lane != "PASS"
	var delta := rule_rul_scoring_correct() if correct else (rule_rul_scoring_wrong_pass() if critical_miss else rule_rul_scoring_wrong_other())
	if correct and correct_lane == "ISOLATE":
		delta += rule_rul_scoring_critical_isolate()
	if correct:
		delta += rule_rul_scoring_efficient_bonus(scan_reversals)
		delta += rule_rul_combo(streak_before + 1)
	delta += false_pin_count * rule_rul_scoring_false_pin()
	delta += int(rule_rul_scan_budget(scan_count).efficiency_penalty)
	return {
		"correct": correct,
		"correct_lane": correct_lane,
		"critical_miss": critical_miss,
		"delta": delta,
		"reason": parcel.get("reason", "Apply the visible hazard rule to the scanned evidence.")
	}
