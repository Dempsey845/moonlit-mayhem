class_name Moonlight
extends SpotLight3D

signal target_entered_light
signal target_exited_light

signal non_target_entered_light(body: Node3D)

signal angle_changed(new_angle: float)

signal deplenished
signal moved

@export var ground_y: float = 0.0
@export var detection_height: float = 3.0

@export_group("Light Cycle")
@export var shrink_duration: float = 10.0
@export var respawn_delay: float = 2.0

@export var spawn_points: Array[Node3D] = []

@export var random_spawn_radius: float = 8.0

@export var fade_duration: float = 0.6

@onready var detection_area: Area3D = $Area3D
@onready var detection_shape: CollisionShape3D = $Area3D/CollisionShape3D

var current_target: Node3D
var current_target_in_light: bool = false

var starting_angle: float
var starting_position: Vector3
var cylinder: CylinderShape3D
var last_spawn_point: Node3D

var starting_energy: float

const MIN_ANGLE: float = 12.0


func _ready() -> void:
	starting_angle = spot_angle
	starting_position = global_position

	starting_energy = light_energy
	light_energy = 0.0

	cylinder = CylinderShape3D.new()
	detection_shape.shape = cylinder

	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	visibility_changed.connect(_on_visibility_changed)

	refresh_detection()

	call_deferred("_run_light_cycle")


func _run_light_cycle() -> void:
	var first_spawn := true

	while is_inside_tree():
		_set_light_angle(starting_angle)
		light_energy = 0.0
		show()

		for body in detection_area.get_overlapping_bodies():
			_on_body_entered(body)

		if not first_spawn:
			moved.emit()

		first_spawn = false

		await _fade_to(starting_energy)

		var tween := create_tween()
		tween.tween_method(
			_set_light_angle,
			starting_angle,
			MIN_ANGLE,
			maxf(shrink_duration, 0.01)
		)

		await tween.finished

		deplenished.emit()

		await _fade_to(0.0)

		hide()
		_set_target_in_light(false)

		_move_to_next_position()
		_set_light_angle(starting_angle)

		await get_tree().create_timer(
			maxf(respawn_delay, 0.01)
		).timeout


func _fade_to(energy: float) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(
		self,
		"light_energy",
		energy,
		maxf(fade_duration, 0.01)
	)

	await tween.finished


func _set_light_angle(angle: float) -> void:
	spot_angle = maxf(angle, 0.01)
	refresh_detection()
	angle_changed.emit(angle)


func refresh_detection() -> void:
	var height := maxf(global_position.y - ground_y, 0.0)
	var cone_radius := height * tan(deg_to_rad(spot_angle))
	var range_radius := sqrt(maxf(
		spot_range * spot_range - height * height,
		0.0
	))

	cylinder.radius = maxf(
		minf(cone_radius, range_radius),
		0.001
	)
	cylinder.height = detection_height

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


func _move_to_next_position() -> void:
	var available_points: Array[Node3D] = []

	for point in spawn_points:
		if is_instance_valid(point) and point != last_spawn_point:
			available_points.append(point)

	var next_position := global_position

	if not available_points.is_empty():
		last_spawn_point = available_points.pick_random()
		next_position.x = last_spawn_point.global_position.x
		next_position.z = last_spawn_point.global_position.z
	else:
		var angle := randf() * TAU
		var distance := sqrt(randf()) * random_spawn_radius

		next_position.x = starting_position.x + cos(angle) * distance
		next_position.z = starting_position.z + sin(angle) * distance

	global_position = next_position


func _on_body_entered(body: Node3D) -> void:
	if !is_visible_in_tree():
		return

	if body == current_target:
		_set_target_in_light(true)
	else:
		non_target_entered_light.emit(body)
	


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