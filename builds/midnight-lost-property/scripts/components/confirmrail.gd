extends Control

signal completed

var progress := 0.0
var armed := false

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_armed(value):
	armed = value
	modulate.a = 1.0 if value else 0.4
	if not value:
		reset()

func set_progress(value):
	progress = clampf(value, 0.0, 1.0)
	scale.x = 0.05 + progress * 0.95

func reset():
	progress = 0.0
	scale.x = 0.05

func complete():
	progress = 1.0
	scale.x = 1.0
	completed.emit()
