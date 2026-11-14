class_name IndustrialTarmacBuilder
extends Node3D

var clipping_zone_scene: PackedScene = preload("res://scenes/clipping_zone.tscn")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_configure_environment()
	_build_industrial_compound()
	_build_drift_layout_and_barriers()
	_spawn_clipping_zones()
	_spawn_distant_treelines()
	# _spawn_rain_effects()
	_place_car_at_grid()

func _spawn_rain_effects() -> void:
	var rain_path := "res://scenes/rain_emitter.tscn"
	if not ResourceLoader.exists(rain_path):
		return
	var rain_scene = load(rain_path) as PackedScene
	if rain_scene:
		var rain = rain_scene.instantiate()
		rain.name = "RainEmitter"
		add_child(rain)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if get_tree() != null:
			get_tree().paused = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	elif Input.is_key_pressed(KEY_R) or (Input.is_key_pressed(KEY_ENTER) and not Engine.get_meta("is_split_screen", false)):
		get_tree().reload_current_scene()

func _configure_environment() -> void:
	if not is_inside_tree() or get_tree() == null or get_tree().root == null:
		return
	var world_env := get_tree().root.find_child("WorldEnvironment", true, false) as WorldEnvironment
	if world_env and world_env.environment:
		var env := world_env.environment
		env.background_mode = Environment.BG_SKY
		if not env.sky:
			env.sky = Sky.new()
		var sky_mat := ProceduralSkyMaterial.new()
		sky_mat.sky_top_color = Color(0.08, 0.14, 0.26)
		sky_mat.sky_horizon_color = Color(0.20, 0.30, 0.46)
		sky_mat.ground_horizon_color = Color(0.10, 0.16, 0.26)
		sky_mat.ground_bottom_color = Color(0.05, 0.08, 0.13)
		env.sky.sky_material = sky_mat
		
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_color = Color(0.20, 0.26, 0.38)
		env.ambient_light_energy = 1.15
		env.ambient_light_sky_contribution = 0.80
		env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
		
		# Tonemapper FILMIC with high exposure and white point
		env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		env.tonemap_exposure = 1.25
		env.tonemap_white = 5.5
		
		# High-quality Bloom and Glow
		env.glow_enabled = true
		env.glow_bloom = 1.6
		env.glow_hdr_threshold = 0.85
		env.glow_intensity = 0.75
		
		# SSAO & SSR for wet surface reflections
		env.ssao_enabled = true
		env.ssao_radius = 2.0
		env.ssao_intensity = 2.2
		env.ssao_power = 1.4
		env.ssr_enabled = true
		env.ssr_max_steps = 64
		env.ssr_fade_in = 0.15
		env.ssr_fade_out = 2.0
		env.ssr_depth_tolerance = 0.2
		
		env.fog_enabled = true
		env.fog_light_color = Color(0.08, 0.12, 0.22)
		env.fog_density = 0.0014

	var dir_light := get_tree().root.find_child("DirectionalLight3D", true, false) as DirectionalLight3D
	if dir_light:
		dir_light.light_color = Color(0.76, 0.85, 0.98)
		dir_light.light_energy = 0.75
		dir_light.shadow_enabled = true

func _build_industrial_compound() -> void:
	# 1. Massive Open Concrete Tarmac Playground with puddles & reflections
	var tarmac := MeshInstance3D.new()
	tarmac.name = "TarmacGround"
	var plane := PlaneMesh.new()
	plane.size = Vector2(700, 700)
	tarmac.mesh = plane
	
	var wet_mat := ShaderMaterial.new()
	wet_mat.shader = load("res://shaders/wet_tarmac.gdshader")
	wet_mat.set_shader_parameter("albedo_color", Color(0.08, 0.09, 0.12))
	wet_mat.set_shader_parameter("metallic", 0.45)
	wet_mat.set_shader_parameter("roughness", 0.55)
	wet_mat.set_shader_parameter("wetness", 0.95)
	wet_mat.set_shader_parameter("normal_scale", 4.5)
	wet_mat.set_shader_parameter("ripple_speed", 1.8)
	wet_mat.set_shader_parameter("ripple_density", 28.0)
	tarmac.material_override = wet_mat
	tarmac.position = Vector3(0, -0.2, 0)
	tarmac.set("use_collision", true) # Make the ground drivable
	tarmac.create_trimesh_collision()
	add_child(tarmac)

	# 2. Weathered Industrial Warehouses & Hangars around the perimeter
	var warehouse_root := Node3D.new()
	warehouse_root.name = "Warehouses"
	add_child(warehouse_root)

	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.55, 0.56, 0.58) # Aged concrete walls
	
	var roof_mat := StandardMaterial3D.new()
	roof_mat.albedo_color = Color(0.42, 0.28, 0.22) # Rusty corrugated metal roof
	roof_mat.roughness = 0.9

	# Spawn multiple warehouse hangars surrounding the lot
	var warehouse_positions: Array[Vector3] = [
		Vector3(0, 4.0, -180),
		Vector3(-140, 4.0, -120),
		Vector3(140, 4.0, -120),
		Vector3(-140, 4.0, 40),
		Vector3(140, 4.0, 40),
		Vector3(0, 4.0, 180)
	]

	for pos in warehouse_positions:
		var hangar := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(80.0, 9.0, 30.0)
		hangar.mesh = box
		hangar.material_override = wall_mat
		hangar.position = pos
		hangar.create_trimesh_collision()
		warehouse_root.add_child(hangar)

		# Rusty curved/peaked roof
		var roof := MeshInstance3D.new()
		var roof_box := BoxMesh.new()
		roof_box.size = Vector3(82.0, 3.5, 32.0)
		roof.mesh = roof_box
		roof.material_override = roof_mat
		roof.position = pos + Vector3(0, 6.0, 0)
		warehouse_root.add_child(roof)

func _build_drift_layout_and_barriers() -> void:
	var course_node := Node3D.new()
	course_node.name = "TarmacDriftCourse"
	add_child(course_node)

	# Barrier Materials
	var red_barrier_mat := StandardMaterial3D.new()
	red_barrier_mat.albedo_color = Color(0.85, 0.16, 0.14) # Red plastic water barrier
	red_barrier_mat.roughness = 0.65
	red_barrier_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON

	var white_barrier_mat := StandardMaterial3D.new()
	white_barrier_mat.albedo_color = Color(0.92, 0.93, 0.95) # White plastic water barrier
	white_barrier_mat.roughness = 0.65
	white_barrier_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON

	var tire_mat := StandardMaterial3D.new()
	tire_mat.albedo_color = Color(0.10, 0.11, 0.12) # Black rubber tire stack
	tire_mat.roughness = 0.95
	tire_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON

	# 1. Start / Launch Straight Barriers (Facing -Z toward Turn 1 sweep)
	_spawn_barrier_line(course_node, Vector3(-12.0, 0.0, 68.0), Vector3(-12.0, 0.0, 25.0), red_barrier_mat, white_barrier_mat)
	_spawn_barrier_line(course_node, Vector3(12.0, 0.0, 68.0), Vector3(12.0, 0.0, 25.0), red_barrier_mat, white_barrier_mat)

	# 2. Turn 1 Sweeper Arc (Curving right from Z=25 toward X=65, Z=-15)
	var arc1_pts: Array[Vector3] = [
		Vector3(12.0, 0.0, 25.0),
		Vector3(25.0, 0.0, 10.0),
		Vector3(55.0, 0.0, 0.0),
		Vector3(75.0, 0.0, -25.0),
		Vector3(70.0, 0.0, -55.0),
		Vector3(45.0, 0.0, -75.0)
	]
	_spawn_barrier_curve(course_node, arc1_pts, red_barrier_mat, white_barrier_mat)

	# 3. Hairpin 1 Apex Island (East Hairpin around X=40, Z=-40)
	_spawn_tire_stack_cluster(course_node, Vector3(40.0, 0.0, -40.0), 3, tire_mat)
	_spawn_barrier_circle(course_node, Vector3(40.0, 0.0, -40.0), 10.0, red_barrier_mat, white_barrier_mat)

	# 4. Figure-Eight Crossover Island & Gates (Center at X=0, Z=-50)
	_spawn_tire_stack_cluster(course_node, Vector3(-12.0, 0.0, -55.0), 2, tire_mat)
	_spawn_tire_stack_cluster(course_node, Vector3(12.0, 0.0, -45.0), 2, tire_mat)
	_spawn_barrier_line(course_node, Vector3(-25.0, 0.0, -62.0), Vector3(-8.0, 0.0, -70.0), red_barrier_mat, white_barrier_mat)
	_spawn_barrier_line(course_node, Vector3(8.0, 0.0, -32.0), Vector3(25.0, 0.0, -40.0), red_barrier_mat, white_barrier_mat)

	# 5. Hairpin 2 Apex Island (West Hairpin around X=-45, Z=-75)
	_spawn_tire_stack_cluster(course_node, Vector3(-45.0, 0.0, -75.0), 3, tire_mat)
	_spawn_barrier_circle(course_node, Vector3(-45.0, 0.0, -75.0), 10.0, red_barrier_mat, white_barrier_mat)

	# Hairpin 2 Outer Runoff Barrier Arc
	var arc2_pts: Array[Vector3] = [
		Vector3(-25.0, 0.0, -100.0),
		Vector3(-60.0, 0.0, -95.0),
		Vector3(-80.0, 0.0, -75.0),
		Vector3(-75.0, 0.0, -50.0),
		Vector3(-55.0, 0.0, -25.0)
	]
	_spawn_barrier_curve(course_node, arc2_pts, red_barrier_mat, white_barrier_mat)

	# 6. South Sweeper & Chicanes leading back toward Start Grid
	var arc3_pts: Array[Vector3] = [
		Vector3(-55.0, 0.0, -25.0),
		Vector3(-40.0, 0.0, 5.0),
		Vector3(-25.0, 0.0, 30.0),
		Vector3(-12.0, 0.0, 45.0)
	]
	_spawn_barrier_curve(course_node, arc3_pts, red_barrier_mat, white_barrier_mat)
	_spawn_tire_stack_cluster(course_node, Vector3(-30.0, 0.0, 15.0), 2, tire_mat)

func _spawn_barrier_line(parent: Node3D, from: Vector3, to: Vector3, mat_red: Material, mat_white: Material) -> void:
	var dir := to - from
	var dist := dir.length()
	if dist < 0.1: return
	var norm_dir := dir.normalized()
	var step: float = 2.4
	var count := int(ceil(dist / step))
	var rot_y := atan2(norm_dir.x, norm_dir.z)

	for i in range(count):
		var t := float(i) / float(max(1, count - 1)) if count > 1 else 0.5
		var pos := from.lerp(to, t)
		var mat: Material = mat_red if (i % 2 == 0) else mat_white
		_spawn_single_barrier(parent, pos, rot_y, mat)

func _spawn_barrier_curve(parent: Node3D, pts: Array[Vector3], mat_red: Material, mat_white: Material) -> void:
	var barrier_idx: int = 0
	for i in range(pts.size() - 1):
		var p1: Vector3 = pts[i]
		var p2: Vector3 = pts[i + 1]
		var seg_dir := p2 - p1
		var seg_dist := seg_dir.length()
		var norm := seg_dir.normalized()
		var rot_y := atan2(norm.x, norm.z)
		var step: float = 2.4
		var count := int(ceil(seg_dist / step))
		for j in range(count):
			var t := float(j) / float(max(1, count))
			var pos := p1.lerp(p2, t)
			var mat: Material = mat_red if (barrier_idx % 2 == 0) else mat_white
			_spawn_single_barrier(parent, pos, rot_y, mat)
			barrier_idx += 1

func _spawn_barrier_circle(parent: Node3D, center: Vector3, radius: float, mat_red: Material, mat_white: Material) -> void:
	var circumference := TAU * radius
	var count := int(ceil(circumference / 2.5))
	for i in range(count):
		var angle := (float(i) / float(count)) * TAU
		var pos := center + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		var rot_y := angle + PI * 0.5
		var mat: Material = mat_red if (i % 2 == 0) else mat_white
		_spawn_single_barrier(parent, pos, rot_y, mat)

func _spawn_single_barrier(parent: Node3D, pos: Vector3, rot_y: float, mat: Material) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation.y = rot_y
	parent.add_child(body)

	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.65, 0.85, 2.2) # Width, Height, Length
	mesh_inst.mesh = box
	mesh_inst.material_override = mat
	mesh_inst.position = Vector3(0.0, 0.425, 0.0)
	body.add_child(mesh_inst)

	var col := CollisionShape3D.new()
	var col_box := BoxShape3D.new()
	col_box.size = Vector3(0.65, 0.85, 2.2)
	col.shape = col_box
	col.position = Vector3(0.0, 0.425, 0.0)
	body.add_child(col)

func _spawn_tire_stack_cluster(parent: Node3D, center: Vector3, count_tier: int, mat: Material) -> void:
	var cluster_body := StaticBody3D.new()
	cluster_body.position = center
	parent.add_child(cluster_body)

	var tire_mesh := CylinderMesh.new()
	tire_mesh.top_radius = 0.55
	tire_mesh.bottom_radius = 0.55
	tire_mesh.height = 0.35
	tire_mesh.radial_segments = 12
	tire_mesh.material = mat

	var offsets := [
		Vector3(0.0, 0.0, 0.0),
		Vector3(-0.6, 0.0, 0.5),
		Vector3(0.6, 0.0, 0.5),
		Vector3(-0.6, 0.0, -0.5),
		Vector3(0.6, 0.0, -0.5)
	]

	for off in offsets:
		for tier in range(count_tier):
			var inst := MeshInstance3D.new()
			inst.mesh = tire_mesh
			inst.position = Vector3(off.x, tier * 0.35 + 0.175, off.z)
			cluster_body.add_child(inst)

	var col := CollisionShape3D.new()
	var col_cyl := CylinderShape3D.new()
	col_cyl.radius = 1.35
	col_cyl.height = count_tier * 0.35 + 0.2
	col.shape = col_cyl
	col.position = Vector3(0.0, (count_tier * 0.35) * 0.5, 0.0)
	cluster_body.add_child(col)

func _spawn_clipping_zones() -> void:
	if clipping_zone_scene == null:
		return

	var clip_node := Node3D.new()
	clip_node.name = "ClippingZones"
	add_child(clip_node)

	var apexes = [
		{"name": "INITIATION SWEEP", "pos": Vector3(50.0, 0.15, -15.0)},
		{"name": "HAIRPIN 1 // APEX", "pos": Vector3(40.0, 0.15, -40.0)},
		{"name": "CROSSOVER FLICK", "pos": Vector3(0.0, 0.15, -50.0)},
		{"name": "HAIRPIN 2 // APEX", "pos": Vector3(-45.0, 0.15, -75.0)},
		{"name": "SOUTH SWEEPER", "pos": Vector3(-25.0, 0.15, 20.0)}
	]

	for a in apexes:
		var zone = clipping_zone_scene.instantiate()
		zone.position = a["pos"]
		zone.set("zone_name", a["name"])
		clip_node.add_child(zone)

func _spawn_distant_treelines() -> void:
	var tree_root := Node3D.new()
	tree_root.name = "DistantTreelines"
	add_child(tree_root)

	var trunk_mat := ForestUtils.create_pine_bark_material()
	var canopy_mat := ForestUtils.create_pine_needle_material()

	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.4
	trunk_mesh.bottom_radius = 0.6
	trunk_mesh.height = 5.0
	trunk_mesh.material = trunk_mat

	var canopy_mesh := CylinderMesh.new()
	canopy_mesh.top_radius = 0.1
	canopy_mesh.bottom_radius = 3.5
	canopy_mesh.height = 12.0
	canopy_mesh.material = canopy_mat

	var total_trees: int = 160
	var mm_trunks := MultiMeshInstance3D.new()
	mm_trunks.multimesh = MultiMesh.new()
	mm_trunks.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	mm_trunks.multimesh.mesh = trunk_mesh
	mm_trunks.multimesh.instance_count = total_trees
	tree_root.add_child(mm_trunks)

	var mm_canopies := MultiMeshInstance3D.new()
	mm_canopies.multimesh = MultiMesh.new()
	mm_canopies.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	mm_canopies.multimesh.mesh = canopy_mesh
	mm_canopies.multimesh.instance_count = total_trees
	tree_root.add_child(mm_canopies)

	# 3D Tree Stumps along treeline perimeter
	var total_stumps: int = 60
	var stump_mesh := ForestUtils.create_tree_stump_mesh()
	var mm_stumps := MultiMeshInstance3D.new()
	mm_stumps.name = "IndustrialTreeStumps"
	mm_stumps.multimesh = MultiMesh.new()
	mm_stumps.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	mm_stumps.multimesh.mesh = stump_mesh
	mm_stumps.multimesh.instance_count = total_stumps
	tree_root.add_child(mm_stumps)

	var stump_idx: int = 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 5543
	for i in range(-15, 15):
		if stump_idx >= total_stumps: break
		var side: float = -322.0 if (i % 2 == 0) else 322.0
		var ss: float = rng.randf_range(0.9, 1.4)
		var rot: float = rng.randf_range(0.0, TAU)
		var b := Basis(Vector3.UP, rot).scaled(Vector3(ss, ss, ss))
		var pos := Vector3(float(i) * 21.0 + rng.randf_range(-3.0, 3.0), 0.42 * ss, side + rng.randf_range(-4.0, 4.0))
		mm_stumps.multimesh.set_instance_transform(stump_idx, Transform3D(b, pos))
		stump_idx += 1

	var tree_idx: int = 0
	# North row at Z = -330
	for i in range(-20, 20):
		var pos := Vector3(float(i) * 16.0, 0.0, -330.0)
		_set_tree_instance(mm_trunks, mm_canopies, tree_idx, pos)
		tree_idx += 1
		if tree_idx >= total_trees: break

	# South row at Z = 330
	for i in range(-20, 20):
		if tree_idx >= total_trees: break
		var pos := Vector3(float(i) * 16.0, 0.0, 330.0)
		_set_tree_instance(mm_trunks, mm_canopies, tree_idx, pos)
		tree_idx += 1

	# West row at X = -330
	for i in range(-20, 20):
		if tree_idx >= total_trees: break
		var pos := Vector3(-330.0, 0.0, float(i) * 16.0)
		_set_tree_instance(mm_trunks, mm_canopies, tree_idx, pos)
		tree_idx += 1

	# East row at X = 330
	for i in range(-20, 20):
		if tree_idx >= total_trees: break
		var pos := Vector3(330.0, 0.0, float(i) * 16.0)
		_set_tree_instance(mm_trunks, mm_canopies, tree_idx, pos)
		tree_idx += 1

func _set_tree_instance(mm_t: MultiMeshInstance3D, mm_c: MultiMeshInstance3D, idx: int, pos: Vector3) -> void:
	var tf_t := Transform3D(Basis.IDENTITY, pos + Vector3(0.0, 2.5, 0.0))
	var tf_c := Transform3D(Basis.IDENTITY, pos + Vector3(0.0, 8.5, 0.0))
	mm_t.multimesh.set_instance_transform(idx, tf_t)
	mm_c.multimesh.set_instance_transform(idx, tf_c)

func _place_car_at_grid() -> void:
	var chosen_car_path: String = ""
	if Engine.has_meta("selected_car_path"):
		chosen_car_path = str(Engine.get_meta("selected_car_path"))
	elif "selected_car_path" in MainMenu:
		chosen_car_path = MainMenu.selected_car_path

	var car: Node3D = null
	if is_inside_tree() and get_tree() != null and get_tree().root != null:
		car = get_tree().root.find_child("DriftCar", true, false) as Node3D
	if chosen_car_path != "" and ResourceLoader.exists(chosen_car_path) and car != null:
		if car.scene_file_path != chosen_car_path:
			var parent = car.get_parent()
			var car_scene: PackedScene = load(chosen_car_path)
			if car_scene != null:
				var new_car = car_scene.instantiate() as Node3D
				new_car.name = "DriftCar"
				parent.remove_child(car)
				car.queue_free()
				parent.add_child(new_car)
				car = new_car

	if car:
		car.global_transform = Transform3D(Basis.IDENTITY, Vector3(0.0, 1.0, 60.0))
		if "spawn_transform" in car:
			car.set("spawn_transform", car.global_transform)
		if car is RigidBody3D:
			car.linear_velocity = Vector3.ZERO
			car.angular_velocity = Vector3.ZERO
