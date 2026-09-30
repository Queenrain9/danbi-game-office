extends Control
signal interaction_event(event)

func handle_input(event: InputEvent) -> void:
 interaction_event.emit(event)
