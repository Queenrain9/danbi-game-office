extends Control

var state := ""
var palette := {
	"ready": Color("66d9ef"),
	"blocked": Color("ff6b6b"),
	"match": Color("6be585"),
	"conflict": Color("ffb454"),
	"empty": Color("8b93a7")
}

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_state(value):
	state = value
	modulate = palette.get(value.to_lower(), Color.WHITE)
