class_name DanbiHoldV1
extends RefCounted
var active:=false
var start_ms:=0
var origin:=Vector2.ZERO
var hold_ms:=600
var movement_tolerance_px:=18.0
func configure(params:Dictionary)->void:hold_ms=int(params.get("hold_ms",hold_ms));movement_tolerance_px=float(params.get("movement_tolerance_px",movement_tolerance_px))
func begin(now_ms:int,pointer_position:Vector2)->Dictionary:active=true;start_ms=now_ms;origin=pointer_position;return {"handled":true,"phase":"begin","completed":false}
func update(now_ms:int,pointer_position:Vector2)->Dictionary:
    if not active:return {"handled":false}
    if pointer_position.distance_to(origin)>movement_tolerance_px:active=false;return {"handled":true,"phase":"cancel","completed":false,"reason":"movement"}
    var elapsed:=now_ms-start_ms;var completed:=elapsed>=hold_ms
    if completed:active=false
    return {"handled":true,"phase":"complete" if completed else "holding","completed":completed,"elapsed_ms":elapsed}
func release(now_ms:int,pointer_position:Vector2)->Dictionary:
    var result:=update(now_ms,pointer_position)
    if result.get("completed",false):return result
    active=false;result["phase"]="release";return result
func cancel()->void:active=false
