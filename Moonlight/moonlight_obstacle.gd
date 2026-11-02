extends NavigationObstacle3D

@export var moonlight: Moonlight

var previous_angle: float

func _ready() -> void:
	previous_angle = moonlight.spot_angle

	moonlight.angle_changed.connect(_on_moonlight_angle_changed)

func _process(_delta: float) -> void:
	global_position = Vector3(moonlight.global_position.x, 0, moonlight.global_position.z)

func _on_moonlight_angle_changed(new_angle):
	if abs(new_angle - previous_angle) > 5:
		previous_angle = new_angle

		var extent = 2.5 * tan(deg_to_rad(new_angle)) / tan(deg_to_rad(30.0))

		vertices = PackedVector3Array([
			Vector3(-extent, 0.0, -extent),
			Vector3( extent, 0.0, -extent),
			Vector3( extent, 0.0,  extent),
			Vector3(-extent, 0.0,  extent)
		])