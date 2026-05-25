extends Node2D

const PetSpriteScript = preload("res://scripts/PetSprite.gd")
const PetPhysicsScript = preload("res://scripts/PetPhysics.gd")
const InteractionScript = preload("res://scripts/InteractionController.gd")
const BehaviorBrainScript = preload("res://scripts/BehaviorBrain.gd")
const MiniGamesScript = preload("res://scripts/MiniGames.gd")
const StateStoreScript = preload("res://scripts/StateStore.gd")

const MENU_WALK := 1
const MENU_FEED := 2
const MENU_SLEEP := 3
const MENU_WAKE := 4
const MENU_CATCH := 5
const MENU_SCALE_100 := 10
const MENU_SCALE_125 := 11
const MENU_SCALE_150 := 12
const MENU_QUIET := 20
const MENU_ACTIVE := 21
const MENU_MISCHIEF := 22
const MENU_CLEAR := 30
const MENU_TOGGLE_GRAVITY := 40
const MENU_EXIT_PEEK := 41
const MENU_EXIT := 99

const HIDE_EDGE_THRESHOLD := 52.0
const PEEK_WINDOW_SIZE := Vector2i(112, 140)
const MISCHIEF_GRAB_SECONDS := 4.0
const MISCHIEF_STOP_SIZE := Vector2(44, 30)

var repo_root := ""
var manifest := {}
var pet_sprite
var physics
var interaction
var brain
var mini_games
var state_store
var popup: PopupMenu
var bubble: Label
var bubble_timer: Timer
var peek_sprite: Sprite2D
var peek_textures := {}
var display_scale := 1.0
var drag_offset := Vector2.ZERO
var landing_squash := 0.0
var rng := RandomNumberGenerator.new()
var mischief_nodes := []
var transparent_window := false
var mouse_passthrough_enabled := false
var gravity_enabled := true
var peek_mode := false
var peek_edge := ""
var behavior_mode := "安静"
var mischief_grab_active := false
var mischief_grab_timer: Timer
var mischief_stop_button: Button
var mischief_cursor_local := Vector2.ZERO
var mischief_elapsed := 0.0


func _ready() -> void:
	rng.randomize()
	repo_root = _resolve_repo_root()
	manifest = _load_json("res://assets/actions.json")
	_configure_window()
	_create_nodes()
	_sync_window_size(true)
	physics.set_position_from_window(Vector2(get_window().position))
	physics.set_gravity_enabled(gravity_enabled)
	pet_sprite.play("idle")
	if transparent_window:
		show_bubble("透明桌宠模式启动。")
	else:
		show_bubble("Godot 安全窗口模式启动。")


func _input(event: InputEvent) -> void:
	if mischief_grab_active:
		if event is InputEventMouseButton and event.pressed and _mischief_stop_rect().has_point(event.position):
			_stop_mischief_grab()
		return
	if mini_games != null and mini_games.handle_input(event):
		return
	if interaction != null and interaction.handle_input(event):
		return


func _process(delta: float) -> void:
	pet_sprite.update_animation(delta)
	if mischief_grab_active:
		_tick_mischief_grab(delta)
		_update_pet_pose(delta)
		queue_redraw()
		return
	mini_games.tick(delta)
	physics.tick(delta, _play_area(), Vector2(get_window().size), _movement_contact_rect())
	_sync_walk_animation_to_velocity()
	get_window().position = Vector2i(round(physics.position.x), round(physics.position.y))
	_update_pet_pose(delta)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()


func _draw() -> void:
	if not mischief_grab_active:
		return
	var t = mischief_elapsed
	var hand_a = pet_sprite.position + Vector2(28, -8).rotated(pet_sprite.sprite.rotation)
	var hand_b = pet_sprite.position + Vector2(46, 10).rotated(pet_sprite.sprite.rotation)
	var pull = mischief_cursor_local
	var wobble = Vector2(sin(t * 31.0) * 3.0, cos(t * 27.0) * 2.0)
	draw_line(hand_a, pull + wobble, Color(0.98, 0.72, 0.18, 0.92), 3.0)
	draw_line(hand_b, pull - wobble, Color(0.95, 0.42, 0.18, 0.8), 2.0)
	draw_arc(pull, 13.0 + sin(t * 18.0) * 2.0, -0.8, 2.9, 18, Color(0.2, 0.22, 0.25, 0.65), 2.0)
	for i in range(3):
		var phase = t * 4.4 + float(i) * 1.7
		var drop = pet_sprite.position + Vector2(-38 + i * 16, -62 - abs(sin(phase)) * 12)
		draw_circle(drop, 3.5 + float(i) * 0.4, Color(0.35, 0.72, 1.0, 0.82))


func _configure_window() -> void:
	var window = get_window()
	var safe_window = _env_flag("CRAYON_PET_SAFE_WINDOW", false)
	transparent_window = _env_flag("CRAYON_PET_TRANSPARENT", true) and not safe_window
	mouse_passthrough_enabled = _env_flag("CRAYON_PET_MOUSE_PASSTHROUGH", true)
	window.borderless = _env_flag("CRAYON_PET_BORDERLESS", transparent_window)
	window.always_on_top = _env_flag("CRAYON_PET_ALWAYS_ON_TOP", transparent_window)
	window.transparent = transparent_window
	window.unresizable = true
	get_viewport().transparent_bg = transparent_window
	if transparent_window:
		RenderingServer.set_default_clear_color(Color(0, 0, 0, 0))
	else:
		RenderingServer.set_default_clear_color(Color(0.96, 0.94, 0.88, 1))


func _create_nodes() -> void:
	state_store = StateStoreScript.new()
	add_child(state_store)

	physics = PetPhysicsScript.new()
	add_child(physics)
	physics.landed.connect(_on_landed)
	physics.bounced.connect(_on_bounced)
	physics.attached_to_wall.connect(_on_attached_to_wall)

	pet_sprite = PetSpriteScript.new()
	add_child(pet_sprite)
	pet_sprite.configure(repo_root, manifest)
	pet_sprite.action_finished.connect(_on_action_finished)

	peek_sprite = Sprite2D.new()
	peek_sprite.centered = false
	peek_sprite.visible = false
	add_child(peek_sprite)
	_load_peek_textures()

	mini_games = MiniGamesScript.new()
	add_child(mini_games)
	mini_games.configure(repo_root, pet_sprite)
	mini_games.feed_success.connect(_on_feed_success)
	mini_games.catch_success.connect(_on_catch_success)
	mini_games.game_finished.connect(_on_game_finished)

	interaction = InteractionScript.new()
	add_child(interaction)
	interaction.single_clicked.connect(_on_single_clicked)
	interaction.double_clicked.connect(_on_double_clicked)
	interaction.right_clicked.connect(_on_right_clicked)
	interaction.wheel_used.connect(_show_status)
	interaction.grab_started.connect(_on_grab_started)
	interaction.grab_moved.connect(_on_grab_moved)
	interaction.grab_released.connect(_on_grab_released)

	brain = BehaviorBrainScript.new()
	add_child(brain)
	brain.action_requested.connect(_on_behavior_action)
	brain.mischief_requested.connect(_on_mischief)
	brain.set_mode(behavior_mode)

	popup = PopupMenu.new()
	add_child(popup)
	popup.id_pressed.connect(_on_menu_id_pressed)

	mischief_grab_timer = Timer.new()
	mischief_grab_timer.one_shot = true
	mischief_grab_timer.timeout.connect(_stop_mischief_grab)
	add_child(mischief_grab_timer)

	mischief_stop_button = Button.new()
	mischief_stop_button.text = "停"
	mischief_stop_button.visible = false
	mischief_stop_button.focus_mode = Control.FOCUS_NONE
	mischief_stop_button.pressed.connect(_stop_mischief_grab)
	add_child(mischief_stop_button)

	bubble = Label.new()
	bubble.visible = false
	bubble.add_theme_font_size_override("font_size", 15)
	bubble.add_theme_color_override("font_color", Color(0.12, 0.1, 0.08))
	bubble.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.8))
	bubble.add_theme_constant_override("shadow_offset_x", 1)
	bubble.add_theme_constant_override("shadow_offset_y", 1)
	add_child(bubble)
	bubble_timer = Timer.new()
	bubble_timer.one_shot = true
	bubble_timer.timeout.connect(func(): bubble.visible = false)
	add_child(bubble_timer)


func _sync_window_size(keep_position := false) -> void:
	var window = get_window()
	var old_center = Vector2(window.position) + Vector2(window.size) * 0.5
	var desired = PEEK_WINDOW_SIZE if peek_mode else pet_sprite.window_size()
	if mini_games != null and mini_games.active != "":
		desired.x = max(desired.x, 420)
		desired.y = max(desired.y, 260)
	window.size = desired
	if keep_position:
		window.position = Vector2i(old_center - Vector2(desired) * 0.5)
	pet_sprite.position = Vector2(desired) * 0.5
	mini_games.position = Vector2.ZERO
	bubble.position = Vector2(20, 14)
	_position_mischief_stop_button()
	_update_mouse_passthrough()


func _update_pet_pose(delta: float) -> void:
	if peek_mode:
		_apply_peek_pose()
		return
	if mischief_grab_active:
		_apply_mischief_grab_pose(delta)
		return
	pet_sprite.position = Vector2(get_window().size) * 0.5
	if landing_squash > 0.0:
		landing_squash = max(0.0, landing_squash - delta * 3.2)
		pet_sprite.squash(landing_squash)
	elif physics.state == "Flinging" or physics.state == "Falling":
		pet_sprite.lean_from_velocity(physics.velocity)
	elif physics.state == "Grabbed":
		pet_sprite.sprite.rotation = sin(Time.get_ticks_msec() / 90.0) * 0.10
	elif physics.state == "WallAttached" or physics.state == "EdgeWalk":
		_apply_wall_walk_pose()
	else:
		pet_sprite.reset_transform()


func _play_area() -> Rect2:
	var screen = DisplayServer.window_get_current_screen()
	return Rect2(
		Vector2(DisplayServer.screen_get_position(screen)),
		Vector2(DisplayServer.screen_get_size(screen))
	)


func _movement_contact_rect() -> Rect2:
	var window_size = Vector2(get_window().size)
	if peek_mode or pet_sprite == null:
		return Rect2(Vector2.ZERO, window_size)
	if mini_games != null and mini_games.active != "":
		return Rect2(Vector2.ZERO, window_size)

	var rect = _pet_visible_rect_for_physics()
	return Rect2(pet_sprite.position + rect.position, rect.size)


func _pet_visible_rect_for_physics() -> Rect2:
	if physics == null:
		return pet_sprite.visible_rect()
	if (physics.state == "WallAttached" or physics.state == "EdgeWalk") and physics.wall_side != 0:
		var rotation = PI * 0.5 if physics.wall_side > 0 else -PI * 0.5
		return pet_sprite.visible_rect_for_rotation(rotation)
	if physics.state == "Flinging" or physics.state == "Falling":
		var rotation = clamp(physics.velocity.x / 1800.0, -0.35, 0.35)
		return pet_sprite.visible_rect_for_rotation(rotation)
	return pet_sprite.visible_rect_for_rotation(0.0)


func _on_single_clicked(local_pos: Vector2) -> void:
	if physics.state == "Grabbed":
		return
	if peek_mode:
		_exit_peek_mode(true)
		return
	var pet_local = pet_sprite.to_local(local_pos)
	if pet_local.y < pet_sprite.pet_rect().position.y + pet_sprite.pet_rect().size.y * 0.42:
		var changes = state_store.pet()
		show_bubble("摸摸头。" + _format_changes(changes))
		_spawn_heart()
	else:
		var changes = state_store.poke()
		show_bubble("戳到了。" + _format_changes(changes))
		_jiggle()


func _on_double_clicked() -> void:
	if peek_mode:
		_exit_peek_mode(true)
	mini_games.start_catch()
	_sync_window_size(true)
	_update_mouse_passthrough()
	show_bubble("接球挑战开始。")


func _on_right_clicked(_local_pos: Vector2) -> void:
	_show_menu()


func _on_grab_started(global_pos: Vector2) -> void:
	if peek_mode:
		_exit_peek_mode(false)
	brain.set_paused(true)
	drag_offset = get_viewport().get_mouse_position()
	physics.begin_grab(global_pos - drag_offset)
	pet_sprite.play("idle")
	show_bubble("抱起来啦。")


func _on_grab_moved(global_pos: Vector2) -> void:
	physics.update_grab(global_pos - drag_offset)


func _on_grab_released(velocity: Vector2, held: bool, global_pos: Vector2) -> void:
	var speed = velocity.length()
	brain.set_paused(false)
	var hide_edge = _hide_edge_for_release(global_pos)
	if held and hide_edge != "":
		_enter_peek_mode(hide_edge)
		return
	if speed > 420.0:
		physics.release(velocity, true)
		pet_sprite.play("fall")
		show_bubble("飞出去啦！")
	else:
		physics.release(velocity, false)
		if held:
			show_bubble("轻轻放下。")


func _on_landed() -> void:
	landing_squash = 0.25
	show_bubble("落地。")
	await get_tree().create_timer(0.45).timeout
	physics.idle()
	pet_sprite.play("idle")


func _on_bounced() -> void:
	landing_squash = 0.12
	_sync_walk_animation_to_velocity()


func _on_attached_to_wall(side: int) -> void:
	_play_wall_walk_action()
	show_bubble("贴到边边了。")


func _on_action_finished(next_action: String) -> void:
	if next_action != "":
		pet_sprite.play(next_action)
		_sync_window_size(true)


func _on_behavior_action(action_name: String) -> void:
	if _busy():
		return
	match action_name:
		"walk":
			var dir = -1 if rng.randf() < 0.5 else 1
			physics.start_walk(dir, 95.0)
			_sync_walk_animation_to_velocity(true)
		"idle":
			physics.idle()
			pet_sprite.play("idle")
		"edge":
			var side = -1 if rng.randf() < 0.5 else 1
			physics.attach_to_wall(side)
			physics.start_edge_walk(70.0 if rng.randf() < 0.5 else -70.0)
			_play_wall_walk_action()
		"invite":
			show_bubble("要不要玩一会儿？")


func _on_mischief(kind: String) -> void:
	if kind == "grab":
		_start_mischief_grab()
	elif kind == "note":
		_spawn_note()
	else:
		_spawn_footprint()


func _on_feed_success() -> void:
	var changes = state_store.feed()
	pet_sprite.play("eat")
	_sync_window_size(true)
	show_bubble("吃到啦。" + _format_changes(changes))


func _on_catch_success(count: int) -> void:
	var changes = state_store.play()
	show_bubble("接住 %d/3。%s" % [count, _format_changes(changes)])


func _on_game_finished(name: String) -> void:
	if name == "catch":
		show_bubble("接球完成！")
	call_deferred("_sync_window_size", true)
	_spawn_heart()


func _show_status() -> void:
	var s = state_store.state
	show_bubble("心情 %d / 饥饿 %d / 体力 %d / 亲密 %d" % [s["mood"], s["hunger"], s["energy"], s["affection"]], 3.0)


func _show_menu() -> void:
	popup.clear()
	popup.add_item("散步", MENU_WALK)
	popup.add_item("饭团投喂", MENU_FEED)
	popup.add_item("睡觉", MENU_SLEEP)
	popup.add_item("唤醒", MENU_WAKE)
	popup.add_item("接球挑战", MENU_CATCH)
	popup.add_separator()
	popup.add_item("显示大小 100%", MENU_SCALE_100)
	popup.add_item("显示大小 125%", MENU_SCALE_125)
	popup.add_item("显示大小 150%", MENU_SCALE_150)
	popup.add_separator()
	popup.add_item("关闭重力：悬浮" if gravity_enabled else "开启重力：落地", MENU_TOGGLE_GRAVITY)
	if peek_mode:
		popup.add_item("出来", MENU_EXIT_PEEK)
	popup.add_separator()
	popup.add_check_item("安静模式", MENU_QUIET)
	popup.add_check_item("活泼模式", MENU_ACTIVE)
	popup.add_check_item("捣乱模式", MENU_MISCHIEF)
	_sync_behavior_menu_checks()
	popup.add_item("清理捣乱物", MENU_CLEAR)
	popup.add_separator()
	popup.add_item("退出", MENU_EXIT)
	popup.popup(Rect2i(DisplayServer.mouse_get_position(), Vector2i(1, 1)))


func _on_menu_id_pressed(id: int) -> void:
	match id:
		MENU_WALK:
			_on_behavior_action("walk")
		MENU_FEED:
			mini_games.start_feed()
			_sync_window_size(true)
			_update_mouse_passthrough()
		MENU_SLEEP:
			pet_sprite.play("sleep")
			physics.idle()
			state_store.sleep_tick()
			_sync_window_size(true)
		MENU_WAKE:
			pet_sprite.play("wake")
			_sync_window_size(true)
		MENU_CATCH:
			mini_games.start_catch()
			_sync_window_size(true)
			_update_mouse_passthrough()
		MENU_SCALE_100:
			_set_display_scale(1.0)
		MENU_SCALE_125:
			_set_display_scale(1.25)
		MENU_SCALE_150:
			_set_display_scale(1.5)
		MENU_TOGGLE_GRAVITY:
			_set_gravity_enabled(not gravity_enabled)
		MENU_EXIT_PEEK:
			_exit_peek_mode(true)
		MENU_QUIET:
			_set_behavior_mode("安静")
		MENU_ACTIVE:
			_set_behavior_mode("活泼")
		MENU_MISCHIEF:
			_set_behavior_mode("捣乱")
		MENU_CLEAR:
			_clear_mischief()
		MENU_EXIT:
			get_tree().quit()


func _set_behavior_mode(value: String, announce := true) -> void:
	var next_mode = value if value in ["安静", "活泼", "捣乱"] else "安静"
	behavior_mode = next_mode
	if brain != null:
		brain.set_mode(next_mode)
	_sync_behavior_menu_checks()
	if next_mode != "捣乱":
		_stop_mischief_grab(false)
	if announce:
		show_bubble("%s模式。" % next_mode)


func _sync_behavior_menu_checks() -> void:
	if popup == null:
		return
	var ids = [MENU_QUIET, MENU_ACTIVE, MENU_MISCHIEF]
	var modes = {
		MENU_QUIET: "安静",
		MENU_ACTIVE: "活泼",
		MENU_MISCHIEF: "捣乱",
	}
	for item_id in ids:
		var index = popup.get_item_index(item_id)
		if index >= 0:
			popup.set_item_checked(index, modes[item_id] == behavior_mode)


func _set_display_scale(scale: float) -> void:
	display_scale = scale
	pet_sprite.set_display_scale(scale)
	_sync_window_size(true)
	_update_mouse_passthrough()
	show_bubble("显示大小 %d%%" % int(scale * 100))


func _set_gravity_enabled(value: bool) -> void:
	gravity_enabled = value
	physics.set_gravity_enabled(value)
	if value:
		if not peek_mode and physics.state != "Grabbed":
			physics.release(Vector2.ZERO, false)
		show_bubble("重力开启，会落地。")
	else:
		show_bubble("重力关闭，悬浮模式。")


func _start_mischief_grab() -> void:
	if behavior_mode != "捣乱" or _busy():
		return
	mischief_grab_active = true
	mischief_elapsed = 0.0
	mischief_cursor_local = get_viewport().get_mouse_position()
	brain.set_paused(true)
	physics.idle()
	if not pet_sprite.play("mischief_grab"):
		pet_sprite.play("idle")
	_sync_window_size(true)
	_position_mischief_stop_button()
	mischief_stop_button.visible = true
	mischief_grab_timer.start(MISCHIEF_GRAB_SECONDS)
	show_bubble("嘿嘿，鼠标借我一下。", 1.25)
	_tick_mischief_grab(0.0)
	_update_mouse_passthrough()


func _stop_mischief_grab(announce := true) -> void:
	if not mischief_grab_active:
		return
	mischief_grab_active = false
	mischief_grab_timer.stop()
	mischief_stop_button.visible = false
	brain.set_paused(false)
	physics.set_position_from_window(Vector2(get_window().position))
	physics.idle()
	pet_sprite.play("idle")
	pet_sprite.reset_transform()
	_sync_window_size(true)
	_update_mouse_passthrough()
	queue_redraw()
	if announce:
		show_bubble("好吧，还给你。")


func _tick_mischief_grab(delta: float) -> void:
	mischief_elapsed += delta
	var window = get_window()
	var window_size = Vector2(window.size)
	var mouse = Vector2(DisplayServer.mouse_get_position())
	var offset = Vector2(-window_size.x * 0.28, window_size.y * 0.22)
	var shake = Vector2(sin(mischief_elapsed * 34.0) * 4.0, cos(mischief_elapsed * 29.0) * 3.0)
	physics.position = _clamp_window_position(mouse - window_size * 0.5 + offset + shake, window_size)
	window.position = Vector2i(round(physics.position.x), round(physics.position.y))
	mischief_cursor_local = mouse - physics.position
	_position_mischief_stop_button()
	_update_mouse_passthrough()


func _apply_mischief_grab_pose(_delta: float) -> void:
	var base = Vector2(get_window().size) * 0.5
	var shake = Vector2(sin(mischief_elapsed * 42.0) * 4.5, cos(mischief_elapsed * 37.0) * 2.5)
	pet_sprite.position = base + shake
	pet_sprite.sprite.rotation = -0.08 + sin(mischief_elapsed * 24.0) * 0.075
	pet_sprite.sprite.scale = pet_sprite._base_sprite_scale() * Vector2(1.04, 0.98)
	bubble.position = Vector2(16, 48)


func _clamp_window_position(pos: Vector2, window_size: Vector2) -> Vector2:
	var area = _play_area()
	var max_x = area.position.x + area.size.x - window_size.x
	var max_y = area.position.y + area.size.y - window_size.y
	if max_x < area.position.x:
		max_x = area.position.x
	if max_y < area.position.y:
		max_y = area.position.y
	return Vector2(
		clamp(pos.x, area.position.x, max_x),
		clamp(pos.y, area.position.y, max_y)
	)


func _position_mischief_stop_button() -> void:
	if mischief_stop_button == null:
		return
	var size = Vector2(get_window().size)
	mischief_stop_button.size = MISCHIEF_STOP_SIZE
	mischief_stop_button.position = Vector2(size.x - MISCHIEF_STOP_SIZE.x - 12.0, 12.0)


func _mischief_stop_rect() -> Rect2:
	if mischief_stop_button == null:
		return Rect2(Vector2.ZERO, MISCHIEF_STOP_SIZE)
	return Rect2(mischief_stop_button.position, mischief_stop_button.size)


func _sync_walk_animation_to_velocity(force := false) -> void:
	if physics == null or pet_sprite == null:
		return
	if physics.state != "Walk":
		return
	if abs(physics.velocity.x) < 1.0:
		return
	var desired = "walk_right" if physics.velocity.x > 0.0 else "walk_left"
	if force or pet_sprite.current_action != desired:
		pet_sprite.play(desired)


func _play_wall_walk_action() -> void:
	var desired = _wall_walk_action()
	if pet_sprite.current_action != desired:
		pet_sprite.play(desired)


func _apply_wall_walk_pose() -> void:
	if physics.wall_side == 0:
		return
	_play_wall_walk_action()
	pet_sprite.sprite.scale = pet_sprite._base_sprite_scale()
	if physics.wall_side > 0:
		pet_sprite.sprite.rotation = PI * 0.5
	else:
		pet_sprite.sprite.rotation = -PI * 0.5


func _wall_walk_action() -> String:
	if abs(physics.velocity.y) < 1.0:
		return "walk_right" if physics.wall_side > 0 else "walk_left"
	if physics.wall_side > 0:
		return "walk_right" if physics.velocity.y > 0.0 else "walk_left"
	return "walk_left" if physics.velocity.y > 0.0 else "walk_right"


func show_bubble(text: String, seconds := 1.8) -> void:
	bubble.text = text
	bubble.visible = true
	bubble_timer.start(seconds)


func _spawn_heart() -> void:
	var heart = _temporary_sprite("effects/heart.png", 38)
	if heart != null:
		heart.position = pet_sprite.position + Vector2(rng.randf_range(-35, 35), -76)


func _spawn_note() -> void:
	var label = Label.new()
	label.text = "小新路过：嘿嘿。"
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.18, 0.15, 0.08))
	label.position = Vector2(rng.randi_range(18, 220), rng.randi_range(36, 170))
	add_child(label)
	mischief_nodes.append(label)
	_auto_remove(label, 5.0)


func _spawn_footprint() -> void:
	var label = Label.new()
	label.text = "・ ・ ・"
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(0.12, 0.1, 0.08, 0.45))
	label.position = Vector2(rng.randi_range(20, 330), rng.randi_range(160, 220))
	add_child(label)
	mischief_nodes.append(label)
	_auto_remove(label, 3.6)


func _temporary_sprite(relative_path: String, size: int):
	var path = repo_root.path_join("assets").path_join(relative_path)
	if not FileAccess.file_exists(path):
		return null
	var image = Image.new()
	if image.load(path) != OK:
		return null
	var texture = ImageTexture.create_from_image(image)
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2(size / texture.get_size().x, size / texture.get_size().y)
	add_child(sprite)
	mischief_nodes.append(sprite)
	_auto_remove(sprite, 1.2)
	return sprite


func _auto_remove(node: Node, seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
	if is_instance_valid(node):
		mischief_nodes.erase(node)
		node.queue_free()


func _clear_mischief() -> void:
	for node in mischief_nodes:
		if is_instance_valid(node):
			node.queue_free()
	mischief_nodes.clear()
	show_bubble("清理完成。")


func _update_mouse_passthrough() -> void:
	var window = get_window()
	if not transparent_window or not mouse_passthrough_enabled:
		window.mouse_passthrough_polygon = PackedVector2Array()
		return
	if mischief_grab_active:
		var rect = _mischief_stop_rect().grow(4.0)
		window.mouse_passthrough_polygon = _rect_polygon(rect)
		return
	if mini_games != null and mini_games.active != "":
		var size = Vector2(window.size)
		window.mouse_passthrough_polygon = _rect_polygon(Rect2(Vector2.ZERO, size))
		return
	if peek_mode:
		var size = Vector2(window.size)
		window.mouse_passthrough_polygon = _rect_polygon(Rect2(Vector2.ZERO, size))
		return

	var visible_rect = pet_sprite.visible_rect()
	var rect = Rect2(pet_sprite.position + visible_rect.position, visible_rect.size).grow(18.0)
	var cut = min(rect.size.x, rect.size.y) * 0.22
	window.mouse_passthrough_polygon = PackedVector2Array([
		rect.position + Vector2(cut, 0),
		rect.position + Vector2(rect.size.x - cut, 0),
		rect.position + Vector2(rect.size.x, cut),
		rect.position + Vector2(rect.size.x, rect.size.y - cut),
		rect.position + Vector2(rect.size.x - cut, rect.size.y),
		rect.position + Vector2(cut, rect.size.y),
		rect.position + Vector2(0, rect.size.y - cut),
		rect.position + Vector2(0, cut),
	])


func _rect_polygon(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0),
		rect.position + rect.size,
		rect.position + Vector2(0, rect.size.y),
	])


func _hide_edge_for_release(global_pos: Vector2) -> String:
	var area = _play_area()
	var left = global_pos.x <= area.position.x + HIDE_EDGE_THRESHOLD
	var right = global_pos.x >= area.position.x + area.size.x - HIDE_EDGE_THRESHOLD
	var top = global_pos.y <= area.position.y + HIDE_EDGE_THRESHOLD
	var bottom = global_pos.y >= area.position.y + area.size.y - HIDE_EDGE_THRESHOLD
	if top and left:
		return "top_left"
	if top and right:
		return "top_right"
	if bottom and left:
		return "bottom_left"
	if bottom and right:
		return "bottom_right"
	if left:
		return "left"
	if right:
		return "right"
	if top:
		return "top"
	if bottom:
		return "bottom"
	return ""


func _enter_peek_mode(edge: String) -> void:
	if mini_games != null:
		mini_games.clear()
	peek_mode = true
	peek_edge = edge
	brain.set_paused(true)
	physics.peek()
	peek_sprite.visible = true
	pet_sprite.visible = false
	_sync_window_size(false)
	physics.position = _peek_window_position(edge, DisplayServer.mouse_get_position())
	get_window().position = Vector2i(round(physics.position.x), round(physics.position.y))
	_apply_peek_pose()
	_update_mouse_passthrough()


func _exit_peek_mode(show_message: bool) -> void:
	if not peek_mode:
		return
	peek_mode = false
	peek_edge = ""
	brain.set_paused(false)
	peek_sprite.visible = false
	pet_sprite.visible = true
	pet_sprite.play("idle")
	_sync_window_size(false)
	var area = _play_area()
	var size = Vector2(get_window().size)
	physics.position = Vector2(
		clamp(physics.position.x, area.position.x, area.position.x + area.size.x - size.x),
		clamp(physics.position.y, area.position.y, area.position.y + area.size.y - size.y)
	)
	if gravity_enabled:
		physics.release(Vector2.ZERO, false)
	else:
		physics.idle()
	pet_sprite.position = size * 0.5
	pet_sprite.reset_transform()
	_update_mouse_passthrough()
	if show_message:
		show_bubble("被发现啦。")


func _peek_window_position(edge: String, global_pos: Vector2) -> Vector2:
	var area = _play_area()
	var size = Vector2(get_window().size)
	var right = area.position.x + area.size.x
	var bottom = area.position.y + area.size.y
	var x = clamp(global_pos.x - size.x * 0.5, area.position.x, right - size.x)
	var y = clamp(global_pos.y - size.y * 0.5, area.position.y, bottom - size.y)

	if edge.contains("left"):
		x = area.position.x
	elif edge.contains("right"):
		x = right - size.x
	if edge.contains("top"):
		y = area.position.y
	elif edge.contains("bottom"):
		y = bottom - size.y
	return Vector2(x, y)


func _apply_peek_pose() -> void:
	pet_sprite.visible = false
	peek_sprite.visible = true
	peek_sprite.texture = _peek_texture_for_edge(peek_edge)
	peek_sprite.position = Vector2.ZERO
	peek_sprite.scale = Vector2.ONE
	bubble.position = Vector2(8, 8)


func _load_peek_textures() -> void:
	peek_textures = {
		"left": _load_asset_texture("character/peek_left.png"),
		"right": _load_asset_texture("character/peek_right.png"),
		"top": _load_asset_texture("character/peek_top.png"),
		"bottom": _load_asset_texture("character/peek_bottom.png"),
	}


func _peek_texture_for_edge(edge: String):
	var key = "bottom"
	if edge.contains("left"):
		key = "left"
	elif edge.contains("right"):
		key = "right"
	elif edge.contains("top"):
		key = "top"
	elif edge.contains("bottom"):
		key = "bottom"
	var texture = peek_textures.get(key, null)
	if texture == null:
		texture = peek_textures.get("right", null)
	return texture


func _load_asset_texture(relative_path: String):
	var path = repo_root.path_join("assets").path_join(relative_path)
	if not FileAccess.file_exists(path):
		return null
	var image = Image.new()
	if image.load(path) != OK:
		return null
	return ImageTexture.create_from_image(image)


func _jiggle() -> void:
	var base = pet_sprite.position
	var offsets = [Vector2(-5, 0), Vector2(6, 0), Vector2(-3, 0), Vector2(0, 0)]
	for i in range(offsets.size()):
		await get_tree().create_timer(0.045).timeout
		pet_sprite.position = base + offsets[i]
	pet_sprite.position = base


func _busy() -> bool:
	return mischief_grab_active or physics.state in ["Grabbed", "Flinging", "Falling", "Landing", "Peeking"] or mini_games.active != ""


func _format_changes(changes: Dictionary) -> String:
	var labels = {"mood": "心情", "hunger": "饥饿", "energy": "体力", "affection": "亲密"}
	var parts := []
	for key in changes.keys():
		var delta = int(changes[key])
		if delta != 0:
			parts.append("%s %+d" % [labels.get(key, key), delta])
	if parts.is_empty():
		return "状态没有变化。"
	return "，".join(parts)


func _load_json(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
	return {}


func _resolve_repo_root() -> String:
	var env = OS.get_environment("CRAYON_PET_ROOT")
	if env != "" and DirAccess.dir_exists_absolute(env.path_join("resource")):
		return env
	var candidates = [
		ProjectSettings.globalize_path("res://..").simplify_path(),
		OS.get_executable_path().get_base_dir().simplify_path(),
		OS.get_executable_path().get_base_dir().path_join("..").simplify_path(),
	]
	for candidate in candidates:
		if DirAccess.dir_exists_absolute(candidate.path_join("resource")):
			return candidate
	return ProjectSettings.globalize_path("res://..").simplify_path()


func _env_flag(name: String, default_value: bool) -> bool:
	var value = OS.get_environment(name).strip_edges().to_lower()
	if value == "":
		return default_value
	return value in ["1", "true", "yes", "on"]
