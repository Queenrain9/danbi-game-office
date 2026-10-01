extends Control
class_name ParcelCaseRouter

const CASES := [
	{"id":"P01","label":"CERAMIC PARTS","metal_dense":false,"padding":true,"edge_distance_percent":50.0,"dense_objects":0,"cable_connected":false,"power_cell_contact":false,"reason":"No hazard condition is present; PASS."},
	{"id":"P02","label":"MOTOR HOUSING","metal_dense":true,"padding":false,"edge_distance_percent":7.0,"dense_objects":1,"cable_connected":false,"power_cell_contact":false,"reason":"Dense metal lies within 10% of the wall without padding; REPACK."},
	{"id":"P03","label":"POWER MODULE","metal_dense":true,"padding":true,"edge_distance_percent":25.0,"dense_objects":2,"cable_connected":true,"power_cell_contact":true,"reason":"Two dense objects are cable-linked and contact a power cell; ISOLATE."},
	{"id":"P04","label":"TEXTILE SAMPLE","metal_dense":false,"padding":false,"edge_distance_percent":60.0,"dense_objects":0,"cable_connected":false,"power_cell_contact":false,"reason":"No hazard condition is present; PASS."},
	{"id":"P05","label":"BEARING KIT","metal_dense":true,"padding":false,"edge_distance_percent":9.0,"dense_objects":1,"cable_connected":false,"power_cell_contact":false,"reason":"Unpadded dense metal is too close to the outer wall; REPACK."},
	{"id":"P06","label":"BATTERY HARNESS","metal_dense":true,"padding":true,"edge_distance_percent":20.0,"dense_objects":2,"cable_connected":true,"power_cell_contact":true,"reason":"Cable-linked dense parts contact the power cell; ISOLATE."},
	{"id":"P07","label":"GLASS FIXTURE","metal_dense":false,"padding":true,"edge_distance_percent":30.0,"dense_objects":0,"cable_connected":false,"power_cell_contact":false,"reason":"No hazard condition is present; PASS."},
	{"id":"P08","label":"STEEL BRACKET","metal_dense":true,"padding":false,"edge_distance_percent":5.0,"dense_objects":1,"cable_connected":false,"power_cell_contact":false,"reason":"Dense metal is unpadded and within the 10% wall margin; REPACK."},
	{"id":"P09","label":"SENSOR ARRAY","metal_dense":true,"padding":true,"edge_distance_percent":35.0,"dense_objects":2,"cable_connected":true,"power_cell_contact":true,"reason":"Connected dense objects touch a power cell; ISOLATE."},
	{"id":"P10","label":"FOAM FILTERS","metal_dense":false,"padding":true,"edge_distance_percent":45.0,"dense_objects":0,"cable_connected":false,"power_cell_contact":false,"reason":"No hazard condition is present; PASS."}
]

func case_for_shift(index: int) -> Dictionary:
	return CASES[index % 8].duplicate(true)

func shift_case_count() -> int:
	return 8

func available_case_count() -> int:
	return CASES.size()
