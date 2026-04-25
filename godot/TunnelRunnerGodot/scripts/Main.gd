extends Node2D

const SECTORS: int = 8
const TAU_F: float = TAU
const PLAYER_Z: float = 0.82
const BASE_OBS_SPEED: float = 0.34
const JUMP_DURATION: float = 0.42
const JUMP_HEIGHT: float = 0.25
const SAVE_PATH: String = "user://tunnel_runner_save.cfg"
const NBANDS: int = 12
const BSPC: float = 0.11
const NLONG: int = 24
const HTML_STEER_SMOOTH: float = 0.105
const HTML_STEER_MAX: float = 0.095
const HTML_WHEEL_DEADZONE: float = 25.0
const HTML_INDICATOR_RADIUS_RATIO: float = 120.0 / 280.0

var score: int = 0
var record: int = 0
var coin_count: int = 0
var run_distance: float = 0.0
var speed_scale: float = 1.0
var spawn_timer: float = 0.0
var coin_timer: float = 0.0
var game_running: bool = false
var game_over: bool = false
var spawn_phase: int = 0
var tunnel_hue: float = 210.0

var player_angle: float = PI / 2.0
var target_angle: float = PI / 2.0
var jumping: bool = false
var jump_timer: float = 0.0
var wheel_spin: float = 0.0
var wheel_dragging: bool = false

var obstacles: Array[Dictionary] = []
var coins: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var bands: Array[Dictionary] = []

@onready var score_label: Label = $UI/ScoreLabel
@onready var record_label: Label = $UI/RecordLabel
@onready var coin_label: Label = $UI/CoinLabel
@onready var controls_root: Control = $UI/ControlsRoot
@onready var controls_bg: ColorRect = $UI/ControlsRoot/ControlsBG
@onready var overlay: Control = $UI/Overlay
@onready var state_label: Label = $UI/Overlay/CenterBox/StateLabel
@onready var start_button: Button = $UI/Overlay/CenterBox/StartButton
@onready var wheel_wrap: Control = $UI/ControlsRoot/WheelWrap
@onready var wheel_outer: Control = $UI/ControlsRoot/WheelWrap/WheelOuter
@onready var wheel_area: Control = $UI/ControlsRoot/WheelWrap/WheelArea
@onready var wheel_cross_h: ColorRect = $UI/ControlsRoot/WheelWrap/WheelArea/WheelCrossH
@onready var wheel_cross_v: ColorRect = $UI/ControlsRoot/WheelWrap/WheelArea/WheelCrossV
@onready var wheel_indicator: ColorRect = $UI/ControlsRoot/WheelWrap/WheelArea/WheelIndicator
@onready var jump_button: Button = $UI/ControlsRoot/WheelWrap/WheelArea/JumpButton

func _ready() -> void:
	randomize()
	_setup_input()
	_load_record()
	_init_bands()
	start_button.pressed.connect(_on_start_pressed)
	jump_button.pressed.connect(_on_jump_pressed)
	wheel_area.gui_input.connect(_on_wheel_gui_input)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	if wheel_indicator.get_parent() != controls_root:
		wheel_indicator.reparent(controls_root)
	_build_wheel_ticks()
	jump_button.text = ""
	jump_button.focus_mode = Control.FOCUS_NONE
	_reset_run_state()
	_layout_controls()
	_update_hud()
	_update_wheel_visuals()
	queue_redraw()

func _setup_input() -> void:
	if not InputMap.has_action("turn_left"):
		InputMap.add_action("turn_left")
		var ev_left: InputEventKey = InputEventKey.new()
		ev_left.physical_keycode = KEY_LEFT
		InputMap.action_add_event("turn_left", ev_left)
		var ev_a: InputEventKey = InputEventKey.new()
		ev_a.physical_keycode = KEY_A
		InputMap.action_add_event("turn_left", ev_a)
	if not InputMap.has_action("turn_right"):
		InputMap.add_action("turn_right")
		var ev_right: InputEventKey = InputEventKey.new()
		ev_right.physical_keycode = KEY_RIGHT
		InputMap.action_add_event("turn_right", ev_right)
		var ev_d: InputEventKey = InputEventKey.new()
		ev_d.physical_keycode = KEY_D
		InputMap.action_add_event("turn_right", ev_d)
	if not InputMap.has_action("jump"):
		InputMap.add_action("jump")
		var ev_space: InputEventKey = InputEventKey.new()
		ev_space.physical_keycode = KEY_SPACE
		InputMap.action_add_event("jump", ev_space)

func _on_start_pressed() -> void:
	start_run()

func _on_jump_pressed() -> void:
	if not game_running and not game_over:
		start_run()
	_perform_jump()

func start_run() -> void:
	_reset_run_state()
	game_running = true
	overlay.visible = false
	queue_redraw()

func _reset_run_state() -> void:
	score = 0
	coin_count = 0
	run_distance = 0.0
	speed_scale = 1.0
	spawn_timer = 0.0
	coin_timer = 0.0
	spawn_phase = 0
	game_running = false
	game_over = false
	player_angle = PI / 2.0
	target_angle = player_angle
	jumping = false
	jump_timer = 0.0
	wheel_spin = 0.0
	wheel_dragging = false
	obstacles.clear()
	coins.clear()
	particles.clear()
	_init_bands()
	state_label.text = "Ausweichen, springen, Coins sammeln"
	start_button.text = "START"
	_update_hud()

func _process(delta: float) -> void:
	_update_input(delta)
	if game_running:
		_update_run(delta)
	_update_wheel_visuals()
	queue_redraw()

func _on_viewport_size_changed() -> void:
	_layout_controls()

func _update_input(delta: float) -> void:
	var turn_input: float = Input.get_action_strength("turn_right") - Input.get_action_strength("turn_left")
	if not wheel_dragging and turn_input != 0.0:
		target_angle = wrapf(target_angle + turn_input * delta * 3.4, 0.0, TAU_F)
	var angle_delta: float = atan2(sin(target_angle - player_angle), cos(target_angle - player_angle))
	var frame_scale: float = delta * 60.0
	player_angle = wrapf(player_angle + sign(angle_delta) * min(abs(angle_delta) * HTML_STEER_SMOOTH, HTML_STEER_MAX) * frame_scale, 0.0, TAU_F)
	if Input.is_action_just_pressed("jump"):
		if not game_running and not game_over:
			start_run()
		_perform_jump()

func _on_wheel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			wheel_dragging = mouse_button.pressed
			if mouse_button.pressed:
				_set_target_from_wheel(mouse_button.position)
	elif event is InputEventMouseMotion and wheel_dragging:
		var mouse_motion: InputEventMouseMotion = event
		_set_target_from_wheel(mouse_motion.position)
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		wheel_dragging = touch.pressed
		if touch.pressed:
			_set_target_from_wheel(wheel_area.get_local_mouse_position())
	elif event is InputEventScreenDrag and wheel_dragging:
		_set_target_from_wheel(wheel_area.get_local_mouse_position())

func _set_target_from_wheel(local_pos: Vector2) -> void:
	var center: Vector2 = wheel_area.size * 0.5
	var delta: Vector2 = local_pos - center
	if delta.length() < HTML_WHEEL_DEADZONE * (wheel_area.size.x / 280.0):
		return
	target_angle = wrapf(delta.angle(), 0.0, TAU_F)
	wheel_area.rotation = target_angle - PI * 0.5

func _layout_controls() -> void:
	var size: Vector2 = get_viewport_rect().size
	var controls_h: float = size.x * 0.8
	controls_root.position = Vector2(0.0, size.y - controls_h)
	controls_root.size = Vector2(size.x, controls_h)
	controls_bg.size = controls_root.size
	var wheel_size: float = size.x * 0.7
	var outer_pad: float = wheel_size * 0.057
	wheel_wrap.position = Vector2((size.x - wheel_size) * 0.5, (controls_h - wheel_size) * 0.5)
	wheel_wrap.size = Vector2(wheel_size, wheel_size)
	wheel_outer.position = Vector2(-outer_pad, -outer_pad)
	wheel_outer.size = Vector2(wheel_size + outer_pad * 2.0, wheel_size + outer_pad * 2.0)
	wheel_area.position = Vector2.ZERO
	wheel_area.size = Vector2(wheel_size, wheel_size)
	wheel_area.pivot_offset = wheel_area.size * 0.5
	wheel_cross_h.position = Vector2(wheel_size * 0.12, wheel_size * 0.5 - 1.0)
	wheel_cross_h.size = Vector2(wheel_size * 0.76, 2.0)
	wheel_cross_v.position = Vector2(wheel_size * 0.5 - 1.0, wheel_size * 0.12)
	wheel_cross_v.size = Vector2(2.0, wheel_size * 0.76)
	jump_button.position = Vector2(wheel_size * 0.5 - wheel_size * 0.136, wheel_size * 0.5 - wheel_size * 0.136)
	jump_button.size = Vector2(wheel_size * 0.272, wheel_size * 0.272)
	jump_button.add_theme_font_size_override("font_size", int(size.x * 0.045))
	wheel_indicator.size = Vector2(max(6.0, size.x * 0.015), size.x * 0.08)
	_update_wheel_ticks_layout()
	_update_wheel_visuals()

func _update_wheel_visuals() -> void:
	wheel_area.rotation = target_angle - PI * 0.5
	var center: Vector2 = Vector2(controls_root.size.x * 0.5, controls_root.size.y * 0.5)
	var r: float = wheel_area.size.x * HTML_INDICATOR_RADIUS_RATIO
	var pos: Vector2 = center + Vector2(cos(player_angle), sin(player_angle)) * r
	wheel_indicator.position = pos - wheel_indicator.size * Vector2(0.5, 0.5)
	wheel_indicator.rotation = player_angle + PI * 0.5

func _build_wheel_ticks() -> void:
	for tick_name in ["TickTop", "TickBottom", "TickLeft", "TickRight"]:
		if wheel_area.has_node(tick_name):
			continue
		var tick: ColorRect = ColorRect.new()
		tick.name = tick_name
		tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tick.color = Color(1.0, 1.0, 1.0, 0.6)
		wheel_area.add_child(tick)

func _update_wheel_ticks_layout() -> void:
	var tick_t := wheel_area.get_node_or_null("TickTop") as Control
	var tick_b := wheel_area.get_node_or_null("TickBottom") as Control
	var tick_l := wheel_area.get_node_or_null("TickLeft") as Control
	var tick_r := wheel_area.get_node_or_null("TickRight") as Control
	if tick_t == null or tick_b == null or tick_l == null or tick_r == null:
		return
	var wheel_size: float = wheel_area.size.x
	var thin: float = max(2.0, wheel_size * (2.0 / 280.0))
	var long_h: float = wheel_size * (14.0 / 280.0)
	var inset: float = wheel_size * (6.0 / 280.0)
	tick_t.position = Vector2(wheel_size * 0.5 - thin * 0.5, inset)
	tick_t.size = Vector2(thin, long_h)
	tick_b.position = Vector2(wheel_size * 0.5 - thin * 0.5, wheel_size - inset - long_h)
	tick_b.size = Vector2(thin, long_h)
	tick_l.position = Vector2(inset, wheel_size * 0.5 - thin * 0.5)
	tick_l.size = Vector2(long_h, thin)
	tick_r.position = Vector2(wheel_size - inset - long_h, wheel_size * 0.5 - thin * 0.5)
	tick_r.size = Vector2(long_h, thin)

func _perform_jump() -> void:
	if jumping or game_over:
		return
	jumping = true
	jump_timer = 0.0

func _update_run(delta: float) -> void:
	run_distance += delta * speed_scale
	score += int(round(delta * speed_scale * 120.0))
	speed_scale = 1.0 + run_distance * 0.018
	wheel_spin += delta * speed_scale * 4.6
	spawn_timer += delta
	coin_timer += delta
	tunnel_hue = fposmod(210.0 + run_distance * 6.0, 360.0)
	if spawn_timer >= max(0.42, 1.05 - run_distance * 0.02):
		spawn_timer = 0.0
		_spawn_group()
	if coin_timer >= 1.8:
		coin_timer = 0.0
		_spawn_coin_line()
	_update_jump(delta)
	_update_bands(delta)
	_update_obstacles(delta)
	_update_coins(delta)
	_update_particles(delta)
	_update_hud()

func _update_jump(delta: float) -> void:
	if not jumping:
		return
	jump_timer += delta
	if jump_timer >= JUMP_DURATION:
		jumping = false
		jump_timer = 0.0

func _jump_offset() -> float:
	if not jumping:
		return 0.0
	return sin((jump_timer / JUMP_DURATION) * PI) * JUMP_HEIGHT

func _init_bands() -> void:
	bands.clear()
	for i in range(NBANDS):
		bands.append({"z": float(i) * BSPC, "id": i})

func _update_bands(delta: float) -> void:
	for band in bands:
		band["z"] += BASE_OBS_SPEED * speed_scale * delta
	for band in bands:
		if band["z"] > 1.15:
			var minimum_z: float = 1.0
			for other in bands:
				minimum_z = min(minimum_z, float(other["z"]))
			band["z"] = minimum_z - BSPC
			band["id"] = int(band["id"]) - NBANDS

func _spawn_group() -> void:
	var difficulty: float = min(1.0, run_distance / 40.0)
	var player_sector: int = _sector_for_angle(player_angle)
	var blocked: Array[int] = []
	match spawn_phase % 5:
		0:
			blocked = _make_block_pattern(player_sector, 2 + int(round(difficulty * 2.0)))
			_spawn_blocks(blocked, 0.12)
		1:
			blocked = _make_block_pattern((player_sector + 1) % SECTORS, 3)
			_spawn_blocks(blocked, 0.13)
		2:
			_spawn_combo_ring(player_sector)
		3:
			blocked = _make_block_pattern((player_sector + SECTORS - 1) % SECTORS, 2)
			_spawn_blocks(blocked, 0.11)
		_:
			_spawn_ring()
	spawn_phase += 1

func _make_block_pattern(anchor_sector: int, width: int) -> Array[int]:
	var sectors: Array[int] = []
	for i in range(width):
		sectors.append((anchor_sector + 2 + i) % SECTORS)
	return sectors

func _spawn_blocks(blocked: Array[int], depth: float) -> void:
	for sector in blocked:
		obstacles.append({"kind": "block", "sector": sector, "z": 0.0, "depth": depth})

func _spawn_combo_ring(player_sector: int) -> void:
	var jump_sector: int = (player_sector + 2) % SECTORS
	for sector in range(SECTORS):
		if sector == jump_sector:
			obstacles.append({"kind": "blue", "sector": sector, "z": 0.0, "depth": 0.10})
		else:
			obstacles.append({"kind": "block", "sector": sector, "z": 0.0, "depth": 0.10})

func _spawn_ring() -> void:
	obstacles.append({"kind": "ring", "sector": -1, "z": 0.0, "depth": 0.08})

func _spawn_coin_line() -> void:
	if not game_running:
		return
	var sector: int = _sector_for_angle(player_angle)
	for i in range(4):
		coins.append({"sector": sector, "angle": _angle_for_sector(sector), "z": -0.12 - i * 0.12})

func _update_obstacles(delta: float) -> void:
	var next: Array[Dictionary] = []
	for obstacle in obstacles:
		obstacle["z"] += BASE_OBS_SPEED * speed_scale * delta
		var back_z: float = float(obstacle["z"]) + float(obstacle["depth"])
		if float(obstacle["z"]) > 1.22:
			continue
		if float(obstacle["z"]) <= PLAYER_Z + 0.03 and back_z >= PLAYER_Z - 0.03:
			if obstacle["kind"] == "ring":
				if _jump_offset() < 0.09:
					_trigger_game_over()
					return
			elif int(obstacle["sector"]) == _sector_for_angle(player_angle):
				if obstacle["kind"] == "blue":
					if _jump_offset() < 0.09:
						_trigger_game_over()
						return
				else:
					_trigger_game_over()
					return
		next.append(obstacle)
	obstacles = next

func _update_coins(delta: float) -> void:
	var next: Array[Dictionary] = []
	for coin in coins:
		coin["z"] += BASE_OBS_SPEED * speed_scale * delta
		if float(coin["z"]) > 1.18:
			continue
		if abs(float(coin["z"]) - PLAYER_Z) < 0.04 and int(coin["sector"]) == _sector_for_angle(player_angle) and _jump_offset() < 0.12:
			coin_count += 1
			score += 100
			_spawn_pickup_particles(float(coin["angle"]), float(coin["z"]))
			continue
		next.append(coin)
	coins = next

func _spawn_pickup_particles(angle: float, z: float) -> void:
	var center: Vector2 = _screen_center()
	var radius: float = _radius_for_z(z)
	var pos: Vector2 = center + Vector2(cos(angle), sin(angle)) * radius
	for i in range(6):
		particles.append({"pos": pos, "vel": Vector2(randf_range(-90.0, 90.0), randf_range(-90.0, 90.0)), "life": 0.45})

func _update_particles(delta: float) -> void:
	var next: Array[Dictionary] = []
	for p in particles:
		p["life"] -= delta
		if float(p["life"]) <= 0.0:
			continue
		p["pos"] += p["vel"] * delta
		next.append(p)
	particles = next

func _trigger_game_over() -> void:
	game_running = false
	game_over = true
	if score > record:
		record = score
		_save_record()
	state_label.text = "Crash! Record: %s" % record
	start_button.text = "NOCHMAL"
	overlay.visible = true
	_update_hud()

func _update_hud() -> void:
	score_label.text = str(score)
	record_label.text = "Record: %s" % record
	coin_label.text = "🪙 %s" % coin_count

func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, get_viewport_rect().size)
	var bg: Color = _background_color()
	draw_rect(rect, bg, true)
	_draw_tunnel()
	_draw_obstacles()
	_draw_coins()
	_draw_player()
	_draw_particles()

func _draw_tunnel() -> void:
	var center: Vector2 = _screen_center()
	var sorted_bands: Array[Dictionary] = bands.duplicate()
	sorted_bands.sort_custom(func(a, b): return float(a["z"]) < float(b["z"]))
	for i in range(sorted_bands.size() - 1):
		var b: Dictionary = sorted_bands[i]
		var n: Dictionary = sorted_bands[i + 1]
		var z0: float = max(0.0, float(b["z"]))
		var z1: float = min(1.06, float(n["z"]))
		if z1 <= z0:
			continue
		var r0: float = _radius_for_z(z0)
		var r1: float = _radius_for_z(z1)
		if r1 - r0 < 0.5:
			continue
		var is_dark: bool = int(b["id"]) % 2 == 0
		for j in range(NLONG):
			var a0: float = (float(j) / float(NLONG)) * TAU_F
			var a1: float = (float(j + 1) / float(NLONG)) * TAU_F
			var panel_var: float = 0.03 if j % 2 == 0 else -0.03
			var base_light: float = 0.28 if is_dark else 0.42
			var light: float = base_light + panel_var
			var depth_fade: float = 0.4 + min(1.0, z0) * 0.6
			var col: Color = Color.from_hsv(tunnel_hue / 360.0, 0.42 + light * 0.18, 0.12 + light * depth_fade * 0.52)
			_draw_ring_slice(center, r0, r1, a0, a1, col)
		draw_arc(center, r1, 0.0, TAU_F, 120, Color(0.03, 0.07, 0.16, 0.55), 1.0 + min(1.0, z1) * 1.5)
	var inner_r: float = _inner_radius()
	var outer_r: float = _outer_radius()
	for i in range(NLONG):
		var a: float = (float(i) / float(NLONG)) * TAU_F
		var col2: Color = Color(0.12, 0.22, 0.42, 0.6) if i % 4 == 0 else Color(0.08, 0.16, 0.32, 0.45)
		draw_line(center + Vector2(cos(a), sin(a)) * inner_r, center + Vector2(cos(a), sin(a)) * outer_r, col2, 2.0 if i % 4 == 0 else 1.0)
	var grad_steps: int = 14
	for i in range(grad_steps, 0, -1):
		var rr: float = inner_r + 12.0 * float(i) / float(grad_steps)
		var alpha: float = 0.06 + 0.04 * float(i) / float(grad_steps)
		draw_circle(center, rr, Color(0.0, 0.0, 0.0, alpha))

func _draw_player() -> void:
	var center: Vector2 = _screen_center()
	var jump_off: float = _jump_offset()
	var r: float = _radius_for_z(PLAYER_Z - jump_off)
	var pos: Vector2 = center + Vector2(cos(player_angle), sin(player_angle)) * r
	var size: float = 18.0 + PLAYER_Z * 8.0
	for t in range(1, 7):
		var trail_z: float = PLAYER_Z - jump_off - 0.03 * float(t)
		if trail_z < 0.05:
			break
		var tr: float = _radius_for_z(trail_z)
		var alpha: float = 0.35 - float(t) * 0.05
		var width: float = size * (0.6 - float(t) * 0.06)
		if alpha <= 0.0 or width <= 0.0:
			break
		draw_arc(center, tr, player_angle - 0.08, player_angle + 0.08, 18, Color(0.12, 0.32, 0.55, alpha), width)
	draw_circle(pos, size * 1.5, Color(0.0, 0.55, 0.95, 0.14))
	draw_circle(pos, size, Color(0.05, 0.12, 0.21))
	draw_arc(pos, size, wheel_spin, wheel_spin + TAU_F, 40, Color(0.0, 0.72, 0.92), 2.5)
	for i in range(8):
		var a: float = wheel_spin + (float(i) / 8.0) * TAU_F
		draw_line(pos + Vector2(cos(a), sin(a)) * size * 0.75, pos + Vector2(cos(a), sin(a)) * size * 0.95, Color(0.0, 0.55, 0.82, 0.45), 2.0)
	for i in range(4):
		var a2: float = wheel_spin + (float(i) / 4.0) * TAU_F
		draw_line(pos, pos + Vector2(cos(a2), sin(a2)) * size * 0.62, Color(0.0, 0.55, 0.75), 2.0)
	draw_circle(pos, size * 0.22, Color(0.24, 0.84, 0.95))

func _draw_obstacles() -> void:
	var center: Vector2 = _screen_center()
	var sorted: Array[Dictionary] = obstacles.duplicate()
	sorted.sort_custom(func(a, b): return float(a["z"]) < float(b["z"]))
	for obstacle in sorted:
		var zf: float = float(obstacle["z"])
		if zf < 0.04:
			continue
		var z_depth: float = 0.14 if obstacle["kind"] == "block" else 0.08
		var rf: float = _radius_for_z(zf)
		var rb: float = _radius_for_z(min(1.1, zf + z_depth))
		var thickness: float = rb - rf
		if rf < 10.0 or thickness < 2.0:
			continue
		if obstacle["kind"] == "ring":
			_draw_ring(center, rf, rb)
		else:
			var sa: float = _angle_for_sector(int(obstacle["sector"])) - _sector_size() * 0.48
			var ea: float = _angle_for_sector(int(obstacle["sector"])) + _sector_size() * 0.48
			if obstacle["kind"] == "blue":
				_draw_blue_segment(center, rf, rb, sa, ea)
			else:
				_draw_block_segment(center, rf, rb, sa, ea)

func _draw_ring(center: Vector2, rf: float, rb: float) -> void:
	var thickness: float = rb - rf
	_draw_ring_slice(center, rf, rb, 0.0, TAU_F, Color(0.02, 0.25, 0.32))
	_draw_ring_slice(center, rf + thickness * 0.3, rf + thickness * 0.7, 0.0, TAU_F, Color(0.03, 0.55, 0.60))
	draw_arc(center, rb, 0.0, TAU_F, 120, Color(0.28, 0.93, 1.0), max(2.0, thickness * 0.08))
	draw_arc(center, rf, 0.0, TAU_F, 120, Color(0.02, 0.18, 0.25), max(1.5, thickness * 0.05))

func _draw_block_segment(center: Vector2, rf: float, rb: float, sa: float, ea: float) -> void:
	var thickness: float = rb - rf
	var t1: float = rf + thickness * 0.33
	var t2: float = rf + thickness * 0.66
	_draw_ring_slice(center, rf, rf + max(2.0, thickness * 0.12), sa, ea, Color(0.16, 0.06, 0.02))
	_draw_ring_slice(center, rf, t1, sa, ea, Color(0.42, 0.16, 0.06))
	_draw_ring_slice(center, t1, t2, sa, ea, Color(0.54, 0.24, 0.09))
	_draw_ring_slice(center, t2, rb, sa, ea, Color(0.72, 0.34, 0.16))
	draw_arc(center, rb, sa, ea, 22, Color(0.87, 0.53, 0.27), max(3.0, thickness * 0.1))
	draw_arc(center, rf, sa, ea, 22, Color(0.16, 0.06, 0.02), max(2.0, thickness * 0.06))

func _draw_blue_segment(center: Vector2, rf: float, rb: float, sa: float, ea: float) -> void:
	var thickness: float = rb - rf
	var blue_outer: float = rb
	var blue_inner: float = rb - thickness * 0.72
	var t1: float = blue_outer - thickness * 0.24
	var t2: float = blue_outer - thickness * 0.48
	_draw_ring_slice(center, blue_inner, blue_inner + 1.0, sa, ea, Color(0.02, 0.22, 0.28))
	_draw_ring_slice(center, t1, blue_outer, sa, ea, Color(0.04, 0.74, 0.80))
	_draw_ring_slice(center, t2, t1, sa, ea, Color(0.02, 0.55, 0.62))
	_draw_ring_slice(center, blue_inner, t2, sa, ea, Color(0.02, 0.34, 0.40))
	draw_arc(center, blue_outer, sa, ea, 22, Color(0.28, 0.93, 1.0), max(2.5, thickness * 0.06))

func _draw_coins() -> void:
	var center: Vector2 = _screen_center()
	for coin in coins:
		var pos: Vector2 = center + Vector2(cos(float(coin["angle"])), sin(float(coin["angle"]))) * _radius_for_z(float(coin["z"]))
		var size: float = 2.0 + pow(max(0.0, float(coin["z"])), 1.8) * 20.0
		draw_circle(pos, size + 2.0, Color(0.04, 0.06, 0.12))
		draw_circle(pos, size, Color(1.0, 0.84, 0.12))
		draw_circle(pos, size * 0.35, Color(0.84, 0.66, 0.08))

func _draw_particles() -> void:
	for p in particles:
		var pos: Vector2 = p["pos"]
		draw_circle(pos, 3.0, Color(1.0, 0.92, 0.5, clampf(float(p["life"]) * 2.0, 0.0, 1.0)))

func _draw_ring_slice(center: Vector2, inner_r: float, outer_r: float, a0: float, a1: float, color: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	var steps: int = max(6, int(abs(a1 - a0) * 24.0 / TAU_F) + 2)
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var a: float = lerpf(a0, a1, t)
		pts.append(center + Vector2(cos(a), sin(a)) * outer_r)
	for i in range(steps, -1, -1):
		var t2: float = float(i) / float(steps)
		var a2: float = lerpf(a0, a1, t2)
		pts.append(center + Vector2(cos(a2), sin(a2)) * inner_r)
	draw_colored_polygon(pts, color)

func _background_color() -> Color:
	return Color.from_hsv(tunnel_hue / 360.0, 0.42, 0.08)

func _radius_for_z(z: float) -> float:
	var t: float = clampf(z, 0.0, 1.06)
	return _inner_radius() + (_outer_radius() - _inner_radius()) * pow(t, 1.8)

func _outer_radius() -> float:
	var size: Vector2 = get_viewport_rect().size
	return min(size.x * 0.45, size.y * 0.31)

func _inner_radius() -> float:
	return _outer_radius() * 0.125

func _screen_center() -> Vector2:
	var size: Vector2 = get_viewport_rect().size
	return Vector2(size.x * 0.5, size.y * 0.42)

func _sector_for_angle(angle: float) -> int:
	var normalized: float = wrapf(angle, 0.0, TAU_F)
	return int(floor(normalized / _sector_size()))

func _angle_for_sector(sector: int) -> float:
	return (float(sector) + 0.5) * _sector_size()

func _sector_size() -> float:
	return TAU_F / float(SECTORS)

func _load_record() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		record = int(config.get_value("save", "record", 0))

func _save_record() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("save", "record", record)
	config.save(SAVE_PATH)
