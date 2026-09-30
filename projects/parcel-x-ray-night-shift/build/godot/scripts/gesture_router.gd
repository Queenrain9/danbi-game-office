extends RefCounted

const DRAG_THRESHOLD:=18.0
const CLASSIFY_ENTER_Y:=440.0
enum Kind { NONE, ROTATE_OR_PIN, SCAN, CLASSIFY }
var kind:=Kind.NONE
var start:=Vector2.ZERO
var last:=Vector2.ZERO

func begin_box(p:Vector2)->void:
 kind=Kind.ROTATE_OR_PIN; start=p; last=p
func begin_scan(p:Vector2)->void:
 kind=Kind.SCAN; start=p; last=p
func move(p:Vector2)->Vector2:
 var d:=p-last; last=p
 if kind==Kind.ROTATE_OR_PIN and p.y-start.y>80.0: kind=Kind.CLASSIFY
 return d
func is_tap(p:Vector2)->bool: return start.distance_to(p)<DRAG_THRESHOLD
func cancel()->void: kind=Kind.NONE
