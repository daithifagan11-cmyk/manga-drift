class_name SpeedLinesOverlay
extends CanvasLayer

@export var target_vehicle: Node3D
@export var min_speed_kmh: float = 65.0
@export var max_speed_kmh: float = 100.0

@onready var color_rect: ColorRect = $SpeedLinesRect if has_node("SpeedLinesRect") else get_node_or_null("ColorRect")

var _mat: ShaderMaterial
var _current_intensity: float = 0.0
var _target_intensity: float = 0.0
var _current_offset: Vector2 = Vector2.ZERO
var _target_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	if color_rect == null:
		color_rect = find_child("ColorRect", true, false) as ColorRect
	if color_rect == null:
		color_rect = find_child("SpeedLinesRect", true, false) as ColorRect

	if color_rect and color_rect.material is ShaderMaterial:
		_mat = color_rect.material as ShaderMaterial

	_resolve_target_vehicle()

func _resolve_target_vehicle() -> void:
	if target_vehicle != null:
		return
	if get_parent() is VehicleBody3D:
		target_vehicle = get_parent()
		return
	# Search viewport or tree root for active player car
	var car = get_viewport().find_child("DriftCar", true, false)
	if car == null:
		car = get_tree().root.find_child("DriftCar", true, false)
	if car == null:
		car = get_viewport().find_child("Player1Car", true, false)
	if car is Node3D:
		target_vehicle = car

func _process(delta: float) -> void:
	if target_vehicle == null:
		_resolve_target_vehicle()
		if target_vehicle == null:
			_apply_intensity(delta, 0.0, Vector2.ZERO)
			return

	# 1. Read vehicle speed
	var spd: float = 0.0
	var spd_val = target_vehicle.get("current_speed_kmh")
	if spd_val == null and target_vehicle.has_meta("current_speed_kmh"):
		spd_val = target_vehicle.get_meta("current_speed_kmh")
	if spd_val != null:
		spd = float(spd_val)
	elif target_vehicle is RigidBody3D:
		spd = target_vehicle.linear_velocity.length() * 3.6

	# 2. Read drift angle & state
	var drift_angle: float = 0.0
	var angle_val = target_vehicle.get("current_drift_angle")
	if angle_val == null:
		angle_val = target_vehicle.get("drift_angle_deg")
	if angle_val == null and target_vehicle.has_meta("drift_angle_deg"):
		angle_val = target_vehicle.get_meta("drift_angle_deg")
	if angle_val != null:
		drift_angle = absf(float(angle_val))

	var is_drifting: bool = false
	var drift_val = target_vehicle.get("is_drifting")
	if drift_val == null and target_vehicle.has_meta("is_drifting"):
		drift_val = target_vehicle.get_meta("is_drifting")
	if drift_val != null:
		is_drifting = bool(drift_val)
	else:
		is_drifting = drift_angle > 12.0 and spd > 18.0

	var drift_side: float = 0.0
	var side_val = target_vehicle.get("drift_side")
	if side_val == null and target_vehicle.has_meta("drift_side"):
		side_val = target_vehicle.get_meta("drift_side")
	if side_val != null:
		drift_side = float(side_val)

	# 3. Scale intensity from 0.0 to 1.0 as speed exceeds 65 KM/H or during active drifts
	var speed_intensity: float = 0.0
	if spd > min_speed_kmh:
		speed_intensity = clampf((spd - min_speed_kmh) / (max_speed_kmh - min_speed_kmh), 0.0, 1.0)

	var drift_intensity: float = 0.0
	if is_drifting:
		# Scales smoothly with drift angle (15 deg -> ~0.35, 45+ deg -> 1.0)
		drift_intensity = clampf(drift_angle / 42.0, 0.25, 1.0)

	# Combine speed and drift effects
	_target_intensity = maxf(speed_intensity, drift_intensity)
	if is_drifting and spd > 50.0:
		_target_intensity = clampf(_target_intensity * 1.2, 0.0, 1.0)

	# Dynamic lateral focal offset when sliding
	if is_drifting:
		_target_offset = Vector2(drift_side * 0.16, 0.0)
	else:
		_target_offset = Vector2.ZERO

	_apply_intensity(delta, _target_intensity, _target_offset)

func _apply_intensity(delta: float, target_int: float, target_off: Vector2) -> void:
	_current_intensity = lerp(_current_intensity, target_int, delta * 8.5)
	_current_offset = _current_offset.lerp(target_off, delta * 6.0)

	if _mat != null:
		_mat.set_shader_parameter("intensity", _current_intensity)
		_mat.set_shader_parameter("center_offset", _current_offset)

func get_current_intensity() -> float:
	return _current_intensity
