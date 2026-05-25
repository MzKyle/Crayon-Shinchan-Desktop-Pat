extends Node

signal single_clicked(local_pos)
signal double_clicked
signal right_clicked(local_pos)
signal wheel_used
signal grab_started(global_pos)
signal grab_moved(global_pos)
signal grab_released(velocity, held, global_pos)

const LONG_PRESS_SECONDS := 0.35
const FLING_SAMPLE_COUNT := 10

var is_pressed := false
var is_grabbed := false
var was_held := false
var press_time := 0.0
var press_local := Vector2.ZERO
var samples := []
var click_timer: Timer
var long_timer: Timer


func _ready() -> void:
	click_timer = Timer.new()
	click_timer.one_shot = true
	click_timer.wait_time = 0.16
	click_timer.timeout.connect(_emit_single_click)
	add_child(click_timer)

	long_timer = Timer.new()
	long_timer.one_shot = true
	long_timer.wait_time = LONG_PRESS_SECONDS
	long_timer.timeout.connect(_begin_grab)
	add_child(long_timer)


func handle_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return _handle_button(event)
	if event is InputEventMouseMotion:
		return _handle_motion(event)
	return false


func _process(_delta: float) -> void:
	if not is_pressed:
		return
	var point = DisplayServer.mouse_get_position()
	_add_sample(point)
	if is_grabbed:
		emit_signal("grab_moved", point)
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_finish_left_release(point)


func _handle_button(event: InputEventMouseButton) -> bool:
	if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		emit_signal("right_clicked", event.position)
		return true
	if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		if event.pressed:
			emit_signal("wheel_used")
		return true
	if event.button_index != MOUSE_BUTTON_LEFT:
		return false

	if event.pressed:
		if event.double_click:
			click_timer.stop()
			long_timer.stop()
			emit_signal("double_clicked")
			return true
		is_pressed = true
		is_grabbed = false
		was_held = false
		press_time = Time.get_ticks_msec() / 1000.0
		press_local = event.position
		samples = []
		_add_sample(DisplayServer.mouse_get_position())
		long_timer.start()
		return true

	_finish_left_release(DisplayServer.mouse_get_position())
	return true


func _handle_motion(_event: InputEventMouseMotion) -> bool:
	if not is_pressed:
		return false
	_add_sample(DisplayServer.mouse_get_position())
	if is_grabbed:
		emit_signal("grab_moved", DisplayServer.mouse_get_position())
	return true


func _begin_grab() -> void:
	if not is_pressed:
		return
	is_grabbed = true
	was_held = true
	emit_signal("grab_started", DisplayServer.mouse_get_position())


func _emit_single_click() -> void:
	emit_signal("single_clicked", press_local)


func _add_sample(point: Vector2) -> void:
	samples.append({"t": Time.get_ticks_msec() / 1000.0, "p": point})
	while samples.size() > FLING_SAMPLE_COUNT:
		samples.pop_front()


func _release_velocity() -> Vector2:
	if samples.size() < 2:
		return Vector2.ZERO
	var last = samples[samples.size() - 1]
	for i in range(samples.size() - 2, -1, -1):
		var previous = samples[i]
		var dt = max(0.001, float(last["t"]) - float(previous["t"]))
		if dt >= 0.04 or i == 0:
			return (Vector2(last["p"]) - Vector2(previous["p"])) / dt
	return Vector2.ZERO


func _finish_left_release(point: Vector2) -> void:
	if not is_pressed:
		return
	long_timer.stop()
	if is_grabbed:
		_add_sample(point)
		emit_signal("grab_released", _release_velocity(), was_held, point)
	else:
		click_timer.start()
	is_pressed = false
	is_grabbed = false
