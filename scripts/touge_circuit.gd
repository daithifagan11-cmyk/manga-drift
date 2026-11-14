extends Node3D
class_name TougeCircuit

@export var road_width: float = 12.0
@export var sample_step: float = 1.8

var cedar_tree_scene: PackedScene = preload("res://scenes/cedar_tree.tscn")
var streetlamp_scene: PackedScene = preload("res://scenes/touge_streetlamp.tscn")
var clipping_zone_scene: PackedScene = preload("res://scenes/clipping_zone.tscn")

var manga_ink_shader: Shader = preload("res://shaders/manga_ink.gdshader")
var manga_outline_shader: Shader = preload("res://shaders/manga_outline.gdshader")

var path_3d: Path3D
var curve: Curve3D

# Apex distances for Hairpins 1, 2, and 3
var hairpin_apexes: Array[float] = []

func _ready() -> void:
	_setup_spline_curve()
	_generate_circuit_meshes()
	_generate_scenery_and_props()
	_spawn_car_at_start_line()

func _setup_spline_curve() -> void:
	path_3d = Path3D.new()
	path_3d.name = "TougePath"
	add_child(path_3d)
	
	curve = Curve3D.new()
	curve.bake_interval = 1.0
	
	# Handcrafted 3D Touge Mountain Pass Loop with 3 wide hairpins & elevation changes
	# Point 0: Start Straight (Elev: 0m)
	curve.add_point(Vector3(0, 0, 0), Vector3(0, 0, 20), Vector3(0, 0, -35))
	# Point 1: Downhill straight (Elev: -2m)
	curve.add_point(Vector3(0, -2, -80), Vector3(0, 1, 25), Vector3(0, -1, -30))
	# Point 2: S-curve Right (Elev: -6m)
	curve.add_point(Vector3(35, -6, -140), Vector3(-20, 0, 25), Vector3(20, 0, -25))
	# Point 3: S-curve Left into Hairpin 1 approach (Elev: -10m)
	curve.add_point(Vector3(-10, -10, -200), Vector3(25, 0, 25), Vector3(-25, 0, -25))
	
	# Hairpin 1: Wide Downhill Hairpin Right (Elev: -14m)
	curve.add_point(Vector3(20, -13, -270), Vector3(-30, 0, 15), Vector3(30, 0, -15))
	curve.add_point(Vector3(80, -14, -280), Vector3(-25, 0, -25), Vector3(25, 0, 25)) # Apex 1
	curve.add_point(Vector3(120, -11, -220), Vector3(-10, -1, -30), Vector3(10, 1, 30))
	
	# Climbing Switchback Straight (Elev: -11m -> +2m)
	curve.add_point(Vector3(140, -4, -130), Vector3(-10, -2, -35), Vector3(10, 2, 35))
	curve.add_point(Vector3(110, 3, -40), Vector3(20, -2, -30), Vector3(-20, 2, 30))
	
	# Hairpin 2: Wide Uphill Hairpin Left (Elev: +8m -> +12m mountain peak!)
	curve.add_point(Vector3(135, 9, 40), Vector3(-15, -1, -30), Vector3(15, 1, 30))
	curve.add_point(Vector3(175, 12, 95), Vector3(-10, -1, -25), Vector3(10, 1, 25)) # Apex 2
	curve.add_point(Vector3(130, 10, 150), Vector3(25, 1, -15), Vector3(-25, -1, 15))
	
	# Mountain Ridge Crest Chicanes (Elev: +10m -> +3m)
	curve.add_point(Vector3(50, 7, 160), Vector3(35, 1, 5), Vector3(-35, -1, -5))
	curve.add_point(Vector3(-30, 4, 130), Vector3(30, 1, 15), Vector3(-30, -1, -15))
	
	# Hairpin 3: Sweeping Downhill Hairpin Right (Elev: +2m -> -1m)
	curve.add_point(Vector3(-105, 1, 65), Vector3(15, 1, 30), Vector3(-15, -1, -30))
	curve.add_point(Vector3(-130, -1, 0), Vector3(5, 1, 30), Vector3(-5, -1, -30)) # Apex 3
	curve.add_point(Vector3(-85, 0, -45), Vector3(-25, 0, 20), Vector3(25, 0, -20))
	
	# Return back to starting line
	curve.add_point(Vector3(-30, 0, -25), Vector3(-25, 0, -10), Vector3(25, 0, 10))
	curve.add_point(Vector3(0, 0, 0), Vector3(-15, 0, -10), Vector3(0, 0, -25))
	
	path_3d.curve = curve

func _generate_circuit_meshes() -> void:
	var total_length = curve.get_baked_length()
	var steps = int(total_length / sample_step)
	
	# Materials
	var outline_mat = ShaderMaterial.new()
	outline_mat.shader = manga_outline_shader
	outline_mat.set_shader_parameter("outline_thickness", 0.025)
	outline_mat.set_shader_parameter("outline_color", Color.BLACK)
	outline_mat.render_priority = 1
	
	var road_mat = ShaderMaterial.new()
	road_mat.shader = manga_ink_shader
	road_mat.set_shader_parameter("albedo_color", Color(0.094, 0.102, 0.122, 1.0)) # #181a1f dark charcoal
	road_mat.set_shader_parameter("enable_screentone", true)
	road_mat.set_shader_parameter("screentone_density", 150.0)
	road_mat.set_shader_parameter("specular_strength", 0.25)
	
	var guardrail_mat = ShaderMaterial.new()
	guardrail_mat.shader = manga_ink_shader
	guardrail_mat.next_pass = outline_mat
	guardrail_mat.set_shader_parameter("albedo_color", Color(0.78, 0.8, 0.84, 1.0)) # steel W-beam
	guardrail_mat.set_shader_parameter("enable_screentone", false)
	guardrail_mat.set_shader_parameter("specular_strength", 0.6)
	
	var curb_red_mat = ShaderMaterial.new()
	curb_red_mat.shader = manga_ink_shader
	curb_red_mat.next_pass = outline_mat
	curb_red_mat.set_shader_parameter("albedo_color", Color(0.85, 0.12, 0.12, 1.0))
	
	var curb_white_mat = ShaderMaterial.new()
	curb_white_mat.shader = manga_ink_shader
	curb_white_mat.next_pass = outline_mat
	curb_white_mat.set_shader_parameter("albedo_color", Color(0.96, 0.96, 0.96, 1.0))
	
	# Identify apex locations along curve for Hairpin 1, 2, and 3
	hairpin_apexes = [
		total_length * 0.29, # Hairpin 1 apex (~280m)
		total_length * 0.58, # Hairpin 2 apex (~550m)
		total_length * 0.86  # Hairpin 3 apex (~820m)
	]
	
	# 1. Road Surface Mesh (Surfaces and Trimesh Collision)
	var st_road = SurfaceTool.new()
	st_road.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_road.set_material(road_mat)
	
	# 2. Guardrails (Left and Right)
	var st_rails = SurfaceTool.new()
	st_rails.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_rails.set_material(guardrail_mat)
	
	# 3. Corner Rumble Curbs
	var st_curbs = SurfaceTool.new()
	st_curbs.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_curbs.set_material(curb_red_mat)
	
	var half_w = road_width * 0.5
	var rail_offset = half_w + 0.5
	var rail_height = 0.95
	
	for i in range(steps):
		var d0 = float(i) * sample_step
		var d1 = minf(float(i + 1) * sample_step, total_length)
		
		var t0 = curve.sample_baked_with_rotation(d0)
		var t1 = curve.sample_baked_with_rotation(d1)
		
		var l0 = t0.origin - t0.basis.x * half_w
		var r0 = t0.origin + t0.basis.x * half_w
		var l1 = t1.origin - t1.basis.x * half_w
		var r1 = t1.origin + t1.basis.x * half_w
		
		var n0 = t0.basis.y
		var n1 = t1.basis.y
		
		# Road Quad (2 triangles)
		st_road.set_normal(n0); st_road.set_uv(Vector2(0, d0 * 0.1)); st_road.add_vertex(l0)
		st_road.set_normal(n1); st_road.set_uv(Vector2(0, d1 * 0.1)); st_road.add_vertex(l1)
		st_road.set_normal(n0); st_road.set_uv(Vector2(1, d0 * 0.1)); st_road.add_vertex(r0)
		
		st_road.set_normal(n0); st_road.set_uv(Vector2(1, d0 * 0.1)); st_road.add_vertex(r0)
		st_road.set_normal(n1); st_road.set_uv(Vector2(0, d1 * 0.1)); st_road.add_vertex(l1)
		st_road.set_normal(n1); st_road.set_uv(Vector2(1, d1 * 0.1)); st_road.add_vertex(r1)
		
		# Left Guardrail
		var gl0_b = t0.origin - t0.basis.x * rail_offset
		var gl0_t = gl0_b + t0.basis.y * rail_height
		var gl1_b = t1.origin - t1.basis.x * rail_offset
		var gl1_t = gl1_b + t1.basis.y * rail_height
		
		var gn_left = t0.basis.x
		st_rails.set_normal(gn_left); st_rails.add_vertex(gl0_b)
		st_rails.set_normal(gn_left); st_rails.add_vertex(gl0_t)
		st_rails.set_normal(gn_left); st_rails.add_vertex(gl1_b)
		
		st_rails.set_normal(gn_left); st_rails.add_vertex(gl1_b)
		st_rails.set_normal(gn_left); st_rails.add_vertex(gl0_t)
		st_rails.set_normal(gn_left); st_rails.add_vertex(gl1_t)
		
		# Right Guardrail
		var gr0_b = t0.origin + t0.basis.x * rail_offset
		var gr0_t = gr0_b + t0.basis.y * rail_height
		var gr1_b = t1.origin + t1.basis.x * rail_offset
		var gr1_t = gr1_b + t1.basis.y * rail_height
		
		var gn_right = -t0.basis.x
		st_rails.set_normal(gn_right); st_rails.add_vertex(gr0_b)
		st_rails.set_normal(gn_right); st_rails.add_vertex(gr1_b)
		st_rails.set_normal(gn_right); st_rails.add_vertex(gr0_t)
		
		st_rails.set_normal(gn_right); st_rails.add_vertex(gr0_t)
		st_rails.set_normal(gn_right); st_rails.add_vertex(gr1_b)
		st_rails.set_normal(gn_right); st_rails.add_vertex(gr1_t)
		
		# Check if within 25m of any hairpin apex for rumble curbs
		var near_apex = false
		for apex_d in hairpin_apexes:
			if absf(d0 - apex_d) < 26.0:
				near_apex = true
				break
				
		if near_apex:
			# Raised rumble curb along inner edge
			var curb_w = 1.0
			var curb_h = 0.14
			var c0_inner = t0.origin - t0.basis.x * half_w
			var c0_outer = c0_inner + t0.basis.x * curb_w + t0.basis.y * curb_h
			var c1_inner = t1.origin - t1.basis.x * half_w
			var c1_outer = c1_inner + t1.basis.x * curb_w + t1.basis.y * curb_h
			
			st_curbs.set_normal(n0); st_curbs.add_vertex(c0_inner)
			st_curbs.set_normal(n1); st_curbs.add_vertex(c1_inner)
			st_curbs.set_normal(n0); st_curbs.add_vertex(c0_outer)
			
			st_curbs.set_normal(n0); st_curbs.add_vertex(c0_outer)
			st_curbs.set_normal(n1); st_curbs.add_vertex(c1_inner)
			st_curbs.set_normal(n1); st_curbs.add_vertex(c1_outer)
	
	# Commit road mesh & collision
	var road_mesh = st_road.commit()
	var road_mesh_inst = MeshInstance3D.new()
	road_mesh_inst.mesh = road_mesh
	road_mesh_inst.name = "RoadMesh"
	add_child(road_mesh_inst)
	road_mesh_inst.create_trimesh_collision()
	
	# Commit guardrail mesh & collision
	var rails_mesh = st_rails.commit()
	var rails_mesh_inst = MeshInstance3D.new()
	rails_mesh_inst.mesh = rails_mesh
	rails_mesh_inst.name = "GuardrailsMesh"
	add_child(rails_mesh_inst)
	rails_mesh_inst.create_trimesh_collision()
	
	# Commit curbs mesh
	var curbs_mesh = st_curbs.commit()
	var curbs_mesh_inst = MeshInstance3D.new()
	curbs_mesh_inst.mesh = curbs_mesh
	curbs_mesh_inst.name = "CurbsMesh"
	add_child(curbs_mesh_inst)

func _generate_scenery_and_props() -> void:
	var total_length = curve.get_baked_length()
	
	# 1. Low-poly Manga Cedar Trees every 15 meters
	var tree_step = 15.0
	var tree_count = int(total_length / tree_step)
	var trees_parent = Node3D.new()
	trees_parent.name = "CedarTrees"
	add_child(trees_parent)
	
	for i in range(tree_count):
		var d = float(i) * tree_step
		var t = curve.sample_baked_with_rotation(d)
		
		# Alternate left and right side with natural jitter
		var side = -1.0 if (i % 2 == 0) else 1.0
		var lateral_dist = (road_width * 0.5) + randf_range(4.5, 12.0)
		var tree_pos = t.origin + (t.basis.x * side * lateral_dist) + Vector3(0, randf_range(-0.5, 1.0), 0)
		
		var tree = cedar_tree_scene.instantiate() as Node3D
		tree.position = tree_pos
		tree.scale = Vector3.ONE * randf_range(0.85, 1.3)
		tree.rotation.y = randf_range(0.0, TAU)
		trees_parent.add_child(tree)
		
	# 2. Overhead Japanese Touge Streetlamps every 35 meters
	var lamp_step = 35.0
	var lamp_count = int(total_length / lamp_step)
	var lamps_parent = Node3D.new()
	lamps_parent.name = "Streetlamps"
	add_child(lamps_parent)
	
	for i in range(lamp_count):
		var d = float(i) * lamp_step + 10.0
		if d >= total_length - 10.0:
			continue
		var t = curve.sample_baked_with_rotation(d)
		
		# Place lamp post just outside the right guardrail, overhang facing toward road
		var lamp_pos = t.origin + (t.basis.x * (road_width * 0.5 + 1.2))
		var lamp = streetlamp_scene.instantiate() as Node3D
		lamp.transform = t
		lamp.position = lamp_pos
		# Rotate so overhang arm points inward across the road
		lamp.rotate_object_local(Vector3.UP, PI)
		lamps_parent.add_child(lamp)
		
	# 3. 3 Glowing Neon Manga "CLIPPING ZONE" ground pads at Hairpin apexes
	var clip_parent = Node3D.new()
	clip_parent.name = "ClippingZones"
	add_child(clip_parent)
	
	for idx in range(hairpin_apexes.size()):
		var apex_d = hairpin_apexes[idx]
		var t = curve.sample_baked_with_rotation(apex_d)
		
		# Inner apex pad position (slightly inside the inner curb)
		var pad_pos = t.origin - (t.basis.x * (road_width * 0.5 - 2.2)) + Vector3(0, 0.08, 0)
		var zone = clipping_zone_scene.instantiate() as ClippingZone
		zone.position = pad_pos
		zone.zone_name = "APEX %d" % (idx + 1)
		clip_parent.add_child(zone)

func _spawn_car_at_start_line() -> void:
	# Find DriftCar in scene or parent
	var car = get_parent().get_node_or_null("DriftCar") as DriftCar
	if car == null:
		car = get_node_or_null("DriftCar") as DriftCar
	if car == null:
		return
		
	# Position car cleanly on start line (at 12m along track) facing along path tangent
	var start_d = 12.0
	var t = curve.sample_baked_with_rotation(start_d)
	
	car.global_position = t.origin + Vector3(0, 0.65, 0)
	# Align car heading along tangent (-Z in Godot)
	car.global_transform.basis = t.basis
	car.linear_velocity = Vector3.ZERO
	car.angular_velocity = Vector3.ZERO
