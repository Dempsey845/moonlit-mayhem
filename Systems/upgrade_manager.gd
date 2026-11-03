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

@onready var upgrade_info: Dictionary[UpgradeType, Dictionary] = {
    UpgradeType.Heart: {
        "max_upgrades": 5,
        "increase": 1,
        "initial_cost": 2,
        "cost_increase": 2
    },
    UpgradeType.Speed: {
        "max_upgrades": 5,
        "increase": 1,
        "property_name": &"speed",
        "target_node": player,
        "initial_cost": 3,
        "cost_increase": 3
    },
    UpgradeType.Duration: {
        "max_upgrades": 5,
        "increase": 2,
        "property_name": &"shrink_duration",
        "target_node": moonlight,
        "initial_cost": 2,
        "cost_increase": 2
    },
    UpgradeType.Angle: {
        "max_upgrades": 5,
        "increase": 5,
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

    if upgrades[type] >= info["max_upgrades"]:
        print("This upgrade has reached its max level!")
        return false

    if !info.has("property_name") or !info.has("target_node"):
        print("Upgrade has no property to change or node to effect!")
        return false
    
    if !is_instance_valid(info["target_node"]):
        print("The upgrades target node is not valid!")
        return false
    
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
    
    upgrades[type] += 1

    return true

func is_upgrade_maxed(type: UpgradeType) -> bool:
    var info: Dictionary = upgrade_info[type]

    return upgrades[type] >= info["max_upgrades"]

func get_upgrade_cost(type: UpgradeType) -> int:
    var info: Dictionary = upgrade_info[type]

    return (upgrades[type] * info["cost_increase"]) + info["initial_cost"]