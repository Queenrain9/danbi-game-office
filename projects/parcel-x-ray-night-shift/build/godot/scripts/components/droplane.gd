extends Control
func accepts(global_point:Vector2)->bool:return get_global_rect().has_point(global_point)
