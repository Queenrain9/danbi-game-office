extends Control
const SceneData=preload("res://scripts/scene_data.gd")
const SessionState=preload("res://scripts/session_state.gd")
enum View { LOBBY, BRIEFING, COUNTDOWN, LIVE, RESULT }
var view:=View.LOBBY
var scenes:Array=SceneData.all()
var s:=SessionState.new()
var selected:=0
var running:=false
var paused:=false
var countdown:=3.0
var overlay:Control
var hud:VBoxContainer
var stage:Panel
var stage_label:Label
var cue_label:Label
var continuity_label:Label
var time_label:Label
var faders:Dictionary={}
var curtain:VSlider
var prop_mark:Panel
var props:Dictionary={}
var active_prop:Control
var prop_home:=Vector2.ZERO
var prop_hold_started:=0
var incident_btn:Button
var incident_spawned:Dictionary={}
var last_wrong:=""
var wrong_repeat:=0

func _ready()->void:
 show_lobby()

func _process(delta:float)->void:
 if view==View.COUNTDOWN:
  countdown-=delta
  if countdown<=0.0: start_live()
  elif hud: hud.get_child(1).text="Curtain up in %d" % int(ceil(countdown))
 elif view==View.LIVE and running and not paused:
  s.elapsed+=delta
  _spawn_incident()
  _expire_incident()
  _expire_cues()
  _update_live()
  if s.continuity<=0 or s.elapsed>=float(scenes[selected].duration): show_result()

func clear_ui()->void:
 for c in get_children():
  if c.name not in ["SceneController","StagePreview","BackstageControls","CueStrip","OverlayLayer"]: c.queue_free()

func root(title:String)->VBoxContainer:
 clear_ui()
 hud=VBoxContainer.new()
 hud.name="ScreenUI"
 hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 hud.add_theme_constant_override("separation",8)
 add_child(hud)
 var h:=Label.new(); h.text=title; h.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; h.add_theme_font_size_override("font_size",24); hud.add_child(h)
 return hud

func button(parent:Control,text:String,cb:Callable)->Button:
 var b:=Button.new(); b.text=text; b.custom_minimum_size=Vector2(0,54); b.pressed.connect(cb); parent.add_child(b); return b

func show_lobby()->void:
 view=View.LOBBY; running=false; paused=false
 var v:=root("TINY STAGEHAND · BACKSTAGE")
 for i in range(scenes.size()):
  var card:=HBoxContainer.new(); v.add_child(card)
  var l:=Label.new(); l.text="%d · %s" % [i+1,scenes[i].title]; l.size_flags_horizontal=Control.SIZE_EXPAND_FILL; card.add_child(l)
  var b:=button(card,"SELECT",open_briefing.bind(i))
 button(v,"HOW TO READ CUES",show_help)

func open_briefing(idx:int)->void:
 selected=idx; view=View.BRIEFING
 var v:=root("SCENE BRIEFING")
 var l:=Label.new(); l.text="%s\nGoal: keep Continuity above 0 for 60 seconds.\nCues: LIGHT A/B · CURTAIN · PROP\nIncidents: snag / dropped prop" % scenes[idx].title; l.custom_minimum_size=Vector2(0,420); l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; v.add_child(l)
 button(v,"START PERFORMANCE",start_countdown)
 button(v,"BACK",show_lobby)

func start_countdown()->void:
 s.reset(selected); view=View.COUNTDOWN; countdown=3.0
 var v:=root("STAGE READY")
 var l:=Label.new(); l.text="Curtain up in 3"; l.custom_minimum_size=Vector2(0,500); l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; v.add_child(l)

func start_live()->void:
 view=View.LIVE; running=true; paused=false; incident_spawned.clear()\n var v:=root("LIVE PERFORMANCE")
 var top:=HBoxContainer.new(); v.add_child(top)
 continuity_label=Label.new(); continuity_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL; top.add_child(continuity_label)
 time_label=Label.new(); top.add_child(time_label)
 button(top,"? CUES",show_help)
 button(top,"II",show_pause)
 stage=Panel.new(); stage.custom_minimum_size=Vector2(0,320); v.add_child(stage)
 stage_label=Label.new(); stage_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); stage_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; stage_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; stage.add_child(stage_label)
 prop_mark=Panel.new(); prop_mark.position=Vector2(360,210); prop_mark.size=Vector2(90,70); stage.add_child(prop_mark)
 var mark:=Label.new(); mark.text="PROP MARK"; mark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); mark.mouse_filter=Control.MOUSE_FILTER_IGNORE; prop_mark.add_child(mark)
 var controls:=HBoxContainer.new(); controls.custom_minimum_size=Vector2(0,260); v.add_child(controls)
 _add_fader(controls,"LIGHT A","light_a")
 _add_fader(controls,"LIGHT B","light_b")
 curtain=VSlider.new(); curtain.min_value=0; curtain.max_value=100; curtain.custom_minimum_size=Vector2(80,230); curtain.value_changed.connect(_curtain_changed); curtain.gui_input.connect(_curtain_input); controls.add_child(curtain)
 var tray:=Control.new(); tray.custom_minimum_size=Vector2(170,230); controls.add_child(tray)
 var tl:=Label.new(); tl.text="PROP TRAY"; tl.position=Vector2(5,0); tray.add_child(tl)
 var names=["ROSE","LETTER","LAMP"]\n for i in range(names.size()): _add_prop(tray,names[i],Vector2(8,35+i*58))
 incident_btn=Button.new(); incident_btn.visible=false; incident_btn.position=Vector2(300,55); incident_btn.size=Vector2(190,60); incident_btn.pressed.connect(_resolve_incident); stage.add_child(incident_btn)
 cue_label=Label.new(); cue_label.custom_minimum_size=Vector2(0,130); cue_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; v.add_child(cue_label)
 _update_live()

func _add_fader(parent:Control,label_text:String,key:String)->void:
 var box:=VBoxContainer.new(); parent.add_child(box)
 var l:=Label.new(); l.text=label_text; box.add_child(l)
 var f:=VSlider.new(); f.min_value=0; f.max_value=100; f.step=1; f.custom_minimum_size=Vector2(90,210); f.value_changed.connect(_light_changed.bind(key)); f.gui_input.connect(_fader_input.bind(key)); box.add_child(f); faders[key]=f

func _add_prop(parent:Control,name:String,pos:Vector2)->void:\n var p:=Panel.new(); p.position=pos; p.size=Vector2(145,50); p.gui_input.connect(_prop_input.bind(p,name)); parent.add_child(p)
 var l:=Label.new(); l.text=name; l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; l.mouse_filter=Control.MOUSE_FILTER_IGNORE; p.add_child(l); props[name]=p

func _light_changed(value:float,key:String)->void:
 if paused:return
 var snapped=round(value/25.0)*25.0
 if abs(value-snapped)<=2.0 and faders[key].value!=snapped: faders[key].set_value_no_signal(snapped); value=snapped
 s.set(key,value)
 stage.modulate.a=0.55+(s.light_a+s.light_b)/400.0
 _judge_control(key,value)

func _curtain_changed(value:float)->void:
 if paused:return
 s.curtain=value
 stage_label.text="CURTAIN %d%%" % int(value)
 _judge_control("curtain",value)

func _fader_input(event:InputEvent,key:String)->void:
 if paused:return
 if (event is InputEventScreenTouch or event is InputEventMouseButton) and not event.pressed:
  _judge_control(key,round(float(s.get(key))/25.0)*25.0)

func _curtain_input(event:InputEvent)->void:
 if paused:return
 if (event is InputEventScreenTouch or event is InputEventMouseButton) and not event.pressed:
  _judge_control("curtain",round(s.curtain/25.0)*25.0)

func _prop_input(event:InputEvent,p:Control,name:String)->void:
 if paused:return
 var pos:=_event_pos(event)
 if event is InputEventScreenTouch or event is InputEventMouseButton:
  if event.pressed:
   active_prop=p; prop_home=p.global_position; prop_hold_started=Time.get_ticks_msec()
  elif active_prop==p:
   if Time.get_ticks_msec()-prop_hold_started>=80: _finish_prop(p,name)
   else: _wrong(name)
   active_prop=null
 elif (event is InputEventScreenDrag or event is InputEventMouseMotion) and active_prop==p:
  if Time.get_ticks_msec()-prop_hold_started>=80:
   p.global_position=pos-p.size*0.5
   prop_mark.modulate.a=1.0 if _mark_open(name) else 0.45

func _finish_prop(p:Control,name:String)->void:
 if _mark_open(name) and prop_mark.get_global_rect().intersects(p.get_global_rect()):
  p.global_position=prop_mark.global_position
  s.staged_prop=name
  _judge_control("prop",name)
 else:
  var tw:=create_tween(); tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT); tw.tween_property(p,"global_position",prop_home,0.18)
  _wrong(name)
 prop_mark.modulate.a=1.0

func _mark_open(name:String)->bool:
 var cue=_current_prop_cue()
 return not cue.is_empty() and String(cue[2])==name and float(cue[0])-s.elapsed<=5.0 and float(cue[0])-s.elapsed>=-0.9

func _current_prop_cue()->Array:
 for c in scenes[selected].cues:
  if c[1]=="prop" and abs(float(c[0])-s.elapsed)<=5.0:return c
 return []

func _judge_control(kind:String,value)->void:
 for i in range(s.cue_index,scenes[selected].cues.size()):
  var c:Array=scenes[selected].cues[i]
  if c[1]!=kind:continue
  var d=abs(float(c[0])-s.elapsed)
  var target_ok := String(c[2])==String(value) if kind=="prop" else abs(float(c[2])-float(value))<=2.0\n  if d<=0.9 and target_ok:
   var pts=100 if d<=0.35 else 65
   s.score+=pts; s.results.append([c[0],c[1],"PERFECT" if pts==100 else "GOOD"]); s.cue_index=max(s.cue_index,i+1); return
 _wrong(kind)

func _wrong(kind:String)->void:
 s.continuity=max(0,s.continuity-8)
 if last_wrong==kind: wrong_repeat+=1
 else: last_wrong=kind; wrong_repeat=1
 if wrong_repeat>=2 and cue_label: cue_label.text="CHECK CONTROL · "+kind.to_upper()

func _expire_cues()->void:
 while s.cue_index<scenes[selected].cues.size():
  var c:Array=scenes[selected].cues[s.cue_index]
  if s.elapsed<=float(c[0])+0.9:return
  s.results.append([c[0],c[1],"MISS"]); s.continuity=max(0,s.continuity-15); s.cue_index+=1

func _spawn_incident()->void:
 if not s.incident.is_empty():return
 for inc in scenes[selected].incidents:
  var key=str(inc[0])
  if s.elapsed>=float(inc[0]) and not incident_spawned.has(key):
   incident_spawned[key]=true; s.incident={"t":inc[0],"kind":inc[1],"expires":s.elapsed+5.0}; incident_btn.text="INCIDENT · %s · TAP FIX" % String(inc[1]).to_upper(); incident_btn.visible=true; return

func _expire_incident()->void:
 if not s.incident.is_empty() and s.elapsed>float(s.incident.expires):
  s.continuity=max(0,s.continuity-20); s.incident={}; incident_btn.visible=false

func _resolve_incident()->void:
 if paused or s.incident.is_empty():return
 s.score+=80; s.results.append([s.elapsed,"incident","RESOLVED"]); s.incident={}; incident_btn.visible=false

func _update_live()->void:
 continuity_label.text="CONTINUITY %d" % s.continuity
 time_label.text="%02d:%02d" % [int(s.elapsed)/60,int(s.elapsed)%60]
 var now="—"; var next="—"
 if s.cue_index<scenes[selected].cues.size(): now=_cue_text(scenes[selected].cues[s.cue_index])
 if s.cue_index+1<scenes[selected].cues.size(): next=_cue_text(scenes[selected].cues[s.cue_index+1])
 cue_label.text="NOW  %s\nNEXT  %s\nUPCOMING · %.1fs" % [now,next,max(0.0,(float(scenes[selected].cues[s.cue_index][0])-s.elapsed) if s.cue_index<scenes[selected].cues.size() else 0.0)]

func _cue_text(c:Array)->String:
 return "%s → %s @ %.1f" % [String(c[1]).to_upper(),str(c[2]),float(c[0])]

func show_pause()->void:
 if view!=View.LIVE or overlay:return
 paused=true; _modal("PAUSED","Timeline and controls are frozen.",[["RESUME",close_modal],["QUIT",quit_to_lobby]])

func quit_to_lobby()->void:\n close_modal()\n show_lobby()\n\nfunc show_help()->void:
 if overlay:return
 var was_live=view==View.LIVE
 if was_live: paused=true
 _modal("CUE HELP","LIGHT A/B → drag fader vertically\nCURTAIN → drag rope slider\nPROP → hold 80ms, drag matching prop to glowing mark\nINCIDENT → tap its hotspot",[["CLOSE",close_modal]])

func _modal(title:String,body:String,actions:Array)->void:
 overlay=ColorRect.new(); overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); overlay.mouse_filter=Control.MOUSE_FILTER_STOP; add_child(overlay)
 var p:=VBoxContainer.new(); p.position=Vector2(55,180); p.size=Vector2(430,520); overlay.add_child(p)
 var h:=Label.new(); h.text=title; p.add_child(h)
 var l:=Label.new(); l.text=body; l.custom_minimum_size=Vector2(0,300); l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; p.add_child(l)
 for a in actions: button(p,a[0],a[1])

func close_modal()->void:
 if overlay: overlay.queue_free(); overlay=null
 if view==View.LIVE: paused=false

func show_result()->void:
 running=false; paused=false; view=View.RESULT
 var bonus=int(s.continuity*2.0); s.score+=bonus
 var v:=root("PERFORMANCE RESULT · "+s.grade())
 var l:=Label.new(); l.text="Continuity %d\nScore %d\nCue Accuracy %d / %d\n\n%s" % [s.continuity,s.score,_hit_count(),scenes[selected].cues.size(),_result_lines()]; l.custom_minimum_size=Vector2(0,500); l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; v.add_child(l)
 button(v,"RETRY",open_briefing.bind(selected)); button(v,"NEXT / LOBBY",show_lobby)

func _hit_count()->int:
 var n=0
 for r in s.results:
  if r[2] in ["PERFECT","GOOD"]:n+=1
 return n

func _result_lines()->String:
 var out=""
 for r in s.results: out+="%.1f  %s  %s\n" % [float(r[0]),String(r[1]).to_upper(),String(r[2])]
 return out

func _event_pos(event:InputEvent)->Vector2:
 if event is InputEventScreenTouch or event is InputEventScreenDrag:return event.position
 if event is InputEventMouseButton or event is InputEventMouseMotion:return event.position
 return Vector2.ZERO

# Fidelity-v1 static scene signal bridges for the legacy rebaseline.
func bp_action_lobby_select()->void:
 open_briefing(0)

func bp_action_result_retry()->void:
 open_briefing(selected)
