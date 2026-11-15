extends Area3D

@export var coin_value: int = 10
var rotation_speed: float = 3.0
var _collected: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	# Spin the coin visually
	rotate_y(rotation_speed * delta)

func _on_body_entered(body: Node3D) -> void:
	if _collected:
		return
	# Check if a player car drove over it
	if "player_id" in body or body.name.begins_with("DriftCar"):
		_collected = true
		CoinManager.add_money(coin_value)
		CoinManager.play_coin_pickup_sfx()
		queue_free() # Remove coin from world
