class_name MainGame
extends Control

@export_file("*.tscn") var level_scene_path: String = "res://scenes/ebisu_level.tscn"
@export_file("*.tscn") var car1_scene_path: String = "res://scenes/drift_car.tscn"
@export_file("*.tscn") var car2_scene_path: String = "res://scenes/car_rx7_fd.tscn"

@onready var container1: SubViewportContainer = $HBoxContainer/ViewportContainer1
@onready var sub_viewport1: SubViewport = $HBoxContainer/ViewportContainer1/SubViewport1
@onready var container2: SubViewportContainer = $HBoxContainer/ViewportContainer2
@onready var sub_viewport2: SubViewport = $HBoxContainer/ViewportContainer2/SubViewport2

var car1: DriftCar
var car2: DriftCar

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_resolve_map_and_cars()
	_setup_split_screen()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if get_tree() != null:
			get_tree().paused = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _resolve_map_and_cars() -> void:
	if Engine.has_meta("selected_map_path"):
		level_scene_path = str(Engine.get_meta("selected_map_path"))

	if Engine.has_meta("selected_car_path"):
		car1_scene_path = str(Engine.get_meta("selected_car_path"))
	elif "selected_car_path" in MainMenu:
		car1_scene_path = MainMenu.selected_car_path

	if Engine.has_meta("selected_car2_path"):
		car2_scene_path = str(Engine.get_meta("selected_car2_path"))
	else:
		# If Car 1 is AE86, default Car 2 to RX-7; if Car 1 is RX-7, default Car 2 to S15
		if car1_scene_path.contains("drift_car"):
			car2_scene_path = "res://scenes/car_rx7_fd.tscn"
		elif car1_scene_path.contains("rx7"):
			car2_scene_path = "res://scenes/car_silvia_s15.tscn"
		else:
			car2_scene_path = "res://scenes/drift_car.tscn"

func _setup_split_screen() -> void:
	# 1. Enable own world on SubViewport1 and share with SubViewport2
	sub_viewport1.own_world_3d = true

	# 2. Instantiate Level in SubViewport1
	if not ResourceLoader.exists(level_scene_path):
		level_scene_path = "res://scenes/ebisu_level.tscn"
	var level_scene = load(level_scene_path) as PackedScene
	var level = level_scene.instantiate()
	sub_viewport1.add_child(level)

	# 3. Share world_3d with SubViewport2
	sub_viewport2.world_3d = sub_viewport1.find_world_3d()

	# 4. Remove any existing single-player car in the instantiated level
	var existing_car = level.find_child("DriftCar", true, false)
	if existing_car != null:
		var parent = existing_car.get_parent()
		parent.remove_child(existing_car)
		existing_car.queue_free()

	# 5. Spawn Dual Cars
	var is_ebisu := level_scene_path.contains("ebisu")
	var is_industrial := level_scene_path.contains("industrial") or level_scene_path.contains("tarmac")
	var car1_tf: Transform3D
	var car2_tf: Transform3D

	if is_ebisu:
		# Ebisu start straight facing +X
		var p1_pos := Vector3(-65.0, 0.5, -3.2)
		var p2_pos := Vector3(-65.0, 0.5, 3.2)
		var basis_facing := Basis(Vector3.UP, -PI * 0.5)
		car1_tf = Transform3D(basis_facing, p1_pos)
		car2_tf = Transform3D(basis_facing, p2_pos)
	elif is_industrial:
		# Industrial tarmac compound facing -Z
		var p1_pos := Vector3(-3.5, 1.0, 60.0)
		var p2_pos := Vector3(3.5, 1.0, 60.0)
		car1_tf = Transform3D(Basis.IDENTITY, p1_pos)
		car2_tf = Transform3D(Basis.IDENTITY, p2_pos)
	else:
		# Touge summit start facing -Z
		var p1_pos := Vector3(-2.8, 85.5, -5.0)
		var p2_pos := Vector3(2.8, 85.5, -5.0)
		car1_tf = Transform3D(Basis.IDENTITY, p1_pos)
		car2_tf = Transform3D(Basis.IDENTITY, p2_pos)

	# Car 1: Player 1 (WASD / Gamepad 0)
	var c1_scene = load(car1_scene_path) as PackedScene
	car1 = c1_scene.instantiate() as DriftCar
	car1.name = "Player1Car"
	car1.player_id = 1
	car1.is_split_screen = true
	level.add_child(car1)
	car1.global_transform = car1_tf
	car1.spawn_transform = car1_tf

	# Car 2: Player 2 (Arrow keys / Gamepad 1)
	var c2_scene = load(car2_scene_path) as PackedScene
	car2 = c2_scene.instantiate() as DriftCar
	car2.name = "Player2Car"
	car2.player_id = 2
	car2.is_split_screen = true
	level.add_child(car2)
	car2.global_transform = car2_tf
	car2.spawn_transform = car2_tf

	# 6. Independent Chase Cameras
	_setup_chase_camera(sub_viewport1, car1, 1)
	_setup_chase_camera(sub_viewport2, car2, 2)

	# 7. Independent HUDs
	_setup_hud(sub_viewport1, car1, 1)
	_setup_hud(sub_viewport2, car2, 2)

func _setup_chase_camera(vp: SubViewport, target: VehicleBody3D, p_id: int) -> void:
	var chase_cam_script = load("res://scripts/chase_camera.gd")
	var pivot := Node3D.new()
	pivot.name = "CameraPivotP%d" % p_id
	pivot.set_script(chase_cam_script)
	pivot.set("target_vehicle", target)
	pivot.set("follow_speed", 6.0)
	pivot.set("rotation_speed", 5.0)
	pivot.set("velocity_influence", 0.45)
	pivot.set("camera_height_offset", 1.4)
	pivot.set("target_pitch_deg", -10.0)

	var arm := SpringArm3D.new()
	arm.name = "SpringArm3D"
	arm.position = Vector3(0, 1.6, 0)
	arm.spring_length = 5.4
	arm.margin = 0.2
	pivot.add_child(arm)

	var cam := Camera3D.new()
	cam.name = "Camera3D"
	cam.position = Vector3(0, 0, 5.4)
	cam.current = true
	cam.fov = 75.0
	arm.add_child(cam)

	vp.add_child(pivot)

func _setup_hud(vp: SubViewport, target_car: DriftCar, p_id: int) -> void:
	var hud_scene = load("res://scenes/drift_hud.tscn") as PackedScene
	var hud = hud_scene.instantiate() as DriftHUD
	hud.name = "DriftHUDP%d" % p_id
	hud.car = target_car
	hud.is_split_screen = true
	if p_id == 1:
		hud.player_title = "PLAYER 1 [W/A/S/D]"
		hud.player_color = Color(0.35, 0.75, 1.0) # Blue Hour Neon
	else:
		hud.player_title = "PLAYER 2 [ARROWS]"
		hud.player_color = Color(1.0, 0.35, 0.45) # Crimson Touge Red
	vp.add_child(hud)
