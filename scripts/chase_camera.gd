extends Node3D
class_name ChaseCamera

@export var target_vehicle: VehicleBody3D
@export var spring_arm: SpringArm3D
@export var camera: Camera3D

@export_group("Follow Settings")
@export var follow_speed: float = 6.0
@export var rotation_speed: float = 5.0
@export var velocity_influence: float = 0.45 ## How much the camera aligns with velocity vs car facing
@export var camera_height_offset: float = 1.3
@export var target_pitch_deg: float = -11.0

@export_group("Dynamic FOV")
@export var base_fov: float = 75.0
@export var max_fov: float = 90.0
@export var max_fov_speed: float = 40.0 ## Speed in m/s (~144 km/h) for max FOV
@export var fov_lerp_speed: float = 4.0

@export_group("Dynamic Camera Roll")
@export var max_roll_deg: float = 3.5
@export var roll_lerp_speed: float = 6.0

@export_group("Screen Shake & Dynamic Zoom")
@export var max_shake_offset: float = 0.08
@export var max_shake_roll_deg: float = 0.8
@export var shake_decay: float = 3.2

var _current_yaw: float = 0.0
var _current_roll: float = 0.0
var _trauma: float = 0.0
var _drift_zoom_offset: float = 0.0

func _ready() -> void:
	# Unparent transform so physics jitter doesn't violently snap the camera
	set_as_top_level(true)
	
	if target_vehicle == null and get_parent() is VehicleBody3D:
		target_vehicle = get_parent()
		
	if spring_arm == null:
		spring_arm = get_node_or_null("SpringArm3D")
		
	if spring_arm != null and camera == null:
		camera = spring_arm.get_node_or_null("Camera3D")
		
	if target_vehicle != null:
		global_position = target_vehicle.global_position + Vector3(0, camera_height_offset, 0)
		_current_yaw = target_vehicle.global_rotation.y
		_connect_vehicle_signals()

func _connect_vehicle_signals() -> void:
	if target_vehicle == null:
		return
	if target_vehicle.has_signal("combo_increased") and not target_vehicle.combo_increased.is_connected(_on_combo_increased):
		target_vehicle.combo_increased.connect(_on_combo_increased)
	if target_vehicle.has_signal("wall_hit") and not target_vehicle.wall_hit.is_connected(_on_wall_hit):
		target_vehicle.wall_hit.connect(_on_wall_hit)
	if target_vehicle.has_signal("high_angle_drift_started") and not target_vehicle.high_angle_drift_started.is_connected(_on_high_angle_started):
		target_vehicle.high_angle_drift_started.connect(_on_high_angle_started)

func trigger_shake(amount: float = 0.35) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)

func _on_combo_increased(_new_mult: int) -> void:
	trigger_shake(0.35)

func _on_wall_hit() -> void:
	trigger_shake(0.65)

func _on_high_angle_started() -> void:
	trigger_shake(0.25)

func _physics_process(delta: float) -> void:
	if target_vehicle == null:
		if get_parent() is VehicleBody3D:
			target_vehicle = get_parent()
			_connect_vehicle_signals()
		else:
			return
		
	var target_pos = target_vehicle.global_position + Vector3(0, camera_height_offset, 0)
	# Smoothly follow vehicle position
	global_position = global_position.lerp(target_pos, delta * follow_speed)
	
	# Determine target heading yaw
	var car_yaw = target_vehicle.global_rotation.y
	var vel = target_vehicle.linear_velocity
	var horizontal_speed = Vector2(vel.x, vel.z).length()
	
	var target_yaw = car_yaw
	if horizontal_speed > 3.0:
		# Velocity yaw (in Godot forward is -Z)
		var vel_yaw = atan2(-vel.x, -vel.z)
		# Blend between car facing and movement trajectory for classic touge drift side-view
		target_yaw = lerp_angle(car_yaw, vel_yaw, velocity_influence)
	
	# Smooth horizontal lag
	_current_yaw = lerp_angle(_current_yaw, target_yaw, delta * rotation_speed)
	
	# Roll / Tilt into corners based on angular velocity (yaw rate) and steering
	var turn_rate = target_vehicle.angular_velocity.y
	var target_roll = clampf(-turn_rate * 0.04, -deg_to_rad(max_roll_deg), deg_to_rad(max_roll_deg))
	_current_roll = lerp(_current_roll, target_roll, delta * roll_lerp_speed)
	
	# High-angle drift shake & zoom check
	var is_drifting: bool = false
	var drift_v = target_vehicle.get("is_drifting")
	if drift_v != null:
		is_drifting = bool(drift_v)
	var is_high_angle: bool = false
	var ha_v = target_vehicle.get("is_high_angle")
	if ha_v != null:
		is_high_angle = bool(ha_v)
	else:
		var deg_v = target_vehicle.get("drift_angle_deg")
		if deg_v != null and is_drifting:
			is_high_angle = absf(float(deg_v)) >= 25.0

	if is_high_angle:
		# Subtle continuous rumble while maintaining high-angle slide
		_trauma = clampf(_trauma + delta * 0.4, 0.0, 0.3)
		var deg_v = target_vehicle.get("drift_angle_deg")
		var angle_deg: float = absf(float(deg_v)) if deg_v != null else 35.0
		var zoom_factor = clampf((angle_deg - 25.0) / 30.0, 0.0, 1.0) * 4.5
		_drift_zoom_offset = lerp(_drift_zoom_offset, zoom_factor, delta * 4.0)
	else:
		_drift_zoom_offset = lerp(_drift_zoom_offset, 0.0, delta * 4.0)

	# Calculate shake offsets from trauma
	var shake: float = _trauma * _trauma
	var shake_h: float = (randf() * 2.0 - 1.0) * max_shake_offset * shake
	var shake_v: float = (randf() * 2.0 - 1.0) * max_shake_offset * shake
	var shake_roll: float = (randf() * 2.0 - 1.0) * deg_to_rad(max_shake_roll_deg) * shake

	# Apply rotation to root pivot
	rotation = Vector3(deg_to_rad(target_pitch_deg), _current_yaw, _current_roll + shake_roll)
	
	# Apply camera shake offsets and dynamic FOV kick
	if camera != null:
		camera.h_offset = shake_h
		camera.v_offset = shake_v
		var speed_ratio = clampf(horizontal_speed / max_fov_speed, 0.0, 1.0)
		var target_fov = lerp(base_fov, max_fov, speed_ratio) + _drift_zoom_offset
		camera.fov = lerp(camera.fov, target_fov, delta * fov_lerp_speed)

	# Decay trauma
	_trauma = maxf(0.0, _trauma - delta * shake_decay)
