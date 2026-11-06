class_name HealthPickupSpawner
extends Node

@export var health_pickup_points: Node3D
@export var player_health: PlayerHealth

var health_pickup_spawn_points: Array[Marker3D] = []
var health_pickup_scene: PackedScene = preload("uid://qpt3jh3sivml")

var _pickups_by_spawn_point: Dictionary = {}


func _ready() -> void:
	for child in health_pickup_points.get_children():
		if child is Marker3D:
			health_pickup_spawn_points.append(child)


func try_spawn_health_pickup() -> bool:
	var available_points: Array[Marker3D] = []

	for spawn_point in health_pickup_spawn_points:
		if is_instance_valid(spawn_point) and not is_instance_valid(
			_pickups_by_spawn_point.get(spawn_point)
		):
			available_points.append(spawn_point)

	if available_points.is_empty():
		return false

	var spawn_point: Marker3D = available_points.pick_random()
	var pickup: HealthPickup = health_pickup_scene.instantiate() as Node3D
	pickup.player_health = player_health

	_pickups_by_spawn_point[spawn_point] = pickup
	spawn_point.add_child(pickup)

	return true