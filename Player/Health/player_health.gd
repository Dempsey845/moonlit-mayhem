class_name PlayerHealth
extends Node

signal health_changed(current_health: int, max_health: int)
signal max_health_changed(max_health: int)
signal damaged(amount: int)
signal healed(amount: int)
signal died

@export var starting_max_health: int = 3

@export_range(0.0, 5.0, 0.05, "suffix:s") var invulnerability_duration: float = 0.5

var _is_invulnerable: bool = false

var max_health: int = 3:
	get:
		return max_health
	set(value):
		var new_max: int = maxi(value, 1)
		if new_max == max_health:
			return

		max_health = new_max
		max_health_changed.emit(max_health)

		if current_health > max_health:
			current_health = max_health
		else:
			health_changed.emit(current_health, max_health)

var current_health: int = 3:
	get:
		return current_health
	set(value):
		var new_health: int = clampi(value, 0, max_health)
		if new_health == current_health:
			return

		var previous_health: int = current_health
		current_health = new_health
		health_changed.emit(current_health, max_health)

		if current_health == 0 and previous_health > 0:
			died.emit()


func _ready() -> void:
	max_health = starting_max_health
	current_health = max_health


func take_damage(amount: int) -> void:
	if amount <= 0 or current_health == 0 or _is_invulnerable:
		return

	var actual_damage: int = mini(amount, current_health)

	if invulnerability_duration > 0.0 and actual_damage < current_health:
		_start_invulnerability()

	current_health -= actual_damage
	damaged.emit(actual_damage)


func _start_invulnerability() -> void:
	_is_invulnerable = true
	await get_tree().create_timer(invulnerability_duration, false).timeout
	_is_invulnerable = false


func heal(amount: int) -> void:
	if amount <= 0 or current_health == 0:
		return

	var actual_healing: int = mini(amount, max_health - current_health)
	if actual_healing == 0:
		return

	current_health += actual_healing
	healed.emit(actual_healing)


func upgrade_max_health(amount: int, restore_health: bool = true) -> void:
	if amount <= 0:
		return

	max_health += amount

	if restore_health:
		heal(max_health)