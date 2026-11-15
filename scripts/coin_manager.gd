extends Node

signal money_changed(new_amount: int)

const SAVE_PATH: String = "user://player_wallet.save"
const COIN_SCENE_PATH: String = "res://scenes/coin_pickup.tscn"
const MAX_ACTIVE_SFX_PLAYERS: int = 8

var player_money: int = 0
var _coin_scene: PackedScene
var _coin_sfx_stream: AudioStreamWAV

func _ready() -> void:
	load_wallet()
	_coin_sfx_stream = _create_coin_pickup_sound()

func add_money(amount: int) -> void:
	if amount <= 0:
		return
	player_money += amount
	save_wallet()
	money_changed.emit(player_money)

func spend_money(amount: int) -> bool:
	if amount <= 0 or player_money < amount:
		return false
	player_money -= amount
	save_wallet()
	money_changed.emit(player_money)
	return true

func save_wallet() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_64(player_money)
		file.close()

func load_wallet() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file != null:
			player_money = int(file.get_64())
			file.close()

func play_coin_pickup_sfx() -> void:
	if _coin_sfx_stream == null or not is_inside_tree():
		return
	if get_child_count() >= MAX_ACTIVE_SFX_PLAYERS:
		return
	var sfx := AudioStreamPlayer.new()
	sfx.stream = _coin_sfx_stream
	sfx.pitch_scale = randf_range(0.96, 1.04)
	sfx.volume_db = -4.0
	sfx.finished.connect(sfx.queue_free)
	add_child(sfx)
	sfx.play()

func spawn_coins_along_curve(parent: Node3D, curve: Curve3D, step: float = 28.0, start_offset: float = 20.0, y_offset: float = 0.0, min_spacing: float = 5.0) -> int:
	if parent == null or curve == null:
		return 0
	var container := _get_or_create_coins_container(parent)
	var total_len: float = curve.get_baked_length()
	var spawned: int = 0
	var d: float = start_offset
	while d < total_len - 16.0:
		var pos: Vector3 = curve.sample_baked(d) + Vector3(0.0, y_offset, 0.0)
		if _spawn_coin_if_clear(container, pos, min_spacing):
			spawned += 1
		d += step
	return spawned

func spawn_coin_points(parent: Node3D, points: Array[Vector3], y_offset: float = 0.0, min_spacing: float = 3.5) -> int:
	if parent == null:
		return 0
	var container := _get_or_create_coins_container(parent)
	var spawned: int = 0
	for pt in points:
		if _spawn_coin_if_clear(container, pt + Vector3(0.0, y_offset, 0.0), min_spacing):
			spawned += 1
	return spawned

func _get_or_create_coins_container(parent: Node3D) -> Node3D:
	var container := parent.get_node_or_null("Coins") as Node3D
	if container == null:
		container = Node3D.new()
		container.name = "Coins"
		parent.add_child(container)
	return container

func _spawn_coin_if_clear(container: Node3D, world_pos: Vector3, min_spacing: float) -> bool:
	if _coin_scene == null and ResourceLoader.exists(COIN_SCENE_PATH):
		_coin_scene = load(COIN_SCENE_PATH) as PackedScene
	if _coin_scene == null:
		return false
	for existing in container.get_children():
		if existing is Node3D and existing.position.distance_to(world_pos) < min_spacing:
			return false
	var coin := _coin_scene.instantiate() as Node3D
	if coin == null:
		return false
	coin.position = world_pos
	container.add_child(coin)
	return true

func _create_coin_pickup_sound() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.22
	var num_samples: int = int(sample_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(num_samples * 2)
	for i in range(num_samples):
		var t: float = float(i) / float(sample_rate)
		var freq: float = 987.77 if t < 0.065 else 1318.51 # B5 -> E6 arcade coin chime
		var attack: float = minf(t / 0.008, 1.0)
		var decay: float = exp(-t * 14.0)
		var wave: float = (sin(t * freq * TAU) * 0.75 + sin(t * freq * 2.0 * TAU) * 0.25)
		var sample_val: int = int(clampf(wave * attack * decay * 0.85, -1.0, 1.0) * 32767.0)
		byte_array.encode_s16(i * 2, sample_val)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = byte_array
	return wav
