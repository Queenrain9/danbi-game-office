extends Control
class_name DropLane
@export var classification := ""
func accepts(global_point: Vector2) -> bool:
	return get_global_rect().has_point(global_point)
