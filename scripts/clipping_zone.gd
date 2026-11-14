extends Area3D
class_name ClippingZone

@export var bonus_points: float = 1000.0
@export var zone_name: String = "APEX 1"

var _active: bool = true
var _cooldown_timer: float = 0.0

@onready var neon_mesh: MeshInstance3D = $NeonPad
@onready var label: Label3D = $Label3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if not _active:
		_cooldown_timer -= delta
		if _cooldown_timer <= 0.0:
			_active = true
			if neon_mesh != null:
				neon_mesh.visible = true
			if label != null:
				label.visible = true

func _on_body_entered(body: Node3D) -> void:
	if not _active:
		return
		
	if body is DriftCar:
		var car = body as DriftCar
		if car.is_drifting:
			_active = false
			_cooldown_timer = 6.0
			car.unbanked_score += bonus_points
			
			# Spawn celebration popup above car
			var popup_pos = car.global_position + Vector3(0, 1.2, 0)
			car._spawn_onomatopoeia("+1000 CLIPPING!", popup_pos, Color(0.2, 1.0, 0.9))
			
			# Temporarily dim pad until cooldown resets
			if neon_mesh != null:
				neon_mesh.visible = false
			if label != null:
				label.visible = false
