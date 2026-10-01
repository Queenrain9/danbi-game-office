extends Control

var card_id := ""
var highlighted := false

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func accepts(id):
	return id != "" and id != card_id

func place(id):
	if not accepts(id):
		return false
	card_id = id
	set_highlighted(false)
	modulate = Color("6be585")
	return true

func clear():
	card_id = ""
	set_highlighted(false)
	modulate = Color.WHITE

func set_highlighted(value):
	highlighted = value
	scale = Vector2(1.03, 1.03) if value else Vector2.ONE
