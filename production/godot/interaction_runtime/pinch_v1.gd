class_name DanbiPinchV1
extends RefCounted

var touches: Dictionary = {}
var start_distance: float = 0.0
var start_value: float = 1.0
var min_value: float = 0.1
var max_value: float = 10.0

func configure(params: Dictionary) -> void:
    min_value = float(params.get("min_value", min_value))
    max_value = float(params.get("max_value", max_value))

func touch(index: int, pressed: bool, position: Vector2, current_value: float) -> Dictionary:
    if pressed:
        touches[index] = position
    else:
        touches.erase(index)

    if touches.size() == 2:
        var pts: Array = touches.values()
        var p0: Vector2 = pts[0]
        var p1: Vector2 = pts[1]
        start_distance = maxf((p1 - p0).length(), 0.001)
        start_value = current_value
        return {"handled": true, "phase": "begin", "value": current_value}

    return {"handled": true, "phase": "touch", "value": current_value}

func drag(index: int, position: Vector2) -> Dictionary:
    if not touches.has(index):
        return {"handled": false}

    touches[index] = position
    if touches.size() != 2 or start_distance <= 0.0:
        return {"handled": false}

    var pts: Array = touches.values()
    var p0: Vector2 = pts[0]
    var p1: Vector2 = pts[1]
    var distance: float = (p1 - p0).length()
    var scale: float = distance / start_distance
    var value: float = clampf(start_value * scale, min_value, max_value)
    return {"handled": true, "phase": "pinch", "value": value, "scale": scale}

func cancel() -> void:
    touches.clear()
    start_distance = 0.0
