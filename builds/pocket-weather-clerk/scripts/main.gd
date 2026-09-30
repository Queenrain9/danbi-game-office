extends Control
var screen="shift_board"; var desk_state="ready"; var selected_order=0; var resolved=0; var adjustments=0
var cloud_pos=Vector2(270,360); var wind_direction=0; var wind_strength=1; var humidity=50; var committed={}
func _ready(): committed=snapshot(); show_screen("shift_board")
func show_screen(id): screen=id; for n in get_children(): if n is Control: n.visible=(n.name==id or n.name=="pause_overlay" and id=="pause_overlay")
func snapshot(): return {"cloud":cloud_pos,"wind_direction":wind_direction,"wind_strength":wind_strength,"humidity":humidity}
func restore(): cloud_pos=committed.cloud; wind_direction=committed.wind_direction; wind_strength=committed.wind_strength; humidity=committed.humidity
func commit_adjustment(): committed=snapshot(); adjustments+=1; desk_state="settling"; await get_tree().create_timer(.25).timeout; desk_state="adjusting"
func state_model(): return {"screen":screen,"desk":desk_state,"resolved":resolved,"adjustments":adjustments}
func rule_model(): return {"shift_orders":3,"adjustment_budget":8,"humidity_step":5,"wind_directions":8,"success":"district targets met"}
func integration_flow(): return ["shift_board","order_brief","weather_desk","order_result","shift_complete"]
func action_shift_board_0(): selected_order=min(resolved+1,3); show_screen("order_brief")
func input_shift_board_0(): action_shift_board_0()
func action_order_brief_0(): adjustments=0; desk_state="adjusting"; committed=snapshot(); show_screen("weather_desk")
func action_order_brief_1(): show_screen("shift_board")
func action_weather_desk_0(pos=Vector2.ZERO): if desk_state=="adjusting": cloud_pos=Vector2(clampf(pos.x,60,480),clampf(pos.y,170,570))
func input_weather_desk_0(pos): action_weather_desk_0(pos)
func action_weather_desk_1(pos=Vector2.ZERO): if desk_state=="adjusting": var a=(pos-Vector2(270,500)).angle(); wind_direction=posmod(roundi(a/(PI/4.0)),8); wind_strength=clampi(roundi(pos.distance_to(Vector2(270,500))/45.0),1,3)
func input_weather_desk_1(pos): action_weather_desk_1(pos)
func action_weather_desk_2(pos=Vector2.ZERO): if desk_state=="adjusting": humidity=clampi(roundi((700-pos.y)/4.0/5.0)*5,0,100)
func input_weather_desk_2(pos): action_weather_desk_2(pos)
func action_weather_desk_3(): if desk_state=="adjusting": desk_state="settling"; await get_tree().create_timer(1.2).timeout; desk_state="adjusting"
func action_weather_desk_4(): if adjustments>0 and desk_state=="adjusting": desk_state="evaluating"; await get_tree().create_timer(.35).timeout; show_screen("order_result")
func action_pause_overlay_0(): show_screen("weather_desk"); desk_state="adjusting"
func action_pause_overlay_1(): restore(); adjustments=0; desk_state="adjusting"; show_screen("weather_desk")
func action_pause_overlay_2(): restore(); show_screen("shift_board")
func action_order_result_0(): adjustments=0; desk_state="adjusting"; show_screen("order_brief")
func action_order_result_1(): resolved+=1; if resolved>=3: show_screen("shift_complete"); else: show_screen("shift_board")
func action_shift_complete_0(): show_screen("shift_board")
func pause_game(): show_screen("pause_overlay")
func _unhandled_input(e):
 if screen!="weather_desk": return
 if e is InputEventScreenDrag:
  var p=e.position
  if get_node("weather_desk/cloud_bank").get_global_rect().has_point(p): action_weather_desk_0(p)
  elif get_node("weather_desk/wind_nozzle").get_global_rect().grow(60).has_point(p): action_weather_desk_1(p)
  elif get_node("weather_desk/humidity_valve").get_global_rect().grow(35).has_point(p): action_weather_desk_2(p)
 if e is InputEventScreenTouch and not e.pressed and desk_state=="adjusting":
  if get_node("weather_desk/cloud_bank").get_global_rect().grow(80).has_point(e.position) or get_node("weather_desk/wind_nozzle").get_global_rect().grow(80).has_point(e.position) or get_node("weather_desk/humidity_valve").get_global_rect().grow(50).has_point(e.position): commit_adjustment()
