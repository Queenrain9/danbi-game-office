extends Control
class_name EvidencePin
var evidence_position := Vector2.ZERO
func configure(position: Vector2) -> void:
	evidence_position = position
	position = evidence_position
