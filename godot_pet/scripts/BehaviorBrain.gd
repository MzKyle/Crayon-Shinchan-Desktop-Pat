extends Node

signal action_requested(action_name)
signal mischief_requested(kind)

var mode := "安静"
var rng := RandomNumberGenerator.new()
var timer: Timer
var paused := false


func _ready() -> void:
	rng.randomize()
	timer = Timer.new()
	timer.one_shot = true
	timer.timeout.connect(_decide)
	add_child(timer)
	schedule_next()


func set_mode(value: String) -> void:
	if value in ["安静", "活泼", "捣乱"]:
		mode = value
	else:
		mode = "安静"
	if timer != null:
		schedule_next()


func set_paused(value: bool) -> void:
	paused = value


func schedule_next() -> void:
	if mode == "捣乱":
		timer.start(rng.randf_range(20.0, 40.0))
	else:
		timer.start(rng.randf_range(4.0, 8.0))


func _decide() -> void:
	if paused:
		schedule_next()
		return
	if mode == "安静":
		schedule_next()
		return
	if mode == "捣乱":
		emit_signal("mischief_requested", "grab")
		schedule_next()
		return

	var roll = rng.randf()
	if roll < 0.34:
		emit_signal("action_requested", "walk")
	elif roll < 0.52:
		emit_signal("action_requested", "idle")
	elif roll < 0.66:
		emit_signal("action_requested", "edge")
	elif roll < 0.80:
		emit_signal("action_requested", "invite")
	elif mode == "活泼":
		emit_signal("mischief_requested", "footprint")
	schedule_next()
