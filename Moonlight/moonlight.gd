extends SpotLight3D

@export var player: Node3D
@export var ground_y: float = 0.0

var player_in_light: bool = false

func _physics_process(_delta: float) -> void:
	player_in_light = is_player_in_light()


func is_player_in_light() -> bool:
	if not is_instance_valid(player) or not is_visible_in_tree():
		return false

	var height: float = global_position.y - ground_y

	if height <= 0.0:
		return false

	var radius: float = height * tan(deg_to_rad(spot_angle))

	var light_position: Vector2 = Vector2(global_position.x, global_position.z)
	var player_position: Vector2 = Vector2(player.global_position.x, player.global_position.z)
	var distance_squared: float = light_position.distance_squared_to(player_position)

	var within_range: bool = height * height + distance_squared <= spot_range * spot_range

	return within_range and distance_squared <= radius * radius