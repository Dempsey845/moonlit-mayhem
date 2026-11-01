extends NavigationObstacle3D

@export var moonlight: Moonlight

func _process(_delta: float) -> void:
    global_position = Vector3(moonlight.global_position.x, 0, moonlight.global_position.z)