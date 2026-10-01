extends Control
class_name ResultStamp
var classification := ""
var correct := false
func configure(lane: String, is_correct: bool) -> void:
	classification = lane
	correct = is_correct
