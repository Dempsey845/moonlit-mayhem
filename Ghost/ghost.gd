class_name Ghost
extends CharacterBody3D

enum State { CHASE, FLEE, DEAD }

@export var player: Node3D
@export var chase_speed: float = 3.0
@export var flee_speed: float = 4.0
@export var flee_distance: float = 4.0
@export var repath_interval: float = 0.25

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

var state: State = State.CHASE
var repath_timer: float = 0.0

var original_collision_layer: int
var original_collision_mask: int

var start_position: Vector3


func _ready() -> void:
	original_collision_layer = collision_layer
	original_collision_mask = collision_mask

	start_position = global_position


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	if not is_instance_valid(player):
		return

	if NavigationServer3D.map_get_iteration_id(
		navigation_agent.get_navigation_map()
	) == 0:
		return

	repath_timer -= delta

	if repath_timer <= 0.0:
		update_target()
		repath_timer = repath_interval

	var direction: Vector3 = Vector3.ZERO

	if not navigation_agent.is_navigation_finished():
		var next_position: Vector3 = navigation_agent.get_next_path_position()
		direction = next_position - global_position
		direction.y = 0.0
		direction = direction.normalized()

	var speed: float = chase_speed if state == State.CHASE else flee_speed
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0

	if direction.length_squared() > 0.001:
		var target_angle: float = atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, 1.0 - exp(-10.0 * delta))

	move_and_slide()


func update_target() -> void:
	match state:
		State.CHASE:
			navigation_agent.target_position = player.global_position

		State.FLEE:
			var away: Vector3 = global_position - player.global_position
			away.y = 0.0

			if away.length_squared() < 0.01:
				away = Vector3.RIGHT

			var flee_target: Vector3 = (
				global_position + away.normalized() * flee_distance
			)

			navigation_agent.target_position = NavigationServer3D.map_get_closest_point(
				navigation_agent.get_navigation_map(),
				flee_target
			)


func set_fleeing(fleeing: bool) -> void:
	if state == State.DEAD:
		return

	state = State.FLEE if fleeing else State.CHASE
	repath_timer = 0.0


func die() -> void:
	if state == State.DEAD:
		return

	state = State.DEAD
	velocity = Vector3.ZERO
	set_physics_process(false)

	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

	hide()


func revive(start_state: State) -> void:
	global_position = start_position
	velocity = Vector3.ZERO
	repath_timer = 0.0
	state = start_state

	navigation_agent.target_position = start_position

	set_deferred("collision_layer", original_collision_layer)
	set_deferred("collision_mask", original_collision_mask)

	show()
	set_physics_process(true)
