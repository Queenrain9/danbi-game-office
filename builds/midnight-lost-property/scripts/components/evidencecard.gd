extends Control

signal drag_started(clue_id)
signal drag_moved(clue_id, position)
signal drag_released(clue_id, position, held_ms)

const LONG_PRESS_MS := 550
var clue_id := ""
var pressed := false
var press_started_ms := 0
var origin := Vector2.ZERO

func configure(value):
	clue_id = value

func begin_drag(position):
	pressed = true
	press_started_ms = Time.get_ticks_msec()
	origin = position

func move_drag(position):
	if pressed and Time.get_ticks_msec() - press_started_ms >= LONG_PRESS_MS:
		drag_started.emit(clue_id)
		drag_moved.emit(clue_id, position)

func end_drag(position):
	if not pressed:
		return
	var held_ms = Time.get_ticks_msec() - press_started_ms
	pressed = false
	drag_released.emit(clue_id, position, held_ms)
	position = Vector2.ZERO
