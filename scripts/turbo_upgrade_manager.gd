extends Node

signal turbo_upgraded(new_stage: int, boost_kmh: float)

const TURBO_NAMES: Array[String] = [
	"NONE (NA)",
	"STAGE 1 // SMALL TURBO",
	"STAGE 2 // MEDIUM TURBO",
	"STAGE 3 // BIG TWIN-TURBO"
]
const TURBO_BOOST_KMH: Array[float] = [0.0, 10.0, 20.0, 30.0]
const TURBO_COSTS: Array[int] = [60, 120, 250]

var turbo_stage: int = 0
var save_path: String = "user://turbo_upgrades.save"

func _ready() -> void:
	load_upgrades()

func get_speed_boost_kmh() -> float:
	var idx: int = clampi(turbo_stage, 0, TURBO_BOOST_KMH.size() - 1)
	return TURBO_BOOST_KMH[idx]

func get_stage_name(stage: int = -1) -> String:
	var idx: int = turbo_stage if stage < 0 else stage
	idx = clampi(idx, 0, TURBO_NAMES.size() - 1)
	return TURBO_NAMES[idx]

func is_max_turbo_stage() -> bool:
	return turbo_stage >= TURBO_COSTS.size()

func get_next_upgrade_cost() -> int:
	if is_max_turbo_stage():
		return -1
	return TURBO_COSTS[turbo_stage]

func try_buy_turbo_upgrade() -> bool:
	if is_max_turbo_stage():
		return false
	var cost: int = TURBO_COSTS[turbo_stage]
	if CoinManager.player_money < cost:
		return false
	if not CoinManager.spend_money(cost):
		return false
	turbo_stage += 1
	save_upgrades()
	var boost: float = get_speed_boost_kmh()
	print("TURBO UPGRADED! %s (+%.0f KM/H)" % [get_stage_name(), boost])
	turbo_upgraded.emit(turbo_stage, boost)
	return true

func save_upgrades() -> void:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file != null:
		file.store_64(turbo_stage)
		file.close()

func load_upgrades() -> void:
	if FileAccess.file_exists(save_path):
		var file := FileAccess.open(save_path, FileAccess.READ)
		if file != null:
			turbo_stage = clampi(int(file.get_64()), 0, TURBO_COSTS.size())
			file.close()
