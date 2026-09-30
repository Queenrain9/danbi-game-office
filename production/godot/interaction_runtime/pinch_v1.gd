class_name DanbiPinchV1
extends RefCounted
var touches:={}
var start_distance:=0.0
var start_value:=1.0
var min_value:=0.1
var max_value:=10.0
func configure(params:Dictionary)->void:min_value=float(params.get("min_value",min_value));max_value=float(params.get("max_value",max_value))
func touch(index:int,pressed:bool,position:Vector2,current_value:float)->Dictionary:
    if pressed:touches[index]=position
    else:touches.erase(index)
    if touches.size()==2:
        var pts:=touches.values();start_distance=maxf((pts[1]-pts[0]).length(),0.001);start_value=current_value;return {"handled":true,"phase":"begin","value":current_value}
    return {"handled":true,"phase":"touch","value":current_value}
func drag(index:int,position:Vector2)->Dictionary:
    if not touches.has(index):return {"handled":false}
    touches[index]=position
    if touches.size()!=2 or start_distance<=0.0:return {"handled":false}
    var pts:=touches.values();var distance:=(pts[1]-pts[0]).length();var value:=clampf(start_value*distance/start_distance,min_value,max_value)
    return {"handled":true,"phase":"pinch","value":value,"scale":distance/start_distance}
func cancel()->void:touches.clear();start_distance=0.0
