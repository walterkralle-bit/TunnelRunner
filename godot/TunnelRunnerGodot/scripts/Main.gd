extends Node2D

const SECTORS := 8
const TAU_F := TAU
const PLAYER_Z := 0.82
const BASE_OBS_SPEED := 0.36
const JUMP_DURATION := 0.42
const JUMP_HEIGHT := 0.24
const TOUCH_JUMP_ACTION := "touch_jump"
const SAVE_PATH := "user://tunnel_runner_save.cfg"

var score := 0
var record := 0
var coin_count := 0
var run_distance := 0.0
var speed_scale := 1.0
var spawn_timer := 0.0
var coin_timer := 0.0
var game_running := false
var game_over := false
var spawn_phase := 0

var player_angle := PI / 2.0
var target_angle := PI / 2.0
var jumping := false
var jump_timer := 0.0

var obstacles: Array = []
var coins: Array = []
var particles: Array = []

@onready var score_label: Label = $UI/ScoreLabel
@onready var record_label: Label = $UI/RecordLabel
@onready var coin_label: Label = $UI/CoinLabel
@onready var overlay: Control = $UI/Overlay
@onready var state_label: Label = $UI/Overlay/CenterBox/StateLabel
@onready var start_button: Button = $UI/Overlay/CenterBox/StartButton
@onready var jump_button: Button = $UI/TouchJumpButton

func _ready() -> void:
	_setup_input()
	_load_record()
	start_button.pressed.connect(_on_start_pressed)
	jump_button.pressed.connect(_on_jump_pressed)
	jump_button.visible = true
	_reset_run_state()
	_update_hud()
	queue_redraw()

func _setup_input() -> void:
	if not InputMap.has_action("turn_left"):
		InputMap.add_action("turn_left")
		var ev_left := InputEventKey.new()
		ev_left.physical_keycode = KEY_LEFT
		InputMap.action_add_event("turn_left", ev_left)
		var ev_a := InputEventKey.new()
		ev_a.physical_keycode = KEY_A
		InputMap.action_add_event("turn_left", ev_a)
	if not InputMap.has_action("turn_right"):
		InputMap.add_action("turn_right")
		var ev_right := InputEventKey.new()
		ev_right.physical_keycode = KEY_RIGHT
		InputMap.action_add_event("turn_right", ev_right)
		var ev_d := InputEventKey.new()
		ev_d.physical_keycode = KEY_D
		InputMap.action_add_event("turn_right", ev_d)
	if not InputMap.has_action("jump"):
		InputMap.add_action("jump")
		var ev_space := InputEventKey.new()
		ev_space.physical_keycode = KEY_SPACE
		InputMap.action_add_event("jump", ev_space)
	if not InputMap.has_action(TOUCH_JUMP_ACTION):
		InputMap.add_action(TOUCH_JUMP_ACTION)

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
	obstacles.clear()
	coins.clear()
	particles.clear()
	state_label.text = "Ausweichen, springen, Coins sammeln"
	_update_hud()

func _process(delta: float) -> void:
	_update_input(delta)
	if game_running:
		_update_run(delta)
	queue_redraw()

func _update_input(delta: float) -> void:
	var turn_input := Input.get_action_strength("turn_right") - Input.get_action_strength("turn_left")
	if turn_input != 0.0:
		target_angle = wrapf(target_angle + turn_input * delta * 3.2, 0.0, TAU_F)
	player_angle = lerp_angle(player_angle, target_angle, min(1.0, delta * 8.0))
	if Input.is_action_just_pressed("jump"):
		if not game_running and not game_over:
			start_run()
		_perform_jump()

func _perform_jump() -> void:
	if jumping or game_over:
		return
	jumping = true
	jump_timer = 0.0

func _update_run(delta: float) -> void:
	run_distance += delta * speed_scale
	score += int(round(delta * speed_scale * 120.0))
	speed_scale = 1.0 + run_distance * 0.018
	spawn_timer += delta
	coin_timer += delta
	if spawn_timer >= max(0.42, 1.05 - run_distance * 0.02):
		spawn_timer = 0.0
		_spawn_group()
	if coin_timer >= 1.8:
		coin_timer = 0.0
		_spawn_coin_line()
	_update_jump(delta)
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

func _spawn_group() -> void:
	var difficulty: float = min(1.0, run_distance / 40.0)
	var safe_sector: int = _sector_for_angle(player_angle)
	var blocked: Array[int] = []
	match spawn_phase % 4:
		0:
			blocked = _make_block_pattern(safe_sector, 2 + int(round(difficulty * 2.0)))
		1:
			blocked = _make_block_pattern((safe_sector + 1) % SECTORS, 3)
		2:
			blocked = _make_jump_gate_pattern(safe_sector)
		_:
			blocked = _make_block_pattern((safe_sector + SECTORS - 1) % SECTORS, 2)
	spawn_phase += 1
	for sector in blocked:
		obstacles.append({
			"kind": "block",
			"sector": sector,
			"z": 0.0,
			"depth": 0.14,
		})

func _make_block_pattern(anchor_sector: int, width: int) -> Array[int]:
	var sectors: Array[int] = []
	for i in range(width):
		sectors.append((anchor_sector + 2 + i) % SECTORS)
	return sectors

func _make_jump_gate_pattern(safe_sector: int) -> Array[int]:
	var blocked: Array[int] = []
	for sector in range(SECTORS):
		if sector == safe_sector:
			continue
		blocked.append(sector)
	return blocked

func _spawn_coin_line() -> void:
	if not game_running:
		return
	var sector: int = _sector_for_angle(player_angle)
	for i in range(4):
		coins.append({
			"sector": sector,
			"angle": _angle_for_sector(sector),
			"z": -0.12 - i * 0.12,
		})

func _update_obstacles(delta: float) -> void:
	var next: Array = []
	for obstacle in obstacles:
		obstacle["z"] += BASE_OBS_SPEED * speed_scale * delta
		var back_z: float = obstacle["z"] + obstacle["depth"]
		if obstacle["z"] > 1.22:
			continue
		if obstacle["z"] <= PLAYER_Z + 0.03 and back_z >= PLAYER_Z - 0.03:
			if obstacle["sector"] == _sector_for_angle(player_angle) and _jump_offset() < 0.08:
				_trigger_game_over()
				return
		next.append(obstacle)
	obstacles = next

func _update_coins(delta: float) -> void:
	var next: Array = []
	for coin in coins:
		coin["z"] += BASE_OBS_SPEED * speed_scale * delta
		if coin["z"] > 1.18:
			continue
		if abs(coin["z"] - PLAYER_Z) < 0.04 and coin["sector"] == _sector_for_angle(player_angle) and _jump_offset() < 0.12:
			coin_count += 1
			score += 100
			_spawn_pickup_particles(coin["angle"], coin["z"])
			continue
		next.append(coin)
	coins = next

func _spawn_pickup_particles(angle: float, z: float) -> void:
	var center: Vector2 = _screen_center()
	var radius: float = _radius_for_z(z)
	var pos: Vector2 = center + Vector2(cos(angle), sin(angle)) * radius
	for i in range(6):
		particles.append({
			"pos": pos,
			"vel": Vector2(randf_range(-90.0, 90.0), randf_range(-90.0, 90.0)),
			"life": 0.45,
		})

func _update_particles(delta: float) -> void:
	var next: Array = []
	for p in particles:
		p["life"] -= delta
		if p["life"] <= 0.0:
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
	var rect := Rect2(Vector2.ZERO, get_viewport_rect().size)
	draw_rect(rect, Color(0.02, 0.03, 0.08), true)
	_draw_tunnel()
	_draw_obstacles()
	_draw_coins()
	_draw_player()
	_draw_particles()

func _draw_tunnel() -> void:
	var center := _screen_center()
	for i in range(10):
		var z0 := float(i) / 10.0
		var z1 := float(i + 1) / 10.0
		var r0 := _radius_for_z(z0)
		var r1 := _radius_for_z(z1)
		var col := Color.from_hsv(0.58 + sin(run_distance * 0.1 + i * 0.2) * 0.04, 0.45, 0.18 + i * 0.05)
		draw_circle(center, r1, col)
		draw_circle(center, r0, Color(0.02, 0.03, 0.08))
	for i in range(24):
		var a := (float(i) / 24.0) * TAU_F
		draw_line(center + Vector2(cos(a), sin(a)) * 50.0, center + Vector2(cos(a), sin(a)) * 440.0, Color(0.16, 0.24, 0.4, 0.5), 2.0)

func _draw_player() -> void:
	var center := _screen_center()
	var r := _radius_for_z(PLAYER_Z - _jump_offset())
	var pos := center + Vector2(cos(player_angle), sin(player_angle)) * r
	draw_circle(pos, 22.0, Color(0.18, 0.78, 0.95))
	draw_circle(pos, 10.0, Color(0.78, 0.94, 1.0))

func _draw_obstacles() -> void:
	var center := _screen_center()
	var sorted := obstacles.duplicate()
	sorted.sort_custom(func(a, b): return a["z"] < b["z"])
	for obstacle in sorted:
		var front_r := _radius_for_z(obstacle["z"])
		var back_r := _radius_for_z(min(1.0, obstacle["z"] + obstacle["depth"]))
		var dir := Vector2(cos(_angle_for_sector(obstacle["sector"])), sin(_angle_for_sector(obstacle["sector"])))
		var tangent := dir.orthogonal()
		var width := 34.0 + front_r * 0.08
		var p1 := center + dir * front_r + tangent * width
		var p2 := center + dir * front_r - tangent * width
		var p3 := center + dir * back_r - tangent * width * 0.72
		var p4 := center + dir * back_r + tangent * width * 0.72
		draw_colored_polygon(PackedVector2Array([p1, p2, p3, p4]), Color(0.74, 0.42, 0.24))

func _draw_coins() -> void:
	var center := _screen_center()
	for coin in coins:
		var pos := center + Vector2(cos(coin["angle"]), sin(coin["angle"])) * _radius_for_z(coin["z"])
		var size := 8.0 + _radius_for_z(coin["z"]) * 0.018
		draw_circle(pos, size, Color(1.0, 0.84, 0.15))
		draw_circle(pos, size * 0.42, Color(0.82, 0.62, 0.08))

func _draw_particles() -> void:
	for p in particles:
		draw_circle(p["pos"], 3.0, Color(1.0, 0.9, 0.5, clampf(p["life"] * 2.0, 0.0, 1.0)))

func _radius_for_z(z: float) -> float:
	var t := clampf(z, 0.0, 1.0)
	var near_r := 420.0
	var far_r := 52.0
	return lerpf(far_r, near_r, pow(t, 1.45))

func _screen_center() -> Vector2:
	var size := get_viewport_rect().size
	return Vector2(size.x * 0.5, size.y * 0.47)

func _sector_for_angle(angle: float) -> int:
	var normalized := wrapf(angle, 0.0, TAU_F)
	return int(floor(normalized / (TAU_F / float(SECTORS))))

func _angle_for_sector(sector: int) -> float:
	return (float(sector) + 0.5) * (TAU_F / float(SECTORS))

func _load_record() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		record = int(config.get_value("save", "record", 0))

func _save_record() -> void:
	var config := ConfigFile.new()
	config.set_value("save", "record", record)
	config.save(SAVE_PATH)
