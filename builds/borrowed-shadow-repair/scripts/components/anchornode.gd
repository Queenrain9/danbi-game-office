extends Control
func _ready(): mouse_filter=Control.MOUSE_FILTER_IGNORE; queue_redraw()
func _draw():
    draw_circle(size*0.5, 22.0, Color(0.91,0.71,0.36,0.35))
    draw_arc(size*0.5, 22.0, 0, TAU, 28, Color("#e7b55d"), 3.0)
