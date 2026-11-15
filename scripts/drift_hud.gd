extends CanvasLayer
class_name DriftHUD

@export_file("*.tscn") var main_menu_path: String = "res://scenes/main_menu.tscn"
@export var car: DriftCar

# Split-Screen configuration
@export var is_split_screen: bool = false
@export var player_title: String = ""
@export var player_color: Color = Color.WHITE

var player_badge_label: Label
var cash_label: Label

# Gameplay & Timer settings
var time_left: float = 120.0
var time_up_triggered: bool = false
var total_banked_score: int = 0
var high_score: int = 0
var save_path: String = "user://touge_highscore.save"

# Node references & aliases
@onready var speed_lines_rect: ColorRect = get_node_or_null("SpeedLinesRect") as ColorRect
@onready var drift_points_label: Label = get_node_or_null("LeftPanel/VBox/DriftPointsLabel") as Label
@onready var combo_badge: Label = get_node_or_null("LeftPanel/VBox/ComboBadge") as Label
@onready var angle_label: Label = get_node_or_null("LeftPanel/VBox/AngleLabel") as Label
@onready var angle_bar: ProgressBar = get_node_or_null("LeftPanel/VBox/AngleBar") as ProgressBar
@onready var bank_timer_bar: ProgressBar = get_node_or_null("LeftPanel/VBox/BankTimerBar") as ProgressBar
@onready var bank_timer_label: Label = get_node_or_null("LeftPanel/VBox/BankTimerLabel") as Label
@onready var high_angle_badge: Label = get_node_or_null("LeftPanel/VBox/HighAngleBadge") as Label

@onready var timer_label: Label = get_node_or_null("TopCenterPanel/StageTimerLabel") as Label
@onready var stage_timer_label: Label = timer_label
@onready var banked_label: Label = get_node_or_null("TopRightPanel/BankedScoreLabel") as Label
@onready var banked_score_label: Label = banked_label
@onready var high_score_label: Label = get_node_or_null("HighScoreLabel") as Label
@onready var speedometer_label: Label = get_node_or_null("BottomRightPanel/VBox/SpeedometerLabel") as Label
@onready var notification_banner: Label = get_node_or_null("CenterNotification/BannerLabel") as Label

var _speed_lines_mat: ShaderMaterial
var _target_intensity: float = 0.0
var _current_intensity: float = 0.0
var _target_offset: Vector2 = Vector2.ZERO
var _current_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	if is_split_screen:
		_adapt_for_split_screen()
	else:
		_load_high_score()
		_setup_middle_high_score_ui()

	if speed_lines_rect != null and speed_lines_rect.material is ShaderMaterial:
		if get_parent() != null and get_parent().has_node("MangaSpeedFX"):
			speed_lines_rect.visible = false
			_speed_lines_mat = null
		else:
			_speed_lines_mat = speed_lines_rect.material as ShaderMaterial
		
	if car == null and get_parent() is DriftCar:
		car = get_parent()
		
	if car != null:
		if car.has_signal("drift_updated"):
			car.drift_updated.connect(_on_drift_updated)
		if car.has_signal("combo_increased"):
			car.combo_increased.connect(_on_combo_increased)
		if car.has_signal("wall_hit"):
			car.wall_hit.connect(_on_wall_hit)
		if car.has_signal("drift_banked"):
			car.drift_banked.connect(_on_drift_banked)
		
	if notification_banner != null:
		notification_banner.modulate.a = 0.0

	_setup_cash_display()
	if not CoinManager.money_changed.is_connected(_on_money_changed):
		CoinManager.money_changed.connect(_on_money_changed)

func _exit_tree() -> void:
	if CoinManager.money_changed.is_connected(_on_money_changed):
		CoinManager.money_changed.disconnect(_on_money_changed)

func _setup_cash_display() -> void:
	if cash_label == null:
		cash_label = Label.new()
		cash_label.name = "CashLabel"
		cash_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		cash_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cash_label.offset_left = -360.0
		cash_label.offset_right = -35.0 if not is_split_screen else -16.0
		cash_label.offset_top = 74.0 if not is_split_screen else 50.0
		cash_label.offset_bottom = 112.0 if not is_split_screen else 84.0
		cash_label.add_theme_font_size_override("font_size", 24 if not is_split_screen else 18)
		cash_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.14))
		cash_label.add_theme_color_override("font_outline_color", Color.BLACK)
		cash_label.add_theme_constant_override("outline_size", 10)
		add_child(cash_label)
	_on_money_changed(CoinManager.player_money)

func _on_money_changed(new_amount: int) -> void:
	if cash_label != null:
		cash_label.text = "CASH: $%d" % new_amount

func _process(delta: float) -> void:
	if time_up_triggered:
		return

	if _speed_lines_mat != null:
		# Smooth speed lines interpolation
		_current_intensity = lerp(_current_intensity, _target_intensity, delta * 8.0)
		_current_offset = _current_offset.lerp(_target_offset, delta * 5.0)
		_speed_lines_mat.set_shader_parameter("intensity", _current_intensity)
		_speed_lines_mat.set_shader_parameter("center_offset", _current_offset)

	# Update bottom-right speedometer every frame directly from car
	if car != null and speedometer_label != null:
		var spd: float = car.current_speed_kmh
		speedometer_label.text = "%d KM/H" % clampi(int(round(spd)), 0, 150)

	if car == null:
		time_left -= delta

	if time_left <= 0.0:
		time_left = 0.0
		time_up_triggered = true
		_check_and_save_high_score()
		_return_to_main_menu()
		return

	_update_timer_display()

func _setup_middle_high_score_ui() -> void:
	# If HighScoreLabel isn't in your scene yet, create it dynamically in the middle-top
	if not high_score_label:
		high_score_label = Label.new()
		high_score_label.name = "HighScoreLabel"
		high_score_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
		high_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		high_score_label.position = Vector2(0, 75) # Positioned right below the 2-min timer in the center
		high_score_label.add_theme_font_size_override("font_size", 24)
		high_score_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0)) # Gold / Yellow
		high_score_label.add_theme_constant_override("outline_size", 4)
		high_score_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
		add_child(high_score_label)
	
	_refresh_high_score_display()

func _refresh_high_score_display() -> void:
	if high_score_label:
		high_score_label.text = "★ ALL-TIME HIGH SCORE: " + str(high_score) + " ★"

func _adapt_for_split_screen() -> void:
	if high_score_label != null:
		high_score_label.visible = false

	# Create sleek Player Badge Label at top center
	player_badge_label = Label.new()
	player_badge_label.name = "PlayerBadgeLabel"
	player_badge_label.text = player_title if player_title != "" else "PLAYER"
	player_badge_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	player_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_badge_label.position = Vector2(0, 16)
	player_badge_label.add_theme_font_size_override("font_size", 20)
	player_badge_label.add_theme_color_override("font_color", player_color)
	player_badge_label.add_theme_color_override("font_outline_color", Color.BLACK)
	player_badge_label.add_theme_constant_override("outline_size", 8)
	add_child(player_badge_label)

	# Adjust StageTimerLabel
	if stage_timer_label != null:
		stage_timer_label.add_theme_font_size_override("font_size", 34)
		var top_panel = stage_timer_label.get_parent() as Control
		if top_panel != null:
			top_panel.offset_top = 44.0
			top_panel.offset_bottom = 90.0

	# Adjust BankedScoreLabel to stay within half-width boundaries
	if banked_score_label != null:
		banked_score_label.add_theme_font_size_override("font_size", 22)
		var tr_panel = banked_score_label.get_parent() as Control
		if tr_panel != null:
			tr_panel.offset_left = -300.0
			tr_panel.offset_top = 18.0
			tr_panel.offset_right = -16.0

	# Scale LeftPanel (Points, combo, angle)
	var left_panel = get_node_or_null("LeftPanel") as Control
	if left_panel != null:
		left_panel.offset_left = 16.0
		left_panel.offset_top = 18.0
	if combo_badge != null:
		combo_badge.add_theme_font_size_override("font_size", 30)
	if drift_points_label != null:
		drift_points_label.add_theme_font_size_override("font_size", 24)

	# Scale BottomRightPanel (Speedometer)
	if speedometer_label != null:
		speedometer_label.add_theme_font_size_override("font_size", 26)


func add_banked_points(pts: int) -> void:
	total_banked_score += pts
	if total_banked_score > high_score:
		high_score = total_banked_score
		_check_and_save_high_score()
	_refresh_high_score_display()
	if banked_label != null:
		banked_label.text = "TOTAL BANKED: %d" % total_banked_score

func _check_and_save_high_score() -> void:
	if total_banked_score > high_score:
		high_score = total_banked_score
	
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_64(high_score)
		file.close()

func _load_high_score() -> void:
	if FileAccess.file_exists(save_path):
		var file := FileAccess.open(save_path, FileAccess.READ)
		if file:
			high_score = file.get_64()
			file.close()

func _update_timer_display() -> void:
	if timer_label:
		var clamped_time: float = maxf(0.0, time_left)
		var mins: int = int(clamped_time) / 60
		var secs: int = int(clamped_time) % 60
		timer_label.text = "%02d:%02d" % [mins, secs]
		if clamped_time < 15.0 and clamped_time > 0.0:
			timer_label.modulate = Color(1.0, 0.25, 0.25) if int(clamped_time * 4) % 2 == 0 else Color.WHITE
		else:
			timer_label.modulate = Color.WHITE

func _return_to_main_menu() -> void:
	if get_tree() != null:
		get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if get_tree() != null:
		get_tree().change_scene_to_file(main_menu_path)

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
			
	_check_and_save_high_score()
	_return_to_main_menu()

func _on_drift_updated(info: Dictionary) -> void:
	var is_drifting: bool = info.get("is_drifting", false)
	var is_high_angle: bool = info.get("is_high_angle", false)
	var angle: float = info.get("drift_angle", 0.0)
	var drift_side: float = info.get("drift_side", 0.0)
	var speed: float = info.get("speed_kph", 0.0)
	var combo: int = info.get("combo_multiplier", 1)
	var unbanked: float = info.get("unbanked_score", 0.0)
	var banked: float = info.get("total_banked_score", 0.0)
	var bank_ratio: float = info.get("bank_ratio", 1.0)
	time_left = info.get("time_left", info.get("stage_time_left", time_left))
	
	# 1. Unbanked Drift Score
	if drift_points_label != null:
		if unbanked > 0.0:
			drift_points_label.text = "%d PTS" % int(unbanked)
			drift_points_label.visible = true
		else:
			drift_points_label.text = "0 PTS"
			drift_points_label.visible = is_drifting
		
	# 2. Combo Multiplier Badge
	if combo_badge != null:
		if combo > 1:
			combo_badge.text = "COMBO x%d!" % combo
			combo_badge.visible = true
		else:
			combo_badge.text = "COMBO x1"
			combo_badge.visible = is_drifting
		
	# 3. Drift Angle Gauge
	if angle_bar != null:
		angle_bar.value = clampf(angle, 0.0, 70.0)
	if angle_label != null:
		angle_label.text = "DRIFT ANGLE: %d°" % int(angle)
		
	# 4. High Angle Indicator
	if high_angle_badge != null:
		high_angle_badge.visible = is_high_angle
		
	# 5. Straight Driving Bank Timer Bar (2.5s window)
	if bank_timer_bar != null and bank_timer_label != null:
		if unbanked > 0.0 and not is_drifting:
			bank_timer_bar.visible = true
			bank_timer_label.visible = true
			bank_timer_bar.value = bank_ratio * 100.0
		else:
			bank_timer_bar.visible = false
			bank_timer_label.visible = false
			
	# 6. Total Banked Score & High Score sync
	if int(banked) > total_banked_score:
		total_banked_score = int(banked)
		if total_banked_score > high_score:
			high_score = total_banked_score
			_check_and_save_high_score()
		_refresh_high_score_display()
		
	if banked_label != null:
		banked_label.text = "TOTAL BANKED: %d" % total_banked_score
		
	# 7. 120-second Stage Countdown Timer
	_update_timer_display()
			
	# 8. Speedometer
	if speedometer_label != null:
		var display_spd: int = clampi(int(round(speed)), 0, 150)
		speedometer_label.text = "%d KM/H" % display_spd
		
	# 9. Speed lines: visible around screen edges when speed exceeds 65 KM/H or during active drifts
	var speed_factor = clampf((speed - 65.0) / 35.0, 0.0, 1.0) if speed > 65.0 else 0.0
	var drift_factor = clampf(angle / 42.0, 0.25, 1.0) if is_drifting else 0.0
	_target_intensity = maxf(speed_factor, drift_factor)
	if is_drifting and speed > 50.0:
		_target_intensity = clampf(_target_intensity * 1.2, 0.0, 1.0)
	if is_drifting:
		_target_offset = Vector2(drift_side * 0.16, 0.0)
	else:
		_target_offset = Vector2.ZERO

	if time_left <= 0.0 and not time_up_triggered:
		time_left = 0.0
		time_up_triggered = true
		_check_and_save_high_score()
		_return_to_main_menu()

func _on_combo_increased(new_multiplier: int) -> void:
	if combo_badge != null:
		var tween = create_tween()
		tween.tween_property(combo_badge, "scale", Vector2(1.45, 1.45), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.chain().tween_property(combo_badge, "scale", Vector2.ONE, 0.12)

func _on_wall_hit() -> void:
	_show_banner("COMBO CANCELLED!", Color(1.0, 0.2, 0.2))

func _on_drift_banked(amount: float) -> void:
	if int(amount) <= 0:
		return
	add_banked_points(int(amount))
	_show_banner("+%d PTS BANKED!" % int(amount), Color(1.0, 0.9, 0.2))
	if banked_label != null:
		var tween = create_tween()
		tween.tween_property(banked_label, "scale", Vector2(1.2, 1.2), 0.1)
		tween.chain().tween_property(banked_label, "scale", Vector2.ONE, 0.14)

func _show_banner(text: String, color: Color) -> void:
	if notification_banner == null:
		return
	notification_banner.text = text
	notification_banner.modulate = color
	notification_banner.modulate.a = 1.0
	
	var tween = create_tween()
	tween.tween_property(notification_banner, "scale", Vector2(1.3, 1.3), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(notification_banner, "scale", Vector2.ONE, 0.15)
	tween.tween_interval(0.65)
	tween.tween_property(notification_banner, "modulate:a", 0.0, 0.35)
