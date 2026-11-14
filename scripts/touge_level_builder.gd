class_name TougeLevelBuilder
extends Node3D

@export var road_width: float = 13.0
@export var guardrail_height: float = 0.72

var clipping_zone_scene: PackedScene = preload("res://scenes/clipping_zone.tscn")
var manga_ink_shader: Shader = preload("res://shaders/manga_ink.gdshader")
var manga_outline_shader: Shader = preload("res://shaders/manga_outline.gdshader")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_configure_environment()
	_build_touge_circuit()
	_build_touge_background_mountain()
	_spawn_rain_effects()
	_place_car_at_grid()

func _spawn_rain_effects() -> void:
	var rain_scene = load("res://scenes/rain_emitter.tscn") as PackedScene
	if rain_scene:
		var rain = rain_scene.instantiate()
		rain.name = "RainEmitter"
		add_child(rain)

func _configure_environment() -> void:
	_configure_twilight_environment()

func _build_touge_circuit() -> void:
	_build_mountain_terrain_and_bay()
	_build_stacked_switchback_pass()

func _place_car_at_grid() -> void:
	_place_car_at_summit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if get_tree() != null:
			get_tree().paused = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	elif Input.is_key_pressed(KEY_R) or (Input.is_key_pressed(KEY_ENTER) and not Engine.get_meta("is_split_screen", false)):
		get_tree().reload_current_scene()

func _configure_twilight_environment() -> void:
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

var _switchback_curve: Curve3D = null

func _get_or_create_switchback_curve() -> Curve3D:
	if _switchback_curve != null:
		return _switchback_curve
	var curve := Curve3D.new()
	curve.bake_interval = 1.5
	
	# Stacked serpentine switchbacks zig-zagging down the mountain face (Y = 84m down to 6m)
	var pts: Array[Vector3] = [
		Vector3(0, 84, 0),
		Vector3(0, 80, -75),
		Vector3(55, 74, -110),     # Switchback 1 Right Apex
		Vector3(0, 67, -140),
		Vector3(-65, 60, -165),    # Switchback 2 Left Apex
		Vector3(0, 52, -195),
		Vector3(70, 44, -225),     # Switchback 3 Right Apex
		Vector3(0, 36, -255),
		Vector3(-70, 28, -285),    # Switchback 4 Left Apex
		Vector3(10, 18, -325),
		Vector3(95, 10, -340),     # Bottom Coastal Sweeper
		Vector3(145, 22, -240),    # Outer Ridge Express Climb back to top
		Vector3(140, 48, -120),
		Vector3(110, 74, -20),
		Vector3(45, 83, 25),
		Vector3(0, 84, 0)
	]
	
	for i in range(pts.size()):
		var prev_p: Vector3 = pts[(i - 1 + pts.size()) % pts.size()]
		var next_p: Vector3 = pts[(i + 1) % pts.size()]
		var tangent: Vector3 = (next_p - prev_p) * 0.22
		curve.add_point(pts[i], -tangent, tangent)
	
	_switchback_curve = curve
	return _switchback_curve

func _build_stacked_switchback_pass() -> void:
	var path := Path3D.new()
	path.name = "TougeSwitchbacks"
	var curve := _get_or_create_switchback_curve()
	path.curve = curve
	add_child(path)
	
	var hw: float = road_width * 0.5
	
	# 1. Asphalt Road Surface (captures warm streetlamp reflections)
	_extrude_csg("RoadAsphalt", PackedVector2Array([
		Vector2(-hw, -0.6), Vector2(-hw, 0.0), Vector2(hw, 0.0), Vector2(hw, -0.6)
	]), Color(0.14, 0.15, 0.18), 0.65, true)
	
	# 2. Dark Steel Low Guardrails (Not white, never glows, doesn't block view of lower tiers)
	_extrude_csg("LeftGuardrail", PackedVector2Array([
		Vector2(-hw - 0.45, -0.6), Vector2(-hw - 0.45, guardrail_height),
		Vector2(-hw, guardrail_height), Vector2(-hw, -0.6)
	]), Color(0.24, 0.27, 0.32), 0.5, true)
	
	_extrude_csg("RightGuardrail", PackedVector2Array([
		Vector2(hw, -0.6), Vector2(hw, guardrail_height),
		Vector2(hw + 0.45, guardrail_height), Vector2(hw + 0.45, -0.6)
	]), Color(0.24, 0.27, 0.32), 0.5, true)
	
	# Retaining foundation strictly under the road width (never spills onto neighboring switchbacks!)
	_extrude_csg("MountainSlope", PackedVector2Array([
		Vector2(-hw - 0.8, -3.5),
		Vector2(-hw - 0.45, -0.35),
		Vector2(hw + 0.45, -0.35),
		Vector2(hw + 0.8, -3.5)
	]), Color(0.10, 0.13, 0.12), 0.95, false)

	_fill_platform_with_forest(curve, hw)
	_spawn_streetlamps_and_foliage(curve, hw)
	_spawn_realistic_forest_and_stumps(curve)
	_spawn_clipping_zones()

func _extrude_csg(n_name: String, poly: PackedVector2Array, col: Color, rough: float, collide: bool) -> void:
	var csg := CSGPolygon3D.new()
	csg.name = n_name
	csg.mode = CSGPolygon3D.MODE_PATH
	csg.path_node = NodePath("../TougeSwitchbacks")
	csg.path_interval_type = CSGPolygon3D.PATH_INTERVAL_DISTANCE
	csg.path_interval = 2.0
	csg.path_joined = true
	csg.use_collision = collide
	csg.polygon = poly
	
	if n_name == "RoadAsphalt":
		var wet_mat := ShaderMaterial.new()
		wet_mat.shader = load("res://shaders/wet_tarmac.gdshader")
		wet_mat.set_shader_parameter("albedo_color", Color(0.08, 0.09, 0.12))
		wet_mat.set_shader_parameter("metallic", 0.45)
		wet_mat.set_shader_parameter("roughness", 0.55)
		wet_mat.set_shader_parameter("wetness", 0.98)
		wet_mat.set_shader_parameter("normal_scale", 4.8)
		wet_mat.set_shader_parameter("ripple_speed", 2.2)
		wet_mat.set_shader_parameter("ripple_density", 28.0)
		wet_mat.set_shader_parameter("puddle_ratio", 0.45)
		csg.material = wet_mat
	else:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = col
		mat.roughness = rough
		csg.material = mat
	add_child(csg)

func _spawn_streetlamps_and_foliage(curve: Curve3D, hw: float) -> void:
	var total_len: float = curve.get_baked_length()
	var d: float = 6.0
	var tree_step: float = 5.5
	var last_lamp_dist: float = -999.0
	var lamp_idx: int = 0
	
	# Streetlamp materials
	var pole_mat := StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.18, 0.20, 0.24)
	
	var bulb_mat := StandardMaterial3D.new()
	bulb_mat.albedo_color = Color(1.0, 0.78, 0.38)
	bulb_mat.emission_enabled = true
	bulb_mat.emission = Color(1.0, 0.65, 0.22)
	bulb_mat.emission_energy_multiplier = 4.5
	
	# Shared streetlamp meshes
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.1
	pole_mesh.bottom_radius = 0.14
	pole_mesh.height = 5.8
	pole_mesh.material = pole_mat
	
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(1.2, 0.18, 0.4)
	head_mesh.material = bulb_mat

	# Manga Ink + Inverted Hull Outlines for Trees & Foliage
	var outline_mat := ShaderMaterial.new()
	outline_mat.shader = manga_outline_shader
	outline_mat.set_shader_parameter("outline_color", Color.BLACK)
	outline_mat.set_shader_parameter("outline_thickness", 0.03)
	outline_mat.render_priority = 1

	var trunk_mat := ForestUtils.create_pine_bark_material()
	trunk_mat.next_pass = outline_mat

	var pine_mat := ForestUtils.create_pine_needle_material()
	pine_mat.next_pass = outline_mat

	var bush_mat := ShaderMaterial.new()
	bush_mat.shader = manga_ink_shader
	bush_mat.next_pass = outline_mat
	bush_mat.set_shader_parameter("albedo_color", Color(0.06, 0.14, 0.09, 1.0))
	bush_mat.set_shader_parameter("enable_screentone", true)
	bush_mat.set_shader_parameter("screentone_density", 120.0)

	# Shared tree meshes
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.material = trunk_mat
	trunk_mesh.top_radius = 0.28
	trunk_mesh.bottom_radius = 0.42
	trunk_mesh.height = 2.4
	trunk_mesh.radial_segments = 8

	var tier1_mesh := CylinderMesh.new()
	tier1_mesh.material = pine_mat
	tier1_mesh.top_radius = 0.38
	tier1_mesh.bottom_radius = 2.4
	tier1_mesh.height = 2.5
	tier1_mesh.radial_segments = 8

	var tier2_mesh := CylinderMesh.new()
	tier2_mesh.material = pine_mat
	tier2_mesh.top_radius = 0.0
	tier2_mesh.bottom_radius = 1.6
	tier2_mesh.height = 2.3
	tier2_mesh.radial_segments = 8

	var bush_mesh := SphereMesh.new()
	bush_mesh.material = bush_mat
	bush_mesh.radius = 1.6
	bush_mesh.height = 2.0
	bush_mesh.radial_segments = 8
	bush_mesh.rings = 6

	var forest_node := Node3D.new()
	forest_node.name = "TougeForest"
	add_child(forest_node)

	var lamps_node := Node3D.new()
	lamps_node.name = "TougeStreetlamps"
	add_child(lamps_node)

	# Ensure trees and stumps stay strictly off the asphalt road
	var min_clearance: float = (road_width * 0.5) + 6.0 # Extra safety margin
	var baked_pts: PackedVector3Array = curve.get_baked_points()

	# 3 Depth Rows: row 1 starts outside clearance at hw + 6.2m, row 2 at hw + 11.5m, row 3 at hw + 17.5m
	var row_depths: Array[float] = [6.2, 11.5, 17.5]

	while d < total_len - 6.0:
		var xf: Transform3D = curve.sample_baked_with_rotation(d, true)
		
		# Streetlamps every 28m on alternating sides
		if d - last_lamp_dist >= 28.0:
			last_lamp_dist = d
			var lamp_side: float = 1.0 if (lamp_idx % 2 == 0) else -1.0
			_spawn_single_streetlamp(lamps_node, xf, hw, lamp_side, pole_mesh, head_mesh)
			lamp_idx += 1

		# Spawn 3 depth rows of trees on BOTH sides of the road
		for side in [-1.0, 1.0]:
			for r in range(row_depths.size()):
				var base_lat: float = hw + row_depths[r]
				var jitter_x: float = randf_range(-0.8, 1.4)
				var jitter_z: float = randf_range(-1.3, 1.3)
				var extra_dist: float = maxf(0.0, (base_lat + jitter_x) - (hw + 0.45))
				var slope_drop: float = -0.45 - (extra_dist * 0.78) + randf_range(-0.35, 0.35)
				
				var local_offset := Vector3(side * (base_lat + jitter_x), slope_drop, jitter_z)
				var tree_world_pos: Vector3 = (xf * Transform3D(Basis.IDENTITY, local_offset)).origin

				# Ensure trees and stumps stay strictly off the asphalt road
				var too_close: bool = false
				for bp in baked_pts:
					if Vector2(tree_world_pos.x, tree_world_pos.z).distance_to(Vector2(bp.x, bp.z)) < min_clearance:
						too_close = true
						break

				if too_close:
					continue # Skip spawning this tree/stump if it touches the road

				var tree_scale: float = randf_range(0.8, 1.45)
				var tree := _build_stylized_cedar_tree(trunk_mesh, tier1_mesh, tier2_mesh, tree_scale)
				tree.transform = Transform3D(xf.basis, tree_world_pos)
				forest_node.add_child(tree)
				
				# Hillside bush clusters mixed in between trees
				if randf() < 0.38:
					var bush_offset := Vector3(
						side * (base_lat + jitter_x + randf_range(-1.2, 1.6)),
						slope_drop + randf_range(-0.25, 0.25),
						jitter_z + randf_range(-1.4, 1.4)
					)
					var bush_world_pos: Vector3 = (xf * Transform3D(Basis.IDENTITY, bush_offset)).origin
					var bush_too_close: bool = false
					for bp in baked_pts:
						if Vector2(bush_world_pos.x, bush_world_pos.z).distance_to(Vector2(bp.x, bp.z)) < min_clearance:
							bush_too_close = true
							break

					if bush_too_close:
						continue # Skip spawning this tree/stump if it touches the road

					var bush_scale: float = randf_range(0.85, 1.35)
					var bush := _build_hillside_bush(bush_mesh, bush_scale)
					bush.transform = Transform3D(xf.basis, bush_world_pos)
					forest_node.add_child(bush)

		d += tree_step

func _build_stylized_cedar_tree(trunk_m: Mesh, tier1_m: Mesh, tier2_m: Mesh, scale_factor: float) -> Node3D:
	var tree := Node3D.new()
	
	var trunk := MeshInstance3D.new()
	trunk.mesh = trunk_m
	trunk.position = Vector3(0.0, 1.2, 0.0)
	tree.add_child(trunk)
	
	var t1 := MeshInstance3D.new()
	t1.mesh = tier1_m
	t1.position = Vector3(0.0, 2.5, 0.0)
	tree.add_child(t1)
	
	var t2 := MeshInstance3D.new()
	t2.mesh = tier2_m
	t2.position = Vector3(0.0, 4.0, 0.0)
	tree.add_child(t2)
	
	tree.scale = Vector3.ONE * scale_factor
	tree.rotation.y = randf_range(0.0, TAU)
	return tree

func _build_hillside_bush(bush_m: Mesh, scale_factor: float) -> Node3D:
	var bush := Node3D.new()
	var m := MeshInstance3D.new()
	m.mesh = bush_m
	m.position = Vector3(0.0, 0.8, 0.0)
	bush.add_child(m)
	bush.scale = Vector3(scale_factor * randf_range(0.9, 1.3), scale_factor * 0.75, scale_factor * randf_range(0.9, 1.3))
	bush.rotation.y = randf_range(0.0, TAU)
	return bush

func _spawn_single_streetlamp(parent: Node3D, xf: Transform3D, hw: float, side: float, pole_m: Mesh, head_m: Mesh) -> void:
	var pole := MeshInstance3D.new()
	pole.mesh = pole_m
	pole.global_transform = xf * Transform3D(Basis.IDENTITY, Vector3(side * (hw + 0.6), 2.9, 0))
	parent.add_child(pole)
	
	var head := MeshInstance3D.new()
	head.mesh = head_m
	head.global_transform = xf * Transform3D(Basis.IDENTITY, Vector3(side * (hw - 0.2), 5.7, 0))
	parent.add_child(head)
	
	var omni := OmniLight3D.new()
	omni.light_color = Color(1.0, 0.68, 0.28)
	omni.light_energy = 2.6
	omni.omni_range = 26.0
	omni.omni_attenuation = 1.3
	omni.light_volumetric_fog_energy = 2.2
	omni.shadow_enabled = true
	omni.global_transform = xf * Transform3D(Basis.IDENTITY, Vector3(side * (hw - 1.0), 5.2, 0))
	parent.add_child(omni)

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

	# Spawn tree stumps and companion pines strictly on outer grassy shoulders
	for i in range(0, baked_pts.size(), 14):
		var pt: Vector3 = baked_pts[i]
		var next_idx: int = (i + 1) % baked_pts.size()
		var tangent := (baked_pts[next_idx] - pt).normalized()
		var normal := Vector3(-tangent.z, 0.0, tangent.x).normalized()
		var side: float = 1.0 if (i % 2 == 0) else -1.0
		var dist: float = min_clearance + rng.randf_range(0.8, 4.5)
		var stump_pos: Vector3 = pt + normal * (side * dist) + Vector3(0.0, 0.3, 0.0)

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

func _build_mountain_terrain_and_bay() -> void:
	var land_mat := StandardMaterial3D.new()
	land_mat.albedo_color = Color(0.05, 0.11, 0.08)
	land_mat.roughness = 0.95
	land_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON

	# Solid Ground Platform at Y = -2.0 (well below the lowest Y = 10.0 road tier, no central cylinder blocking the track)
	var platform_body := StaticBody3D.new()
	platform_body.name = "WorldGroundPlatform"
	platform_body.position = Vector3(0.0, -22.0, -150.0)
	add_child(platform_body)

	var platform_mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1800.0, 40.0, 1800.0)
	platform_mesh.mesh = box
	platform_mesh.material_override = land_mat
	platform_body.add_child(platform_mesh)

	var platform_col := CollisionShape3D.new()
	var col_shape := BoxShape3D.new()
	col_shape.size = Vector3(1800.0, 40.0, 1800.0)
	platform_col.shape = col_shape
	platform_body.add_child(platform_col)

func _build_touge_background_mountain() -> void:
	var ridge_root := Node3D.new()
	ridge_root.name = "TougeBackgroundRidge"
	ridge_root.position = Vector3(0.0, -40.0, -600.0) # Far back in deep distance (Z <= -500.0), well clear of the track
	add_child(ridge_root)

	# Massive Background Mountain Wall (safely in the distance, no crest/snowcap mesh)
	var mountain_wall := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1600.0, 220.0, 80.0)
	mountain_wall.mesh = box

	var mountain_mat := StandardMaterial3D.new()
	mountain_mat.albedo_color = Color(0.10, 0.12, 0.17) # Dark twilight rock
	mountain_mat.roughness = 0.95
	mountain_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mountain_wall.material_override = mountain_mat
	ridge_root.add_child(mountain_wall)

func _fill_platform_with_forest(curve: Curve3D, hw: float) -> void:
	var tree_count: int = 2500
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242

	var trunk_mat := ForestUtils.create_pine_bark_material()
	var canopy_mat := ForestUtils.create_pine_needle_material()

	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.25
	trunk_mesh.bottom_radius = 0.4
	trunk_mesh.height = 3.0
	trunk_mesh.material = trunk_mat

	var canopy_mesh := CylinderMesh.new()
	canopy_mesh.top_radius = 0.05
	canopy_mesh.bottom_radius = 2.8
	canopy_mesh.height = 8.5
	canopy_mesh.material = canopy_mat

	var mm_trunks := MultiMeshInstance3D.new()
	mm_trunks.name = "PlatformForestTrunks"
	mm_trunks.multimesh = MultiMesh.new()
	mm_trunks.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	mm_trunks.multimesh.mesh = trunk_mesh
	add_child(mm_trunks)

	var mm_canopies := MultiMeshInstance3D.new()
	mm_canopies.name = "PlatformForestCanopies"
	mm_canopies.multimesh = MultiMesh.new()
	mm_canopies.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	mm_canopies.multimesh.mesh = canopy_mesh
	add_child(mm_canopies)

	# 3D Tree Stumps scattered on platform and along track margins
	var stump_count: int = 400
	var stump_mesh := ForestUtils.create_tree_stump_mesh()
	var mm_stumps := MultiMeshInstance3D.new()
	mm_stumps.name = "PlatformForestStumps"
	mm_stumps.multimesh = MultiMesh.new()
	mm_stumps.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	mm_stumps.multimesh.mesh = stump_mesh
	add_child(mm_stumps)

	var baked_pts: PackedVector3Array = curve.get_baked_points()
	# Ensure trees and stumps stay strictly off the asphalt road
	var min_clearance: float = (road_width * 0.5) + 6.0 # Extra safety margin

	var trunk_transforms: Array[Transform3D] = []
	var canopy_transforms: Array[Transform3D] = []
	var attempts: int = 0
	while trunk_transforms.size() < tree_count and attempts < tree_count * 5:
		attempts += 1
		var px: float = rng.randf_range(-380.0, 380.0)
		var pz: float = rng.randf_range(-520.0, 180.0)

		# Ensure trees and stumps stay strictly off the asphalt road
		var too_close: bool = false
		for bp in baked_pts:
			if Vector2(px, pz).distance_to(Vector2(bp.x, bp.z)) < min_clearance:
				too_close = true
				break

		if too_close:
			continue # Skip spawning this tree/stump if it touches the road

		var ground_y: float = -2.0
		var s: float = rng.randf_range(0.95, 1.85)
		var basis_scaled := Basis.IDENTITY.scaled(Vector3(s, s, s))

		trunk_transforms.append(Transform3D(basis_scaled, Vector3(px, ground_y + 1.5 * s, pz)))
		canopy_transforms.append(Transform3D(basis_scaled, Vector3(px, ground_y + 6.2 * s, pz)))

	mm_trunks.multimesh.instance_count = trunk_transforms.size()
	for i in range(trunk_transforms.size()):
		mm_trunks.multimesh.set_instance_transform(i, trunk_transforms[i])

	mm_canopies.multimesh.instance_count = canopy_transforms.size()
	for i in range(canopy_transforms.size()):
		mm_canopies.multimesh.set_instance_transform(i, canopy_transforms[i])

	# Scatter stumps across platform and along track margins
	var stump_transforms: Array[Transform3D] = []
	var stump_attempts: int = 0
	while stump_transforms.size() < stump_count and stump_attempts < stump_count * 6:
		stump_attempts += 1
		var spx: float = rng.randf_range(-370.0, 370.0)
		var spz: float = rng.randf_range(-510.0, 170.0)

		# Ensure trees and stumps stay strictly off the asphalt road
		var stump_too_close: bool = false
		for bp in baked_pts:
			if Vector2(spx, spz).distance_to(Vector2(bp.x, bp.z)) < min_clearance:
				stump_too_close = true
				break

		if stump_too_close:
			continue # Skip spawning this tree/stump if it touches the road

		var ground_y: float = -2.0
		var ss: float = rng.randf_range(0.85, 1.45)
		var srot: float = rng.randf_range(0.0, TAU)
		var sbasis := Basis(Vector3.UP, srot).scaled(Vector3(ss, ss, ss))
		stump_transforms.append(Transform3D(sbasis, Vector3(spx, ground_y + 0.42 * ss, spz)))

	mm_stumps.multimesh.instance_count = stump_transforms.size()
	for i in range(stump_transforms.size()):
		mm_stumps.multimesh.set_instance_transform(i, stump_transforms[i])

func _spawn_clipping_zones() -> void:
	if clipping_zone_scene == null:
		return
	var apexes = [
		{"name": "HAIRPIN 1", "pos": Vector3(50, 74.2, -110)},
		{"name": "HAIRPIN 2", "pos": Vector3(-60, 60.2, -165)},
		{"name": "HAIRPIN 3", "pos": Vector3(65, 44.2, -225)},
		{"name": "HAIRPIN 4", "pos": Vector3(-65, 28.2, -285)},
		{"name": "COASTAL APEX", "pos": Vector3(90, 10.2, -340)}
	]
	var clip_node := Node3D.new()
	clip_node.name = "ClippingZones"
	add_child(clip_node)
	for a in apexes:
		var zone = clipping_zone_scene.instantiate()
		zone.position = a["pos"]
		zone.set("zone_name", a["name"])
		clip_node.add_child(zone)

func _place_car_at_summit() -> void:
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
		car.global_transform = Transform3D(Basis.IDENTITY, Vector3(0, 85.5, -5.0))
		if "spawn_transform" in car:
			car.set("spawn_transform", car.global_transform)
		if car is RigidBody3D:
			car.linear_velocity = Vector3.ZERO
			car.angular_velocity = Vector3.ZERO
