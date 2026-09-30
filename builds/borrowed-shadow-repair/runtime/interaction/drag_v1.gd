class_name DanbiDragV1
extends RefCounted
var active:=false
var pointer_id:=-1
var pointer_origin:=Vector2.ZERO
var value_origin:=Vector2.ZERO
var axis:="both"
var cancel_mode:="keep"
var min_position:=Vector2(-1.0e12,-1.0e12)
var max_position:=Vector2(1.0e12,1.0e12)
func configure(params:Dictionary)->void:
    axis=str(params.get("axis","both"));cancel_mode=str(params.get("cancel","keep"))
    if params.has("min_position"):min_position=params["min_position"]
    if params.has("max_position"):max_position=params["max_position"]
func begin(id:int,pointer_position:Vector2,value_position:Vector2)->Dictionary:
    active=true;pointer_id=id;pointer_origin=pointer_position;value_origin=value_position
    return {"handled":true,"phase":"begin","position":value_position}
func update(id:int,pointer_position:Vector2)->Dictionary:
    if not active or id!=pointer_id:return {"handled":false}
    var delta:=pointer_position-pointer_origin
    if axis=="x":delta.y=0.0
    elif axis=="y":delta.x=0.0
    var next:=value_origin+delta
    next.x=clampf(next.x,min_position.x,max_position.x);next.y=clampf(next.y,min_position.y,max_position.y)
    return {"handled":true,"phase":"move","position":next,"delta":delta}
func release(id:int,pointer_position:Vector2)->Dictionary:
    var result:=update(id,pointer_position)
    if not result.get("handled",false):return result
    active=false;pointer_id=-1;result["phase"]="release";return result
func cancel()->Dictionary:
    if not active:return {"handled":false}
    active=false;pointer_id=-1
    return {"handled":true,"phase":"cancel","position":value_origin if cancel_mode=="return_origin" else null}
func handle_event(event:InputEvent,value_position:Vector2)->Dictionary:
    if event is InputEventScreenTouch:return begin(event.index,event.position,value_position) if event.pressed else release(event.index,event.position)
    if event is InputEventScreenDrag:return update(event.index,event.position)
    if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:return begin(-1,event.global_position,value_position) if event.pressed else release(-1,event.global_position)
    if event is InputEventMouseMotion and active and pointer_id==-1:return update(-1,event.global_position)
    return {"handled":false}
