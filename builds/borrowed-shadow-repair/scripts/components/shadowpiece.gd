extends Control
func _ready(): mouse_filter=Control.MOUSE_FILTER_IGNORE; queue_redraw()
func _draw():
    var game=get_node_or_null("/root/AppRoot")
    if not game: return
    var remaining=maxi(game.required_pieces-game.snapped_pieces,0)
    for i in range(remaining):
        var x=24.0+i*minf(62.0,(size.x-48.0)/maxf(game.required_pieces,1.0))
        draw_colored_polygon(PackedVector2Array([Vector2(x,18),Vector2(x+38,8),Vector2(x+48,48),Vector2(x+8,58)]),Color("#8d78b8"))
