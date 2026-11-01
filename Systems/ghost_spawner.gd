class_name GhostSpawner
extends Node

signal all_ghosts_inactive

var ghosts: Array[Ghost] = []

@export var ghost_container: Node3D

var ghost_scene: PackedScene = preload("uid://wrg516q7xe4g")

var start_ghosts: int = 10

var active_ghosts: int = 0

func _ready() -> void:
	for child in ghost_container.get_children():
		if child is Ghost:
			ghosts.append(child)

	await get_tree().create_timer(2.0).timeout

	spawn_ghosts(start_ghosts, Ghost.State.CHASE)

func spawn_ghosts(amount: int, start_state: Ghost.State) -> int:
	var ghosts_spawned: int = 0

	for ghost in ghosts:
		if ghosts_spawned >= amount:
			return ghosts_spawned

		if ghost.state == Ghost.State.DEAD:
			ghost.revive(start_state)
			active_ghosts += 1
			ghosts_spawned += 1
	
	# if ghosts_spawned < amount:
	# 	for i in range(amount - ghosts_spawned):
	# 		var new_ghost: Ghost = ghost_scene.instantiate()

	# 		ghost_container.add_child(new_ghost)

	# 		new_ghost.global_position = Vector3.ZERO

	# 		ghosts.append(new_ghost)

	# 		active_ghosts += 1

	return ghosts_spawned

func deactivate_ghost(ghost: Ghost):
	ghost.die()
	active_ghosts -= 1

	if active_ghosts <= 0:
		active_ghosts = 0
		all_ghosts_inactive.emit()
