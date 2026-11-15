class_name MainMenu
extends Node3D

@export var target_scene_path: String = "res://scenes/test_arena.tscn"

# Static variables accessible across scenes
static var selected_car_path: String = "res://scenes/drift_car.tscn"
static var selected_car_name: String = "PANDA AE86 TRUENO"

# Camera references
@onready var camera: Camera3D = $CameraRig/Camera3D
@onready var showcase_car: Node3D = $ShowcaseCar

# UI references - Main Tile Menu
@onready var menu_container: Control = $MenuCanvas/MenuContainer
@onready var menu_vbox: VBoxContainer = $MenuCanvas/MenuContainer/ButtonList
@onready var play_button: Button = $MenuCanvas/MenuContainer/ButtonList/PlayButton
@onready var maps_button: Button = $MenuCanvas/MenuContainer/ButtonList/MapsButton
@onready var quit_button: Button = $MenuCanvas/MenuContainer/ButtonList/QuitButton

@onready var play_title: Label = $MenuCanvas/MenuContainer/ButtonList/PlayButton/Margin/HBox/TextVBox/TitleLabel
@onready var play_sub: Label = $MenuCanvas/MenuContainer/ButtonList/PlayButton/Margin/HBox/TextVBox/SubLabel
@onready var play_icon: TextureRect = $MenuCanvas/MenuContainer/ButtonList/PlayButton/Margin/HBox/IconRect

@onready var maps_title: Label = $MenuCanvas/MenuContainer/ButtonList/MapsButton/Margin/HBox/TextVBox/TitleLabel
@onready var maps_sub: Label = $MenuCanvas/MenuContainer/ButtonList/MapsButton/Margin/HBox/TextVBox/SubLabel
@onready var maps_icon: TextureRect = $MenuCanvas/MenuContainer/ButtonList/MapsButton/Margin/HBox/IconRect

@onready var quit_title: Label = $MenuCanvas/MenuContainer/ButtonList/QuitButton/Margin/HBox/TextVBox/TitleLabel
@onready var quit_sub: Label = $MenuCanvas/MenuContainer/ButtonList/QuitButton/Margin/HBox/TextVBox/SubLabel
@onready var quit_icon: TextureRect = $MenuCanvas/MenuContainer/ButtonList/QuitButton/Margin/HBox/IconRect

# UI references - Maps Sub-Menu Overlay
@onready var maps_container: Control = $MenuCanvas/MapsContainer
@onready var map_default_button: Button = get_node_or_null("MenuCanvas/MapsContainer/VBox/MapDefaultButton") as Button
@onready var map_default_title: Label = get_node_or_null("MenuCanvas/MapsContainer/VBox/MapDefaultButton/Margin/HBox/TextVBox/TitleLabel") as Label
@onready var map_default_sub: Label = get_node_or_null("MenuCanvas/MapsContainer/VBox/MapDefaultButton/Margin/HBox/TextVBox/SubLabel") as Label
@onready var map_default_icon: TextureRect = get_node_or_null("MenuCanvas/MapsContainer/VBox/MapDefaultButton/Margin/HBox/IconRect") as TextureRect

@onready var map_ebisu_button: Button = get_node_or_null("MenuCanvas/MapsContainer/VBox/MapEbisuButton") as Button
@onready var map_ebisu_title: Label = get_node_or_null("MenuCanvas/MapsContainer/VBox/MapEbisuButton/Margin/HBox/TextVBox/TitleLabel") as Label
@onready var map_ebisu_sub: Label = get_node_or_null("MenuCanvas/MapsContainer/VBox/MapEbisuButton/Margin/HBox/TextVBox/SubLabel") as Label
@onready var map_ebisu_icon: TextureRect = get_node_or_null("MenuCanvas/MapsContainer/VBox/MapEbisuButton/Margin/HBox/IconRect") as TextureRect

@onready var map_splitscreen_button: Button = get_node_or_null("MenuCanvas/MapsContainer/VBox/MapSplitScreenButton") as Button
@onready var map_splitscreen_title: Label = get_node_or_null("MenuCanvas/MapsContainer/VBox/MapSplitScreenButton/Margin/HBox/TextVBox/TitleLabel") as Label
@onready var map_splitscreen_sub: Label = get_node_or_null("MenuCanvas/MapsContainer/VBox/MapSplitScreenButton/Margin/HBox/TextVBox/SubLabel") as Label
@onready var map_splitscreen_icon: TextureRect = get_node_or_null("MenuCanvas/MapsContainer/VBox/MapSplitScreenButton/Margin/HBox/IconRect") as TextureRect

@onready var back_to_menu_button: Button = $MenuCanvas/MapsContainer/VBox/BackToMenuButton
@onready var back_title: Label = $MenuCanvas/MapsContainer/VBox/BackToMenuButton/Margin/HBox/TextVBox/TitleLabel
@onready var back_sub: Label = $MenuCanvas/MapsContainer/VBox/BackToMenuButton/Margin/HBox/TextVBox/SubLabel
@onready var back_icon: TextureRect = $MenuCanvas/MapsContainer/VBox/BackToMenuButton/Margin/HBox/IconRect

# UI references - Car Selection Screen
@onready var car_select_panel: Control = get_node_or_null("MenuCanvas/CarSelectContainer") as Control
@onready var car_select_container: Control = car_select_panel

@onready var car_ae86_button: Button = get_node_or_null("MenuCanvas/CarSelectContainer/VBox/CarAE86Button") as Button
@onready var car_ae86_title: Label = get_node_or_null("MenuCanvas/CarSelectContainer/VBox/CarAE86Button/Margin/HBox/TextVBox/TitleLabel") as Label
@onready var car_ae86_sub: Label = get_node_or_null("MenuCanvas/CarSelectContainer/VBox/CarAE86Button/Margin/HBox/TextVBox/SubLabel") as Label
@onready var car_ae86_badge: Label = get_node_or_null("MenuCanvas/CarSelectContainer/VBox/CarAE86Button/Margin/HBox/BadgeLabel") as Label
@onready var car_ae86_icon: TextureRect = get_node_or_null("MenuCanvas/CarSelectContainer/VBox/CarAE86Button/Margin/HBox/IconRect") as TextureRect

@onready var car_rx7_button: Button = get_node_or_null("MenuCanvas/CarSelectContainer/VBox/CarRX7Button") as Button
@onready var car_rx7_title: Label = get_node_or_null("MenuCanvas/CarSelectContainer/VBox/CarRX7Button/Margin/HBox/TextVBox/TitleLabel") as Label
@onready var car_rx7_sub: Label = get_node_or_null("MenuCanvas/CarSelectContainer/VBox/CarRX7Button/Margin/HBox/TextVBox/SubLabel") as Label
@onready var car_rx7_badge: Label = get_node_or_null("MenuCanvas/CarSelectContainer/VBox/CarRX7Button/Margin/HBox/BadgeLabel") as Label
@onready var car_rx7_icon: TextureRect = get_node_or_null("MenuCanvas/CarSelectContainer/VBox/CarRX7Button/Margin/HBox/IconRect") as TextureRect

@onready var car_s15_button: Button = get_node_or_null("MenuCanvas/CarSelectContainer/VBox/CarS15Button") as Button
@onready var car_s15_title: Label = get_node_or_null("MenuCanvas/CarSelectContainer/VBox/CarS15Button/Margin/HBox/TextVBox/TitleLabel") as Label
@onready var car_s15_sub: Label = get_node_or_null("MenuCanvas/CarSelectContainer/VBox/CarS15Button/Margin/HBox/TextVBox/SubLabel") as Label
@onready var car_s15_badge: Label = get_node_or_null("MenuCanvas/CarSelectContainer/VBox/CarS15Button/Margin/HBox/BadgeLabel") as Label
@onready var car_s15_icon: TextureRect = get_node_or_null("MenuCanvas/CarSelectContainer/VBox/CarS15Button/Margin/HBox/IconRect") as TextureRect

@onready var start_drift_button: Button = get_node_or_null("MenuCanvas/CarSelectContainer/VBox/StartDriftButton") as Button
@onready var start_drift_title: Label = get_node_or_null("MenuCanvas/CarSelectContainer/VBox/StartDriftButton/Margin/HBox/TextVBox/TitleLabel") as Label
@onready var start_drift_sub: Label = get_node_or_null("MenuCanvas/CarSelectContainer/VBox/StartDriftButton/Margin/HBox/TextVBox/SubLabel") as Label
@onready var start_drift_icon: TextureRect = get_node_or_null("MenuCanvas/CarSelectContainer/VBox/StartDriftButton/Margin/HBox/IconRect") as TextureRect

@onready var back_to_maps_button: Button = get_node_or_null("MenuCanvas/CarSelectContainer/VBox/BackToMapsButton") as Button
@onready var back_to_maps_title: Label = get_node_or_null("MenuCanvas/CarSelectContainer/VBox/BackToMapsButton/Margin/HBox/TextVBox/TitleLabel") as Label
@onready var back_to_maps_sub: Label = get_node_or_null("MenuCanvas/CarSelectContainer/VBox/BackToMapsButton/Margin/HBox/TextVBox/SubLabel") as Label
@onready var back_to_maps_icon: TextureRect = get_node_or_null("MenuCanvas/CarSelectContainer/VBox/BackToMapsButton/Margin/HBox/IconRect") as TextureRect

# Loading Screen references
@onready var loading_container: Control = $MenuCanvas/LoadingContainer
@onready var loading_label: Label = $MenuCanvas/LoadingContainer/VBox/LoadingLabel
@onready var loading_bar: ProgressBar = $MenuCanvas/LoadingContainer/VBox/ProgressBar

# Multiplayer sub-menu references
var multiplayer_container: MarginContainer
var mp_main_btn: Button
var mp_touge_button: Button
var mp_ebisu_button: Button
var mp_industrial_button: Button
var back_from_mp_button: Button
var _prev_menu_before_mp: Control = null

# Singleplayer 3rd map card
var map_industrial_button: Button

# Garage speed & turbo upgrade UI
var upgrade_speed_button: Button
var upgrade_speed_sub: Label
var upgrade_turbo_button: Button
var upgrade_turbo_sub: Label
var garage_wallet_label: Label

# Colors matching the reference UI specification
const COLOR_NORMAL_TEXT: Color = Color(0.12, 0.14, 0.18, 1.0) # Dark charcoal
const COLOR_NORMAL_SUB: Color = Color(0.38, 0.42, 0.48, 1.0)
const COLOR_HOVER_TEXT: Color = Color(1.0, 1.0, 1.0, 1.0) # Pure white
const COLOR_HOVER_SUB: Color = Color(0.85, 0.92, 1.0, 1.0)

var _initial_cam_pos: Vector3
var _car_target_pos: Vector3 = Vector3(2.1, 0.72, -0.2)
var _look_target_pos: Vector3 = Vector3(0.6, 0.72, -0.2)
var _zoom_target_pos: Vector3 = Vector3(0.8, 0.95, 2.6)
var _orbit_time: float = 0.0
var _is_transitioning: bool = false
var _loading_elapsed: float = 0.0
var _loading_map_name: String = "TOUGE PASS"
var menu_music: AudioStreamPlayer

func _ready() -> void:
	# Configure camera initial state
	if camera != null:
		_initial_cam_pos = camera.position
		camera.look_at(_look_target_pos, Vector3.UP)
		
	# Disable physics & HUD on showcase car so it stays parked quietly in the paddock
	_freeze_showcase_car()
	
	# Load SVG icons
	_setup_icons()
	
	# Setup and play looping background music
	_setup_menu_music()
	
	# Build / configure left tile UI
	_build_left_tile_ui()
	
	# Hide loading & car select containers initially
	if loading_container != null:
		loading_container.visible = false
		loading_container.modulate.a = 0.0
	if loading_bar != null:
		loading_bar.value = 0.0
	if car_select_panel != null:
		car_select_panel.visible = false
		car_select_panel.modulate.a = 0.0
	
	# Focus play button by default for gamepad/keyboard accessibility
	if play_button != null:
		play_button.grab_focus()

func _build_left_tile_ui() -> void:
	# Connect Button 1: PLAY
	if play_button != null:
		play_button.pressed.connect(_on_maps_pressed) # Opens map selection
		play_button.mouse_entered.connect(func(): _set_button_highlight(play_button, play_title, play_sub, play_icon, true))
		play_button.mouse_exited.connect(func(): if not play_button.has_focus(): _set_button_highlight(play_button, play_title, play_sub, play_icon, false))
		play_button.focus_entered.connect(func(): _set_button_highlight(play_button, play_title, play_sub, play_icon, true))
		play_button.focus_exited.connect(func(): if not play_button.has_focus(): _set_button_highlight(play_button, play_title, play_sub, play_icon, false))
		_set_button_highlight(play_button, play_title, play_sub, play_icon, false)

	# Connect Button 2 / 3: VIEW MAPS
	if maps_button != null:
		maps_button.pressed.connect(_on_maps_pressed)
		maps_button.mouse_entered.connect(func(): _set_button_highlight(maps_button, maps_title, maps_sub, maps_icon, true))
		maps_button.mouse_exited.connect(func(): if not maps_button.has_focus(): _set_button_highlight(maps_button, maps_title, maps_sub, maps_icon, false))
		maps_button.focus_entered.connect(func(): _set_button_highlight(maps_button, maps_title, maps_sub, maps_icon, true))
		maps_button.focus_exited.connect(func(): if not maps_button.has_focus(): _set_button_highlight(maps_button, maps_title, maps_sub, maps_icon, false))
		_set_button_highlight(maps_button, maps_title, maps_sub, maps_icon, false)

	# Connect Button QUIT
	if quit_button != null:
		quit_button.pressed.connect(_on_quit_pressed)
		quit_button.mouse_entered.connect(func(): _set_button_highlight(quit_button, quit_title, quit_sub, quit_icon, true))
		quit_button.mouse_exited.connect(func(): if not quit_button.has_focus(): _set_button_highlight(quit_button, quit_title, quit_sub, quit_icon, false))
		quit_button.focus_entered.connect(func(): _set_button_highlight(quit_button, quit_title, quit_sub, quit_icon, true))
		quit_button.focus_exited.connect(func(): if not quit_button.has_focus(): _set_button_highlight(quit_button, quit_title, quit_sub, quit_icon, false))
		_set_button_highlight(quit_button, quit_title, quit_sub, quit_icon, false)

	# Connect Maps Sub-Menu Overlay buttons
	if map_default_button != null:
		map_default_button.pressed.connect(_on_map_default_pressed)
		map_default_button.mouse_entered.connect(func(): _set_button_highlight(map_default_button, map_default_title, map_default_sub, map_default_icon, true))
		map_default_button.mouse_exited.connect(func(): if not map_default_button.has_focus(): _set_button_highlight(map_default_button, map_default_title, map_default_sub, map_default_icon, false))
		map_default_button.focus_entered.connect(func(): _set_button_highlight(map_default_button, map_default_title, map_default_sub, map_default_icon, true))
		map_default_button.focus_exited.connect(func(): if not map_default_button.has_focus(): _set_button_highlight(map_default_button, map_default_title, map_default_sub, map_default_icon, false))
		_set_button_highlight(map_default_button, map_default_title, map_default_sub, map_default_icon, false)

	if map_ebisu_button != null:
		map_ebisu_button.pressed.connect(_on_map_ebisu_pressed)
		map_ebisu_button.mouse_entered.connect(func(): _set_button_highlight(map_ebisu_button, map_ebisu_title, map_ebisu_sub, map_ebisu_icon, true))
		map_ebisu_button.mouse_exited.connect(func(): if not map_ebisu_button.has_focus(): _set_button_highlight(map_ebisu_button, map_ebisu_title, map_ebisu_sub, map_ebisu_icon, false))
		map_ebisu_button.focus_entered.connect(func(): _set_button_highlight(map_ebisu_button, map_ebisu_title, map_ebisu_sub, map_ebisu_icon, true))
		map_ebisu_button.focus_exited.connect(func(): if not map_ebisu_button.has_focus(): _set_button_highlight(map_ebisu_button, map_ebisu_title, map_ebisu_sub, map_ebisu_icon, false))
		_set_button_highlight(map_ebisu_button, map_ebisu_title, map_ebisu_sub, map_ebisu_icon, false)

	# 3rd Playable Course: Industrial Tarmac
	var maps_vbox := get_node_or_null("MenuCanvas/MapsContainer/VBox") as VBoxContainer
	if maps_vbox != null:
		var ind_card := _create_custom_card_button("INDUSTRIAL TARMAC (WAREHOUSE)", "COMPOUND TARMAC // 600M OPEN RUN", map_ebisu_icon.texture if map_ebisu_icon else null, Vector2(360, 95))
		map_industrial_button = ind_card.button
		map_industrial_button.name = "MapIndustrialButton"
		maps_vbox.add_child(map_industrial_button)
		var ebisu_idx := map_ebisu_button.get_index() if map_ebisu_button != null else 2
		maps_vbox.move_child(map_industrial_button, ebisu_idx + 1)
		map_industrial_button.pressed.connect(_on_map_industrial_pressed)
		if map_ebisu_button != null:
			map_ebisu_button.focus_neighbor_bottom = map_ebisu_button.get_path_to(map_industrial_button)
			map_industrial_button.focus_neighbor_top = map_industrial_button.get_path_to(map_ebisu_button)

	if map_splitscreen_button != null:
		if map_splitscreen_title != null:
			map_splitscreen_title.text = "MULTIPLAYER (2P)"
		if map_splitscreen_sub != null:
			map_splitscreen_sub.text = "LOCAL 2-PLAYER SPLIT-SCREEN"
		if map_industrial_button != null:
			map_industrial_button.focus_neighbor_bottom = map_industrial_button.get_path_to(map_splitscreen_button)
			map_splitscreen_button.focus_neighbor_top = map_splitscreen_button.get_path_to(map_industrial_button)
		map_splitscreen_button.pressed.connect(_on_multiplayer_pressed)
		map_splitscreen_button.mouse_entered.connect(func(): _set_button_highlight(map_splitscreen_button, map_splitscreen_title, map_splitscreen_sub, map_splitscreen_icon, true))
		map_splitscreen_button.mouse_exited.connect(func(): if not map_splitscreen_button.has_focus(): _set_button_highlight(map_splitscreen_button, map_splitscreen_title, map_splitscreen_sub, map_splitscreen_icon, false))
		map_splitscreen_button.focus_entered.connect(func(): _set_button_highlight(map_splitscreen_button, map_splitscreen_title, map_splitscreen_sub, map_splitscreen_icon, true))
		map_splitscreen_button.focus_exited.connect(func(): if not map_splitscreen_button.has_focus(): _set_button_highlight(map_splitscreen_button, map_splitscreen_title, map_splitscreen_sub, map_splitscreen_icon, false))
		_set_button_highlight(map_splitscreen_button, map_splitscreen_title, map_splitscreen_sub, map_splitscreen_icon, false)

	# Build dedicated Multiplayer Split-Screen selection screen
	_build_multiplayer_ui()

	# Also add MULTIPLAYER (2P) directly on main menu button list
	if menu_vbox != null:
		var mp_main_card := _create_custom_card_button("MULTIPLAYER (2P)", "LOCAL 2-PLAYER SPLIT-SCREEN", map_splitscreen_icon.texture if map_splitscreen_icon else null, Vector2(360, 115))
		mp_main_btn = mp_main_card.button
		mp_main_btn.name = "MultiplayerMainButton"
		if mp_main_card.title != null:
			mp_main_card.title.add_theme_font_size_override("font_size", 28)
		if mp_main_card.sub != null:
			mp_main_card.sub.add_theme_font_size_override("font_size", 11)
		menu_vbox.add_child(mp_main_btn)
		menu_vbox.move_child(mp_main_btn, 2)
		mp_main_btn.pressed.connect(_on_multiplayer_pressed)

		if maps_button != null:
			maps_button.focus_neighbor_bottom = maps_button.get_path_to(mp_main_btn)
		if quit_button != null:
			quit_button.focus_neighbor_top = quit_button.get_path_to(mp_main_btn)
		mp_main_btn.focus_neighbor_top = mp_main_btn.get_path_to(maps_button if maps_button != null else play_button)
		mp_main_btn.focus_neighbor_bottom = mp_main_btn.get_path_to(quit_button)

	if back_to_menu_button != null:
		back_to_menu_button.pressed.connect(_on_back_from_maps_pressed)
		back_to_menu_button.mouse_entered.connect(func(): _set_button_highlight(back_to_menu_button, back_title, back_sub, back_icon, true))
		back_to_menu_button.mouse_exited.connect(func(): if not back_to_menu_button.has_focus(): _set_button_highlight(back_to_menu_button, back_title, back_sub, back_icon, false))
		back_to_menu_button.focus_entered.connect(func(): _set_button_highlight(back_to_menu_button, back_title, back_sub, back_icon, true))
		back_to_menu_button.focus_exited.connect(func(): if not back_to_menu_button.has_focus(): _set_button_highlight(back_to_menu_button, back_title, back_sub, back_icon, false))
		_set_button_highlight(back_to_menu_button, back_title, back_sub, back_icon, false)

	# Connect Car Selection Buttons
	if car_ae86_button != null:
		car_ae86_button.pressed.connect(func(): _select_car(0))
		car_ae86_button.mouse_entered.connect(func(): _set_button_highlight(car_ae86_button, car_ae86_title, car_ae86_sub, car_ae86_icon, true))
		car_ae86_button.mouse_exited.connect(func(): if not car_ae86_button.has_focus(): _set_button_highlight(car_ae86_button, car_ae86_title, car_ae86_sub, car_ae86_icon, false))
		car_ae86_button.focus_entered.connect(func(): _set_button_highlight(car_ae86_button, car_ae86_title, car_ae86_sub, car_ae86_icon, true))
		car_ae86_button.focus_exited.connect(func(): if not car_ae86_button.has_focus(): _set_button_highlight(car_ae86_button, car_ae86_title, car_ae86_sub, car_ae86_icon, false))
		_set_button_highlight(car_ae86_button, car_ae86_title, car_ae86_sub, car_ae86_icon, false)

	if car_rx7_button != null:
		car_rx7_button.pressed.connect(func(): _select_car(1))
		car_rx7_button.mouse_entered.connect(func(): _set_button_highlight(car_rx7_button, car_rx7_title, car_rx7_sub, car_rx7_icon, true))
		car_rx7_button.mouse_exited.connect(func(): if not car_rx7_button.has_focus(): _set_button_highlight(car_rx7_button, car_rx7_title, car_rx7_sub, car_rx7_icon, false))
		car_rx7_button.focus_entered.connect(func(): _set_button_highlight(car_rx7_button, car_rx7_title, car_rx7_sub, car_rx7_icon, true))
		car_rx7_button.focus_exited.connect(func(): if not car_rx7_button.has_focus(): _set_button_highlight(car_rx7_button, car_rx7_title, car_rx7_sub, car_rx7_icon, false))
		_set_button_highlight(car_rx7_button, car_rx7_title, car_rx7_sub, car_rx7_icon, false)

	if car_s15_button != null:
		car_s15_button.pressed.connect(func(): _select_car(2))
		car_s15_button.mouse_entered.connect(func(): _set_button_highlight(car_s15_button, car_s15_title, car_s15_sub, car_s15_icon, true))
		car_s15_button.mouse_exited.connect(func(): if not car_s15_button.has_focus(): _set_button_highlight(car_s15_button, car_s15_title, car_s15_sub, car_s15_icon, false))
		car_s15_button.focus_entered.connect(func(): _set_button_highlight(car_s15_button, car_s15_title, car_s15_sub, car_s15_icon, true))
		car_s15_button.focus_exited.connect(func(): if not car_s15_button.has_focus(): _set_button_highlight(car_s15_button, car_s15_title, car_s15_sub, car_s15_icon, false))
		_set_button_highlight(car_s15_button, car_s15_title, car_s15_sub, car_s15_icon, false)

	if start_drift_button != null:
		start_drift_button.pressed.connect(_on_start_drifting_pressed)
		start_drift_button.mouse_entered.connect(func(): _set_button_highlight(start_drift_button, start_drift_title, start_drift_sub, start_drift_icon, true))
		start_drift_button.mouse_exited.connect(func(): if not start_drift_button.has_focus(): _set_button_highlight(start_drift_button, start_drift_title, start_drift_sub, start_drift_icon, false))
		start_drift_button.focus_entered.connect(func(): _set_button_highlight(start_drift_button, start_drift_title, start_drift_sub, start_drift_icon, true))
		start_drift_button.focus_exited.connect(func(): if not start_drift_button.has_focus(): _set_button_highlight(start_drift_button, start_drift_title, start_drift_sub, start_drift_icon, false))
		_set_button_highlight(start_drift_button, start_drift_title, start_drift_sub, start_drift_icon, false)

	if back_to_maps_button != null:
		back_to_maps_button.pressed.connect(_on_back_from_car_select_pressed)
		back_to_maps_button.mouse_entered.connect(func(): _set_button_highlight(back_to_maps_button, back_to_maps_title, back_to_maps_sub, back_to_maps_icon, true))
		back_to_maps_button.mouse_exited.connect(func(): if not back_to_maps_button.has_focus(): _set_button_highlight(back_to_maps_button, back_to_maps_title, back_to_maps_sub, back_to_maps_icon, false))
		back_to_maps_button.focus_entered.connect(func(): _set_button_highlight(back_to_maps_button, back_to_maps_title, back_to_maps_sub, back_to_maps_icon, true))
		back_to_maps_button.focus_exited.connect(func(): if not back_to_maps_button.has_focus(): _set_button_highlight(back_to_maps_button, back_to_maps_title, back_to_maps_sub, back_to_maps_icon, false))
		_set_button_highlight(back_to_maps_button, back_to_maps_title, back_to_maps_sub, back_to_maps_icon, false)

	_build_garage_upgrade_ui()

	# Initial overlay state
	if maps_container != null:
		maps_container.visible = false
		maps_container.modulate.a = 0.0

	_select_car(0)

func _setup_menu_music() -> void:
	var music_path: String = "res://assets/audio/menu_theme.mp3"
	if ResourceLoader.exists(music_path):
		menu_music = AudioStreamPlayer.new()
		var stream := load(music_path) as AudioStream
		if stream is AudioStreamMP3 or stream is AudioStreamOggVorbis:
			stream.loop = true
		menu_music.stream = stream
		menu_music.volume_db = -4.0
		add_child(menu_music)
		menu_music.play()

func _freeze_showcase_car() -> void:
	if showcase_car == null:
		return
	if showcase_car is VehicleBody3D:
		showcase_car.freeze = true
		showcase_car.sleeping = true
		showcase_car.linear_velocity = Vector3.ZERO
		showcase_car.angular_velocity = Vector3.ZERO
		
	# Remove or disable the gameplay chase camera and HUD from the showcase car
	var cam_pivot = showcase_car.get_node_or_null("CameraPivot")
	if cam_pivot != null:
		cam_pivot.queue_free()
	var hud_node = showcase_car.get_node_or_null("DriftHUD")
	if hud_node != null:
		hud_node.queue_free()

func _setup_icons() -> void:
	# Clean steering wheel SVG for PLAY
	var wheel_svg = """<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
		<circle cx="12" cy="12" r="10"/>
		<circle cx="12" cy="12" r="3"/>
		<line x1="12" y1="2" x2="12" y2="9"/>
		<line x1="4" y1="17" x2="9.5" y2="13.5"/>
		<line x1="20" y1="17" x2="14.5" y2="13.5"/>
	</svg>"""
	var img_wheel = Image.new()
	if img_wheel.load_svg_from_string(wheel_svg, 1.0) == OK and play_icon != null:
		play_icon.texture = ImageTexture.create_from_image(img_wheel)

	# Folded map / grid SVG for VIEW MAPS
	var map_svg = """<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
		<polygon points="1 6 1 22 8 18 16 22 23 18 23 2 16 6 8 2 1 6"/>
		<line x1="8" y1="2" x2="8" y2="18"/>
		<line x1="16" y1="6" x2="16" y2="22"/>
	</svg>"""
	var img_map = Image.new()
	if img_map.load_svg_from_string(map_svg, 1.0) == OK and maps_icon != null:
		maps_icon.texture = ImageTexture.create_from_image(img_map)
		
	# Clean door exit SVG for QUIT
	var exit_svg = """<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
		<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/>
		<polyline points="16 17 21 12 16 7"/>
		<line x1="21" y1="12" x2="9" y2="12"/>
	</svg>"""
	var img_exit = Image.new()
	if img_exit.load_svg_from_string(exit_svg, 1.0) == OK and quit_icon != null:
		quit_icon.texture = ImageTexture.create_from_image(img_exit)

	# Mountain peak SVG for TOUGE PASS
	var mountain_svg = """<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
		<path d="m8 3 4 8 5-5 5 15H2L8 3z"/>
	</svg>"""
	var img_mountain = Image.new()
	if img_mountain.load_svg_from_string(mountain_svg, 1.0) == OK and map_default_icon != null:
		map_default_icon.texture = ImageTexture.create_from_image(img_mountain)

	# Race flag SVG for EBISU CIRCUIT
	var flag_svg = """<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
		<path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z"/>
		<line x1="4" y1="22" x2="4" y2="15"/>
	</svg>"""
	var img_flag = Image.new()
	if img_flag.load_svg_from_string(flag_svg, 1.0) == OK and map_ebisu_icon != null:
		map_ebisu_icon.texture = ImageTexture.create_from_image(img_flag)

	# Split-screen dual screen / swords SVG for 2-PLAYER SPLIT-SCREEN
	var split_svg = """<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
		<rect x="2" y="3" width="20" height="18" rx="2"/>
		<line x1="12" y1="3" x2="12" y2="21"/>
	</svg>"""
	var img_split = Image.new()
	if img_split.load_svg_from_string(split_svg, 1.0) == OK and map_splitscreen_icon != null:
		map_splitscreen_icon.texture = ImageTexture.create_from_image(img_split)

	# Left back arrow SVG for BACK TO MENU
	var back_svg = """<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
		<line x1="19" y1="12" x2="5" y2="12"/>
		<polyline points="12 19 5 12 12 5"/>
	</svg>"""
	var img_back = Image.new()
	if img_back.load_svg_from_string(back_svg, 1.0) == OK and back_icon != null:
		back_icon.texture = ImageTexture.create_from_image(img_back)
	if img_back.load_svg_from_string(back_svg, 1.0) == OK and back_to_maps_icon != null:
		back_to_maps_icon.texture = ImageTexture.create_from_image(img_back)

	# Car silhouette SVGs for the car selection cards
	var car_svg = """<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.0" stroke-linecap="round" stroke-linejoin="round">
		<path d="M19 17h2c.6 0 1-.4 1-1v-3c0-.9-.7-1.7-1.5-1.9C18.7 10.6 16 10 16 10s-1.3-1.4-2.2-2.3c-.5-.4-1.1-.7-1.8-.7H5c-.6 0-1.1.4-1.4.9l-1.4 2.9C2.1 11.1 2 11.5 2 12v4c0 .6.4 1 1 1h2"/>
		<circle cx="7" cy="17" r="2"/>
		<path d="M9 17h6"/>
		<circle cx="17" cy="17" r="2"/>
	</svg>"""
	var img_car = Image.new()
	if img_car.load_svg_from_string(car_svg, 1.0) == OK:
		var tex = ImageTexture.create_from_image(img_car)
		if car_ae86_icon != null: car_ae86_icon.texture = tex
		if car_rx7_icon != null: car_rx7_icon.texture = tex
		if car_s15_icon != null: car_s15_icon.texture = tex
		if start_drift_icon != null: start_drift_icon.texture = tex

func _set_button_highlight(_btn: Button, title_lbl: Label, sub_lbl: Label, icon_rect: TextureRect, is_active: bool) -> void:
	if title_lbl != null:
		title_lbl.modulate = COLOR_HOVER_TEXT if is_active else COLOR_NORMAL_TEXT
	if sub_lbl != null:
		sub_lbl.modulate = COLOR_HOVER_SUB if is_active else COLOR_NORMAL_SUB
	if icon_rect != null:
		icon_rect.modulate = COLOR_HOVER_TEXT if is_active else COLOR_NORMAL_TEXT

func _select_car(car_idx: int) -> void:
	match car_idx:
		0:
			selected_car_path = "res://scenes/drift_car.tscn"
			selected_car_name = "PANDA AE86 TRUENO"
			_update_car_selection_badges(0)
			_update_showcase_car_color(Color(0.82, 0.84, 0.86))
		1:
			selected_car_path = "res://scenes/car_rx7_fd.tscn"
			selected_car_name = "ROTARY RX-7 FD"
			_update_car_selection_badges(1)
			_update_showcase_car_color(Color(0.08, 0.16, 0.38))
		2:
			selected_car_path = "res://scenes/car_silvia_s15.tscn"
			selected_car_name = "SILVIA S15 SPEC-R"
			_update_car_selection_badges(2)
			_update_showcase_car_color(Color(0.82, 0.12, 0.16))

func _update_car_selection_badges(active_idx: int) -> void:
	if car_ae86_badge != null:
		car_ae86_badge.text = "[SELECTED]" if active_idx == 0 else ""
	if car_rx7_badge != null:
		car_rx7_badge.text = "[SELECTED]" if active_idx == 1 else ""
	if car_s15_badge != null:
		car_s15_badge.text = "[SELECTED]" if active_idx == 2 else ""

func _update_showcase_car_color(col: Color) -> void:
	if showcase_car == null:
		return
	var meshes = showcase_car.find_children("*", "MeshInstance3D", true, false)
	for m in meshes:
		if m is MeshInstance3D and m.mesh != null and m.mesh.material is ShaderMaterial:
			var mat := m.mesh.material as ShaderMaterial
			var cur_col = mat.get_shader_parameter("albedo_color")
			# Only update panels with primary body paint (exclude dark black trim/aero)
			if cur_col != null and cur_col.v > 0.4:
				mat.set_shader_parameter("albedo_color", col)

func _process(delta: float) -> void:
	if not _is_transitioning:
		# Subtle alive orbit / drift around the parked car
		_orbit_time += delta
		var offset_x = sin(_orbit_time * 0.35) * 0.16
		var offset_y = cos(_orbit_time * 0.5) * 0.06
		var offset_z = cos(_orbit_time * 0.25) * 0.10
		camera.position = _initial_cam_pos + Vector3(offset_x, offset_y, offset_z)
		camera.look_at(_look_target_pos + Vector3(0, sin(_orbit_time * 0.3) * 0.03, 0), Vector3.UP)
	else:
		# Animated loading text dots
		_loading_elapsed += delta
		var dot_count = int(_loading_elapsed * 4.0) % 4
		var dots = ""
		for d in range(dot_count):
			dots += "."
		loading_label.text = "LOADING " + _loading_map_name + " // " + selected_car_name + dots

func _on_maps_pressed() -> void:
	if _is_transitioning:
		return
	var tween = create_tween().set_parallel(true)
	tween.tween_property(menu_container, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_QUAD)
	tween.chain().tween_callback(func():
		menu_container.visible = false
		if maps_container != null:
			maps_container.visible = true
			maps_container.modulate.a = 0.0
			var in_tween = create_tween()
			in_tween.tween_property(maps_container, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_QUAD)
			if map_default_button != null:
				map_default_button.grab_focus()
	)

func _on_back_from_maps_pressed() -> void:
	if _is_transitioning:
		return
	if maps_container != null:
		var tween = create_tween().set_parallel(true)
		tween.tween_property(maps_container, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_QUAD)
		tween.chain().tween_callback(func():
			maps_container.visible = false
			menu_container.visible = true
			menu_container.modulate.a = 0.0
			var in_tween = create_tween()
			in_tween.tween_property(menu_container, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_QUAD)
			if maps_button != null:
				maps_button.grab_focus()
	)

func _on_map_default_pressed() -> void:
	target_scene_path = "res://scenes/touge_level.tscn" if ResourceLoader.exists("res://scenes/touge_level.tscn") else "res://scenes/test_arena.tscn"
	_loading_map_name = "TOUGE PASS"
	_show_car_select_panel()

func _on_map_ebisu_pressed() -> void:
	target_scene_path = "res://scenes/ebisu_level.tscn"
	_loading_map_name = "EBISU CIRCUIT"
	_show_car_select_panel()

func _on_map_industrial_pressed() -> void:
	target_scene_path = "res://scenes/industrial_tarmac_level.tscn"
	_loading_map_name = "INDUSTRIAL TARMAC"
	_show_car_select_panel()

func _on_map_splitscreen_pressed() -> void:
	_on_multiplayer_pressed()

func _on_multiplayer_pressed() -> void:
	if _is_transitioning:
		return
	var active_menu: Control = null
	if maps_container != null and maps_container.visible:
		active_menu = maps_container
	elif menu_container != null and menu_container.visible:
		active_menu = menu_container

	_prev_menu_before_mp = active_menu

	if active_menu != null:
		var tween = create_tween().set_parallel(true)
		tween.tween_property(active_menu, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_QUAD)
		tween.chain().tween_callback(func():
			active_menu.visible = false
			if multiplayer_container != null:
				multiplayer_container.visible = true
				multiplayer_container.modulate.a = 0.0
				var in_tween = create_tween()
				in_tween.tween_property(multiplayer_container, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_QUAD)
				if mp_touge_button != null:
					mp_touge_button.grab_focus()
		)

func _on_back_from_multiplayer_pressed() -> void:
	if _is_transitioning:
		return
	if multiplayer_container != null:
		var tween = create_tween().set_parallel(true)
		tween.tween_property(multiplayer_container, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_QUAD)
		tween.chain().tween_callback(func():
			multiplayer_container.visible = false
			var target_menu = _prev_menu_before_mp if _prev_menu_before_mp != null else menu_container
			if target_menu != null:
				target_menu.visible = true
				target_menu.modulate.a = 0.0
				var in_tween = create_tween()
				in_tween.tween_property(target_menu, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_QUAD)
				if target_menu == maps_container and map_splitscreen_button != null:
					map_splitscreen_button.grab_focus()
				elif mp_main_btn != null:
					mp_main_btn.grab_focus()
				elif maps_button != null:
					maps_button.grab_focus()
		)

func _on_mp_touge_pressed() -> void:
	target_scene_path = "res://scenes/split_screen_touge.tscn"
	_loading_map_name = "MULTIPLAYER // TOUGE PASS"
	Engine.set_meta("is_split_screen", true)
	Engine.set_meta("selected_map_path", "res://scenes/touge_level.tscn")
	_start_multiplayer_game()

func _on_mp_ebisu_pressed() -> void:
	target_scene_path = "res://scenes/split_screen_ebisu.tscn"
	_loading_map_name = "MULTIPLAYER // EBISU CIRCUIT"
	Engine.set_meta("is_split_screen", true)
	Engine.set_meta("selected_map_path", "res://scenes/ebisu_level.tscn")
	_start_multiplayer_game()

func _on_mp_industrial_pressed() -> void:
	target_scene_path = "res://scenes/split_screen_industrial_tarmac.tscn"
	_loading_map_name = "MULTIPLAYER // INDUSTRIAL TARMAC"
	Engine.set_meta("is_split_screen", true)
	Engine.set_meta("selected_map_path", "res://scenes/industrial_tarmac_level.tscn")
	_start_multiplayer_game()

func _start_multiplayer_game() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true

	if mp_touge_button != null: mp_touge_button.disabled = true
	if mp_ebisu_button != null: mp_ebisu_button.disabled = true
	if mp_industrial_button != null: mp_industrial_button.disabled = true
	if back_from_mp_button != null: back_from_mp_button.disabled = true
	if mp_main_btn != null: mp_main_btn.disabled = true
	if play_button != null: play_button.disabled = true
	if maps_button != null: maps_button.disabled = true
	if quit_button != null: quit_button.disabled = true

	var tween = create_tween().set_parallel(true)
	if multiplayer_container != null:
		tween.tween_property(multiplayer_container, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_QUAD)

	loading_container.visible = true
	tween.tween_property(loading_container, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_QUAD)

	loading_bar.value = 0.0
	tween.tween_property(loading_bar, "value", 100.0, 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	tween.tween_property(camera, "fov", 38.0, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "position", _zoom_target_pos, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	if menu_music != null and menu_music.playing:
		tween.tween_property(menu_music, "volume_db", -60.0, 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.chain().tween_callback(_on_loading_complete)

func _build_multiplayer_ui() -> void:
	multiplayer_container = MarginContainer.new()
	multiplayer_container.name = "MultiplayerContainer"
	multiplayer_container.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	multiplayer_container.anchor_top = 0.5
	multiplayer_container.anchor_bottom = 0.5
	multiplayer_container.offset_left = 70.0
	multiplayer_container.offset_top = -275.0
	multiplayer_container.offset_right = 430.0
	multiplayer_container.offset_bottom = 275.0
	multiplayer_container.grow_vertical = Control.GROW_DIRECTION_BOTH
	multiplayer_container.visible = false
	multiplayer_container.modulate.a = 0.0

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 12)
	multiplayer_container.add_child(vbox)

	var header_box := VBoxContainer.new()
	header_box.add_theme_constant_override("separation", 2)
	var header_title := Label.new()
	header_title.text = "2P MULTIPLAYER"
	header_title.add_theme_font_size_override("font_size", 24)
	header_title.add_theme_color_override("font_color", Color(0.96, 0.97, 1.0))
	header_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	header_title.add_theme_constant_override("shadow_offset_x", 2)
	header_title.add_theme_constant_override("shadow_offset_y", 2)
	header_box.add_child(header_title)

	var header_sub := Label.new()
	header_sub.text = "SELECT SPLIT-SCREEN BATTLEGROUND"
	header_sub.add_theme_font_size_override("font_size", 11)
	header_sub.add_theme_color_override("font_color", Color(0.28, 0.75, 0.92))
	header_box.add_child(header_sub)
	vbox.add_child(header_box)

	var touge_card := _create_custom_card_button("MULTIPLAYER // TOUGE PASS", "SPLIT-SCREEN DOWNHILL // 1.26 KM", map_default_icon.texture if map_default_icon else null, Vector2(360, 95))
	mp_touge_button = touge_card.button
	mp_touge_button.name = "MpTougeButton"
	vbox.add_child(mp_touge_button)
	mp_touge_button.pressed.connect(_on_mp_touge_pressed)

	var ebisu_card := _create_custom_card_button("MULTIPLAYER // EBISU CIRCUIT", "COMPOUND DRIFT ARENA // 2P SPLIT", map_ebisu_icon.texture if map_ebisu_icon else null, Vector2(360, 95))
	mp_ebisu_button = ebisu_card.button
	mp_ebisu_button.name = "MpEbisuButton"
	vbox.add_child(mp_ebisu_button)
	mp_ebisu_button.pressed.connect(_on_mp_ebisu_pressed)

	var ind_card := _create_custom_card_button("INDUSTRIAL TARMAC (WAREHOUSE)", "2P WAREHOUSE TARMAC BATTLE", map_ebisu_icon.texture if map_ebisu_icon else null, Vector2(360, 95))
	mp_industrial_button = ind_card.button
	mp_industrial_button.name = "MpIndustrialButton"
	vbox.add_child(mp_industrial_button)
	mp_industrial_button.pressed.connect(_on_mp_industrial_pressed)

	var back_card := _create_custom_card_button("BACK TO MENU", "RETURN TO PREVIOUS MENU", back_icon.texture if back_icon else null, Vector2(360, 80))
	back_from_mp_button = back_card.button
	back_from_mp_button.name = "BackFromMpButton"
	vbox.add_child(back_from_mp_button)
	back_from_mp_button.pressed.connect(_on_back_from_multiplayer_pressed)

	mp_touge_button.focus_neighbor_top = mp_touge_button.get_path_to(back_from_mp_button)
	mp_touge_button.focus_neighbor_bottom = mp_touge_button.get_path_to(mp_ebisu_button)
	mp_ebisu_button.focus_neighbor_top = mp_ebisu_button.get_path_to(mp_touge_button)
	mp_ebisu_button.focus_neighbor_bottom = mp_ebisu_button.get_path_to(mp_industrial_button)
	mp_industrial_button.focus_neighbor_top = mp_industrial_button.get_path_to(mp_ebisu_button)
	mp_industrial_button.focus_neighbor_bottom = mp_industrial_button.get_path_to(back_from_mp_button)
	back_from_mp_button.focus_neighbor_top = back_from_mp_button.get_path_to(mp_industrial_button)
	back_from_mp_button.focus_neighbor_bottom = back_from_mp_button.get_path_to(mp_touge_button)

	var menu_canvas := $MenuCanvas
	menu_canvas.add_child(multiplayer_container)

func _build_garage_upgrade_ui() -> void:
	var menu_canvas := get_node_or_null("MenuCanvas")
	if menu_canvas != null and garage_wallet_label == null:
		garage_wallet_label = Label.new()
		garage_wallet_label.name = "GarageWalletLabel"
		garage_wallet_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		garage_wallet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		garage_wallet_label.offset_left = -460.0
		garage_wallet_label.offset_top = 26.0
		garage_wallet_label.offset_right = -36.0
		garage_wallet_label.offset_bottom = 66.0
		garage_wallet_label.add_theme_font_size_override("font_size", 22)
		garage_wallet_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.14))
		garage_wallet_label.add_theme_color_override("font_outline_color", Color.BLACK)
		garage_wallet_label.add_theme_constant_override("outline_size", 8)
		menu_canvas.add_child(garage_wallet_label)

	var car_vbox := get_node_or_null("MenuCanvas/CarSelectContainer/VBox") as VBoxContainer
	if car_vbox != null:
		if car_select_panel != null:
			car_select_panel.offset_top = -318.0
			car_select_panel.offset_bottom = 318.0
		car_vbox.add_theme_constant_override("separation", 6)
		for b in [car_ae86_button, car_rx7_button, car_s15_button, start_drift_button, back_to_maps_button]:
			if b != null:
				b.custom_minimum_size = Vector2(380, 68)

		var bolt_svg := """<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
			<polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/>
		</svg>"""
		var bolt_img := Image.new()
		var bolt_tex: Texture2D = null
		if bolt_img.load_svg_from_string(bolt_svg, 1.0) == OK:
			bolt_tex = ImageTexture.create_from_image(bolt_img)

		var turbo_svg := """<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
			<circle cx="11" cy="13" r="7"/>
			<circle cx="11" cy="13" r="2.5"/>
			<path d="M11 6h10v4h-4"/>
		</svg>"""
		var turbo_img := Image.new()
		var turbo_tex: Texture2D = bolt_tex
		if turbo_img.load_svg_from_string(turbo_svg, 1.0) == OK:
			turbo_tex = ImageTexture.create_from_image(turbo_img)

		var upg_card := _create_custom_card_button("UPGRADE SPEED ($50 / $100)", "", bolt_tex, Vector2(380, 68))
		upgrade_speed_button = upg_card.button
		upgrade_speed_button.name = "UpgradeSpeedButton"
		upgrade_speed_sub = upg_card.sub
		car_vbox.add_child(upgrade_speed_button)
		var start_idx := start_drift_button.get_index() if start_drift_button != null else car_vbox.get_child_count() - 1
		car_vbox.move_child(upgrade_speed_button, start_idx)
		upgrade_speed_button.pressed.connect(_on_upgrade_speed_pressed)

		var turbo_card := _create_custom_card_button("UPGRADE TURBO ($60 / $120 / $250)", "", turbo_tex, Vector2(380, 68))
		upgrade_turbo_button = turbo_card.button
		upgrade_turbo_button.name = "UpgradeTurboButton"
		upgrade_turbo_sub = turbo_card.sub
		car_vbox.add_child(upgrade_turbo_button)
		car_vbox.move_child(upgrade_turbo_button, upgrade_speed_button.get_index() + 1)
		upgrade_turbo_button.pressed.connect(_on_upgrade_turbo_pressed)

		if car_s15_button != null and start_drift_button != null:
			car_s15_button.focus_neighbor_bottom = car_s15_button.get_path_to(upgrade_speed_button)
			upgrade_speed_button.focus_neighbor_top = upgrade_speed_button.get_path_to(car_s15_button)
			upgrade_speed_button.focus_neighbor_bottom = upgrade_speed_button.get_path_to(upgrade_turbo_button)
			upgrade_turbo_button.focus_neighbor_top = upgrade_turbo_button.get_path_to(upgrade_speed_button)
			upgrade_turbo_button.focus_neighbor_bottom = upgrade_turbo_button.get_path_to(start_drift_button)
			start_drift_button.focus_neighbor_top = start_drift_button.get_path_to(upgrade_turbo_button)

	if not CoinManager.money_changed.is_connected(_on_wallet_or_upgrade_changed):
		CoinManager.money_changed.connect(_on_wallet_or_upgrade_changed)
	if not CarUpgradeManager.speed_upgraded.is_connected(_on_speed_upgraded):
		CarUpgradeManager.speed_upgraded.connect(_on_speed_upgraded)
	if not TurboUpgradeManager.turbo_upgraded.is_connected(_on_turbo_upgraded):
		TurboUpgradeManager.turbo_upgraded.connect(_on_turbo_upgraded)
	_refresh_upgrade_ui()

func _exit_tree() -> void:
	if CoinManager.money_changed.is_connected(_on_wallet_or_upgrade_changed):
		CoinManager.money_changed.disconnect(_on_wallet_or_upgrade_changed)
	if CarUpgradeManager.speed_upgraded.is_connected(_on_speed_upgraded):
		CarUpgradeManager.speed_upgraded.disconnect(_on_speed_upgraded)
	if TurboUpgradeManager.turbo_upgraded.is_connected(_on_turbo_upgraded):
		TurboUpgradeManager.turbo_upgraded.disconnect(_on_turbo_upgraded)

func _on_wallet_or_upgrade_changed(_new_val: int) -> void:
	_refresh_upgrade_ui()

func _on_speed_upgraded(_new_tier: int, _new_speed: float) -> void:
	_refresh_upgrade_ui()

func _on_turbo_upgraded(_new_stage: int, _boost_kmh: float) -> void:
	_refresh_upgrade_ui()

func _on_upgrade_speed_pressed() -> void:
	if _is_transitioning:
		return
	var upgraded: bool = CarUpgradeManager.try_buy_speed_upgrade()
	if not upgraded and upgrade_speed_sub != null and not CarUpgradeManager.is_max_speed_tier():
		var needed: int = CarUpgradeManager.get_next_upgrade_cost()
		upgrade_speed_sub.text = "NEED $%d COINS (HAVE $%d)" % [needed, CoinManager.player_money]
	else:
		_refresh_upgrade_ui()

func _on_upgrade_turbo_pressed() -> void:
	if _is_transitioning:
		return
	var upgraded: bool = TurboUpgradeManager.try_buy_turbo_upgrade()
	if not upgraded and upgrade_turbo_sub != null and not TurboUpgradeManager.is_max_turbo_stage():
		var needed: int = TurboUpgradeManager.get_next_upgrade_cost()
		upgrade_turbo_sub.text = "NEED $%d COINS (HAVE $%d)" % [needed, CoinManager.player_money]
	else:
		_refresh_upgrade_ui()

func _refresh_upgrade_ui() -> void:
	var tier: int = CarUpgradeManager.speed_tier
	var base_speed: int = int(CarUpgradeManager.get_max_speed_kmh())
	var turbo_stage: int = TurboUpgradeManager.turbo_stage
	var turbo_boost: int = int(TurboUpgradeManager.get_speed_boost_kmh())
	var total_speed: int = base_speed + turbo_boost
	var cash: int = CoinManager.player_money
	if garage_wallet_label != null:
		garage_wallet_label.text = "CASH: $%d  //  MAX SPEED: %d KM/H (T%d + S%d)" % [cash, total_speed, tier, turbo_stage]
	if upgrade_speed_sub != null:
		if CarUpgradeManager.is_max_speed_tier():
			upgrade_speed_sub.text = "TIER %d // %d KM/H BASE [MAXED OUT]" % [tier, base_speed]
		else:
			var next_cost: int = CarUpgradeManager.get_next_upgrade_cost()
			var next_speed: int = int(CarUpgradeManager.SPEED_TIERS_KMH[tier + 1])
			upgrade_speed_sub.text = "TIER %d: %d -> %d KM/H // COST: $%d (CASH: $%d)" % [tier, base_speed, next_speed, next_cost, cash]
	if upgrade_turbo_sub != null:
		if TurboUpgradeManager.is_max_turbo_stage():
			upgrade_turbo_sub.text = "%s (+%d KM/H) [MAXED OUT]" % [TurboUpgradeManager.get_stage_name(), turbo_boost]
		else:
			var next_turbo_cost: int = TurboUpgradeManager.get_next_upgrade_cost()
			var next_boost: int = int(TurboUpgradeManager.TURBO_BOOST_KMH[turbo_stage + 1])
			var next_name: String = TurboUpgradeManager.get_stage_name(turbo_stage + 1)
			upgrade_turbo_sub.text = "%s (+%d KM/H) // COST: $%d (CASH: $%d)" % [next_name, next_boost, next_turbo_cost, cash]

func _create_custom_card_button(title_text: String, sub_text: String, icon_tex: Texture2D, min_size: Vector2) -> Dictionary:
	var btn := Button.new()
	btn.custom_minimum_size = min_size
	if map_default_button != null:
		btn.add_theme_stylebox_override("normal", map_default_button.get_theme_stylebox("normal"))
		btn.add_theme_stylebox_override("hover", map_default_button.get_theme_stylebox("hover"))
		btn.add_theme_stylebox_override("pressed", map_default_button.get_theme_stylebox("pressed"))
		btn.add_theme_stylebox_override("focus", map_default_button.get_theme_stylebox("focus"))

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 16)
	btn.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(hbox)

	var text_vbox := VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(text_vbox)

	var title_lbl := Label.new()
	title_lbl.text = title_text
	title_lbl.add_theme_font_size_override("font_size", 20 if title_text.length() > 22 else 22)
	text_vbox.add_child(title_lbl)

	var sub_lbl := Label.new()
	sub_lbl.text = sub_text
	sub_lbl.add_theme_font_size_override("font_size", 10)
	text_vbox.add_child(sub_lbl)

	var icon_rect := TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(54, 54)
	icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if icon_tex != null:
		icon_rect.texture = icon_tex
	hbox.add_child(icon_rect)

	btn.mouse_entered.connect(func(): _set_button_highlight(btn, title_lbl, sub_lbl, icon_rect, true))
	btn.mouse_exited.connect(func(): if not btn.has_focus(): _set_button_highlight(btn, title_lbl, sub_lbl, icon_rect, false))
	btn.focus_entered.connect(func(): _set_button_highlight(btn, title_lbl, sub_lbl, icon_rect, true))
	btn.focus_exited.connect(func(): if not btn.has_focus(): _set_button_highlight(btn, title_lbl, sub_lbl, icon_rect, false))
	_set_button_highlight(btn, title_lbl, sub_lbl, icon_rect, false)

	return {"button": btn, "title": title_lbl, "sub": sub_lbl, "icon": icon_rect}

func _show_car_select_panel() -> void:
	if _is_transitioning:
		return
	if maps_container != null:
		var tween = create_tween().set_parallel(true)
		tween.tween_property(maps_container, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_QUAD)
		tween.chain().tween_callback(func():
			maps_container.visible = false
			if car_select_panel != null:
				car_select_panel.visible = true
				car_select_panel.modulate.a = 0.0
				var in_tween = create_tween()
				in_tween.tween_property(car_select_panel, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_QUAD)
				if start_drift_button != null:
					start_drift_button.grab_focus()
		)

func _on_back_from_car_select_pressed() -> void:
	if _is_transitioning:
		return
	if car_select_panel != null:
		var tween = create_tween().set_parallel(true)
		tween.tween_property(car_select_panel, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_QUAD)
		tween.chain().tween_callback(func():
			car_select_panel.visible = false
			if maps_container != null:
				maps_container.visible = true
				maps_container.modulate.a = 0.0
				var in_tween = create_tween()
				in_tween.tween_property(maps_container, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_QUAD)
				if map_default_button != null:
					map_default_button.grab_focus()
		)

func _on_start_drifting_pressed() -> void:
	if _is_transitioning:
		return
	MainMenu.selected_car_path = selected_car_path
	Engine.set_meta("selected_car_path", selected_car_path)
	_on_play_pressed()

func _on_play_pressed() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	
	# Disable buttons
	if play_button != null: play_button.disabled = true
	if maps_button != null: maps_button.disabled = true
	if quit_button != null: quit_button.disabled = true
	if mp_main_btn != null: mp_main_btn.disabled = true
	if map_default_button != null: map_default_button.disabled = true
	if map_ebisu_button != null: map_ebisu_button.disabled = true
	if map_splitscreen_button != null: map_splitscreen_button.disabled = true
	if back_to_menu_button != null: back_to_menu_button.disabled = true
	if mp_touge_button != null: mp_touge_button.disabled = true
	if mp_ebisu_button != null: mp_ebisu_button.disabled = true
	if back_from_mp_button != null: back_from_mp_button.disabled = true
	if car_ae86_button != null: car_ae86_button.disabled = true
	if car_rx7_button != null: car_rx7_button.disabled = true
	if car_s15_button != null: car_s15_button.disabled = true
	if upgrade_speed_button != null: upgrade_speed_button.disabled = true
	if upgrade_turbo_button != null: upgrade_turbo_button.disabled = true
	if start_drift_button != null: start_drift_button.disabled = true
	if back_to_maps_button != null: back_to_maps_button.disabled = true
	
	# Fade out active container
	var tween = create_tween().set_parallel(true)
	var active_container: Control = null
	if car_select_panel != null and car_select_panel.visible:
		active_container = car_select_panel
	elif multiplayer_container != null and multiplayer_container.visible:
		active_container = multiplayer_container
	elif maps_container != null and maps_container.visible:
		active_container = maps_container
	else:
		active_container = menu_container

	if active_container != null:
		tween.tween_property(active_container, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_QUAD)
	
	loading_container.visible = true
	tween.tween_property(loading_container, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_QUAD)
	
	loading_bar.value = 0.0
	tween.tween_property(loading_bar, "value", 100.0, 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(camera, "fov", 38.0, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "position", _zoom_target_pos, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	
	if menu_music != null and menu_music.playing:
		tween.tween_property(menu_music, "volume_db", -60.0, 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	tween.chain().tween_callback(_on_loading_complete)

func _on_loading_complete() -> void:
	if ResourceLoader.exists(target_scene_path):
		get_tree().change_scene_to_file(target_scene_path)
	else:
		push_error("Target scene path not found: " + target_scene_path)

const HOME_REDIRECT_URL: String = "https://daithi.fagans.eu/"

func _on_quit_pressed() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("try { window.top.location.href = '" + HOME_REDIRECT_URL + "'; } catch (e) { window.location.href = '" + HOME_REDIRECT_URL + "'; }")
	else:
		OS.shell_open(HOME_REDIRECT_URL)
		get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if car_select_panel != null and car_select_panel.visible:
			_on_back_from_car_select_pressed()
		elif multiplayer_container != null and multiplayer_container.visible:
			_on_back_from_multiplayer_pressed()
		elif maps_container != null and maps_container.visible:
			_on_back_from_maps_pressed()
		else:
			_on_quit_pressed()
