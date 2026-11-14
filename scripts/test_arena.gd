extends Node3D

@onready var path_3d: Path3D = $TougePath
@onready var car: DriftCar = $DriftCar

var cedar_tree_scene: PackedScene = preload("res://scenes/cedar_tree.tscn")
var streetlamp_scene: PackedScene = preload("res://scenes/touge_streetlamp.tscn")
var clipping_zone_scene: PackedScene = preload("res://scenes/clipping_zone.tscn")

var manga_ink_shader: Shader = preload("res://shaders/manga_ink.gdshader")
var manga_outline_shader: Shader = preload("res://shaders/manga_outline.gdshader")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if path_3d != null and path_3d.curve != null:
		_generate_roadside_touge_scenery()
		_spawn_car_on_start_line()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if get_tree() != null:
			get_tree().paused = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	elif Input.is_key_pressed(KEY_ENTER):
		get_tree().reload_current_scene()

func _generate_roadside_touge_scenery() -> void:
	var curve = path_3d.curve
	var total_length = curve.get_baked_length()
	var road_half_width = 6.0
	
	# 1. Stylized Low-Poly Manga Cedar Trees every 15 meters
	var tree_step = 15.0
	var tree_count = int(total_length / tree_step)
	var trees_node = Node3D.new()
	trees_node.name = "CedarTrees"
	add_child(trees_node)
	
	for i in range(tree_count):
		var d = float(i) * tree_step + 4.0
		var t = curve.sample_baked_with_rotation(d)
		
		# Place trees on alternating sides outside the guardrails (8m to 14m from centerline)
		var side = -1.0 if (i % 2 == 0) else 1.0
		var lateral = road_half_width + randf_range(2.8, 8.5)
		var pos = t.origin + (t.basis.x * side * lateral) + Vector3(0, randf_range(-0.4, 0.8), 0)
		
		var tree = cedar_tree_scene.instantiate() as Node3D
		tree.position = pos
		tree.scale = Vector3.ONE * randf_range(0.85, 1.35)
		tree.rotation.y = randf_range(0.0, TAU)
		trees_node.add_child(tree)
		
	# 2. Overhead Japanese Touge Arched Streetlamps every 35 meters
	var lamp_step = 35.0
	var lamp_count = int(total_length / lamp_step)
	var lamps_node = Node3D.new()
	lamps_node.name = "TougeStreetlamps"
	add_child(lamps_node)
	
	for i in range(lamp_count):
		var d = float(i) * lamp_step + 12.0
		if d >= total_length - 15.0:
			continue
		var t = curve.sample_baked_with_rotation(d)
		
		# Place post on right side of road, overhang arm reaching across towards center
		var lamp_pos = t.origin + (t.basis.x * (road_half_width + 1.2))
		var lamp = streetlamp_scene.instantiate() as Node3D
		lamp.transform = t
		lamp.position = lamp_pos
		lamp.rotate_object_local(Vector3.UP, PI)
		lamps_node.add_child(lamp)
		
	# 3. 3 Glowing Neon Manga "CLIPPING ZONE" pads at inner apexes of Hairpins 1, 2, and 3
	var apex_distances = [
		total_length * 0.28, # Hairpin 1 apex
		total_length * 0.58, # Hairpin 2 apex
		total_length * 0.86  # Hairpin 3 apex
	]
	
	var clips_node = Node3D.new()
	clips_node.name = "ClippingZones"
	add_child(clips_node)
	
	for idx in range(apex_distances.size()):
		var apex_d = apex_distances[idx]
		var t = curve.sample_baked_with_rotation(apex_d)
		
		# Place pad on inner apex side
		var inner_sign = -1.0 if (idx != 1) else 1.0
		var pad_pos = t.origin + (t.basis.x * inner_sign * (road_half_width - 2.5)) + Vector3(0, 0.08, 0)
		
		var zone = clipping_zone_scene.instantiate()
		zone.position = pad_pos
		zone.set("zone_name", "APEX %d" % (idx + 1))
		clips_node.add_child(zone)
		
	# 4. Mountain Cliffs & Rock Formations along inner mountain side
	var cliffs_node = Node3D.new()
	cliffs_node.name = "MountainCliffs"
	add_child(cliffs_node)
	
	var cliff_mat = ShaderMaterial.new()
	cliff_mat.shader = manga_ink_shader
	cliff_mat.set_shader_parameter("albedo_color", Color(0.11, 0.12, 0.15, 1.0))
	cliff_mat.set_shader_parameter("enable_screentone", true)
	cliff_mat.set_shader_parameter("screentone_density", 120.0)
	cliff_mat.set_shader_parameter("specular_strength", 0.1)
	
	var cliff_outline = ShaderMaterial.new()
	cliff_outline.shader = manga_outline_shader
	cliff_outline.set_shader_parameter("outline_thickness", 0.035)
	cliff_outline.set_shader_parameter("outline_color", Color.BLACK)
	cliff_outline.render_priority = 1
	cliff_mat.next_pass = cliff_outline
	
	for i in range(16):
		var cliff_d = (float(i) / 16.0) * total_length
		var t = curve.sample_baked_with_rotation(cliff_d)
		var cliff_mesh = BoxMesh.new()
		cliff_mesh.size = Vector3(randf_range(16.0, 28.0), randf_range(18.0, 32.0), randf_range(20.0, 36.0))
		cliff_mesh.material = cliff_mat
		
		var inst = MeshInstance3D.new()
		inst.mesh = cliff_mesh
		var side = 1.0 if (i % 2 == 0) else -1.0
		inst.position = t.origin + (t.basis.x * side * (road_half_width + randf_range(14.0, 24.0))) + Vector3(0, 10.0, 0)
		inst.rotation = Vector3(randf_range(-0.15, 0.15), randf_range(0, TAU), randf_range(-0.15, 0.15))
		cliffs_node.add_child(inst)

func _spawn_car_on_start_line() -> void:
	if car == null or path_3d == null or path_3d.curve == null:
		return
		
	var start_dist = 8.0
	var t = path_3d.curve.sample_baked_with_rotation(start_dist)
	
	# Spawn cleanly above the asphalt road surface
	car.global_position = t.origin + Vector3(0, 0.65, 0)
	# Align car forward heading along road tangent
	car.global_transform.basis = t.basis
	car.linear_velocity = Vector3.ZERO
	car.angular_velocity = Vector3.ZERO
