class_name UpgradeManager
extends Node

enum UpgradeType {
	Heart,
	Speed,
	Duration,
	Angle
}

@export var player: Player
@export var moonlight: Moonlight
@export var ghost_counter: GhostCounter
@export var player_health: PlayerHealth

@onready var upgrade_info: Dictionary[UpgradeType, Dictionary] = {
	UpgradeType.Heart: {
		"max_upgrades": 5,
		"function_name": "upgrade_max_health",
		"function_arguments": [1, true],
		"target_node": player_health,
		"initial_cost": 2,
		"cost_increase": 4
	},
	UpgradeType.Speed: {
		"max_upgrades": 5,
		"increase": 1,
		"property_name": &"speed",
		"target_node": player,
		"initial_cost": 3,
		"cost_increase": 5
	},
	UpgradeType.Duration: {
		"max_upgrades": 10,
		"increase": 1,
		"property_name": &"shrink_duration",
		"target_node": moonlight,
		"initial_cost": 2,
		"cost_increase": 3
	},
	UpgradeType.Angle: {
		"max_upgrades": 12,
		"increase": 2,
		"property_name": &"starting_angle",
		"target_node": moonlight,
		"initial_cost": 2,
		"cost_increase": 3
	}
}

var upgrades: Dictionary[UpgradeType, int] = {
	UpgradeType.Heart: 0,
	UpgradeType.Speed: 0,
	UpgradeType.Duration: 0,
	UpgradeType.Angle: 0,
}

func try_apply_upgrade(type: UpgradeType) -> bool:
	var info: Dictionary = upgrade_info[type]

	var cost: int = get_upgrade_cost(type)

	if upgrades[type] >= info["max_upgrades"]:
		print("This upgrade has reached its max level!")
		return false

	if cost > ghost_counter.ghost_count:
		print("Does not have enough ghosts for upgrade")
		return false

	if (!info.has("property_name") and !info.has("function_name")) or !info.has("target_node"):
		print("Upgrade has no property to change or node to effect!")
		return false
	
	if !is_instance_valid(info["target_node"]):
		print("The upgrades target node is not valid!")
		return false
	

	if info.has("property_name"):
		if !_try_apply_property_change(info):
			return false
	
	if info.has("function_name"):
		_apply_upgrade_function(info)
	
	upgrades[type] += 1

	ghost_counter.remove_ghosts(cost)

	return true

func _try_apply_property_change(info: Dictionary) -> bool:
	var target_node: Node = info["target_node"]

	var property_name: StringName = info["property_name"]

	if target_node.get(property_name) == null:
		print("The upgrades property name does not exist!")
		return false
	
	var property = target_node.get(property_name)

	if typeof(property) != TYPE_INT and typeof(property) != TYPE_FLOAT:
		print("The upgrades property is not an integer or float!")
		return false
	
	target_node.set(property_name, property + info["increase"])

	return true

func _apply_upgrade_function(info: Dictionary) -> void:
	var target_node: Node = info["target_node"]

	target_node.callv(
		info["function_name"],
		info["function_arguments"]
	)

func is_upgrade_maxed(type: UpgradeType) -> bool:
	var info: Dictionary = upgrade_info[type]

	return upgrades[type] >= info["max_upgrades"]

func get_max_upgrades(type: UpgradeType) -> int:
	var info: Dictionary = upgrade_info[type]
	return info["max_upgrades"]

func get_upgrade_cost(type: UpgradeType) -> int:
	var info: Dictionary = upgrade_info[type]

	return (upgrades[type] * info["cost_increase"]) + info["initial_cost"]