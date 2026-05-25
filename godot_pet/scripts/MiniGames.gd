extends Node2D

signal feed_success
signal catch_success(count)
signal game_finished(name)

var repo_root := ""
var pet_sprite
var active := ""
var food: Sprite2D
var ball: Sprite2D
var dragging_food := false
var dragging_ball := false
var ball_velocity := Vector2.ZERO
var catch_count := 0


func configure(root: String, pet) -> void:
	repo_root = root
	pet_sprite = pet


func start_feed() -> void:
	clear()
	active = "feed"
	food = _make_sprite("games/rice_ball.png", 58)
	food.position = Vector2(300, 110)
	add_child(food)


func start_catch() -> void:
	clear()
	active = "catch"
	catch_count = 0
	_spawn_ball()


func clear() -> void:
	for child in get_children():
		child.queue_free()
	active = ""
	food = null
	ball = null
	dragging_food = false
	dragging_ball = false
	ball_velocity = Vector2.ZERO


func handle_input(event: InputEvent) -> bool:
	if active == "":
		return false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if food != null and food.get_rect().has_point(food.to_local(event.position)):
				dragging_food = true
				return true
			if ball != null and ball.get_rect().has_point(ball.to_local(event.position)):
				dragging_ball = true
				ball_velocity = Vector2.ZERO
				return true
		else:
			if dragging_food:
				dragging_food = false
				_check_food_hit()
				return true
			if dragging_ball:
				dragging_ball = false
				ball_velocity = (Vector2(210, -340) + (Vector2(210, 130) - ball.position) * 2.8)
				return true
	if event is InputEventMouseMotion:
		if dragging_food and food != null:
			food.position = event.position
			return true
		if dragging_ball and ball != null:
			ball.position = event.position
			return true
	return false


func tick(delta: float) -> void:
	if active != "catch" or ball == null or dragging_ball:
		return
	ball_velocity.y += 900.0 * delta
	ball.position += ball_velocity * delta
	if ball.position.x < 24 or ball.position.x > 396:
		ball_velocity.x *= -0.72
		ball.position.x = clamp(ball.position.x, 24, 396)
	if ball.position.y < 24 or ball.position.y > 236:
		ball_velocity.y *= -0.62
		ball.position.y = clamp(ball.position.y, 24, 236)
	if pet_sprite.pet_rect().has_point(pet_sprite.to_local(ball.global_position)):
		catch_count += 1
		emit_signal("catch_success", catch_count)
		if catch_count >= 3:
			emit_signal("game_finished", "catch")
			clear()
		else:
			_spawn_ball()


func _check_food_hit() -> void:
	if food == null:
		return
	if pet_sprite.mouth_rect().has_point(pet_sprite.to_local(food.global_position)):
		emit_signal("feed_success")
		emit_signal("game_finished", "feed")
		clear()


func _spawn_ball() -> void:
	if ball != null:
		ball.queue_free()
	ball = _make_sprite("games/ball.png", 52)
	ball.position = Vector2(70, 180)
	ball_velocity = Vector2.ZERO
	add_child(ball)


func _make_sprite(relative_path: String, size: int) -> Sprite2D:
	var sprite = Sprite2D.new()
	var texture = _load_texture(relative_path)
	if texture != null:
		sprite.texture = texture
		var texture_size = texture.get_size()
		sprite.scale = Vector2(size / texture_size.x, size / texture_size.y)
	return sprite


func _load_texture(relative_path: String):
	var path = repo_root.path_join("assets").path_join(relative_path)
	if not FileAccess.file_exists(path):
		return null
	var image = Image.new()
	if image.load(path) != OK:
		return null
	return ImageTexture.create_from_image(image)
