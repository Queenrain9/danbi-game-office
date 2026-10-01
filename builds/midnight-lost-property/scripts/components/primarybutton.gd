extends Control

var enabled := true
var pulse_strength := 0.0

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_enabled(value):
	enabled = value
	var button = get_parent()
	if button is Button:
		button.disabled = not value
	modulate.a = 1.0 if value else 0.45

func pulse():
	pulse_strength = 1.0
	scale = Vector2(1.03, 1.03)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.12)
	tween.finished.connect(func(): pulse_strength = 0.0)
