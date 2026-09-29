extends RefCounted
var scene_index:=0
var elapsed:=0.0
var continuity:=100
var score:=0
var cue_index:=0
var results:Array=[]
var light_a:=0.0
var light_b:=0.0
var curtain:=0.0
var staged_prop:=""
var incident:Dictionary={}
func reset(idx:int)->void:
 scene_index=idx
 elapsed=0.0
 continuity=100
 score=0
 cue_index=0
 results.clear()
 light_a=0.0
 light_b=0.0
 curtain=0.0
 staged_prop=""
 incident={}
func grade()->String:
 if continuity>=90 and score>=450:return "S"
 if continuity>=75:return "A"
 if continuity>=50:return "B"
 return "C"
