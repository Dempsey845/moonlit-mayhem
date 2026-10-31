class_name Moonlight
extends SpotLight3D

signal target_entered_light
signal target_exited_light

@export var ground_y: float = 0.0
@export var detection_height: float = 3.0

@onready var detection_area: Area3D = $Area3D
@onready var detection_shape: CollisionShape3D = $Area3D/CollisionShape3D

var current_target: Node3D
var current_target_in_light: bool = false


func _ready() -> void:
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	visibility_changed.connect(_on_visibility_changed)

	refresh_detection()


func refresh_detection() -> void:
	var height := maxf(global_position.y - ground_y, 0.0)
	var cone_radius := height * tan(deg_to_rad(spot_angle))
	var range_radius := sqrt(maxf(
		spot_range * spot_range - height * height,
		0.0
	))

	var shape := CylinderShape3D.new()
	shape.radius = maxf(minf(cone_radius, range_radius), 0.001)
	shape.height = detection_height
	detection_shape.shape = shape

	detection_area.global_transform = Transform3D(
		Basis.IDENTITY,
		Vector3(
			global_position.x,
			ground_y + detection_height * 0.5,
			global_position.z
		)
	)

	detection_shape.set_deferred(
		"disabled",
		height <= 0.0 or height >= spot_range
	)


func _on_body_entered(body: Node3D) -> void:
	if body == current_target and is_visible_in_tree():
		_set_target_in_light(true)


func _on_body_exited(body: Node3D) -> void:
	if body == current_target:
		_set_target_in_light(false)


func _on_visibility_changed() -> void:
	if not is_node_ready():
		return

	_set_target_in_light(
		is_visible_in_tree()
		and is_instance_valid(current_target)
		and detection_area.overlaps_body(current_target)
	)


func _set_target_in_light(value: bool) -> void:
	if current_target_in_light == value:
		return

	current_target_in_light = value

	if value:
		target_entered_light.emit()
	else:
		target_exited_light.emit()