extends Node

var state := {
	"mood": 70,
	"hunger": 60,
	"energy": 80,
	"affection": 30,
}
var state_path := ""


func _ready() -> void:
	state_path = _state_path()
	load_state()


func load_state() -> void:
	if not FileAccess.file_exists(state_path):
		return
	var file = FileAccess.open(state_path, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		for key in state.keys():
			if parsed.has(key):
				state[key] = clamp(int(parsed[key]), 0, 100)


func save_state() -> void:
	var dir = state_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var file = FileAccess.open(state_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(state, "\t"))


func apply(deltas: Dictionary) -> Dictionary:
	var changes := {}
	for key in deltas.keys():
		var before = int(state.get(key, 0))
		var after = clamp(before + int(deltas[key]), 0, 100)
		state[key] = after
		changes[key] = after - before
	save_state()
	return changes


func feed() -> Dictionary:
	return apply({"hunger": -25, "mood": 5, "affection": 3})


func pet() -> Dictionary:
	return apply({"mood": 4, "affection": 6})


func poke() -> Dictionary:
	return apply({"mood": -1, "affection": 1})


func play() -> Dictionary:
	return apply({"mood": 12, "affection": 6, "energy": -8, "hunger": 4})


func sleep_tick() -> Dictionary:
	return apply({"energy": 6, "mood": 1})


func _state_path() -> String:
	var home = OS.get_environment("HOME")
	if home == "":
		return "user://state.json"
	return home.path_join(".config").path_join("crayon-shinchan-desktop-pet").path_join("state.json")
