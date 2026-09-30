class_name DanbiSwipeV1
extends RefCounted
var active:=false
var pointer_id:=-1
var start_position:=Vector2.ZERO
var start_ms:=0
var min_distance_px:=48.0
var max_duration_ms:=700
func configure(params:Dictionary)->void:min_distance_px=float(params.get("min_distance_px",min_distance_px));max_duration_ms=int(params.get("max_duration_ms",max_duration_ms))
func begin(id:int,pointer_position:Vector2,now_ms:int)->void:active=true;pointer_id=id;start_position=pointer_position;start_ms=now_ms
func release(id:int,pointer_position:Vector2,now_ms:int)->Dictionary:
    if not active or id!=pointer_id:return {"handled":false}
    active=false;var delta:=pointer_position-start_position;var elapsed:=now_ms-start_ms;var accepted:=delta.length()>=min_distance_px and elapsed<=max_duration_ms;var direction:=""
    if accepted:direction="right" if absf(delta.x)>=absf(delta.y) and delta.x>0.0 else "left" if absf(delta.x)>=absf(delta.y) else "down" if delta.y>0.0 else "up"
    return {"handled":true,"accepted":accepted,"direction":direction,"delta":delta,"elapsed_ms":elapsed}
