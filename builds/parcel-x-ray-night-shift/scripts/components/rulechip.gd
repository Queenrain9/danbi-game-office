extends Control
class_name RuleChip
var rule_id := ""
var rule_text := ""
func configure(id: String, text: String) -> void:
	rule_id = id
	rule_text = text
	tooltip_text = text
