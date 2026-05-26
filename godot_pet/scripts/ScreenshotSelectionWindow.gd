extends Window

signal selection_finished(accepted, image)

class SelectionLayer:
	extends Control

	signal selection_chosen(rect)
	signal selection_cancelled

	var dragging := false
	var drag_start := Vector2.ZERO
	var drag_end := Vector2.ZERO


	func _ready() -> void:
		focus_mode = Control.FOCUS_ALL
		mouse_filter = Control.MOUSE_FILTER_STOP


	func reset() -> void:
		dragging = false
		drag_start = Vector2.ZERO
		drag_end = Vector2.ZERO
		queue_redraw()


	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					dragging = true
					drag_start = event.position
					drag_end = event.position
					queue_redraw()
				else:
					if dragging:
						dragging = false
						drag_end = event.position
						var rect = _selection_rect()
						if rect.size.x >= 4.0 and rect.size.y >= 4.0:
							emit_signal("selection_chosen", rect)
						else:
							emit_signal("selection_cancelled")
						queue_redraw()
			elif event.pressed and event.button_index in [MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
				emit_signal("selection_cancelled")
		elif event is InputEventMouseMotion and dragging:
			drag_end = event.position
			queue_redraw()


	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.22), true)
		if not dragging:
			return
		var rect = _selection_rect()
		draw_rect(rect, Color(1, 1, 1, 0.16), true)
		draw_rect(rect, Color(1, 1, 1, 0.96), false, 2.0)


	func _selection_rect() -> Rect2:
		var min_pos = Vector2(min(drag_start.x, drag_end.x), min(drag_start.y, drag_end.y))
		var max_pos = Vector2(max(drag_start.x, drag_end.x), max(drag_start.y, drag_end.y))
		return Rect2(min_pos, max_pos - min_pos)


var capture_image: Image
var screen_rect := Rect2i()
var texture_rect: TextureRect
var layer: SelectionLayer


func _ready() -> void:
	title = "选择截图区域"
	borderless = true
	always_on_top = true
	unresizable = true
	close_requested.connect(_cancel)
	_ensure_ui()


func open_with_capture(image: Image, rect: Rect2i) -> void:
	_ensure_ui()
	capture_image = image
	screen_rect = rect
	size = rect.size
	position = rect.position
	texture_rect.texture = ImageTexture.create_from_image(image)
	layer.reset()
	show()
	grab_focus()
	if layer.is_inside_tree():
		layer.grab_focus()
	else:
		layer.call_deferred("grab_focus")


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_cancel()
			get_viewport().set_input_as_handled()


func _ensure_ui() -> void:
	if texture_rect != null and layer != null:
		return
	texture_rect = TextureRect.new()
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(texture_rect)

	layer = SelectionLayer.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.selection_chosen.connect(_accept_selection)
	layer.selection_cancelled.connect(_cancel)
	add_child(layer)


func _accept_selection(rect: Rect2) -> void:
	if capture_image == null:
		_cancel()
		return
	var clipped = rect.intersection(Rect2(Vector2.ZERO, Vector2(screen_rect.size)))
	if clipped.size.x < 1.0 or clipped.size.y < 1.0:
		_cancel()
		return

	var scale_x = float(capture_image.get_width()) / float(max(1, screen_rect.size.x))
	var scale_y = float(capture_image.get_height()) / float(max(1, screen_rect.size.y))
	var source = Rect2i(
		Vector2i(roundi(clipped.position.x * scale_x), roundi(clipped.position.y * scale_y)),
		Vector2i(roundi(clipped.size.x * scale_x), roundi(clipped.size.y * scale_y))
	)
	source.position.x = clampi(source.position.x, 0, max(0, capture_image.get_width() - 1))
	source.position.y = clampi(source.position.y, 0, max(0, capture_image.get_height() - 1))
	source.size.x = clampi(source.size.x, 1, capture_image.get_width() - source.position.x)
	source.size.y = clampi(source.size.y, 1, capture_image.get_height() - source.position.y)

	var crop = capture_image.get_region(source)
	hide()
	emit_signal("selection_finished", true, crop)


func _cancel() -> void:
	hide()
	emit_signal("selection_finished", false, null)
