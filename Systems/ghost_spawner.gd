class_name GhostSpawner
extends Node

signal all_ghosts_inactive

@export var ghost_container: Node3D
@export_range(1, 100) var start_ghosts: int = 2

var ghosts: Array[Ghost] = []

var max_ghosts: int:
	get:
		var count: int = 0
		for ghost in ghosts:
			if is_instance_valid(ghost):
				count += 1
		return count

var active_ghosts: int:
	get:
		var count: int = 0
		for ghost in ghosts:
			if is_instance_valid(ghost) and ghost.state != Ghost.State.DEAD:
				count += 1
		return count


func _ready() -> void:
	if ghost_container == null:
		push_error("Assign a ghost container to GhostSpawner.")
		return

	for child in ghost_container.get_children():
		if child is Ghost:
			ghosts.append(child)

			if child.state != Ghost.State.DEAD:
				child.die()


func spawn_ghosts(amount: int, start_state: Ghost.State) -> int:
	if amount <= 0 or start_state == Ghost.State.DEAD:
		return 0

	var spawned: int = 0

	for ghost in ghosts:
		if spawned >= amount:
			break

		if not is_instance_valid(ghost):
			continue

		if ghost.state != Ghost.State.DEAD:
			continue

		ghost.revive(start_state)
		spawned += 1

	return spawned


func deactivate_ghost(ghost: Ghost) -> bool:
	if not is_instance_valid(ghost):
		return false

	if not ghosts.has(ghost) or ghost.state == Ghost.State.DEAD:
		return false

	ghost.die()

	if active_ghosts == 0:
		all_ghosts_inactive.emit()

	return true