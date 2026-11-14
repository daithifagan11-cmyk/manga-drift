extends CanvasLayer
class_name MangaHUD

@export var car: DriftCar

@onready var speed_lines_rect: ColorRect = $SpeedLinesRect
@onready var drift_points_label: Label = $VBoxContainer/DriftPointsLabel
@onready var combo_label: Label = $VBoxContainer/ComboLabel
@onready var angle_bar: ProgressBar = $VBoxContainer/AngleBar
@onready var angle_label: Label = $VBoxContainer/AngleLabel
@onready var banked_score_label: Label = $TopRightContainer/BankedScoreLabel
@onready var timer_label: Label = $TopCenterContainer/TimerLabel
@onready var speedometer_label: Label = $BottomRightContainer/SpeedometerLabel

var _speed_lines_mat: ShaderMaterial
var _target_intensity: float = 0.0
var _current_intensity: float = 0.0
var _target_offset: Vector2 = Vector2.ZERO
var _current_offset: Vector2 = Vector2.ZERO

var time_up_triggered: bool = false
var time_left: float = 120.0

func _ready() -> void:
	if speed_lines_rect != null and speed_lines_rect.material is ShaderMaterial:
		_speed_lines_mat = speed_lines_rect.material as ShaderMaterial
		
	if car == null and get_parent() is DriftCar:
		car = get_parent()
		
	if car != null:
		car.drift_updated.connect(_on_drift_updated)
		car.combo_increased.connect(_on_combo_increased)
		car.wall_hit.connect(_on_wall_hit)
		car.drift_banked.connect(_on_drift_banked)

func _process(delta: float) -> void:
	if _speed_lines_mat != null:
		# Smoothly interpolate intensity and center offset
		_current_intensity = lerp(_current_intensity, _target_intensity, delta * 7.0)
		_current_offset = _current_offset.lerp(_target_offset, delta * 5.0)
		
		_speed_lines_mat.set_shader_parameter("intensity", _current_intensity)
		_speed_lines_mat.set_shader_parameter("center_offset", _current_offset)

func _on_drift_updated(info: Dictionary) -> void:
	var is_drifting: bool = info.get("is_drifting", false)
	var angle: float = info.get("drift_angle", 0.0)
	var drift_side: float = info.get("drift_side", 0.0)
	var speed: float = info.get("speed_kph", 0.0)
	var combo: int = info.get("combo_multiplier", 1)
	var unbanked: float = info.get("unbanked_score", 0.0)
	var banked: float = info.get("total_banked_score", 0.0)
	time_left = info.get("time_left", info.get("stage_time_left", time_left))
	
	# Update Drift Points
	if unbanked > 0.0:
		drift_points_label.text = "%d PTS" % int(unbanked)
		drift_points_label.visible = true
	else:
		drift_points_label.text = "0 PTS"
		drift_points_label.visible = is_drifting
		
	# Update Combo
	if combo > 1:
		combo_label.text = "COMBO x%d!" % combo
		combo_label.visible = true
	else:
		combo_label.visible = is_drifting
		combo_label.text = "COMBO x1"
		
	# Update Angle
	if angle_bar != null:
		angle_bar.value = clampf(angle, 0.0, 70.0)
	if angle_label != null:
		angle_label.text = "DRIFT ANGLE: %d°" % int(angle)
		
	# Update Banked Score
	banked_score_label.text = "TOTAL BANKED: %d" % int(banked)
	
	# Update Stage Timer (MM:SS)
	var mins = int(maxf(0.0, time_left)) / 60
	var secs = int(maxf(0.0, time_left)) % 60
	timer_label.text = "%02d:%02d" % [mins, secs]
	if time_left < 15.0:
		timer_label.modulate = Color(1.0, 0.2, 0.2) if int(time_left * 4) % 2 == 0 else Color.WHITE
	else:
		timer_label.modulate = Color.WHITE

	if time_left <= 0.0 and not time_up_triggered:
		_trigger_return_to_main_menu()
		return
		
	# Speedometer (displays 0 KM/H up to 100 KM/H)
	if speedometer_label != null:
		speedometer_label.text = "%d KM/H" % clampi(int(round(speed)), 0, 100)
	
	# Speed lines procedural intensification based on drift speed & angle
	var forward_factor = clampf((speed - 45.0) / 75.0, 0.0, 0.35)
	var drift_intensity = 0.0
	
	if is_drifting and speed > 20.0:
		var speed_factor = clampf((speed - 20.0) / 55.0, 0.0, 1.0)
		var angle_factor = clampf(angle / 40.0, 0.3, 1.25)
		drift_intensity = speed_factor * angle_factor * 0.8
		# Offset center slightly in drift direction to showcase lateral slide momentum
		_target_offset = Vector2(drift_side * 0.12, 0.0)
	else:
		_target_offset = Vector2.ZERO
		
	_target_intensity = clampf(forward_factor + drift_intensity, 0.0, 1.0)

func _trigger_return_to_main_menu() -> void:
	if time_up_triggered:
		return
	time_left = 0.0
	time_up_triggered = true
	
	if timer_label != null:
		timer_label.text = "00:00"
		
	# Bank any remaining unbanked drift combo points into the total score
	if car != null:
		if car.has_method("_bank_current_combo"):
			car._bank_current_combo()
		elif "unbanked_score" in car and "total_banked_score" in car:
			car.total_banked_score += car.unbanked_score
			car.unbanked_score = 0.0
		if "time_up_triggered" in car:
			car.time_up_triggered = true
			
	# Ensure game is unpaused and restore mouse cursor
	if get_tree() != null:
		get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Immediately transition back to the main menu
	if get_tree() != null:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_combo_increased(new_multiplier: int) -> void:
	if combo_label != null:
		var tween = create_tween()
		tween.tween_property(combo_label, "scale", Vector2(1.4, 1.4), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.chain().tween_property(combo_label, "scale", Vector2.ONE, 0.12)

func _on_wall_hit() -> void:
	if drift_points_label != null:
		drift_points_label.text = "COMBO LOST!"
		var tween = create_tween()
		tween.tween_property(drift_points_label, "modulate", Color.RED, 0.05)
		tween.tween_property(drift_points_label, "modulate", Color.WHITE, 0.3)

func _on_drift_banked(amount: float) -> void:
	if banked_score_label != null:
		var tween = create_tween()
		tween.tween_property(banked_score_label, "scale", Vector2(1.2, 1.2), 0.1)
		tween.chain().tween_property(banked_score_label, "scale", Vector2.ONE, 0.15)
