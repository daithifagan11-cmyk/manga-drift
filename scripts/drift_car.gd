class_name DriftCar
extends VehicleBody3D

signal drift_updated(info: Dictionary)
signal combo_increased(new_multiplier: int)
signal wall_hit()
signal drift_banked(amount: float)
signal high_angle_drift_started()

@export var max_engine_force: float = 3400.0
@export var max_steer_angle: float = 0.58
@export var steer_speed: float = 5.5
@export var arcade_boost_accel: float = 20.0
@export var max_speed_kmh: float = 100.0

# Player Input & Split-Screen configuration
@export var player_id: int = 1 ## 1 = Player 1 (WASD / Gamepad 0), 2 = Player 2 (Arrows / Shift / Gamepad 1), 0 = Solo / Any
@export var is_split_screen: bool = false

# Tuck factor to pull protruding rims flush inside the fenders
@export var wheel_track_half_width: float = 0.82

# Scoring & Stage settings
@export var combo_bank_time: float = 2.5 ## seconds of straight driving before combo banks
@export var score_rate_scale: float = 0.65 ## score multiplier
@export var stage_duration: float = 120.0 ## seconds stage timer

var current_speed_kmh: float = 0.0
var drift_angle_deg: float = 0.0
var drift_side: float = 0.0 # +1 = sliding left, -1 = sliding right
var is_drifting: bool = false
var is_high_angle: bool = false
var spawn_transform: Transform3D

# Scoring & State
var previous_drift_side: int = 0
var combo_multiplier: int = 1
var unbanked_score: float = 0.0
var total_banked_score: float = 0.0
var straight_driving_timer: float = 0.0
var stage_time_left: float = 120.0
var is_stage_running: bool = true
var time_up_triggered: bool = false
var time_left: float:
	get:
		return stage_time_left
	set(val):
		stage_time_left = val
		if stage_time_left <= 0.0 and not time_up_triggered:
			_trigger_return_to_main_menu()

var _last_high_angle_popup_time: float = 0.0
var onomatopoeia_scene: PackedScene = preload("res://scenes/onomatopoeia.tscn")

# Control inputs
var throttle_input: float = 0.0
var steer_input: float = 0.0
var handbrake: bool = false

# Wheel references
@onready var wheel_fl: VehicleWheel3D = $WheelFL
@onready var wheel_fr: VehicleWheel3D = $WheelFR
@onready var wheel_rl: VehicleWheel3D = $WheelRL
@onready var wheel_rr: VehicleWheel3D = $WheelRR

# Tire smoke particle references
@onready var smoke_left: GPUParticles3D = get_node_or_null("WheelRL/SmokeLeft")
@onready var smoke_right: GPUParticles3D = get_node_or_null("WheelRR/SmokeRight")

# Visual & Lighting references
@onready var neon_underglow: OmniLight3D = get_node_or_null("NeonUnderglow")
@onready var brake_light_omni: OmniLight3D = get_node_or_null("BrakeLight")
@onready var taillight_mesh: MeshInstance3D = get_node_or_null("CarModel/TaillightRed")
@onready var exhaust_flame: GPUParticles3D = get_node_or_null("ExhaustFlame")
@onready var exhaust_flash: OmniLight3D = get_node_or_null("ExhaustFlash")

var _taillight_mat: StandardMaterial3D
var _prev_throttle_input: float = 0.0
var _slip_speed: float = 0.0
var turbo_flutter_player: AudioStreamPlayer3D
var _had_hard_throttle: bool = false
var _turbo_flutter_cooldown: float = 0.0

var exhaust_pop_player: AudioStreamPlayer3D
var _backfire_cooldown: float = 0.0
var _last_gear_band: int = 0

const SKID_MAX_MARKS: int = 800
var _skid_pool: MultiMeshInstance3D
var _skid_write_idx: int = 0
var _skid_active_count: int = 0
var _prev_skid_pos_l: Vector3 = Vector3.ZERO
var _prev_skid_pos_r: Vector3 = Vector3.ZERO
var _has_prev_skid_l: bool = false
var _has_prev_skid_r: bool = false

# Horn audio player & cooldown
var horn_audio: AudioStreamPlayer3D
var horn_cooldown: float = 0.0
var horn_player: AudioStreamPlayer3D:
	get:
		return horn_audio
	set(val):
		horn_audio = val

func _ready() -> void:
	_apply_speed_upgrade()
	spawn_transform = global_transform
	mass = 1150.0
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0.0, -0.30, 0.04)
	
	# Keeps rotation stable while allowing faster straight-line and drift speed
	angular_damp = 2.4
	linear_damp = 0.35
	
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)
	stage_time_left = stage_duration
	_setup_tire_smoke()
	_setup_car_horn()
	_setup_turbo_flutter()
	_setup_exhaust_pop_audio()
	_setup_visual_lighting()
	_setup_enhanced_car_visuals()
	neon_underglow = get_node_or_null("NeonUnderglow")

	if is_split_screen:
		# In split screen, dedicated SubViewport cameras and HUDs are used
		var built_in_cam = get_node_or_null("CameraPivot")
		if built_in_cam:
			built_in_cam.queue_free()
		var built_in_hud = get_node_or_null("DriftHUD")
		if built_in_hud:
			built_in_hud.queue_free()
	
	for child in get_children():
		if child is CollisionShape3D and child.position.y < 0.55:
			child.position.y = 0.65
		elif child is VehicleWheel3D:
			# 1. Tuck wheels & protruding rims flush under the fender arches
			var side_sign: float = sign(child.position.x)
			if abs(child.position.x) > wheel_track_half_width:
				child.position.x = side_sign * wheel_track_half_width
			for mesh_child in child.get_children():
				if mesh_child is Node3D and abs(mesh_child.position.x) > 0.03:
					mesh_child.position.x *= 0.35 # Pull sticking-out rim caps inward
			
			child.wheel_radius = 0.35
			child.wheel_rest_length = 0.24
			child.suspension_travel = 0.30
			child.suspension_stiffness = 26.0
			child.damping_compression = 0.60
			child.damping_relaxation = 0.70
			child.wheel_roll_influence = 0.22
			
			if child.position.z < 0.0:
				child.use_as_steering = true
				child.use_as_traction = true
				child.wheel_friction_slip = 2.45 # Grippy front tires for sharp turn-in
			else:
				child.use_as_traction = true
				child.wheel_friction_slip = 1.60 # Looser rear tires for natural oversteer

func _physics_process(delta: float) -> void:
	_check_horn_input(delta)

	throttle_input = 0.0
	steer_input = 0.0
	handbrake = false

	if player_id == 1:
		# Player 1: WASD, Space, Gamepad 0
		if Input.is_key_pressed(KEY_R) or Input.is_joy_button_pressed(0, JOY_BUTTON_BACK):
			_reset_car()
			return

		if Input.is_key_pressed(KEY_W) or Input.is_joy_button_pressed(0, JOY_BUTTON_A) or Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT) > 0.2:
			throttle_input += 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_joy_button_pressed(0, JOY_BUTTON_B) or Input.get_joy_axis(0, JOY_AXIS_TRIGGER_LEFT) > 0.2:
			throttle_input -= 1.0

		if Input.is_key_pressed(KEY_A) or Input.get_joy_axis(0, JOY_AXIS_LEFT_X) < -0.2 or Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_LEFT):
			steer_input += 1.0
		if Input.is_key_pressed(KEY_D) or Input.get_joy_axis(0, JOY_AXIS_LEFT_X) > 0.2 or Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_RIGHT):
			steer_input -= 1.0

		handbrake = (
			Input.is_key_pressed(KEY_SPACE) or 
			Input.is_joy_button_pressed(0, JOY_BUTTON_X) or 
			Input.is_joy_button_pressed(0, JOY_BUTTON_RIGHT_SHOULDER)
		)

	elif player_id == 2:
		# Player 2: Arrow Keys, Shift / KP_0 / Enter, Gamepad 1
		if Input.is_key_pressed(KEY_BACKSPACE) or Input.is_key_pressed(KEY_KP_PERIOD) or Input.is_joy_button_pressed(1, JOY_BUTTON_BACK):
			_reset_car()
			return

		if Input.is_key_pressed(KEY_UP) or Input.is_joy_button_pressed(1, JOY_BUTTON_A) or Input.get_joy_axis(1, JOY_AXIS_TRIGGER_RIGHT) > 0.2:
			throttle_input += 1.0
		if Input.is_key_pressed(KEY_DOWN) or Input.is_joy_button_pressed(1, JOY_BUTTON_B) or Input.get_joy_axis(1, JOY_AXIS_TRIGGER_LEFT) > 0.2:
			throttle_input -= 1.0

		if Input.is_key_pressed(KEY_LEFT) or Input.get_joy_axis(1, JOY_AXIS_LEFT_X) < -0.2 or Input.is_joy_button_pressed(1, JOY_BUTTON_DPAD_LEFT):
			steer_input += 1.0
		if Input.is_key_pressed(KEY_RIGHT) or Input.get_joy_axis(1, JOY_AXIS_LEFT_X) > 0.2 or Input.is_joy_button_pressed(1, JOY_BUTTON_DPAD_RIGHT):
			steer_input -= 1.0

		handbrake = (
			Input.is_key_pressed(KEY_SHIFT) or 
			Input.is_key_pressed(KEY_KP_0) or 
			Input.is_key_pressed(KEY_ENTER) or 
			Input.is_joy_button_pressed(1, JOY_BUTTON_X) or 
			Input.is_joy_button_pressed(1, JOY_BUTTON_RIGHT_SHOULDER)
		)

	else:
		# Solo / Any Input
		if Input.is_key_pressed(KEY_R) or Input.is_action_just_pressed("reset_car"):
			_reset_car()
			return

		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) or Input.is_action_pressed("throttle") or Input.is_action_pressed("ui_up"):
			throttle_input += 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) or Input.is_action_pressed("brake") or Input.is_action_pressed("ui_down"):
			throttle_input -= 1.0

		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) or Input.is_action_pressed("steer_left") or Input.is_action_pressed("ui_left"):
			steer_input += 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) or Input.is_action_pressed("steer_right") or Input.is_action_pressed("ui_right"):
			steer_input -= 1.0

		handbrake = (
			Input.is_key_pressed(KEY_SPACE) or 
			Input.is_action_pressed("handbrake") or 
			Input.is_action_pressed("ui_select")
		)

	var forward_dir: Vector3 = -global_transform.basis.z
	forward_dir.y = 0.0
	forward_dir = forward_dir.normalized()
	
	var right_dir: Vector3 = global_transform.basis.x
	right_dir.y = 0.0
	right_dir = right_dir.normalized()

	# Clamp horizontal velocity so current_speed_kmh never exceeds max_speed_kmh
	var max_speed_mps: float = max_speed_kmh / 3.6
	var horiz_vel: Vector3 = Vector3(linear_velocity.x, 0.0, linear_velocity.z)
	var horiz_speed: float = horiz_vel.length()
	if horiz_speed > max_speed_mps:
		var clamped_horiz = (horiz_vel / horiz_speed) * max_speed_mps
		linear_velocity.x = clamped_horiz.x
		linear_velocity.z = clamped_horiz.z
		horiz_vel = clamped_horiz
		horiz_speed = max_speed_mps

	current_speed_kmh = clampf(horiz_speed * 3.6, 0.0, max_speed_kmh)

	# Speed-sensitive steering so high speeds stay stable
	var speed_factor: float = clamp(1.0 - (current_speed_kmh / 210.0), 0.55, 1.0)
	var target_steer: float = steer_input * max_steer_angle * speed_factor
	steering = move_toward(steering, target_steer, steer_speed * delta)

	# Cut engine force cleanly at max_speed_kmh
	if throttle_input > 0.0 and current_speed_kmh >= max_speed_kmh:
		engine_force = 0.0
	else:
		engine_force = throttle_input * max_engine_force
	
	# Lighter coasting drag so the car doesn't bog down between corners
	if abs(throttle_input) < 0.05:
		brake = 8.0
	elif throttle_input < 0.0 and current_speed_kmh > 10.0 and linear_velocity.dot(forward_dir) > 0.0:
		brake = 45.0
	else:
		brake = 0.0

	if abs(throttle_input) > 0.05 and current_speed_kmh < max_speed_kmh:
		apply_central_force(forward_dir * throttle_input * mass * arcade_boost_accel)

	# Calculate drift angle and lateral slide speed
	horiz_vel = Vector3(linear_velocity.x, 0.0, linear_velocity.z)
	var sideways_speed: float = horiz_vel.dot(right_dir)
	if horiz_vel.length() > 2.0:
		var norm_vel: Vector3 = horiz_vel.normalized()
		drift_angle_deg = rad_to_deg(forward_dir.angle_to(norm_vel))
		if drift_angle_deg > 90.0:
			drift_angle_deg = 180.0 - drift_angle_deg
		drift_side = signf(forward_dir.cross(norm_vel).y)
	else:
		drift_angle_deg = 0.0
		drift_side = 0.0

	var turning_at_speed: bool = abs(steer_input) > 0.2 and current_speed_kmh > 18.0
	var target_rear_slip: float = 1.60
	
	if handbrake:
		target_rear_slip = 0.92
	elif turning_at_speed or drift_angle_deg > 10.0:
		target_rear_slip = 1.12

	for child in get_children():
		if child is VehicleWheel3D and child.position.z >= 0.0:
			child.wheel_friction_slip = move_toward(child.wheel_friction_slip, target_rear_slip, 4.5 * delta)

	# Controlled Yaw Assist & stronger mid-drift speed maintenance
	if current_speed_kmh > 18.0:
		if handbrake:
			apply_torque(Vector3(0.0, steer_input * mass * 4.6, 0.0))
		elif abs(steer_input) > 0.15 and drift_angle_deg < 44.0:
			apply_torque(Vector3(0.0, steer_input * mass * 3.2, 0.0))
		
		if drift_angle_deg > 10.0:
			if throttle_input > 0.1 and current_speed_kmh < max_speed_kmh * 0.95:
				var slide_forward: Vector3 = (forward_dir * 0.65 + horiz_vel.normalized() * 0.35).normalized()
				apply_central_force(slide_forward * mass * 7.5)
			apply_central_force(-right_dir * sideways_speed * mass * 1.55)

	is_drifting = current_speed_kmh > 18.0 and drift_angle_deg > 10.0
	is_high_angle = is_drifting and (drift_angle_deg >= 25.0)

	# Update rear tire smoke & raycasted skid marks whenever tires lose traction (slip_speed > 2.5) or handbrake pulled
	var forward_speed: float = forward_dir.dot(linear_velocity)
	_slip_speed = abs(sideways_speed)
	if handbrake:
		_slip_speed = maxf(_slip_speed, abs(forward_speed) * 0.75 + 4.0)
	elif is_drifting:
		_slip_speed = maxf(_slip_speed, (drift_angle_deg / 12.0) * (current_speed_kmh * 0.18))

	var should_emit_smoke: bool = _slip_speed > 2.5
	if should_emit_smoke:
		var smoke_ratio: float = clampf((_slip_speed - 2.5) / 9.0, 0.32, 1.0)
		if smoke_left != null:
			smoke_left.emitting = true
			smoke_left.amount_ratio = smoke_ratio
		if smoke_right != null:
			smoke_right.emitting = true
			smoke_right.amount_ratio = smoke_ratio
	else:
		if smoke_left != null and smoke_left.emitting:
			smoke_left.emitting = false
		if smoke_right != null and smoke_right.emitting:
			smoke_right.emitting = false

	_update_tire_skid_marks(should_emit_smoke or (handbrake and current_speed_kmh > 6.0))

	# Dynamic glowing brake lights (high-intensity red bloom when braking)
	var is_braking: bool = (brake > 5.0 or handbrake or (throttle_input < -0.1 and current_speed_kmh > 3.0))
	if _taillight_mat != null:
		var target_emission: float = 8.5 if is_braking else 2.5
		_taillight_mat.emission_energy_multiplier = lerpf(_taillight_mat.emission_energy_multiplier, target_emission, delta * 15.0)
	if brake_light_omni != null:
		var target_omni_energy: float = 4.2 if is_braking else 0.8
		brake_light_omni.light_energy = lerpf(brake_light_omni.light_energy, target_omni_energy, delta * 15.0)

	# Turbo flutter / compressor surge audio on hard throttle lift-off
	_check_turbo_flutter(delta)

	# Exhaust flame & pop/bang audio on sudden throttle cut, high-RPM upshift, or high-speed handbrake pull
	if _backfire_cooldown > 0.0:
		_backfire_cooldown = maxf(0.0, _backfire_cooldown - delta)
	var cur_gear_band: int = int(current_speed_kmh / 20.0)
	var upshifted_at_high_rpm: bool = cur_gear_band > _last_gear_band and throttle_input > 0.7 and current_speed_kmh >= 36.0
	_last_gear_band = cur_gear_band
	if _prev_throttle_input > 0.65 and throttle_input <= 0.08 and current_speed_kmh > 20.0:
		_trigger_exhaust_backfire()
	elif upshifted_at_high_rpm:
		_trigger_exhaust_backfire()
	elif handbrake and current_speed_kmh > 42.0 and _prev_throttle_input > 0.45:
		_trigger_exhaust_backfire()
	_prev_throttle_input = throttle_input

	if exhaust_flash != null and exhaust_flash.light_energy > 0.01:
		exhaust_flash.light_energy = lerpf(exhaust_flash.light_energy, 0.0, delta * 14.0)

	# Ensure horizontal speed remains strictly capped at max_speed_kmh
	var final_horiz: Vector3 = Vector3(linear_velocity.x, 0.0, linear_velocity.z)
	var final_speed: float = final_horiz.length()
	if final_speed > max_speed_mps:
		var clamped_final = (final_horiz / final_speed) * max_speed_mps
		linear_velocity.x = clamped_final.x
		linear_velocity.z = clamped_final.z
		final_speed = max_speed_mps
	current_speed_kmh = clampf(final_speed * 3.6, 0.0, max_speed_kmh)

	_update_stage_timer(delta)
	_update_scoring(delta)
	_emit_hud_info()

func _update_stage_timer(delta: float) -> void:
	if not is_stage_running and time_up_triggered:
		return
	stage_time_left -= delta
	if stage_time_left <= 0.0:
		stage_time_left = 0.0
		is_stage_running = false
		_bank_current_combo()
		if not time_up_triggered:
			_trigger_return_to_main_menu()

func _trigger_return_to_main_menu() -> void:
	if time_up_triggered:
		return
	stage_time_left = 0.0
	time_up_triggered = true
	_bank_current_combo()
	if not is_split_screen:
		var hud = get_node_or_null("DriftHUD")
		if hud == null and get_parent() != null:
			hud = get_parent().get_node_or_null("DriftHUD")
		if hud != null and hud.has_method("_check_and_save_high_score"):
			hud._check_and_save_high_score()
	if get_tree() != null:
		get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if get_tree() != null:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _update_scoring(delta: float) -> void:
	var vel_horizontal = Vector3(linear_velocity.x, 0.0, linear_velocity.z)
	var speed_mps = vel_horizontal.length()
	
	if is_drifting and is_stage_running:
		# Reset straight driving timer during active drift
		straight_driving_timer = 0.0
		
		# Transition drift detection (switching left to right or vice-versa)
		var current_side_int = int(drift_side)
		if current_side_int != 0:
			if previous_drift_side != 0 and current_side_int != previous_drift_side:
				# Chained transition between left and right!
				combo_multiplier = clampi(combo_multiplier + 1, 1, 10)
				combo_increased.emit(combo_multiplier)
				_spawn_onomatopoeia("DRIFT!", _get_rear_tire_pos(), Color(1.0, 0.85, 0.1))
			elif previous_drift_side == 0:
				# Drift initiation popup
				_spawn_onomatopoeia("GOGOGO!", _get_rear_tire_pos(), Color(1.0, 0.95, 0.2))
				
			previous_drift_side = current_side_int
			
		# Accrue live unbanked drift points based on: Drift Angle * Speed * Combo Multiplier
		var frame_points = drift_angle_deg * speed_mps * float(combo_multiplier) * delta * score_rate_scale
		unbanked_score += frame_points
		
		# Spawn floating manga sound-effect text ('GOGOGO!', 'DRIFT!') above rear tires during high-angle slides
		if is_high_angle:
			var current_time = Time.get_ticks_msec() / 1000.0
			if current_time - _last_high_angle_popup_time > 0.42:
				_last_high_angle_popup_time = current_time
				_spawn_high_angle_sound_effect()
	else:
		# Straight driving: count up to 2.5 seconds before banking combos
		straight_driving_timer += delta
		if straight_driving_timer >= combo_bank_time:
			if unbanked_score > 0.0:
				_bank_current_combo()
			combo_multiplier = 1
			previous_drift_side = 0

func _bank_current_combo() -> void:
	if int(unbanked_score) > 0:
		total_banked_score += unbanked_score
		drift_banked.emit(unbanked_score)
		unbanked_score = 0.0
	else:
		unbanked_score = 0.0

func _on_body_entered(body: Node) -> void:
	# Cancel combos on wall collisions
	var hit_speed = linear_velocity.length()
	if hit_speed > 3.5:
		unbanked_score = 0.0
		combo_multiplier = 1
		previous_drift_side = 0
		straight_driving_timer = 0.0
		wall_hit.emit()
		_spawn_onomatopoeia("CRASH!", global_position + Vector3(0, 0.9, 0), Color(1.0, 0.2, 0.2))

func _spawn_high_angle_sound_effect() -> void:
	var sounds = ["GOGOGO!", "DRIFT!"]
	var selected_sound = sounds[randi() % sounds.size()]
	var color = Color(1.0, 0.92, 0.1) if selected_sound == "GOGOGO!" else Color(1.0, 0.45, 0.1)
	var spawn_pos = _get_rear_tire_pos()
	_spawn_onomatopoeia(selected_sound, spawn_pos, color)

func _spawn_onomatopoeia(text: String, spawn_pos: Vector3, color: Color = Color(1.0, 0.95, 0.3)) -> void:
	if onomatopoeia_scene == null:
		return
	var popup = onomatopoeia_scene.instantiate() as OnomatopoeiaPopup
	if popup == null:
		return
	get_tree().root.add_child(popup)
	popup.global_position = spawn_pos
	popup.setup(text, color)

func _get_rear_tire_pos() -> Vector3:
	var chosen_wheel = wheel_rl if (randi() % 2 == 0) else wheel_rr
	if chosen_wheel != null:
		return chosen_wheel.global_position + Vector3(randf_range(-0.15, 0.15), 0.75, randf_range(-0.15, 0.15))
	return global_position + Vector3(0, 0.75, 1.2)

func _reset_car() -> void:
	global_transform = spawn_transform
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	steering = 0.0
	engine_force = 0.0
	brake = 0.0
	unbanked_score = 0.0
	combo_multiplier = 1
	straight_driving_timer = 0.0
	if smoke_left != null:
		smoke_left.emitting = false
	if smoke_right != null:
		smoke_right.emitting = false

func _setup_tire_smoke() -> void:
	if smoke_left == null:
		smoke_left = get_node_or_null("WheelRL/SmokeLeft")
	if smoke_right == null:
		smoke_right = get_node_or_null("WheelRR/SmokeRight")
	
	for child in get_children():
		if child is VehicleWheel3D and child.position.z >= 0.0:
			var is_left: bool = child.position.x < 0.0
			var smoke_name: String = "SmokeLeft" if is_left else "SmokeRight"
			var smoke_node = child.get_node_or_null(smoke_name) as GPUParticles3D
			if smoke_node == null:
				smoke_node = _create_smoke_particles(smoke_name)
				child.add_child(smoke_node)
				smoke_node.position = Vector3(0.0, -0.25, 0.2)
			if is_left:
				smoke_left = smoke_node
			else:
				smoke_right = smoke_node

func _apply_speed_upgrade() -> void:
	var base_speed_kmh: float = 60.0
	match CarUpgradeManager.speed_tier:
		0:
			base_speed_kmh = 60.0
		1:
			base_speed_kmh = 70.0
		_:
			base_speed_kmh = 80.0
	max_speed_kmh = base_speed_kmh + TurboUpgradeManager.get_speed_boost_kmh()

func _setup_turbo_flutter() -> void:
	var flutter_paths: Array[String] = [
		"res://assets/audio/turbo_flutter.wav",
		"res://assets/audio/turbo_flutter.mp3"
	]
	var stream: AudioStream = null
	for path in flutter_paths:
		if ResourceLoader.exists(path):
			stream = load(path) as AudioStream
			break

	turbo_flutter_player = AudioStreamPlayer3D.new()
	turbo_flutter_player.name = "TurboFlutterPlayer"
	turbo_flutter_player.position = Vector3(0.0, 0.55, -1.4) # Engine bay mount
	turbo_flutter_player.unit_size = 18.0
	turbo_flutter_player.max_distance = 90.0
	add_child(turbo_flutter_player)

	turbo_flutter_player.stream = stream if stream != null else _create_synthesized_turbo_flutter_sound()

func _check_turbo_flutter(delta: float) -> void:
	if _turbo_flutter_cooldown > 0.0:
		_turbo_flutter_cooldown = maxf(0.0, _turbo_flutter_cooldown - delta)

	if throttle_input > 0.8:
		_had_hard_throttle = true
	elif (_had_hard_throttle or _prev_throttle_input > 0.8) and throttle_input <= 0.0:
		_had_hard_throttle = false
		if TurboUpgradeManager.turbo_stage > 0 and _turbo_flutter_cooldown <= 0.0:
			_turbo_flutter_cooldown = 0.35
			if turbo_flutter_player != null and turbo_flutter_player.stream != null:
				var stage_pitch: float = 1.12 - float(TurboUpgradeManager.turbo_stage - 1) * 0.13
				turbo_flutter_player.pitch_scale = stage_pitch * randf_range(0.97, 1.03)
				turbo_flutter_player.volume_db = -3.0 + float(TurboUpgradeManager.turbo_stage) * 1.2
				turbo_flutter_player.play()
	elif throttle_input < 0.8:
		_had_hard_throttle = false

func _create_synthesized_turbo_flutter_sound() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.56
	var num_samples: int = int(sample_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(num_samples * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4286

	# 4-pulse compressor surge ("stut-stut-stut-stut") with turbo whistle + air chop
	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var overall_decay: float = exp(-t * 3.8)
		var pulse_rate: float = 8.5 - t * 2.2
		var pulse_phase: float = fmod(t * pulse_rate, 1.0)
		var pulse_env: float = sin(pulse_phase * PI)
		pulse_env = pulse_env * pulse_env * exp(-pulse_phase * 2.4)

		var whistle_freq: float = lerpf(2450.0, 1450.0, t / duration)
		var whistle: float = sin(t * whistle_freq * TAU) * 0.35 + sin(t * whistle_freq * 0.5 * TAU) * 0.25
		var surge_air: float = rng.randf_range(-1.0, 1.0) * 0.45
		var s: float = (whistle + surge_air) * pulse_env * overall_decay * 0.9
		var sample_val: int = int(clampf(s, -1.0, 1.0) * 32767.0)
		byte_array.encode_s16(i * 2, sample_val)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = byte_array
	return wav

func _setup_visual_lighting() -> void:
	if taillight_mesh != null:
		var base_mat: Material = null
		if taillight_mesh.mesh and taillight_mesh.mesh.material is StandardMaterial3D:
			base_mat = taillight_mesh.mesh.material
		elif taillight_mesh.material_override is StandardMaterial3D:
			base_mat = taillight_mesh.material_override
		if base_mat is StandardMaterial3D:
			_taillight_mat = base_mat.duplicate() as StandardMaterial3D
			taillight_mesh.material_override = _taillight_mat

func _setup_enhanced_car_visuals() -> void:
	var car_mesh := find_child("CarBodyMesh", true, false) as MeshInstance3D
	if car_mesh:
		var paint_mat := StandardMaterial3D.new()
		paint_mat.albedo_color = Color(0.08, 0.08, 0.1) # Deep midnight metallic
		paint_mat.metallic = 0.9
		paint_mat.roughness = 0.15
		paint_mat.clearcoat_enabled = true
		paint_mat.clearcoat = 1.0
		car_mesh.material_override = paint_mat

	# Neon Underglow Light
	var underglow := OmniLight3D.new()
	underglow.name = "NeonUnderglow"
	underglow.light_color = Color(0.2, 0.6, 1.0) # Electric Cyan
	underglow.light_energy = 2.5
	underglow.omni_range = 3.5
	underglow.position = Vector3(0, -0.3, 0)
	add_child(underglow)

func _trigger_exhaust_backfire() -> void:
	if _backfire_cooldown > 0.0:
		return
	_backfire_cooldown = 0.22
	if exhaust_flame != null:
		exhaust_flame.restart()
		exhaust_flame.emitting = true
	if exhaust_flash != null:
		exhaust_flash.light_energy = 5.5
	if exhaust_pop_player != null and exhaust_pop_player.stream != null:
		exhaust_pop_player.pitch_scale = randf_range(0.88, 1.16)
		exhaust_pop_player.play()
	var cam = get_node_or_null("CameraPivot")
	if cam != null and cam.has_method("trigger_shake"):
		cam.trigger_shake(0.18)

func _setup_exhaust_pop_audio() -> void:
	var pop_paths: Array[String] = [
		"res://assets/audio/exhaust_pop.wav",
		"res://assets/audio/exhaust_pop.mp3"
	]
	var stream: AudioStream = null
	for path in pop_paths:
		if ResourceLoader.exists(path):
			stream = load(path) as AudioStream
			break

	exhaust_pop_player = AudioStreamPlayer3D.new()
	exhaust_pop_player.name = "ExhaustPopPlayer"
	exhaust_pop_player.position = Vector3(-0.54, 0.32, 2.05) # Mounted at rear exhaust tip
	exhaust_pop_player.unit_size = 20.0
	exhaust_pop_player.max_distance = 100.0
	exhaust_pop_player.volume_db = 1.5
	add_child(exhaust_pop_player)
	exhaust_pop_player.stream = stream if stream != null else _create_synthesized_exhaust_pop_sound()

func _create_synthesized_exhaust_pop_sound() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.28
	var num_samples: int = int(sample_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(num_samples * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9091

	# Sharp transient crack + deep exhaust thump (double pop-bang feel)
	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var main_crack: float = exp(-t * 34.0) * (rng.randf_range(-1.0, 1.0) * 0.75 + sin(t * 115.0 * TAU) * 0.45)
		var echo_t: float = maxf(0.0, t - 0.085)
		var echo_pop: float = (exp(-echo_t * 42.0) * (rng.randf_range(-1.0, 1.0) * 0.55 + sin(echo_t * 130.0 * TAU) * 0.3)) if t >= 0.085 else 0.0
		var s: float = (main_crack + echo_pop * 0.65) * 0.95
		var sample_val: int = int(clampf(s, -1.0, 1.0) * 32767.0)
		byte_array.encode_s16(i * 2, sample_val)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = byte_array
	return wav

func _ensure_skid_pool() -> MultiMeshInstance3D:
	if _skid_pool != null and is_instance_valid(_skid_pool):
		return _skid_pool
	var host: Node = get_parent()
	if host == null:
		return null
	var existing := host.get_node_or_null("SkidMarksPool") as MultiMeshInstance3D
	if existing != null:
		_skid_pool = existing
		return _skid_pool

	var plane := PlaneMesh.new()
	plane.size = Vector2(0.28, 1.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.03, 0.03, 0.035, 0.78)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = false
	plane.material = mat

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = SKID_MAX_MARKS
	mm.visible_instance_count = 0
	mm.mesh = plane

	_skid_pool = MultiMeshInstance3D.new()
	_skid_pool.name = "SkidMarksPool"
	_skid_pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_skid_pool.multimesh = mm
	host.add_child(_skid_pool)
	return _skid_pool

func _update_tire_skid_marks(should_leave_marks: bool) -> void:
	if not should_leave_marks:
		_has_prev_skid_l = false
		_has_prev_skid_r = false
		return

	var space_state := get_world_3d().direct_space_state if get_world_3d() != null else null
	if space_state == null:
		return

	if wheel_rl != null:
		var hit_l := _raycast_wheel_ground(space_state, wheel_rl)
		if not hit_l.is_empty():
			var pos_l: Vector3 = hit_l["position"]
			var norm_l: Vector3 = hit_l["normal"]
			if _has_prev_skid_l:
				var seg_len_l := _prev_skid_pos_l.distance_to(pos_l)
				if seg_len_l >= 0.35 and seg_len_l <= 4.0:
					_stamp_skid_segment(_prev_skid_pos_l, pos_l, norm_l)
					_prev_skid_pos_l = pos_l
			else:
				_prev_skid_pos_l = pos_l
				_has_prev_skid_l = true
		else:
			_has_prev_skid_l = false

	if wheel_rr != null:
		var hit_r := _raycast_wheel_ground(space_state, wheel_rr)
		if not hit_r.is_empty():
			var pos_r: Vector3 = hit_r["position"]
			var norm_r: Vector3 = hit_r["normal"]
			if _has_prev_skid_r:
				var seg_len_r := _prev_skid_pos_r.distance_to(pos_r)
				if seg_len_r >= 0.35 and seg_len_r <= 4.0:
					_stamp_skid_segment(_prev_skid_pos_r, pos_r, norm_r)
					_prev_skid_pos_r = pos_r
			else:
				_prev_skid_pos_r = pos_r
				_has_prev_skid_r = true
		else:
			_has_prev_skid_r = false

func _raycast_wheel_ground(space_state: PhysicsDirectSpaceState3D, wheel: VehicleWheel3D) -> Dictionary:
	var from: Vector3 = wheel.global_position + Vector3.UP * 0.25
	var to: Vector3 = wheel.global_position - Vector3.UP * (wheel.wheel_radius + 0.55)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	return space_state.intersect_ray(query)

func _stamp_skid_segment(from_pos: Vector3, to_pos: Vector3, ground_normal: Vector3) -> void:
	var pool := _ensure_skid_pool()
	if pool == null or pool.multimesh == null:
		return
	var diff := to_pos - from_pos
	var seg_len := diff.length()
	if seg_len < 0.05:
		return
	var up := ground_normal.normalized()
	var dir := diff.slide(up)
	if dir.length_squared() < 0.0001:
		return
	dir = dir.normalized()
	var right := up.cross(dir).normalized()
	var mid := (from_pos + to_pos) * 0.5 + up * 0.028
	var basis := Basis(right, up, dir * (seg_len * 1.15))

	var mm := pool.multimesh
	mm.set_instance_transform(_skid_write_idx, Transform3D(basis, mid))
	_skid_write_idx = (_skid_write_idx + 1) % SKID_MAX_MARKS
	_skid_active_count = mini(_skid_active_count + 1, SKID_MAX_MARKS)
	mm.visible_instance_count = _skid_active_count

func _create_smoke_particles(p_name: String) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.name = p_name
	particles.emitting = false
	particles.amount = 80
	particles.lifetime = 1.25
	particles.explosiveness = 0.0
	particles.randomness = 0.45
	particles.local_coords = false
	particles.position = Vector3(0.0, -0.25, 0.2)
	
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 0.25
	mat.direction = Vector3(0.0, 0.25, 1.0)
	mat.spread = 42.0
	mat.initial_velocity_min = 1.8
	mat.initial_velocity_max = 4.2
	mat.gravity = Vector3(0.0, 0.85, 0.0)
	mat.damping_min = 2.0
	mat.damping_max = 3.5
	mat.angle_min = -180.0
	mat.angle_max = 180.0
	mat.scale_min = 0.85
	mat.scale_max = 1.45
	
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.35), 0.0, 3.8)
	curve.add_point(Vector2(0.35, 1.85), 1.2, 1.2)
	curve.add_point(Vector2(1.0, 3.4), 0.8, 0.0)
	var curve_tex := CurveTexture.new()
	curve_tex.curve = curve
	mat.scale_curve = curve_tex

	var color_grad := Gradient.new()
	color_grad.offsets = PackedFloat32Array([0.0, 0.15, 0.55, 1.0])
	color_grad.colors = PackedColorArray([
		Color(0.95, 0.96, 0.98, 0.88),
		Color(0.90, 0.92, 0.95, 0.72),
		Color(0.82, 0.84, 0.88, 0.35),
		Color(0.75, 0.78, 0.82, 0.0)
	])
	var color_tex := GradientTexture1D.new()
	color_tex.gradient = color_grad
	mat.color_ramp = color_tex
	
	particles.process_material = mat
	
	var quad := QuadMesh.new()
	quad.size = Vector2(1.5, 1.5)
	
	var smoke_mat := StandardMaterial3D.new()
	smoke_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke_mat.vertex_color_use_as_albedo = true
	smoke_mat.roughness = 0.95
	smoke_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	smoke_mat.billboard_keep_scale = true
	smoke_mat.proximity_fade_enabled = true
	smoke_mat.proximity_fade_distance = 0.45

	var rad_grad := Gradient.new()
	rad_grad.offsets = PackedFloat32Array([0.0, 0.28, 0.65, 1.0])
	rad_grad.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 1.0, 1.0, 0.82),
		Color(1.0, 1.0, 1.0, 0.22),
		Color(1.0, 1.0, 1.0, 0.0)
	])
	var rad_tex := GradientTexture2D.new()
	rad_tex.width = 128
	rad_tex.height = 128
	rad_tex.fill = GradientTexture2D.FILL_RADIAL
	rad_tex.fill_from = Vector2(0.5, 0.5)
	rad_tex.fill_to = Vector2(0.5, 0.0)
	rad_tex.gradient = rad_grad
	smoke_mat.albedo_texture = rad_tex

	quad.material = smoke_mat
	particles.draw_pass_1 = quad
	
	return particles

func _emit_hud_info() -> void:
	var vel_horizontal = Vector3(linear_velocity.x, 0.0, linear_velocity.z)
	var speed_kph = clampf(vel_horizontal.length() * 3.6, 0.0, max_speed_kmh)
	
	var bank_ratio: float = 1.0
	if not is_drifting:
		bank_ratio = clampf(1.0 - (straight_driving_timer / combo_bank_time), 0.0, 1.0)
		
	var info = {
		"is_drifting": is_drifting,
		"is_high_angle": is_high_angle,
		"drift_angle": drift_angle_deg,
		"drift_side": drift_side,
		"speed_kph": speed_kph,
		"combo_multiplier": combo_multiplier,
		"unbanked_score": unbanked_score,
		"total_banked_score": total_banked_score,
		"bank_ratio": bank_ratio,
		"straight_driving_timer": straight_driving_timer,
		"stage_time_left": stage_time_left,
		"time_left": stage_time_left,
		"is_stage_running": is_stage_running
	}
	drift_updated.emit(info)

# Call _setup_car_horn() inside your car's _ready() function:
func _setup_car_horn() -> void:
	var horn_paths: Array[String] = [
		"res://assets/audio/car_horn.wav",
		"res://assets/audio/horn.mp3"
	]
	
	var stream: AudioStream = null
	for path in horn_paths:
		if ResourceLoader.exists(path):
			stream = load(path) as AudioStream
			break
			
	horn_audio = AudioStreamPlayer3D.new()
	horn_audio.name = "HornPlayer"
	horn_audio.position = Vector3(0.0, 0.6, -1.8)
	horn_audio.unit_size = 20.0
	horn_audio.max_distance = 100.0
	add_child(horn_audio)
	
	if stream:
		horn_audio.stream = stream
	else:
		# Fallback: Print note if custom horn file isn't added yet
		print("NOTE: Drop car_horn.wav into res://assets/audio/ for a custom horn sound.")
		horn_audio.stream = _create_synthesized_horn_sound()

# Call _check_horn_input(delta) inside your _physics_process(delta) function:
func _check_horn_input(delta: float) -> void:
	if horn_cooldown > 0.0:
		horn_cooldown -= delta
		return
		
	var honked: bool = false
	if (player_id == 1 or player_id == 0) and (Input.is_key_pressed(KEY_G) or (InputMap.has_action("horn_p1") and Input.is_action_pressed("horn_p1"))):
		honked = true
	elif (player_id == 2 or player_id == 0) and (Input.is_key_pressed(KEY_1) or Input.is_key_pressed(KEY_KP_1) or (InputMap.has_action("horn_p2") and Input.is_action_pressed("horn_p2"))):
		honked = true
		
	if honked:
		horn_cooldown = 0.35 # Prevent audio clipping / spamming
		if horn_audio and horn_audio.stream:
			horn_audio.pitch_scale = randf_range(0.95, 1.05) # Slight pitch variation
			horn_audio.play()
		else:
			print("HONK! (P%d)" % player_id)

func _create_synthesized_horn_sound() -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	var num_samples := int(22050 * 0.3)
	var byte_array := PackedByteArray()
	byte_array.resize(num_samples * 2)
	for i in range(num_samples):
		var t := float(i) / 22050.0
		var env := 1.0
		if t < 0.02:
			env = t / 0.02
		elif t > 0.25:
			env = (0.3 - t) / 0.05
		var s := (sin(t * 415.0 * TAU) * 0.5 + sin(t * 520.0 * TAU) * 0.5) * env * 0.85
		var sample_val := int(clampf(s, -1.0, 1.0) * 32767.0)
		byte_array.encode_s16(i * 2, sample_val)
	wav.data = byte_array
	return wav
