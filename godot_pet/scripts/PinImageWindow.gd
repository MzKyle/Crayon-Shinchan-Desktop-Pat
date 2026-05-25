extends Window

signal activated(pin)

const SCREEN_MARGIN := 16

var source_path := ""
var texture_rect: TextureRect
var drag_active := false
var drag_mouse_origin := Vector2i.ZERO
var drag_window_origin := Vector2i.ZERO


func setup(image: Image, path: String, start_position: Vector2i, max_size: Vector2i) -> bool:
	if image.get_width() <= 0 or image.get_height() <= 0:
		return false
	source_path = path
	borderless = true
	always_on_top = true
	unresizable = true
	transparent = true
	exclusive = false
	title = "截图贴图"
	size = _fit_size(image.get_size(), max_size)
	position = _clamp_position(start_position, size)

	texture_rect = TextureRect.new()
	texture_rect.texture = ImageTexture.create_from_image(image)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	texture_rect.gui_input.connect(_on_texture_input)
	add_child(texture_rect)
	return true


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		queue_free()


func _on_texture_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			drag_active = true
			drag_mouse_origin = DisplayServer.mouse_get_position()
			drag_window_origin = position
			emit_signal("activated", self)
		else:
			drag_active = false
		return

	if event is InputEventMouseMotion and drag_active:
		var delta = DisplayServer.mouse_get_position() - drag_mouse_origin
		position = _clamp_position(drag_window_origin + delta, size)
		emit_signal("activated", self)


func _fit_size(image_size: Vector2i, max_size: Vector2i) -> Vector2i:
	var width = image_size.x
	var height = image_size.y
	if width <= max_size.x and height <= max_size.y:
		return image_size
	var scale = min(float(max_size.x) / float(width), float(max_size.y) / float(height))
	return Vector2i(max(1, roundi(width * scale)), max(1, roundi(height * scale)))


func _clamp_position(target: Vector2i, window_size: Vector2i) -> Vector2i:
	var screen = DisplayServer.get_screen_from_rect(Rect2i(target, window_size))
	if screen < 0:
		screen = DisplayServer.window_get_current_screen()
	var screen_rect = Rect2i(
		DisplayServer.screen_get_position(screen),
		DisplayServer.screen_get_size(screen)
	).grow(-SCREEN_MARGIN)
	var max_x = max(screen_rect.position.x, screen_rect.position.x + screen_rect.size.x - window_size.x)
	var max_y = max(screen_rect.position.y, screen_rect.position.y + screen_rect.size.y - window_size.y)
	return Vector2i(
		clampi(target.x, screen_rect.position.x, max_x),
		clampi(target.y, screen_rect.position.y, max_y)
	)
