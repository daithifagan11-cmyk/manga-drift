extends Node

signal speed_upgraded(new_tier: int, new_max_speed_kmh: float)

const SPEED_TIERS_KMH: Array[float] = [60.0, 70.0, 80.0]
const UPGRADE_COSTS: Array[int] = [50, 100]

var speed_tier: int = 0
var save_path: String = "user://car_upgrades.save"

func _ready() -> void:
	load_upgrades()

func get_max_speed_kmh() -> float:
	var idx: int = clampi(speed_tier, 0, SPEED_TIERS_KMH.size() - 1)
	return SPEED_TIERS_KMH[idx]

func is_max_speed_tier() -> bool:
	return speed_tier >= UPGRADE_COSTS.size()

func get_next_upgrade_cost() -> int:
	if is_max_speed_tier():
		return -1
	return UPGRADE_COSTS[speed_tier]

func try_buy_speed_upgrade() -> bool:
	if is_max_speed_tier():
		return false
	var cost: int = UPGRADE_COSTS[speed_tier]
	if CoinManager.player_money < cost:
		return false
	if not CoinManager.spend_money(cost):
		return false
	speed_tier += 1
	save_upgrades()
	var new_speed: float = get_max_speed_kmh()
	print("SPEED UPGRADED! Tier %d (Max Speed: %.0f KM/H)" % [speed_tier, new_speed])
	speed_upgraded.emit(speed_tier, new_speed)
	return true

func save_upgrades() -> void:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file != null:
		file.store_64(speed_tier)
		file.close()

func load_upgrades() -> void:
	if FileAccess.file_exists(save_path):
		var file := FileAccess.open(save_path, FileAccess.READ)
		if file != null:
			speed_tier = clampi(int(file.get_64()), 0, UPGRADE_COSTS.size())
			file.close()
