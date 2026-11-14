extends Node3D
class_name OnomatopoeiaPopup

@onready var label: Label3D = $Label3D

@export var float_speed: float = 2.4
@export var lifetime: float = 0.85

var _timer: float = 0.0
var _initial_scale: Vector3 = Vector3.ONE

func _ready() -> void:
	_initial_scale = scale
	scale = Vector3.ZERO
	# Punchy pop-in tween with elastic bounce
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", _initial_scale * 1.35, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "scale", _initial_scale, 0.1)

func setup(text: String, color: Color = Color(1.0, 0.9, 0.1), tilt_deg: float = 0.0) -> void:
	if not is_inside_tree():
		await ready
	label.text = text
	label.modulate = color
	# Manga sound effect slant/tilt
	if tilt_deg != 0.0:
		label.rotation.z = deg_to_rad(tilt_deg)
	else:
		label.rotation.z = deg_to_rad(randf_range(-14.0, 14.0))

func _process(delta: float) -> void:
	_timer += delta
	global_position.y += float_speed * delta
	
	if _timer > lifetime * 0.55:
		var fade_ratio = 1.0 - ((_timer - lifetime * 0.55) / (lifetime * 0.45))
		label.modulate.a = clampf(fade_ratio, 0.0, 1.0)
		label.outline_modulate.a = clampf(fade_ratio, 0.0, 1.0)
		
	if _timer >= lifetime:
		queue_free()
