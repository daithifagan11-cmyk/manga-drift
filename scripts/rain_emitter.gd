class_name RainEmitter
extends Node3D

@export var follow_target: Node3D
@export var height_above_target: float = 12.0
@export var rain_particles: GPUParticles3D

func _ready() -> void:
	set_as_top_level(true)
	if rain_particles == null:
		rain_particles = get_node_or_null("GPUParticles3D") as GPUParticles3D
	_resolve_target()

func _resolve_target() -> void:
	if follow_target != null:
		return
	if get_parent() is VehicleBody3D:
		follow_target = get_parent()
		return
	var cam = get_viewport().get_camera_3d()
	if cam != null:
		follow_target = cam
		return
	var car = get_viewport().find_child("DriftCar", true, false)
	if car == null:
		car = get_tree().root.find_child("DriftCar", true, false)
	if car is Node3D:
		follow_target = car

func _process(delta: float) -> void:
	if follow_target == null:
		_resolve_target()
		if follow_target == null:
			return

	var target_pos: Vector3 = follow_target.global_position
	# Smoothly track above vehicle / camera so streaks follow everywhere
	var desired_pos := Vector3(target_pos.x, target_pos.y + height_above_target, target_pos.z)
	global_position = global_position.lerp(desired_pos, delta * 12.0)
