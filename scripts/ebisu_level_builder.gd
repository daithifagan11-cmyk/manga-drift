class_name EbisuLevelBuilder
extends Node3D

@export var road_width: float = 16.0
@export var curb_width: float = 1.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_configure_environment()
	_build_lush_terrain_and_stadium()
	_build_ebisu_technical_circuit()
	_place_car_at_grid()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if get_tree() != null:
			get_tree().paused = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	elif Input.is_key_pressed(KEY_R) or (Input.is_key_pressed(KEY_ENTER) and not Engine.get_meta("is_split_screen", false)):
		get_tree().reload_current_scene()

func _configure_environment() -> void:
	# Ultra-realistic next-gen GTA 6 visual fidelity pipeline
	if not is_inside_tree() or get_tree() == null or get_tree().root == null:
		return
	var world_env := get_tree().root.find_child("WorldEnvironment", true, false) as WorldEnvironment
	if world_env and world_env.environment:
		var env := world_env.environment
		env.background_mode = Environment.BG_SKY
		if not env.sky:
			env.sky = Sky.new()
		var sky_mat := ProceduralSkyMaterial.new()
		sky_mat.sky_top_color = Color(0.07, 0.13, 0.26)
		sky_mat.sky_horizon_color = Color(0.16, 0.28, 0.48)
		sky_mat.ground_horizon_color = Color(0.08, 0.14, 0.24)
		sky_mat.ground_bottom_color = Color(0.04, 0.07, 0.12)
		env.sky.sky_material = sky_mat
		
		env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		env.ambient_light_color = Color(0.20, 0.26, 0.38)
		env.ambient_light_energy = 1.15
		env.ambient_light_sky_contribution = 0.80
		env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
		
		# Tonemapper ACES with high dynamic range compression
		env.tonemap_mode = Environment.TONE_MAPPER_ACES
		env.tonemap_exposure = 1.25
		env.tonemap_white = 5.8
		
		# High-quality Bloom and Glow
		env.glow_enabled = true
		env.glow_normalized = true
		env.glow_intensity = 0.75
		env.glow_bloom = 1.6
		env.glow_hdr_threshold = 0.85
		env.glow_hdr_scale = 2.0
		env.glow_hdr_luminance_cap = 16.0
		
		# SSAO & SSR for deep contact shadows and wet tarmac reflections
		env.ssao_enabled = true
		env.ssao_radius = 2.4
		env.ssao_intensity = 2.4
		env.ssao_power = 1.5
		env.ssao_detail = 1.2
		env.ssao_horizon = 0.08
		env.ssao_sharpness = 0.98

		env.ssr_enabled = true
		env.ssr_max_steps = 128
		env.ssr_fade_in = 0.1
		env.ssr_fade_out = 2.4
		env.ssr_depth_tolerance = 0.3
		
		# Volumetric Fog: dense atmospheric haze with light shafts
		env.volumetric_fog_enabled = true
		env.volumetric_fog_density = 0.025
		env.volumetric_fog_albedo = Color(0.16, 0.22, 0.34)
		env.volumetric_fog_emission = Color(0.025, 0.035, 0.06)
		env.volumetric_fog_emission_energy = 0.9
		env.volumetric_fog_gi_inject = 1.0
		env.volumetric_fog_anisotropy = 0.35
		env.volumetric_fog_length = 350.0
		env.volumetric_fog_ambient_inject = 0.45
		env.volumetric_fog_sky_affect = 0.25

		# Cinematic Color Grading Adjustments
		env.adjustment_enabled = true
		env.adjustment_brightness = 1.08
		env.adjustment_contrast = 1.12
		env.adjustment_saturation = 1.25

	var dir_light := get_tree().root.find_child("DirectionalLight3D", true, false) as DirectionalLight3D
	if dir_light:
		dir_light.light_color = Color(0.76, 0.85, 0.98)
		dir_light.light_energy = 0.75
		dir_light.shadow_enabled = true
		dir_light.light_volumetric_fog_energy = 1.5

func _build_lush_terrain_and_stadium() -> void:
	# 1. Lush Green Rolling Grass Ground (Replaces gray floor)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(1400, 1400)
	ground.mesh = plane
	var grass_mat := StandardMaterial3D.new()
	grass_mat.albedo_color = Color(0.12, 0.35, 0.16) # Vibrant Japanese hill grass
	grass_mat.roughness = 0.95
	grass_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	ground.material_override = grass_mat
	ground.position = Vector3(0, -0.25, -60)
	add_child(ground)
	ground.create_trimesh_collision()

	# Dedicated concrete pit lane pad under the paddock
	var pit_pad := MeshInstance3D.new()
	var pad_box := BoxMesh.new()
	pad_box.size = Vector3(130.0, 0.1, 16.0)
	pit_pad.mesh = pad_box
	var pad_mat := StandardMaterial3D.new()
	pad_mat.albedo_color = Color(0.16, 0.18, 0.22)
	pad_mat.roughness = 0.88
	pit_pad.material_override = pad_mat
	pit_pad.position = Vector3(0.0, -0.05, 15.0)
	add_child(pit_pad)

	# Paddock Pit Garages
	var pit := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(85.0, 5.5, 9.0)
	pit.mesh = box
	var pit_mat := StandardMaterial3D.new()
	pit_mat.albedo_color = Color(0.92, 0.94, 0.96)
	pit_mat.roughness = 0.5
	pit.material_override = pit_mat
	pit.position = Vector3(0.0, 2.65, 18.0)
	add_child(pit)
	pit.create_trimesh_collision()

	# Pit Building Roof Trim / Awning
	var awning := MeshInstance3D.new()
	var awning_mesh := BoxMesh.new()
	awning_mesh.size = Vector3(88.0, 0.5, 12.0)
	awning.mesh = awning_mesh
	var awning_mat := StandardMaterial3D.new()
	awning_mat.albedo_color = Color(0.18, 0.22, 0.30)
	awning.material_override = awning_mat
	awning.position = Vector3(0.0, 5.4, 16.5)
	add_child(awning)

	for b in range(6):
		var bay := MeshInstance3D.new()
		var bay_mesh := BoxMesh.new()
		bay_mesh.size = Vector3(10.0, 3.8, 0.4)
		bay.mesh = bay_mesh
		var bay_mat := StandardMaterial3D.new()
		bay_mat.albedo_color = Color(0.12, 0.14, 0.18)
		bay.material_override = bay_mat
		bay.position = Vector3(-35.0 + float(b) * 14.0, 1.9, 13.4)
		add_child(bay)

	# 2. Stadium Grandstands filled with spectators along the main straight
	var stadium_root := Node3D.new()
	stadium_root.name = "StadiumGrandstands"
	stadium_root.position = Vector3(0, 0, 35)
	add_child(stadium_root)

	var concrete_mat := StandardMaterial3D.new()
	concrete_mat.albedo_color = Color(0.55, 0.58, 0.62)

	for i in range(5): # Tiered grandstand rows
		var tier := MeshInstance3D.new()
		var t_box := BoxMesh.new()
		t_box.size = Vector3(160.0, 1.8, 3.0)
		tier.mesh = t_box
		tier.material_override = concrete_mat
		tier.position = Vector3(0.0, float(i) * 1.5, float(i) * -2.8)
		stadium_root.add_child(tier)
		tier.create_trimesh_collision()

	# Roof canopy over grandstands
	var roof := MeshInstance3D.new()
	var roof_box := BoxMesh.new()
	roof_box.size = Vector3(165.0, 0.6, 14.0)
	roof.mesh = roof_box
	var roof_mat := StandardMaterial3D.new()
	roof_mat.albedo_color = Color(0.85, 0.15, 0.15) # Red racing canopy
	roof.material_override = roof_mat
	roof.position = Vector3(0.0, 8.0, -6.0)
	stadium_root.add_child(roof)

	# Packed Spectator Crowd inside Grandstands
	_spawn_spectator_crowd(stadium_root)

	# 3. Start / Finish Line Grid Markings on Track
	var grid_line := MeshInstance3D.new()
	var g_box := BoxMesh.new()
	g_box.size = Vector3(1.2, 0.05, road_width)
	grid_line.mesh = g_box
	var g_mat := StandardMaterial3D.new()
	g_mat.albedo_color = Color(0.95, 0.95, 0.95)
	grid_line.material_override = g_mat
	grid_line.position = Vector3(-50.0, 0.05, 0.0)
	add_child(grid_line)

func _spawn_spectator_crowd(parent_node: Node3D) -> void:
	var rows := 5
	var cols := 140
	var total_crowd := rows * cols

	var multi_mesh := MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.use_colors = true
	multi_mesh.instance_count = total_crowd

	var fan_mesh := CapsuleMesh.new()
	fan_mesh.radius = 0.22
	fan_mesh.height = 1.15
	fan_mesh.radial_segments = 6
	fan_mesh.rings = 2

	var fan_mat := StandardMaterial3D.new()
	fan_mat.vertex_color_use_as_albedo = true
	fan_mat.roughness = 0.85
	fan_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	fan_mesh.material = fan_mat
	multi_mesh.mesh = fan_mesh

	var fan_palette: Array[Color] = [
		Color(0.88, 0.16, 0.18),
		Color(0.18, 0.48, 0.92),
		Color(0.96, 0.82, 0.12),
		Color(0.94, 0.95, 0.98),
		Color(0.14, 0.15, 0.18),
		Color(0.16, 0.68, 0.34),
		Color(0.95, 0.48, 0.16)
	]

	var rng := RandomNumberGenerator.new()
	rng.seed = 77123

	var idx := 0
	for r in range(rows):
		var row_z = float(r) * -2.8
		var row_y = float(r) * 1.5 + 1.48
		for c in range(cols):
			var frac := float(c) / float(cols - 1)
			var row_x = -75.0 + frac * 150.0
			var jx = row_x + rng.randf_range(-0.15, 0.15)
			var jz = row_z + rng.randf_range(-0.10, 0.10)
			var jy = row_y + rng.randf_range(-0.04, 0.08)
			var yaw = rng.randf_range(-0.20, 0.20)

			var basis := Basis(Vector3.UP, yaw)
			var t := Transform3D(basis, Vector3(jx, jy, jz))
			multi_mesh.set_instance_transform(idx, t)

			var col = fan_palette[rng.randi() % fan_palette.size()]
			multi_mesh.set_instance_color(idx, col)
			idx += 1

	var crowd_inst := MultiMeshInstance3D.new()
	crowd_inst.name = "StadiumCrowd"
	crowd_inst.multimesh = multi_mesh
	parent_node.add_child(crowd_inst)

func _build_ebisu_technical_circuit() -> void:
	var path := Path3D.new()
	path.name = "EbisuTechnicalPath"
	var curve := Curve3D.new()
	curve.bake_interval = 0.8
	
	# Technical multi-turn drift layout (Hairpins, Chicanes, Sweepers)
	var pts: Array[Vector3] = [
		Vector3(-80, 0, 0),       # Main straight start / Pit lane
		Vector3(80, 0, 0),        # Turn 1 entry
		Vector3(140, 0, -35),     # Sweeping hairpin 1
		Vector3(130, 0, -100),    # Chicane entry
		Vector3(80, 0, -130),     # Technical switchback apex A
		Vector3(30, 0, -110),
		Vector3(-20, 0, -140),    # Deep hairpin 2 (Minami style)
		Vector3(-90, 0, -160),
		Vector3(-150, 0, -120),   # Sweeper loop
		Vector3(-140, 0, -60),
		Vector3(-80, 0, -30),     # S-curve transition
		Vector3(-40, 0, -70),
		Vector3(40, 0, -60),
		Vector3(90, 0, -20),
		Vector3(-80, 0, 0)        # Loop back to main straight
	]
	
	for i in range(pts.size()):
		var prev_p: Vector3 = pts[(i - 1 + pts.size()) % pts.size()]
		var next_p: Vector3 = pts[(i + 1) % pts.size()]
		var tangent: Vector3 = (next_p - prev_p) * 0.28
		curve.add_point(pts[i], -tangent, tangent)
	
	path.curve = curve
	add_child(path)
	
	var hw: float = road_width * 0.5
	
	# Procedural red-and-white alternating rumble curb texture
	var curb_img := Image.create(2, 1, false, Image.FORMAT_RGBA8)
	curb_img.set_pixel(0, 0, Color(0.85, 0.16, 0.16)) # Vivid Touge Red
	curb_img.set_pixel(1, 0, Color(0.96, 0.96, 0.98)) # Stark White
	var curb_tex := ImageTexture.create_from_image(curb_img)

	# 1. Main Asphalt Road (with cull_mode disabled to ensure top surface visibility)
	_extrude_csg("EbisuAsphalt", PackedVector2Array([
		Vector2(-hw, -0.3),
		Vector2(hw, -0.3),
		Vector2(hw, 0.02),
		Vector2(-hw, 0.02)
	]), Color(0.14, 0.15, 0.18), null, true)

	# 2. Red & White Rumble Curbs (Inner & Outer Apexes)
	_extrude_csg("InnerCurb", PackedVector2Array([
		Vector2(-hw - curb_width, -0.3), Vector2(-hw, -0.3), Vector2(-hw, 0.08), Vector2(-hw - curb_width, 0.08)
	]), Color.WHITE, curb_tex, true)

	_extrude_csg("OuterCurb", PackedVector2Array([
		Vector2(hw, -0.3), Vector2(hw + curb_width, -0.3), Vector2(hw + curb_width, 0.08), Vector2(hw, 0.08)
	]), Color.WHITE, curb_tex, true)

	# 3. Dense 3,000+ Pine Forest across the map
	_spawn_dense_pine_forest(curve, hw)

	# 4. Roadside Bush Clusters framing corners
	_spawn_roadside_bushes(curve, hw)

	# 5. Track-border Tree Stumps and Companion Pines
	_spawn_realistic_forest_and_stumps(curve)

func _extrude_csg(n_name: String, poly: PackedVector2Array, col: Color, tex: Texture2D, collide: bool) -> void:
	var csg := CSGPolygon3D.new()
	csg.name = n_name
	csg.mode = CSGPolygon3D.MODE_PATH
	csg.path_node = NodePath("../EbisuTechnicalPath")
	csg.path_interval_type = CSGPolygon3D.PATH_INTERVAL_DISTANCE
	csg.path_interval = 0.8
	csg.path_joined = true
	csg.use_collision = collide
	csg.polygon = poly
	
	if n_name == "EbisuAsphalt" or n_name == "EbisuRoad":
		var tarmac_mat := ShaderMaterial.new()
		tarmac_mat.shader = load("res://shaders/wet_tarmac.gdshader")
		tarmac_mat.set_shader_parameter("albedo_color", Color(0.11, 0.12, 0.14))
		tarmac_mat.set_shader_parameter("metallic", 0.05)
		tarmac_mat.set_shader_parameter("roughness", 0.85)
		tarmac_mat.set_shader_parameter("normal_scale", 3.2)
		csg.material = tarmac_mat
	else:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = col
		mat.roughness = 0.82
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		if tex:
			mat.albedo_texture = tex
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			mat.uv1_scale = Vector3(1.0, 180.0, 1.0)
		csg.material = mat
	add_child(csg)

func _spawn_dense_pine_forest(curve: Curve3D, hw: float) -> void:
	var target_tree_count := 3200
	# Ensure trees and stumps stay strictly off the asphalt road
	var min_clearance: float = (road_width * 0.5) + 6.0 # Extra safety margin
	var baked_pts: PackedVector3Array = curve.get_baked_points()

	var pine_mesh := CylinderMesh.new()
	pine_mesh.top_radius = 0.0
	pine_mesh.bottom_radius = 3.4
	pine_mesh.height = 9.0
	pine_mesh.radial_segments = 6

	var pine_mat := ForestUtils.create_pine_needle_material()
	pine_mesh.material = pine_mat

	var rng := RandomNumberGenerator.new()
	rng.seed = 987654

	var transforms: Array[Transform3D] = []
	var max_attempts := 7500
	var attempts := 0

	while transforms.size() < target_tree_count and attempts < max_attempts:
		attempts += 1
		var tx := rng.randf_range(-500.0, 500.0)
		var tz := rng.randf_range(-550.0, 200.0)

		# Facility clearance (paddock pit building & grandstand area)
		if absf(tx) < 95.0 and tz > 5.0 and tz < 48.0:
			continue

		# Ensure trees and stumps stay strictly off the asphalt road
		var too_close: bool = false
		for bp in baked_pts:
			if Vector2(tx, tz).distance_to(Vector2(bp.x, bp.z)) < min_clearance:
				too_close = true
				break

		if too_close:
			continue # Skip spawning this tree/stump if it touches the road

		var scale_y := rng.randf_range(0.85, 1.45)
		var scale_xz := rng.randf_range(0.85, 1.25)
		var rot_y := rng.randf_range(0.0, TAU)
		var b := Basis(Vector3.UP, rot_y).scaled(Vector3(scale_xz, scale_y, scale_xz))
		var pos := Vector3(tx, scale_y * 4.5 - 0.25, tz)
		transforms.append(Transform3D(b, pos))

	var multi_mesh := MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.mesh = pine_mesh
	multi_mesh.instance_count = transforms.size()
	for i in range(transforms.size()):
		multi_mesh.set_instance_transform(i, transforms[i])

	var mm_inst := MultiMeshInstance3D.new()
	mm_inst.name = "DensePineForest"
	mm_inst.multimesh = multi_mesh
	add_child(mm_inst)

	# 3D Tree Stumps along asphalt margins and forest floor
	var stump_count := 300
	var stump_mesh := ForestUtils.create_tree_stump_mesh()
	var stump_transforms: Array[Transform3D] = []
	var stump_attempts := 0

	while stump_transforms.size() < stump_count and stump_attempts < stump_count * 5:
		stump_attempts += 1
		var sx := rng.randf_range(-480.0, 480.0)
		var sz := rng.randf_range(-530.0, 180.0)

		# Facility clearance
		if absf(sx) < 95.0 and sz > 5.0 and sz < 48.0:
			continue

		# Ensure trees and stumps stay strictly off the asphalt road
		var stump_too_close: bool = false
		for bp in baked_pts:
			if Vector2(sx, sz).distance_to(Vector2(bp.x, bp.z)) < min_clearance:
				stump_too_close = true
				break

		if stump_too_close:
			continue # Skip spawning this tree/stump if it touches the road

		var ss := rng.randf_range(0.85, 1.45)
		var rot_y := rng.randf_range(0.0, TAU)
		var sb := Basis(Vector3.UP, rot_y).scaled(Vector3(ss, ss, ss))
		var spos := Vector3(sx, 0.42 * ss - 0.25, sz)
		stump_transforms.append(Transform3D(sb, spos))

	var mm_stumps := MultiMeshInstance3D.new()
	mm_stumps.name = "EbisuForestStumps"
	mm_stumps.multimesh = MultiMesh.new()
	mm_stumps.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	mm_stumps.multimesh.mesh = stump_mesh
	mm_stumps.multimesh.instance_count = stump_transforms.size()
	for i in range(stump_transforms.size()):
		mm_stumps.multimesh.set_instance_transform(i, stump_transforms[i])
	add_child(mm_stumps)

func _spawn_roadside_bushes(curve: Curve3D, hw: float) -> void:
	var bush_mesh := SphereMesh.new()
	bush_mesh.radius = 1.1
	bush_mesh.height = 1.6
	bush_mesh.radial_segments = 8
	bush_mesh.rings = 4

	var bush_mat := StandardMaterial3D.new()
	bush_mat.albedo_color = Color(0.09, 0.30, 0.12)
	bush_mat.roughness = 0.90
	bush_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	bush_mesh.material = bush_mat

	var rng := RandomNumberGenerator.new()
	rng.seed = 24680

	var transforms: Array[Transform3D] = []
	var total_len := curve.get_baked_length()
	var step_size := 5.5
	var d := 0.0

	# Ensure trees and stumps stay strictly off the asphalt road
	var min_clearance: float = (road_width * 0.5) + 6.0 # Extra safety margin
	var baked_pts: PackedVector3Array = curve.get_baked_points()

	while d < total_len:
		var p := curve.sample_baked(d)
		var p_next := curve.sample_baked(d + 1.0)
		var tangent := (p_next - p).normalized()
		var normal := Vector3(-tangent.z, 0.0, tangent.x).normalized()

		var sides: Array[float] = [-1.0, 1.0]
		for side in sides:
			# Avoid placing bushes along the pit straight / grandstand apron
			if absf(p.z) < 14.0 and p.x > -75.0 and p.x < 75.0:
				continue

			# 85% chance of cluster at each station
			if rng.randf() > 0.85:
				continue

			var cluster_count := rng.randi_range(2, 3)
			var base_dist: float = min_clearance + 0.8
			var base_pos: Vector3 = p + normal * (side * base_dist)

			for k in range(cluster_count):
				var along_jitter: Vector3 = tangent * rng.randf_range(-1.2, 1.2)
				var out_jitter: Vector3 = normal * (side * rng.randf_range(0.2, 1.6))
				var b_pos: Vector3 = base_pos + along_jitter + out_jitter

				# Ensure trees and stumps stay strictly off the asphalt road
				var too_close: bool = false
				for bp in baked_pts:
					if Vector2(b_pos.x, b_pos.z).distance_to(Vector2(bp.x, bp.z)) < min_clearance:
						too_close = true
						break

				if too_close:
					continue # Skip spawning this tree/stump if it touches the road

				var scale_r := rng.randf_range(0.85, 1.35)
				var scale_y := scale_r * rng.randf_range(0.75, 1.05)
				b_pos.y = scale_y * 0.7 - 0.15

				var rot_y := rng.randf_range(0.0, TAU)
				var b_basis := Basis(Vector3.UP, rot_y).scaled(Vector3(scale_r, scale_y, scale_r))
				transforms.append(Transform3D(b_basis, b_pos))

		d += step_size

	if transforms.is_empty():
		return

	var multi_mesh := MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.mesh = bush_mesh
	multi_mesh.instance_count = transforms.size()
	for i in range(transforms.size()):
		multi_mesh.set_instance_transform(i, transforms[i])

	var mm_inst := MultiMeshInstance3D.new()
	mm_inst.name = "RoadsideBushes"
	mm_inst.multimesh = multi_mesh
	add_child(mm_inst)

func _spawn_realistic_forest_and_stumps(curve: Curve3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242

	# 1. Photorealistic Bark Material
	var bark_mat := StandardMaterial3D.new()
	bark_mat.albedo_color = Color(0.14, 0.10, 0.07)
	bark_mat.roughness = 0.96
	bark_mat.normal_enabled = true
	bark_mat.normal_scale = 3.5
	bark_mat.normal_texture = ForestUtils.create_pine_bark_material().normal_texture
	bark_mat.uv1_scale = Vector3(1.0, 4.0, 1.0)

	# 2. Photorealistic Needle Material
	var needle_mat := StandardMaterial3D.new()
	needle_mat.albedo_color = Color(0.05, 0.16, 0.08)
	needle_mat.roughness = 0.85
	needle_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
	needle_mat.subsurf_scatter_enabled = true
	needle_mat.subsurf_scatter_strength = 0.25
	needle_mat.subsurf_scatter_transmittance_enabled = true
	needle_mat.subsurf_scatter_transmittance_color = Color(0.08, 0.25, 0.10)

	# 3. Tree Stump Mesh with Wood Grain Top
	var stump_mesh := CylinderMesh.new()
	stump_mesh.top_radius = 0.45
	stump_mesh.bottom_radius = 0.55
	stump_mesh.height = 0.7
	var stump_mat := StandardMaterial3D.new()
	stump_mat.albedo_color = Color(0.22, 0.15, 0.10)
	stump_mat.roughness = 0.9
	stump_mat.albedo_texture = ForestUtils.create_stump_rings_material().albedo_texture
	stump_mesh.material = stump_mat

	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.24
	trunk_mesh.bottom_radius = 0.42
	trunk_mesh.height = 3.0
	trunk_mesh.material = bark_mat

	var canopy_mesh := CylinderMesh.new()
	canopy_mesh.top_radius = 0.05
	canopy_mesh.bottom_radius = 2.4
	canopy_mesh.height = 7.5
	canopy_mesh.material = needle_mat

	# Ensure trees and stumps stay strictly off the asphalt road
	var min_clearance: float = (road_width * 0.5) + 6.0 # Extra safety margin
	var baked_pts: PackedVector3Array = curve.get_baked_points()

	# Spawn tree stumps strictly on outer grassy shoulders
	for i in range(0, baked_pts.size(), 14):
		var pt: Vector3 = baked_pts[i]
		var next_idx: int = (i + 1) % baked_pts.size()
		var tangent := (baked_pts[next_idx] - pt).normalized()
		var normal := Vector3(-tangent.z, 0.0, tangent.x).normalized()
		var side: float = 1.0 if (i % 2 == 0) else -1.0
		var dist: float = min_clearance + rng.randf_range(0.8, 4.5)
		var stump_pos: Vector3 = pt + normal * (side * dist) + Vector3(0.0, 0.3, 0.0)

		# Facility clearance
		if absf(stump_pos.x) < 95.0 and stump_pos.z > 5.0 and stump_pos.z < 48.0:
			continue

		# Ensure trees and stumps stay strictly off the asphalt road
		var too_close: bool = false
		for bp in baked_pts:
			if Vector2(stump_pos.x, stump_pos.z).distance_to(Vector2(bp.x, bp.z)) < min_clearance:
				too_close = true
				break

		if too_close:
			continue # Skip spawning this tree/stump if it touches the road

		var stump := MeshInstance3D.new()
		stump.mesh = stump_mesh
		stump.global_transform = Transform3D(Basis.IDENTITY, stump_pos)
		add_child(stump)

		# Companion pine trees along the track border
		if (i / 14) % 2 == 0:
			var tree_pos: Vector3 = stump_pos + normal * (side * rng.randf_range(2.5, 5.0))
			if absf(tree_pos.x) < 95.0 and tree_pos.z > 5.0 and tree_pos.z < 48.0:
				continue

			var tree_too_close: bool = false
			for bp in baked_pts:
				if Vector2(tree_pos.x, tree_pos.z).distance_to(Vector2(bp.x, bp.z)) < min_clearance:
					tree_too_close = true
					break

			if tree_too_close:
				continue # Skip spawning this tree/stump if it touches the road
				var tree_root := Node3D.new()
				tree_root.position = tree_pos

				var trunk := MeshInstance3D.new()
				trunk.mesh = trunk_mesh
				trunk.position = Vector3(0, 1.5, 0)
				tree_root.add_child(trunk)

				var canopy := MeshInstance3D.new()
				canopy.mesh = canopy_mesh
				canopy.position = Vector3(0, 5.5, 0)
				tree_root.add_child(canopy)

				add_child(tree_root)

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
		# Place car at start straight facing +X direction down the straight
		var spawn_pos := Vector3(-70.0, 0.5, 0.0)
		var spawn_transform := Transform3D(Basis(Vector3.UP, -PI * 0.5), spawn_pos)
		car.global_transform = spawn_transform
		if "spawn_transform" in car:
			car.set("spawn_transform", spawn_transform)
