extends Control
class_name ParcelShiftController

var case_index := 0
var cases_done := 0
var score := 0
var correct_count := 0
var correct_streak := 0
var critical_misses := 0
var total_scans := 0
var total_scan_reversals := 0
var last_result: Dictionary = {}

func reset_shift() -> void:
	case_index = 0
	cases_done = 0
	score = 0
	correct_count = 0
	correct_streak = 0
	critical_misses = 0
	total_scans = 0
	total_scan_reversals = 0
	last_result = {}

func begin_case() -> void:
	case_index = cases_done

func commit_result(result: Dictionary, scan_count: int, scan_reversals: int) -> void:
	last_result = result.duplicate(true)
	cases_done += 1
	total_scans += scan_count
	total_scan_reversals += scan_reversals
	score += int(result.delta)
	if bool(result.correct):
		correct_count += 1
		correct_streak += 1
	else:
		correct_streak = 0
	if bool(result.critical_miss):
		critical_misses += 1

func summary() -> Dictionary:
	var accuracy := float(correct_count) / 8.0
	var grade := "A" if accuracy >= 0.875 else ("B" if accuracy >= 0.75 else ("C" if accuracy >= 0.5 else "D"))
	if critical_misses >= 2 and grade in ["A", "B"]:
		grade = "C"
	return {
		"grade": grade,
		"accuracy": accuracy,
		"critical_misses": critical_misses,
		"efficiency": max(0, 100 - max(0, total_scans - 32) * 5),
		"score": score
	}
