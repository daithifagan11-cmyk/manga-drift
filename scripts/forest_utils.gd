class_name ForestUtils

static func create_pine_bark_material() -> StandardMaterial3D:
	var bark_mat := StandardMaterial3D.new()
	bark_mat.albedo_color = Color(0.15, 0.11, 0.08)
	bark_mat.roughness = 0.95
	bark_mat.normal_enabled = true
	bark_mat.normal_scale = 3.5

	var bark_noise := NoiseTexture2D.new()
	bark_noise.as_normal_map = true
	bark_noise.bump_strength = 10.0
	bark_noise.width = 128
	bark_noise.height = 256
	var fnl := FastNoiseLite.new()
	fnl.noise_type = FastNoiseLite.TYPE_SIMPLEX
	fnl.frequency = 0.035
	fnl.fractal_octaves = 4
	bark_noise.noise = fnl

	bark_mat.normal_texture = bark_noise
	bark_mat.uv1_scale = Vector3(1.0, 4.0, 1.0)
	return bark_mat

static func create_pine_needle_material() -> StandardMaterial3D:
	var pine_mat := StandardMaterial3D.new()
	pine_mat.albedo_color = Color(0.05, 0.15, 0.08)
	pine_mat.roughness = 0.85
	pine_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
	pine_mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	pine_mat.subsurf_scatter_enabled = true
	pine_mat.subsurf_scatter_strength = 0.25
	pine_mat.subsurf_scatter_transmittance_enabled = true
	pine_mat.subsurf_scatter_transmittance_color = Color(0.08, 0.25, 0.10)
	return pine_mat

static func create_stump_rings_material() -> StandardMaterial3D:
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.36, 0.26, 0.18)
	ring_mat.roughness = 0.88

	var grad_tex := GradientTexture2D.new()
	grad_tex.width = 128
	grad_tex.height = 128
	grad_tex.fill = GradientTexture2D.FILL_RADIAL
	grad_tex.fill_from = Vector2(0.5, 0.5)
	grad_tex.fill_to = Vector2(0.5, 0.0)
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.18, 0.38, 0.62, 0.82, 1.0])
	grad.colors = PackedColorArray([
		Color(0.25, 0.16, 0.10),
		Color(0.42, 0.30, 0.20),
		Color(0.28, 0.18, 0.12),
		Color(0.44, 0.32, 0.22),
		Color(0.26, 0.17, 0.11),
		Color(0.38, 0.28, 0.18)
	])
	grad_tex.gradient = grad
	ring_mat.albedo_texture = grad_tex
	return ring_mat

static func create_tree_stump_mesh(bark_mat: Material = null, ring_mat: Material = null) -> ArrayMesh:
	if bark_mat == null:
		bark_mat = create_pine_bark_material()
	if ring_mat == null:
		ring_mat = create_stump_rings_material()

	var st_bark := SurfaceTool.new()
	var cyl_bark := CylinderMesh.new()
	cyl_bark.top_radius = 0.42
	cyl_bark.bottom_radius = 0.58
	cyl_bark.height = 0.85
	cyl_bark.cap_top = false
	cyl_bark.cap_bottom = false
	cyl_bark.radial_segments = 12
	st_bark.append_from(cyl_bark, 0, Transform3D.IDENTITY)

	# Outward-protruding root spurs / branch stubs at base
	var angles = [0.35, 2.25, 4.35]
	for a in angles:
		var stub := CylinderMesh.new()
		stub.top_radius = 0.08
		stub.bottom_radius = 0.18
		stub.height = 0.55
		stub.radial_segments = 6
		var b := Basis(Vector3.UP, a) * Basis(Vector3.FORWARD, deg_to_rad(45.0))
		var offset := Vector3(cos(a) * 0.48, -0.22, sin(a) * 0.48)
		st_bark.append_from(stub, 0, Transform3D(b, offset))

	# Mid-trunk broken branch stub pointing out from side
	var mid_stub := CylinderMesh.new()
	mid_stub.top_radius = 0.06
	mid_stub.bottom_radius = 0.12
	mid_stub.height = 0.42
	mid_stub.radial_segments = 6
	var b_mid := Basis(Vector3.UP, 1.4) * Basis(Vector3.RIGHT, deg_to_rad(55.0))
	st_bark.append_from(mid_stub, 0, Transform3D(b_mid, Vector3(0.12, 0.15, -0.42)))

	var bark_mesh := st_bark.commit()

	# Top disc cap for textured wood rings
	var st_cap := SurfaceTool.new()
	var cap_disc := CylinderMesh.new()
	cap_disc.top_radius = 0.42
	cap_disc.bottom_radius = 0.42
	cap_disc.height = 0.02
	cap_disc.radial_segments = 12
	st_cap.append_from(cap_disc, 0, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.425, 0.0)))

	var final_mesh := st_cap.commit(bark_mesh)
	final_mesh.surface_set_material(0, bark_mat)
	final_mesh.surface_set_material(1, ring_mat)
	return final_mesh
