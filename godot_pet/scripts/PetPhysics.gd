extends Node

signal landed
signal attached_to_wall(side)
signal bounced

const GRAVITY := 2200.0
const DAMPING := 0.985
const FLOOR_BOUNCE := 0.35
const WALL_BOUNCE := 0.45
const LANDING_SPEED := 90.0

var state := "Idle"
var position := Vector2(1000, 500)
var velocity := Vector2.ZERO
var grab_target := Vector2.ZERO
var wall_side := 0
var gravity_enabled := true


func set_position_from_window(pos: Vector2) -> void:
	position = pos


func set_gravity_enabled(value: bool) -> void:
	gravity_enabled = value
	if not gravity_enabled and (state == "Falling" or state == "Landing"):
		idle()


func begin_grab(target: Vector2) -> void:
	state = "Grabbed"
	grab_target = target
	velocity = Vector2.ZERO


func update_grab(target: Vector2) -> void:
	grab_target = target


func release(release_velocity: Vector2, flinging: bool) -> void:
	velocity = release_velocity
	if flinging:
		state = "Flinging"
	elif not gravity_enabled:
		idle()
	else:
		state = "Falling"
		velocity *= 0.25


func start_walk(direction: int, speed: float) -> void:
	state = "Walk"
	velocity = Vector2(direction * speed, 0)


func attach_to_wall(side: int) -> void:
	state = "WallAttached"
	wall_side = side
	velocity = Vector2.ZERO
	emit_signal("attached_to_wall", side)


func start_edge_walk(speed: float) -> void:
	state = "EdgeWalk"
	velocity = Vector2(0, speed)


func idle() -> void:
	state = "Idle"
	velocity = Vector2.ZERO
	wall_side = 0


func peek() -> void:
	state = "Peeking"
	velocity = Vector2.ZERO
	wall_side = 0


func tick(delta: float, play_area: Rect2, window_size: Vector2, contact_rect := Rect2()) -> void:
	match state:
		"Grabbed":
			var before = position
			position = position.lerp(grab_target, min(1.0, 18.0 * delta))
			velocity = (position - before) / max(delta, 0.001)
		"Flinging", "Falling":
			_tick_air(delta, play_area, window_size, contact_rect)
		"Walk":
			_tick_walk(delta, play_area, window_size, contact_rect)
		"WallAttached", "EdgeWalk":
			_tick_wall(delta, play_area, window_size, contact_rect)
		"Peeking":
			pass


func _tick_air(delta: float, play_area: Rect2, window_size: Vector2, contact_rect: Rect2) -> void:
	if gravity_enabled:
		velocity.y += GRAVITY * delta
	velocity *= pow(DAMPING, delta * 60.0)
	position += velocity * delta

	var horizontal_limits = _horizontal_limits(play_area, window_size, contact_rect)
	var vertical_limits = _vertical_limits(play_area, window_size, contact_rect)
	var left = horizontal_limits.x
	var right = horizontal_limits.y
	var top = vertical_limits.x
	var bottom = vertical_limits.y

	if position.x < left:
		position.x = left
		_hit_wall(1)
	elif position.x > right:
		position.x = right
		_hit_wall(-1)
	if position.y < top:
		position.y = top
		velocity.y = abs(velocity.y) * WALL_BOUNCE
	if position.y > bottom:
		position.y = bottom
		if gravity_enabled and abs(velocity.y) > LANDING_SPEED:
			velocity.y = -abs(velocity.y) * FLOOR_BOUNCE
			velocity.x *= 0.78
			emit_signal("bounced")
		elif gravity_enabled:
			velocity = Vector2.ZERO
			state = "Landing"
			emit_signal("landed")
		else:
			velocity.y = -abs(velocity.y) * WALL_BOUNCE
			emit_signal("bounced")

	if not gravity_enabled and velocity.length() < 18.0:
		idle()


func _tick_walk(delta: float, play_area: Rect2, window_size: Vector2, contact_rect: Rect2) -> void:
	position += velocity * delta
	var horizontal_limits = _horizontal_limits(play_area, window_size, contact_rect)
	var left = horizontal_limits.x
	var right = horizontal_limits.y
	if position.x <= left:
		position.x = left
		velocity.x = abs(velocity.x)
		emit_signal("bounced")
	elif position.x >= right:
		position.x = right
		velocity.x = -abs(velocity.x)
		emit_signal("bounced")


func _tick_wall(delta: float, play_area: Rect2, window_size: Vector2, contact_rect: Rect2) -> void:
	var horizontal_limits = _horizontal_limits(play_area, window_size, contact_rect)
	var left = horizontal_limits.x
	var right = horizontal_limits.y
	if wall_side > 0:
		position.x = left
	elif wall_side < 0:
		position.x = right
	if state == "EdgeWalk":
		position.y += velocity.y * delta
		var vertical_limits = _vertical_limits(play_area, window_size, contact_rect)
		var top = vertical_limits.x
		var bottom = vertical_limits.y
		if position.y <= top or position.y >= bottom:
			velocity.y *= -1.0
			position.y = clamp(position.y, top, bottom)


func _horizontal_limits(play_area: Rect2, window_size: Vector2, contact_rect: Rect2) -> Vector2:
	var contact = _effective_contact_rect(window_size, contact_rect)
	var left = play_area.position.x - contact.position.x
	var right = play_area.position.x + play_area.size.x - contact.position.x - contact.size.x
	if right < left:
		var center = play_area.position.x + (play_area.size.x - window_size.x) * 0.5
		return Vector2(center, center)
	return Vector2(left, right)


func _vertical_limits(play_area: Rect2, window_size: Vector2, contact_rect: Rect2) -> Vector2:
	var contact = _effective_contact_rect(window_size, contact_rect)
	var top = play_area.position.y - contact.position.y
	var bottom = play_area.position.y + play_area.size.y - contact.position.y - contact.size.y
	if bottom < top:
		var center = play_area.position.y + (play_area.size.y - window_size.y) * 0.5
		return Vector2(center, center)
	return Vector2(top, bottom)


func _effective_contact_rect(window_size: Vector2, contact_rect: Rect2) -> Rect2:
	if contact_rect.size.x <= 0.0 or contact_rect.size.y <= 0.0:
		return Rect2(Vector2.ZERO, window_size)
	return contact_rect


func _hit_wall(side: int) -> void:
	if abs(velocity.x) < 520.0 and velocity.y > 120.0:
		attach_to_wall(side)
	else:
		velocity.x = abs(velocity.x) * WALL_BOUNCE * float(side)
		emit_signal("bounced")
