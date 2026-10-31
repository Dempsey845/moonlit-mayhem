extends Node

@export var moonlight: Moonlight
@export var player: Player
@export var moon_light_follow_speed: float = 9.0
@export var ghost_container: Node3D

var ghosts: Array[Ghost] = []
var is_moonlight_following: bool = false


func _ready() -> void:
	set_process(false)

	for child in ghost_container.get_children():
		if child is Ghost:
			ghosts.append(child)

	moonlight.target_entered_light.connect(_on_target_entered_light)
	moonlight.target_exited_light.connect(_on_target_exited_light)
	moonlight.current_target = player

	moonlight.non_target_entered_light.connect(_on_moonlight_non_target_entered)


func _process(delta: float) -> void:
	var weight := 1.0 - exp(-moon_light_follow_speed * delta)
	var position := moonlight.global_position

	position.x = lerpf(position.x, player.global_position.x, weight)
	position.z = lerpf(position.z, player.global_position.z, weight)

	moonlight.global_position = position


func _on_target_entered_light() -> void:
	is_moonlight_following = true
	set_process(true)
	set_ghosts_fleeing(true)


func _on_target_exited_light() -> void:
	is_moonlight_following = false
	set_process(false)
	set_ghosts_fleeing(false)


func set_ghosts_fleeing(fleeing: bool) -> void:
	for ghost in ghosts:
		if is_instance_valid(ghost):
			ghost.set_fleeing(fleeing)

func _on_moonlight_non_target_entered(body: Node3D):
	if !is_moonlight_following:
		return

	if body is Ghost:
		print("Ghost hit by light")